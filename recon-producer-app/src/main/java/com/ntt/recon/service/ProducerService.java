package com.ntt.recon.service;

import com.ntt.recon.config.ReconciliationProperties;
import com.ntt.recon.domain.ReconciliationTransaction;
import com.ntt.recon.domain.SimulationMode;
import com.ntt.recon.exception.ProducerPublishException;
import com.ntt.recon.support.MqExceptionClassifier;
import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import jakarta.jms.Message;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.slf4j.MDC;
import org.springframework.jms.JmsException;
import org.springframework.jms.core.JmsTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
public class ProducerService {
    private static final Logger log = LoggerFactory.getLogger(ProducerService.class);

    private final JmsTemplate jmsTemplate;
    private final ReconciliationProperties properties;
    private final TransactionGenerator generator;
    private final SimulationState simulationState;
    private final Counter produced;
    private final Counter producerFailures;
    private final Counter generationFailures;

    public ProducerService(
            JmsTemplate jmsTemplate,
            ReconciliationProperties properties,
            TransactionGenerator generator,
            SimulationState simulationState,
            MeterRegistry registry
    ) {
        this.jmsTemplate = jmsTemplate;
        this.properties = properties;
        this.generator = generator;
        this.simulationState = simulationState;
        this.produced = Counter.builder("recon_producer_messages_total").register(registry);
        this.producerFailures = Counter.builder("recon_producer_failures_total").register(registry);
        this.generationFailures = Counter.builder("recon_producer_generation_failures_total").register(registry);
    }

    @Scheduled(fixedRateString = "${recon.producer-interval-ms}")
    public void publishBatch() {
        try {
            publishBatchSafely();
        } catch (RuntimeException ex) {
            generationFailures.increment();
            log.error("event=producer_batch_failed action=continue_next_schedule", ex);
        }
    }

    private void publishBatchSafely() {
        SimulationMode mode = simulationState.current();
        if (mode == SimulationMode.MQ_OUTAGE) {
            producerFailures.increment();
            log.warn("mq_outage_simulated=true action=skip_publish");
            return;
        }
        for (int i = 0; i < properties.producerTps(); i++) {
            ReconciliationTransaction transaction = generator.next(properties.invalidPercent(), mode, properties.messageSource());
            String correlationId = mode == SimulationMode.DUPLICATE_MESSAGE && i % 5 == 0
                    ? "duplicate-correlation-id"
                    : UUID.randomUUID().toString();
            publish(transaction, correlationId);
            if (mode == SimulationMode.DUPLICATE_MESSAGE && i % 5 == 0) {
                publish(transaction, correlationId);
            }
        }
    }

    private void publish(ReconciliationTransaction transaction, String correlationId) {
        try (MDC.MDCCloseable ignored = MDC.putCloseable("correlationId", correlationId)) {
            jmsTemplate.convertAndSend(properties.inputQueue(), transaction, message -> enrich(message, correlationId));
            produced.increment();
            log.info("event=transaction_published transactionId={} queue={}", transaction.transactionId(), properties.inputQueue());
        } catch (JmsException ex) {
            producerFailures.increment();
            if (MqExceptionClassifier.isMqrc2035(ex)) {
                log.error("event=mq_authorization_failed mqrc=2035 action=verify_mq_user_channel_authentication transactionId={}",
                        transaction.transactionId(), ex);
                return;
            }
            log.error("event=transaction_publish_failed transactionId={} action=continue", transaction.transactionId(), ex);
        } catch (RuntimeException ex) {
            producerFailures.increment();
            throw new ProducerPublishException("Unexpected producer failure while publishing transaction " + transaction.transactionId(), ex);
        }
    }

    private Message enrich(Message message, String correlationId) throws jakarta.jms.JMSException {
        message.setJMSCorrelationID(correlationId);
        message.setStringProperty("correlationId", correlationId);
        message.setStringProperty("traceparent", UUID.randomUUID().toString());
        message.setStringProperty("source", properties.messageSource());
        return message;
    }
}
