package com.ntt.recon.observability;

import com.ntt.recon.config.ReconciliationProperties;
import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import jakarta.jms.QueueBrowser;
import jakarta.jms.Session;
import org.junit.jupiter.api.Test;
import org.springframework.jms.core.BrowserCallback;
import org.springframework.jms.core.JmsTemplate;

import java.util.Collections;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class QueueDepthMetricsTest {
    private final JmsTemplate jmsTemplate = mock(JmsTemplate.class);

    @Test
    void registersQueueDepthGaugesAndCountsMessages() {
        SimpleMeterRegistry registry = new SimpleMeterRegistry();
        when(jmsTemplate.browse(eq("RECON.IN"), any(BrowserCallback.class))).thenAnswer(invocation -> {
            BrowserCallback<Integer> callback = invocation.getArgument(1);
            QueueBrowser browser = mock(QueueBrowser.class);
            when(browser.getEnumeration()).thenReturn(Collections.enumeration(List.of("m1", "m2")));
            return callback.doInJms(mock(Session.class), browser);
        });

        new QueueDepthMetrics(jmsTemplate, properties(), registry);

        assertThat(registry.find("mq_queue_depth").tag("queue", "RECON.IN").gauge()).isNotNull();
        assertThat(registry.find("mq_queue_depth").tag("queue", "RECON.IN").gauge().value()).isEqualTo(2.0);
    }

    @Test
    void returnsNegativeDepthWhenQueueBrowserFails() {
        SimpleMeterRegistry registry = new SimpleMeterRegistry();
        when(jmsTemplate.browse(eq("RECON.BACKOUT"), any(BrowserCallback.class))).thenThrow(new IllegalStateException("mq unavailable"));

        new QueueDepthMetrics(jmsTemplate, properties(), registry);

        assertThat(registry.find("mq_queue_depth").tag("queue", "RECON.BACKOUT").gauge().value()).isEqualTo(-1.0);
    }

    private static ReconciliationProperties properties() {
        return new ReconciliationProperties(
                "RECON.IN", "RECON.RETRY", "RECON.BACKOUT", "SYSTEM.DEAD.LETTER.QUEUE", "RECON.REPLAY",
                1, 0, 1, 1, 2, 1);
    }
}
