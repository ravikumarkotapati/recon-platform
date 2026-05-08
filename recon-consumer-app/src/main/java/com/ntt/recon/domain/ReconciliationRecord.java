package com.ntt.recon.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import jakarta.persistence.Version;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "reconciliation_record", uniqueConstraints = {
        @UniqueConstraint(name = "uk_reconciliation_correlation", columnNames = "correlation_id"),
        @UniqueConstraint(name = "uk_reconciliation_transaction", columnNames = "transaction_id")
})
public class ReconciliationRecord {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "transaction_id", nullable = false)
    private String transactionId;

    @Column(name = "correlation_id", nullable = false)
    private String correlationId;

    @Column(name = "source_system", nullable = false)
    private String sourceSystem;

    @Column(name = "account_number", nullable = false)
    private String accountNumber;

    @Column(nullable = false, precision = 19, scale = 4)
    private BigDecimal amount;

    @Column(nullable = false, length = 3)
    private String currency;

    @Column(name = "transaction_time", nullable = false)
    private Instant transactionTime;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private ReconciliationStatus status;

    @Column(name = "failure_reason", length = 2048)
    private String failureReason;

    @Column(name = "retry_count", nullable = false)
    private int retryCount;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @Version
    private long version;

    public static ReconciliationRecord from(ReconciliationTransaction transaction, String correlationId) {
        ReconciliationRecord record = new ReconciliationRecord();
        record.transactionId = transaction.transactionId();
        record.correlationId = correlationId;
        record.sourceSystem = transaction.sourceSystem();
        record.accountNumber = transaction.accountNumber();
        record.amount = transaction.amount();
        record.currency = transaction.currency();
        record.transactionTime = transaction.transactionTime();
        record.status = ReconciliationStatus.RECEIVED;
        record.createdAt = Instant.now();
        record.updatedAt = record.createdAt;
        return record;
    }

    public UUID getId() { return id; }
    public String getTransactionId() { return transactionId; }
    public String getCorrelationId() { return correlationId; }
    public ReconciliationStatus getStatus() { return status; }
    public String getFailureReason() { return failureReason; }
    public int getRetryCount() { return retryCount; }
    public Instant getUpdatedAt() { return updatedAt; }

    public void mark(ReconciliationStatus newStatus, String reason) {
        this.status = newStatus;
        this.failureReason = reason;
        this.updatedAt = Instant.now();
    }

    public void incrementRetry() {
        this.retryCount++;
        this.updatedAt = Instant.now();
    }
}

