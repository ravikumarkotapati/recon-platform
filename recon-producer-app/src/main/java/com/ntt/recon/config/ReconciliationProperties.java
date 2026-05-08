package com.ntt.recon.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "recon")
public record ReconciliationProperties(
        String inputQueue,
        int producerTps,
        long producerIntervalMs,
        int invalidPercent,
        String messageSource
) {
}
