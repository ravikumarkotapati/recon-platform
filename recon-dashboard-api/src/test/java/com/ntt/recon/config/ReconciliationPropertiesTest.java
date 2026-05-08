package com.ntt.recon.config;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class ReconciliationPropertiesTest {
    @Test
    void exposesConfiguredQueueNamesAndRuntimeSettings() {
        ReconciliationProperties properties = new ReconciliationProperties(
                "RECON.IN", "RECON.RETRY", "RECON.BACKOUT", "SYSTEM.DEAD.LETTER.QUEUE", "RECON.REPLAY",
                10, 5, 2, 8, 3, 100);

        assertThat(properties.inputQueue()).isEqualTo("RECON.IN");
        assertThat(properties.retryQueue()).isEqualTo("RECON.RETRY");
        assertThat(properties.backoutQueue()).isEqualTo("RECON.BACKOUT");
        assertThat(properties.deadLetterQueue()).isEqualTo("SYSTEM.DEAD.LETTER.QUEUE");
        assertThat(properties.replayQueue()).isEqualTo("RECON.REPLAY");
        assertThat(properties.producerTps()).isEqualTo(10);
        assertThat(properties.invalidPercent()).isEqualTo(5);
        assertThat(properties.listenerConcurrency()).isEqualTo(2);
        assertThat(properties.listenerMaxConcurrency()).isEqualTo(8);
        assertThat(properties.dbDeadlockRetryAttempts()).isEqualTo(3);
        assertThat(properties.dbSlowThresholdMs()).isEqualTo(100);
    }
}
