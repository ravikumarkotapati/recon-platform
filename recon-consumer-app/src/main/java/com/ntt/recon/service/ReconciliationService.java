package com.ntt.recon.service;

import com.ntt.recon.config.ReconciliationProperties;
import com.ntt.recon.domain.ReconciliationRecord;
import com.ntt.recon.domain.ReconciliationStatus;
import com.ntt.recon.domain.ReconciliationTransaction;
import com.ntt.recon.domain.SimulationMode;
import com.ntt.recon.repository.ReconciliationRepository;
import io.github.resilience4j.bulkhead.annotation.Bulkhead;
import io.github.resilience4j.circuitbreaker.annotation.CircuitBreaker;
import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import jakarta.transaction.Transactional;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.dao.CannotAcquireLockException;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.dao.DeadlockLoserDataAccessException;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.util.Set;

@Service
public class ReconciliationService {
    private static final Logger log = LoggerFactory.getLogger(ReconciliationService.class);
    private static final Set<String> VALID_CURRENCIES = Set.of("SGD", "USD", "JPY", "EUR", "GBP");

    private final ReconciliationRepository repository;
    private final ReconciliationProperties properties;
    private final Counter reconciled;
    private final Counter invalid;
    private final Counter duplicates;
    private final Counter retries;

    public ReconciliationService(ReconciliationRepository repository, ReconciliationProperties properties, MeterRegistry registry) {
        this.repository = repository;
        this.properties = properties;
        this.reconciled = Counter.builder("recon_records_reconciled_total").register(registry);
        this.invalid = Counter.builder("recon_records_invalid_total").register(registry);
        this.duplicates = Counter.builder("recon_duplicate_messages_total").register(registry);
        this.retries = Counter.builder("recon_db_deadlock_retries_total").register(registry);
    }

    @Bulkhead(name = "databaseBulkhead")
    @CircuitBreaker(name = "databaseCircuitBreaker", fallbackMethod = "degrade")
    public void reconcileWithRetry(ReconciliationTransaction transaction, String correlationId) {
        int attempt = 0;
        while (true) {
            try {
                reconcile(transaction, correlationId);
                return;
            } catch (DeadlockLoserDataAccessException | CannotAcquireLockException ex) {
                attempt++;
                retries.increment();
                if (attempt >= properties.dbDeadlockRetryAttempts()) {
                    throw ex;
                }
                sleep(backoff(attempt));
            }
        }
    }

    @Transactional
    void reconcile(ReconciliationTransaction transaction, String correlationId) {
        if (repository.existsByCorrelationId(correlationId)) {
            duplicates.increment();
            log.info("event=duplicate_message_ignored correlationId={}", correlationId);
            return;
        }

        maybeSimulateDatabaseCondition(transaction);

        ReconciliationRecord record = ReconciliationRecord.from(transaction, correlationId);
        if (!isValid(transaction)) {
            record.mark(ReconciliationStatus.INVALID, "Invalid transaction payload");
            repository.saveAndFlush(record);
            invalid.increment();
            return;
        }
        record.mark(ReconciliationStatus.RECONCILED, null);
        try {
            repository.saveAndFlush(record);
            reconciled.increment();
        } catch (DataIntegrityViolationException ex) {
            duplicates.increment();
            log.info("event=duplicate_race_lost correlationId={}", correlationId);
        }
    }

    @Transactional
    public void recordFailure(ReconciliationTransaction transaction, String correlationId, ReconciliationStatus status, String reason) {
        if (transaction == null) {
            log.warn("event=failed_record_not_persisted reason=null_transaction correlationId={}", correlationId);
            return;
        }
        try {
            ReconciliationRecord record = repository.findByCorrelationId(correlationId)
                    .orElseGet(() -> ReconciliationRecord.from(transaction, correlationId));
            record.mark(status, reason);
            repository.saveAndFlush(record);
        } catch (DataIntegrityViolationException ex) {
            duplicates.increment();
            log.info("event=failed_record_duplicate_race correlationId={}", correlationId);
        }
    }

    @SuppressWarnings("unused")
    void degrade(ReconciliationTransaction transaction, String correlationId, Throwable throwable) {
        log.error("event=database_circuit_open correlationId={} action=graceful_degradation", correlationId, throwable);
        throw new IllegalStateException("Database circuit is open; message will be retried or moved to backout", throwable);
    }

    private boolean isValid(ReconciliationTransaction transaction) {
        return !transaction.intentionallyInvalid()
                && transaction.amount().signum() > 0
                && VALID_CURRENCIES.contains(transaction.currency());
    }

    private void maybeSimulateDatabaseCondition(ReconciliationTransaction transaction) {
        if (transaction.simulationMode() == SimulationMode.SLOW_DATABASE) {
            sleep(Duration.ofMillis(properties.dbSlowThresholdMs()));
        }
        if (transaction.simulationMode() == SimulationMode.DB_DEADLOCK) {
            throw new DeadlockLoserDataAccessException("Simulated database deadlock", null);
        }
    }

    private Duration backoff(int attempt) {
        long millis = Math.min(2000, 100L * (1L << attempt));
        return Duration.ofMillis(millis);
    }

    private void sleep(Duration duration) {
        try {
            Thread.sleep(duration.toMillis());
        } catch (InterruptedException ex) {
            Thread.currentThread().interrupt();
            throw new IllegalStateException("Interrupted during retry backoff", ex);
        }
    }
}
