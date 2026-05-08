package com.ntt.recon.domain;

import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

class ReconciliationRecordTest {
    @Test
    void createsRecordFromTransactionAndUpdatesStatusAndRetryCount() {
        ReconciliationTransaction transaction = new ReconciliationTransaction(
                "txn-1", "CARD", "ACCT-1", BigDecimal.TEN, "SGD", Instant.now(), false, SimulationMode.NORMAL, Map.of());

        ReconciliationRecord record = ReconciliationRecord.from(transaction, "corr-1");
        Instant initialUpdatedAt = record.getUpdatedAt();

        assertThat(record.getId()).isNull();
        assertThat(record.getTransactionId()).isEqualTo("txn-1");
        assertThat(record.getCorrelationId()).isEqualTo("corr-1");
        assertThat(record.getStatus()).isEqualTo(ReconciliationStatus.RECEIVED);
        assertThat(record.getRetryCount()).isZero();

        record.mark(ReconciliationStatus.FAILED, "db unavailable");
        record.incrementRetry();

        assertThat(record.getStatus()).isEqualTo(ReconciliationStatus.FAILED);
        assertThat(record.getFailureReason()).isEqualTo("db unavailable");
        assertThat(record.getRetryCount()).isEqualTo(1);
        assertThat(record.getUpdatedAt()).isAfterOrEqualTo(initialUpdatedAt);
    }
}
