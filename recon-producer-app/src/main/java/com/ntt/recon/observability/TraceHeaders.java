package com.ntt.recon.observability;

import io.opentelemetry.api.trace.Span;
import io.opentelemetry.api.trace.SpanContext;

import java.security.SecureRandom;
import java.util.HexFormat;

public record TraceHeaders(String traceparent, String traceId, String spanId) {
    private static final SecureRandom RANDOM = new SecureRandom();
    private static final HexFormat HEX = HexFormat.of();

    public static TraceHeaders currentOrNew() {
        SpanContext context = Span.current().getSpanContext();
        if (context.isValid()) {
            return new TraceHeaders("00-" + context.getTraceId() + "-" + context.getSpanId() + "-01",
                    context.getTraceId(), context.getSpanId());
        }
        return create();
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
