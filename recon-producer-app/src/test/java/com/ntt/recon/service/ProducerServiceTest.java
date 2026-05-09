package com.ntt.recon.service;

import com.ntt.recon.config.ReconciliationProperties;
import com.ntt.recon.domain.ReconciliationTransaction;
import com.ntt.recon.domain.SimulationMode;
import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import jakarta.jms.Message;
import org.junit.jupiter.api.Test;
import org.springframework.jms.JmsException;
import org.springframework.jms.core.JmsTemplate;
import org.springframework.jms.core.MessagePostProcessor;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.argThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;

class ProducerServiceTest {
    private final JmsTemplate jmsTemplate = mock(JmsTemplate.class);
    private final TransactionGenerator generator = mock(TransactionGenerator.class);
    private final SimulationState simulationState = new SimulationState();

    @Test
    void publishBatchPublishesConfiguredTransactionsToInputQueue() {
        ReconciliationTransaction transaction = transaction(SimulationMode.NORMAL);
        when(generator.next(5, SimulationMode.NORMAL, "unit-test-producer")).thenReturn(transaction);
        ProducerService service = new ProducerService(jmsTemplate, properties(3), generator, simulationState, new SimpleMeterRegistry());

        service.publishBatch();

        verify(jmsTemplate, org.mockito.Mockito.times(3))
                .convertAndSend(eq("RECON.IN"), eq(transaction), any(MessagePostProcessor.class));
    }

    @Test
    void mqOutageSimulationDoesNotPublishMessages() {
        simulationState.set(SimulationMode.MQ_OUTAGE);
        ProducerService service = new ProducerService(jmsTemplate, properties(3), generator, simulationState, new SimpleMeterRegistry());

        service.publishBatch();

        verify(generator, never()).next(any(Integer.class), any(SimulationMode.class), any(String.class));
        verify(jmsTemplate, never()).convertAndSend(any(String.class), any(Object.class), any(MessagePostProcessor.class));
    }

    @Test
    void publishBatchHandlesUnexpectedGenerationFailureAndContinuesScheduler() {
        when(generator.next(5, SimulationMode.NORMAL, "unit-test-producer"))
                .thenThrow(new IllegalStateException("generator unavailable"));
        ProducerService service = new ProducerService(jmsTemplate, properties(3), generator, simulationState, new SimpleMeterRegistry());

        assertDoesNotThrow(service::publishBatch);

        verify(jmsTemplate, never()).convertAndSend(any(String.class), any(Object.class), any(MessagePostProcessor.class));
    }

    @Test
    void duplicateSimulationPublishesSameTransactionTwiceWithSameCorrelationId() throws Exception {
        simulationState.set(SimulationMode.DUPLICATE_MESSAGE);
        ReconciliationTransaction transaction = transaction(SimulationMode.DUPLICATE_MESSAGE);
        when(generator.next(5, SimulationMode.DUPLICATE_MESSAGE, "unit-test-producer")).thenReturn(transaction);
        ProducerService service = new ProducerService(jmsTemplate, properties(1), generator, simulationState, new SimpleMeterRegistry());

        service.publishBatch();

        org.mockito.ArgumentCaptor<MessagePostProcessor> captor = org.mockito.ArgumentCaptor.forClass(MessagePostProcessor.class);
        verify(jmsTemplate, times(2)).convertAndSend(eq("RECON.IN"), eq(transaction), captor.capture());
        List<MessagePostProcessor> processors = captor.getAllValues();
        Message first = mock(Message.class);
        Message second = mock(Message.class);

        processors.get(0).postProcessMessage(first);
        processors.get(1).postProcessMessage(second);

        verify(first).setJMSCorrelationID("duplicate-correlation-id");
        verify(first).setStringProperty("source", "unit-test-producer");
        verify(first).setStringProperty(eq("traceparent"),
                argThat(value -> value.matches("00-[0-9a-f]{32}-[0-9a-f]{16}-01")));
        verify(first).setStringProperty(eq("traceId"), argThat(value -> value.matches("[0-9a-f]{32}")));
        verify(second).setJMSCorrelationID("duplicate-correlation-id");
        verify(second).setStringProperty(eq("traceparent"),
                argThat(value -> value.matches("00-[0-9a-f]{32}-[0-9a-f]{16}-01")));
    }

    @Test
    void publishBatchContinuesWhenMqPublishFails() {
        ReconciliationTransaction transaction = transaction(SimulationMode.NORMAL);
        when(generator.next(5, SimulationMode.NORMAL, "unit-test-producer")).thenReturn(transaction);
        doThrow(new JmsException("mq unavailable") { })
                .when(jmsTemplate).convertAndSend(eq("RECON.IN"), eq(transaction), any(MessagePostProcessor.class));
        ProducerService service = new ProducerService(jmsTemplate, properties(1), generator, simulationState, new SimpleMeterRegistry());

        assertDoesNotThrow(service::publishBatch);

        verify(jmsTemplate).convertAndSend(eq("RECON.IN"), eq(transaction), any(MessagePostProcessor.class));
    }

    @Test
    void publishBatchCatchesUnexpectedPublishRuntimeFailure() {
        ReconciliationTransaction transaction = transaction(SimulationMode.NORMAL);
        when(generator.next(5, SimulationMode.NORMAL, "unit-test-producer")).thenReturn(transaction);
        doThrow(new IllegalArgumentException("message conversion failed"))
                .when(jmsTemplate).convertAndSend(eq("RECON.IN"), eq(transaction), any(MessagePostProcessor.class));
        ProducerService service = new ProducerService(jmsTemplate, properties(1), generator, simulationState, new SimpleMeterRegistry());

        assertDoesNotThrow(service::publishBatch);

        assertThat(transaction.transactionId()).isEqualTo("txn-1");
    }

    private static ReconciliationProperties properties(int tps) {
        return new ReconciliationProperties("RECON.IN", tps, 1000, 5, "unit-test-producer");
    }

    private static ReconciliationTransaction transaction(SimulationMode mode) {
        return new ReconciliationTransaction("txn-1", "CARD", "ACCT-1", BigDecimal.TEN, "SGD", Instant.now(), false, mode, Map.of("traceparent", "trace-1"));
    }
}



