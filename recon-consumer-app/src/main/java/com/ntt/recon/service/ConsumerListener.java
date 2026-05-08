package com.ntt.recon.service;

import com.ntt.recon.config.ReconciliationProperties;
import com.ntt.recon.domain.ReconciliationTransaction;
import com.ntt.recon.domain.SimulationMode;
import com.ntt.recon.exception.BackoutPublishException;
import com.ntt.recon.exception.ReconciliationProcessingException;
import com.ntt.recon.exception.RetryPublishException;
import com.ntt.recon.support.MqExceptionClassifier;
import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import jakarta.jms.JMSException;
import jakarta.jms.Message;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.slf4j.MDC;
import org.springframework.jms.JmsException;
import org.springframework.jms.annotation.JmsListener;
import org.springframework.jms.core.JmsTemplate;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.stereotype.Component;

@Component
public class ConsumerListener {
    private static final Logger log = LoggerFactory.getLogger(ConsumerListener.class);
    private static final int DEFAULT_BACKOUT_THRESHOLD = 3;
    private static final String RETRY_ATTEMPT_PROPERTY = "reconRetryAttempt";
    private static final int MAX_FAILURE_REASON_LENGTH = 512;

    private final ReconciliationService reconciliationService;
    private final JmsTemplate jmsTemplate;
    private final ReconciliationProperties properties;
    private final Counter consumed;
    private final Counter retry;
    private final Counter backout;
    private final Counter processingFailures;
    private final Counter retryFailures;
    private final Counter backoutFailures;

    public ConsumerListener(
            ReconciliationService reconciliationService,
            JmsTemplate jmsTemplate,
            ReconciliationProperties properties,
            MeterRegistry registry
    ) {
        this.reconciliationService = reconciliationService;
        this.jmsTemplate = jmsTemplate;
        this.properties = properties;
        this.consumed = Counter.builder("recon_consumer_messages_total").register(registry);
        this.retry = Counter.builder("recon_retry_messages_total").register(registry);
        this.backout = Counter.builder("recon_backout_messages_total").register(registry);
        this.processingFailures = Counter.builder("recon_consumer_processing_failures_total").register(registry);
        this.retryFailures = Counter.builder("recon_retry_publish_failures_total").register(registry);
        this.backoutFailures = Counter.builder("recon_backout_publish_failures_total").register(registry);
    }

    @JmsListener(destination = "${recon.input-queue}")
    public void onMessage(@Payload ReconciliationTransaction transaction, Message message) throws JMSException {
        handleMessage(transaction, message, false);
    }

    @JmsListener(destination = "${recon.retry-queue}")
    public void onRetryMessage(@Payload ReconciliationTransaction transaction, Message message) throws JMSException {
        handleMessage(transaction, message, true);
    }

    private void handleMessage(ReconciliationTransaction transaction, Message message, boolean retryQueueMessage) throws JMSException {
        String correlationId = correlationId(message);
        try (MDC.MDCCloseable ignored = MDC.putCloseable("correlationId", correlationId)) {
            if (transaction == null) {
                throw new ReconciliationProcessingException("Received null transaction payload", null);
            }
            if (transaction.simulationMode() == SimulationMode.CONSUMER_CRASH) {
                log.error("event=consumer_crash_simulated correlationId={}", correlationId);
                Runtime.getRuntime().halt(137);
            }
            consumed.increment();
            log.info("event=transaction_consumed transactionId={}", transaction.transactionId());
            reconciliationService.reconcileWithRetry(transaction, correlationId);
        } catch (RuntimeException ex) {
            processingFailures.increment();
            handleProcessingFailure(transaction, message, correlationId, retryQueueMessage, ex);
        }
    }

    private void handleProcessingFailure(ReconciliationTransaction transaction,
                                         Message message,
                                         String correlationId,
                                         boolean retryQueueMessage,
                                         RuntimeException ex) {
        int deliveryCount = deliveryCount(message);
        int retryAttempt = retryAttempt(message);
        if (deliveryCount >= DEFAULT_BACKOUT_THRESHOLD || retryAttempt >= DEFAULT_BACKOUT_THRESHOLD - 1) {
            moveToBackout(transaction, correlationId, ex);
            return;
        }
        moveToRetry(transaction, correlationId, retryQueueMessage ? retryAttempt + 1 : 1, ex);
    }

    private void moveToRetry(ReconciliationTransaction transaction, String correlationId, int nextRetryAttempt, RuntimeException ex) {
        try {
            jmsTemplate.convertAndSend(properties.retryQueue(), transaction, out -> {
                out.setJMSCorrelationID(correlationId);
                out.setStringProperty("originalQueue", properties.inputQueue());
                out.setIntProperty(RETRY_ATTEMPT_PROPERTY, nextRetryAttempt);
                out.setStringProperty("failureReason", safeReason(ex));
                return out;
            });
            retry.increment();
            log.warn("event=message_moved_to_retry correlationId={} retryAttempt={} queue={}",
                    correlationId, nextRetryAttempt, properties.retryQueue(), ex);
        } catch (JmsException publishFailure) {
            retryFailures.increment();
            if (MqExceptionClassifier.isMqrc2035(publishFailure)) {
                log.error("event=mq_authorization_failed mqrc=2035 action=verify_mq_user_channel_authentication correlationId={}",
                        correlationId, publishFailure);
            } else {
                log.error("event=retry_publish_failed correlationId={} action=redeliver_original", correlationId, publishFailure);
            }
            throw new RetryPublishException("Failed to publish message to retry queue", publishFailure);
        }
    }

    private void moveToBackout(ReconciliationTransaction transaction, String correlationId, RuntimeException ex) {
        try {
            jmsTemplate.convertAndSend(properties.backoutQueue(), transaction, out -> {
                out.setJMSCorrelationID(correlationId);
                out.setStringProperty("originalQueue", properties.inputQueue());
                out.setStringProperty("failureReason", safeReason(ex));
                return out;
            });
            backout.increment();
            log.error("event=message_moved_to_backout correlationId={}", correlationId, ex);
        } catch (JmsException publishFailure) {
            backoutFailures.increment();
            if (MqExceptionClassifier.isMqrc2035(publishFailure)) {
                log.error("event=mq_authorization_failed mqrc=2035 action=verify_mq_user_channel_authentication correlationId={}",
                        correlationId, publishFailure);
            } else {
                log.error("event=backout_publish_failed correlationId={} action=redeliver_original", correlationId, publishFailure);
            }
            throw new BackoutPublishException("Failed to publish message to backout queue", publishFailure);
        }
    }

    private String correlationId(Message message) throws JMSException {
        String correlationId = message.getJMSCorrelationID();
        return correlationId == null || correlationId.isBlank() ? message.getJMSMessageID() : correlationId;
    }

    private int deliveryCount(Message message) {
        try {
            return message.getIntProperty("JMSXDeliveryCount");
        } catch (JMSException ex) {
            log.warn("event=delivery_count_unavailable action=assume_first_delivery", ex);
            return 1;
        }
    }

    private int retryAttempt(Message message) {
        try {
            return message.propertyExists(RETRY_ATTEMPT_PROPERTY) ? message.getIntProperty(RETRY_ATTEMPT_PROPERTY) : 0;
        } catch (JMSException ex) {
            log.warn("event=retry_attempt_unavailable action=assume_first_retry", ex);
            return 0;
        }
    }

    private String safeReason(Throwable ex) {
        String message = ex.getMessage() == null ? ex.getClass().getSimpleName() : ex.getMessage();
        return message.length() <= MAX_FAILURE_REASON_LENGTH ? message : message.substring(0, MAX_FAILURE_REASON_LENGTH);
    }
}
