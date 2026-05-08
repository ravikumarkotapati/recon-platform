package com.ntt.recon.domain;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.Map;

public record ReconciliationTransaction(
        @NotBlank String transactionId,
        @NotBlank String sourceSystem,
        @NotBlank String accountNumber,
        @NotNull @Positive BigDecimal amount,
        @NotBlank String currency,
        @NotNull Instant transactionTime,
        boolean intentionallyInvalid,
        SimulationMode simulationMode,
        Map<String, String> tracing
) {
}

