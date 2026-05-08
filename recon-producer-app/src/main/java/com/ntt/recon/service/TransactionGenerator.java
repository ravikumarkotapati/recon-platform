package com.ntt.recon.service;

import com.ntt.recon.domain.ReconciliationTransaction;
import com.ntt.recon.domain.SimulationMode;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.Map;
import java.util.Random;
import java.util.UUID;

@Component
public class TransactionGenerator {
    private final Random random = new Random();

    public ReconciliationTransaction next(int invalidPercent, SimulationMode simulationMode, String generatedBy) {
        boolean invalid = random.nextInt(100) < invalidPercent;
        BigDecimal amount = invalid ? BigDecimal.valueOf(-1) : BigDecimal.valueOf(random.nextInt(250_000) + 100, 2);
        String transactionId = "txn-" + UUID.randomUUID();
        return new ReconciliationTransaction(
                transactionId,
                random.nextBoolean() ? "CARD" : "CORE_BANKING",
                "ACCT-" + (100000 + random.nextInt(900000)),
                amount,
                invalid ? "XX" : "SGD",
                Instant.now(),
                invalid,
                simulationMode,
                Map.of(
                        "traceparent", UUID.randomUUID().toString(),
                        "generatedBy", generatedBy
                )
        );
    }
}
