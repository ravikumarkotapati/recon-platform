package com.ntt.recon.service;

import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import jakarta.jms.Message;
import org.junit.jupiter.api.Test;

import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.atLeastOnce;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class DeadLetterListenerTest {
    @Test
    void recordsDeadLetterMessageWithCorrelationId() throws Exception {
        Message message = mock(Message.class);
        when(message.getJMSCorrelationID()).thenReturn("corr-dlq");
        when(message.getJMSMessageID()).thenReturn("msg-dlq");

        new DeadLetterListener(new SimpleMeterRegistry()).onDeadLetter(message);

        verify(message).getJMSMessageID();
    }

    @Test
    void fallsBackToMessageIdWhenCorrelationIdIsMissing() throws Exception {
        Message message = mock(Message.class);
        when(message.getJMSCorrelationID()).thenReturn(null);
        when(message.getJMSMessageID()).thenReturn("msg-dlq");

        new DeadLetterListener(new SimpleMeterRegistry()).onDeadLetter(message);

        verify(message, atLeastOnce()).getJMSMessageID();
    }
}
