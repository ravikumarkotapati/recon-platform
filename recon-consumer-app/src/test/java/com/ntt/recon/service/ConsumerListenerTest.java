package com.ntt.recon.service;

import com.ntt.recon.config.ReconciliationProperties;
import com.ntt.recon.domain.ReconciliationTransaction;
import com.ntt.recon.domain.SimulationMode;
import com.ntt.recon.exception.BackoutPublishException;
import com.ntt.recon.exception.RetryPublishException;
import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import jakarta.jms.Message;
import org.junit.jupiter.api.Test;
import org.springframework.jms.JmsException;
import org.springframework.jms.core.JmsTemplate;
import org.springframework.jms.core.MessagePostProcessor;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.isNull;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class ConsumerListenerTest {
    private final ReconciliationService reconciliationService = mock(ReconciliationService.class);
    private final JmsTemplate jmsTemplate = mock(JmsTemplate.class);
    private final ConsumerListener listener = new ConsumerListener(reconciliationService, jmsTemplate, props(), new SimpleMeterRegistry());

    @Test
    void movesMessageToBackoutAfterDeliveryThreshold() throws Exception {
        ReconciliationTransaction transaction = transaction();
        Message message = message(3);
        doThrow(new IllegalStateException("processing failed"))
                .when(reconciliationService).reconcileWithRetry(transaction, "corr-1");

        listener.onMessage(transaction, message);

        verify(jmsTemplate).convertAndSend(eq("RECON.BACKOUT"), eq(transaction), any(MessagePostProcessor.class));
    }

    @Test
    void throwsWhenBackoutPublishFailsSoOriginalMessageCanBeRedelivered() throws Exception {
        ReconciliationTransaction transaction = transaction();
        Message message = message(3);
        doThrow(new IllegalStateException("processing failed"))
                .when(reconciliationService).reconcileWithRetry(transaction, "corr-1");
        doThrow(new JmsException("backout unavailable") { })
                .when(jmsTemplate).convertAndSend(eq("RECON.BACKOUT"), eq(transaction), any(MessagePostProcessor.class));

        assertThatThrownBy(() -> listener.onMessage(transaction, message))
                .isInstanceOf(BackoutPublishException.class);
    }

    @Test
    void movesFirstFailureToRetryQueue() throws Exception {
        ReconciliationTransaction transaction = transaction();
        Message message = message(2);
        doThrow(new IllegalStateException("processing failed"))
                .when(reconciliationService).reconcileWithRetry(transaction, "corr-1");

        listener.onMessage(transaction, message);

        verify(jmsTemplate).convertAndSend(eq("RECON.RETRY"), eq(transaction), any(MessagePostProcessor.class));
    }

    @Test
    void fallsBackToJmsMessageIdWhenCorrelationIdIsBlank() throws Exception {
        ReconciliationTransaction transaction = transaction();
        Message message = message(1);
        when(message.getJMSCorrelationID()).thenReturn(" ");

        listener.onMessage(transaction, message);

        verify(reconciliationService).reconcileWithRetry(transaction, "msg-1");
    }

    @Test
    void assumesFirstDeliveryWhenDeliveryCountCannotBeRead() throws Exception {
        ReconciliationTransaction transaction = transaction();
        Message message = message(1);
        when(message.getIntProperty("JMSXDeliveryCount")).thenThrow(new jakarta.jms.JMSException("missing"));
        doThrow(new IllegalStateException("processing failed"))
                .when(reconciliationService).reconcileWithRetry(transaction, "corr-1");

        listener.onMessage(transaction, message);

        verify(jmsTemplate).convertAndSend(eq("RECON.RETRY"), eq(transaction), any(MessagePostProcessor.class));
    }

    @Test
    void retryQueueMessageMovesToBackoutAfterRetryAttemptsAreExhausted() throws Exception {
        ReconciliationTransaction transaction = transaction();
        Message message = message(1);
        when(message.propertyExists("reconRetryAttempt")).thenReturn(true);
        when(message.getIntProperty("reconRetryAttempt")).thenReturn(2);
        doThrow(new IllegalStateException("processing failed"))
                .when(reconciliationService).reconcileWithRetry(transaction, "corr-1");

        listener.onRetryMessage(transaction, message);

        verify(jmsTemplate).convertAndSend(eq("RECON.BACKOUT"), eq(transaction), any(MessagePostProcessor.class));
    }

    @Test
    void retryPublishFailureRethrowsSoOriginalMessageCanBeRedelivered() throws Exception {
        ReconciliationTransaction transaction = transaction();
        Message message = message(1);
        doThrow(new IllegalStateException("processing failed"))
                .when(reconciliationService).reconcileWithRetry(transaction, "corr-1");
        doThrow(new JmsException("JMSCMQ0001 reason '2035'") { })
                .when(jmsTemplate).convertAndSend(eq("RECON.RETRY"), eq(transaction), any(MessagePostProcessor.class));

        assertThatThrownBy(() -> listener.onMessage(transaction, message))
                .isInstanceOf(RetryPublishException.class);
    }

    @Test
    void nullPayloadMovesToBackoutAtThreshold() throws Exception {
        Message message = message(3);

        listener.onMessage(null, message);

        verify(jmsTemplate).convertAndSend(eq("RECON.BACKOUT"), isNull(), any(MessagePostProcessor.class));
    }

    @Test
    void truncatesFailureReasonWhenMovingToBackout() throws Exception {
        ReconciliationTransaction transaction = transaction();
        Message message = message(3);
        doThrow(new IllegalStateException("x".repeat(600)))
                .when(reconciliationService).reconcileWithRetry(transaction, "corr-1");

        listener.onMessage(transaction, message);

        org.mockito.ArgumentCaptor<MessagePostProcessor> captor = org.mockito.ArgumentCaptor.forClass(MessagePostProcessor.class);
        verify(jmsTemplate).convertAndSend(eq("RECON.BACKOUT"), eq(transaction), captor.capture());
        Message backoutMessage = mock(Message.class);
        captor.getValue().postProcessMessage(backoutMessage);
        verify(backoutMessage).setStringProperty(eq("failureReason"), org.mockito.ArgumentMatchers.argThat(reason -> reason.length() == 512));
    }

    private static Message message(int deliveryCount) throws Exception {
        Message message = mock(Message.class);
        when(message.getJMSCorrelationID()).thenReturn("corr-1");
        when(message.getJMSMessageID()).thenReturn("msg-1");
        when(message.getIntProperty("JMSXDeliveryCount")).thenReturn(deliveryCount);
        return message;
    }

    private static ReconciliationTransaction transaction() {
        return new ReconciliationTransaction("txn-1", "CARD", "ACCT-1", BigDecimal.TEN, "SGD", Instant.now(), false, SimulationMode.NORMAL, Map.of());
    }

    private static ReconciliationProperties props() {
        return new ReconciliationProperties("RECON.IN", "RECON.RETRY", "RECON.BACKOUT", "SYSTEM.DEAD.LETTER.QUEUE", "RECON.REPLAY", 1, 0, 1, 1, 2, 1);
    }
}
