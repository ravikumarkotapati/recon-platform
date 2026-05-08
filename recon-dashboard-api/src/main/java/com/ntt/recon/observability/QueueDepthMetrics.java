package com.ntt.recon.observability;

import com.ntt.recon.config.ReconciliationProperties;
import io.micrometer.core.instrument.Gauge;
import io.micrometer.core.instrument.MeterRegistry;
import org.springframework.jms.core.BrowserCallback;
import org.springframework.jms.core.JmsTemplate;
import org.springframework.stereotype.Component;

import java.util.Enumeration;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Component
public class QueueDepthMetrics {
    private final JmsTemplate jmsTemplate;
    private final Map<String, Number> gauges = new ConcurrentHashMap<>();

    public QueueDepthMetrics(JmsTemplate jmsTemplate, ReconciliationProperties properties, MeterRegistry registry) {
        this.jmsTemplate = jmsTemplate;
        register(registry, properties.inputQueue());
        register(registry, properties.retryQueue());
        register(registry, properties.backoutQueue());
        register(registry, properties.deadLetterQueue());
    }

    private void register(MeterRegistry registry, String queue) {
        Gauge.builder("mq_queue_depth", () -> depth(queue))
                .tag("queue", queue)
                .description("Approximate queue depth observed via JMS queue browser")
                .register(registry);
    }

    private int depth(String queue) {
        try {
            return jmsTemplate.browse(queue, (BrowserCallback<Integer>) (session, browser) -> {
                int count = 0;
                Enumeration<?> messages = browser.getEnumeration();
                while (messages.hasMoreElements()) {
                    messages.nextElement();
                    count++;
                }
                return count;
            });
        } catch (Exception ex) {
            return -1;
        }
    }
}

