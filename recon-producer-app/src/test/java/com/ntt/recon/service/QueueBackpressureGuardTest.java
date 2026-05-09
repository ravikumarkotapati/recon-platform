package com.ntt.recon.service;

import com.ntt.recon.config.ReconciliationProperties;
import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import jakarta.jms.QueueBrowser;
import jakarta.jms.Session;
import org.junit.jupiter.api.Test;
import org.springframework.jms.core.BrowserCallback;
import org.springframework.jms.core.JmsTemplate;

import java.util.Collections;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class QueueBackpressureGuardTest {
    private final JmsTemplate jmsTemplate = mock(JmsTemplate.class);
    private final SimpleMeterRegistry registry = new SimpleMeterRegistry();

    @Test
    void allowsPublishingWhenObservedDepthIsBelowLimit() {
        mockDepth(2);
        QueueBackpressureGuard guard = new QueueBackpressureGuard(jmsTemplate, properties(5), registry);

        assertThat(guard.canPublish()).isTrue();
        assertThat(registry.find("recon_producer_input_queue_depth_observed").gauge().value()).isEqualTo(2.0);
    }

    @Test
    void blocksPublishingWhenObservedDepthReachesLimit() {
        mockDepth(5);
        QueueBackpressureGuard guard = new QueueBackpressureGuard(jmsTemplate, properties(5), registry);

        assertThat(guard.canPublish()).isFalse();
        assertThat(registry.find("recon_producer_backpressure_skips_total").counter().count()).isEqualTo(1.0);
    }

    @Test
    void blocksPublishingWhenDepthCheckFails() {
        when(jmsTemplate.browse(eq("RECON.IN"), any(BrowserCallback.class)))
                .thenThrow(new IllegalStateException("mq unavailable"));
        QueueBackpressureGuard guard = new QueueBackpressureGuard(jmsTemplate, properties(5), registry);

        assertThat(guard.canPublish()).isFalse();
        assertThat(registry.find("recon_producer_queue_depth_check_failures_total").counter().count()).isEqualTo(1.0);
    }

    @Test
    void disabledLimitAlwaysAllowsPublishing() {
        QueueBackpressureGuard guard = new QueueBackpressureGuard(jmsTemplate, properties(0), registry);

        assertThat(guard.canPublish()).isTrue();
    }

    private void mockDepth(int depth) {
        when(jmsTemplate.browse(eq("RECON.IN"), any(BrowserCallback.class))).thenAnswer(invocation -> {
            @SuppressWarnings("unchecked")
            BrowserCallback<Integer> callback = invocation.getArgument(1);
            QueueBrowser browser = mock(QueueBrowser.class);
            when(browser.getEnumeration()).thenReturn(Collections.enumeration(Collections.nCopies(depth, "message")));
            return callback.doInJms(mock(Session.class), browser);
        });
    }

    private static ReconciliationProperties properties(int maxDepth) {
        return new ReconciliationProperties("RECON.IN", 2, 1000, 10, "unit-test-producer", maxDepth);
    }
}
