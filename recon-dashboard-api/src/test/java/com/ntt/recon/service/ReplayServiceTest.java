package com.ntt.recon.service;

import com.ntt.recon.config.ReconciliationProperties;
import com.ntt.recon.domain.ReconciliationTransaction;
import com.ntt.recon.domain.SimulationMode;
import jakarta.jms.Message;
import org.junit.jupiter.api.Test;
import org.springframework.jms.JmsException;
import org.springframework.jms.core.JmsTemplate;
import org.springframework.jms.core.MessagePostProcessor;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class ReplayServiceTest {
    private final JmsTemplate jmsTemplate = mock(JmsTemplate.class);
    private final ReplayService service = new ReplayService(jmsTemplate, properties());

    @Test
    void republishesTransactionToInputQueueWithReplayMetadata() throws Exception {
        ReconciliationTransaction transaction = transaction();

        String replayCorrelationId = service.replay(transaction, "original-corr");

        org.mockito.ArgumentCaptor<MessagePostProcessor> captor = org.mockito.ArgumentCaptor.forClass(MessagePostProcessor.class);
        verify(jmsTemplate).convertAndSend(eq("RECON.IN"), eq(transaction), captor.capture());
        assertThat(replayCorrelationId).startsWith("replay-");

        Message message = mock(Message.class);
        captor.getValue().postProcessMessage(message);
        verify(message).setJMSCorrelationID(replayCorrelationId);
        verify(message).setStringProperty("originalCorrelationId", "original-corr");
        verify(message).setStringProperty("replayed", "true");
    }

    @Test
    void rethrowsReplayPublishFailureAfterClassifyingMqAuthorizationErrors() {
        ReconciliationTransaction transaction = transaction();
        doThrow(new JmsException("JMSCMQ0001 reason '2035'") { })
                .when(jmsTemplate).convertAndSend(eq("RECON.IN"), eq(transaction), org.mockito.ArgumentMatchers.any(MessagePostProcessor.class));

        assertThatThrownBy(() -> service.replay(transaction, "original-corr"))
                .isInstanceOf(JmsException.class);
    }

    private static ReconciliationTransaction transaction() {
        return new ReconciliationTransaction("txn-1", "CARD", "ACCT-1", BigDecimal.TEN, "SGD", Instant.now(), false, SimulationMode.NORMAL, Map.of());
    }

    private static ReconciliationProperties properties() {
        return new ReconciliationProperties(
                "RECON.IN", "RECON.RETRY", "RECON.BACKOUT", "SYSTEM.DEAD.LETTER.QUEUE", "RECON.REPLAY",
                1, 0, 1, 1, 2, 1);
    }
}
