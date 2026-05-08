package com.ntt.recon.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "recon")
public record ReconciliationProperties(
        String inputQueue,
        String retryQueue,
        String backoutQueue,
        String deadLetterQueue,
        String replayQueue,
        int producerTps,
        int invalidPercent,
        int listenerConcurrency,
        int listenerMaxConcurrency,
        int dbDeadlockRetryAttempts,
        long dbSlowThresholdMs
) {
}

