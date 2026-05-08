package com.ntt.recon.service;

import com.ntt.recon.domain.ReconciliationTransaction;
import com.ntt.recon.domain.SimulationMode;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class TransactionGeneratorTest {
    private final TransactionGenerator generator = new TransactionGenerator();

    @Test
    void generatesValidTransactionWhenInvalidPercentIsZero() {
        ReconciliationTransaction transaction = generator.next(0, SimulationMode.NORMAL, "unit-test-producer");

        assertThat(transaction.transactionId()).startsWith("txn-");
        assertThat(transaction.amount()).isPositive();
        assertThat(transaction.currency()).isEqualTo("SGD");
        assertThat(transaction.intentionallyInvalid()).isFalse();
        assertThat(transaction.tracing()).containsKeys("traceparent", "generatedBy");
    }

    @Test
    void generatesInvalidTransactionWhenInvalidPercentIsOneHundred() {
        ReconciliationTransaction transaction = generator.next(100, SimulationMode.NORMAL, "unit-test-producer");

        assertThat(transaction.amount()).isNegative();
        assertThat(transaction.currency()).isEqualTo("XX");
        assertThat(transaction.intentionallyInvalid()).isTrue();
    }
}

