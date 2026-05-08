package com.ntt.recon.service;

import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import jakarta.jms.JMSException;
import jakarta.jms.Message;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.slf4j.MDC;
import org.springframework.jms.annotation.JmsListener;
import org.springframework.stereotype.Component;

@Component
public class DeadLetterListener {
    private static final Logger log = LoggerFactory.getLogger(DeadLetterListener.class);

    private final Counter deadLetters;

    public DeadLetterListener(MeterRegistry registry) {
        this.deadLetters = Counter.builder("recon_dead_letter_messages_total").register(registry);
    }

    @JmsListener(destination = "${recon.dead-letter-queue}")
    public void onDeadLetter(Message message) throws JMSException {
        String correlationId = correlationId(message);
        try (MDC.MDCCloseable ignored = MDC.putCloseable("correlationId", correlationId)) {
            deadLetters.increment();
            log.error("event=dead_letter_received correlationId={} messageId={} action=inspect_or_replay",
                    correlationId, message.getJMSMessageID());
        }
    }

    private String correlationId(Message message) throws JMSException {
        String correlationId = message.getJMSCorrelationID();
        return correlationId == null || correlationId.isBlank() ? message.getJMSMessageID() : correlationId;
    }
}
