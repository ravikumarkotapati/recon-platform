package com.ntt.recon.observability;

import io.opentelemetry.api.trace.Span;
import io.opentelemetry.api.trace.SpanContext;
import jakarta.jms.JMSException;
import jakarta.jms.Message;

import java.security.SecureRandom;
import java.util.HexFormat;
import java.util.Optional;
import java.util.regex.Pattern;

public record TraceHeaders(String traceparent, String traceId, String spanId) {
    private static final Pattern W3C_TRACEPARENT =
            Pattern.compile("^[\\da-f]{2}-([\\da-f]{32})-([\\da-f]{16})-[\\da-f]{2}$");
    private static final SecureRandom RANDOM = new SecureRandom();
    private static final HexFormat HEX = HexFormat.of();

    public static TraceHeaders currentOr(Message message) {
        SpanContext context = Span.current().getSpanContext();
        if (context.isValid()) {
            return new TraceHeaders("00-" + context.getTraceId() + "-" + context.getSpanId() + "-01",
                    context.getTraceId(), context.getSpanId());
        }
        return from(message).orElseGet(TraceHeaders::create);
    }

    public static Optional<TraceHeaders> from(Message message) {
        try {
            String traceparent = message.getStringProperty("traceparent");
            if (traceparent == null || traceparent.isBlank()) {
                return Optional.empty();
            }
            var matcher = W3C_TRACEPARENT.matcher(traceparent);
            if (!matcher.matches()) {
                return Optional.empty();
            }
            return Optional.of(new TraceHeaders(traceparent, matcher.group(1), matcher.group(2)));
        } catch (JMSException ex) {
            return Optional.empty();
        }
    }

    private static TraceHeaders create() {
        String traceId = randomHex(16);
        String spanId = randomHex(8);
        return new TraceHeaders("00-" + traceId + "-" + spanId + "-01", traceId, spanId);
    }

    private static String randomHex(int bytes) {
        byte[] value = new byte[bytes];
        RANDOM.nextBytes(value);
        return HEX.formatHex(value);
    }
}
