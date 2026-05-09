package com.ntt.recon.service;

import com.ntt.recon.config.ReconciliationProperties;
import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.Gauge;
import io.micrometer.core.instrument.MeterRegistry;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jms.core.BrowserCallback;
import org.springframework.jms.core.JmsTemplate;
import org.springframework.stereotype.Component;

import java.util.Enumeration;
import java.util.concurrent.atomic.AtomicInteger;

@Component
public class QueueBackpressureGuard {
    private static final Logger log = LoggerFactory.getLogger(QueueBackpressureGuard.class);

    private final JmsTemplate jmsTemplate;
    private final ReconciliationProperties properties;
    private final AtomicInteger lastObservedDepth = new AtomicInteger(-1);
    private final Counter backpressureSkips;
    private final Counter depthCheckFailures;

    public QueueBackpressureGuard(JmsTemplate jmsTemplate, ReconciliationProperties properties, MeterRegistry registry) {
        this.jmsTemplate = jmsTemplate;
        this.properties = properties;
        this.backpressureSkips = Counter.builder("recon_producer_backpressure_skips_total").register(registry);
        this.depthCheckFailures = Counter.builder("recon_producer_queue_depth_check_failures_total").register(registry);
        Gauge.builder("recon_producer_input_queue_depth_observed", lastObservedDepth, AtomicInteger::get)
                .description("Last input queue depth observed by the producer before publishing")
                .register(registry);
    }

    public boolean canPublish() {
        int maxDepth = properties.maxInputQueueDepth();
        if (maxDepth <= 0) {
            return true;
        }
        int depth = inputQueueDepth(maxDepth);
        lastObservedDepth.set(depth);
        if (depth < 0) {
            depthCheckFailures.increment();
            log.warn("event=producer_backpressure_depth_unavailable queue={} action=skip_publish", properties.inputQueue());
            return false;
        }
        if (depth >= maxDepth) {
            backpressureSkips.increment();
            log.warn("event=producer_backpressure_active queue={} depth={} maxDepth={} action=skip_publish",
                    properties.inputQueue(), depth, maxDepth);
            return false;
        }
        return true;
    }

    private int inputQueueDepth(int maxDepth) {
        try {
            return jmsTemplate.browse(properties.inputQueue(), (BrowserCallback<Integer>) (session, browser) -> {
                int count = 0;
                Enumeration<?> messages = browser.getEnumeration();
                while (messages.hasMoreElements() && count < maxDepth) {
                    messages.nextElement();
                    count++;
                }
                return count;
            });
        } catch (Exception ex) {
            log.warn("event=producer_backpressure_depth_check_failed queue={}", properties.inputQueue(), ex);
            return -1;
        }
    }
}
