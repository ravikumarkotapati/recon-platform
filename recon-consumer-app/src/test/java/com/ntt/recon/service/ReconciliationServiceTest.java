package com.ntt.recon.service;

import com.ntt.recon.config.ReconciliationProperties;
import com.ntt.recon.domain.ReconciliationRecord;
import com.ntt.recon.domain.ReconciliationStatus;
import com.ntt.recon.domain.ReconciliationTransaction;
import com.ntt.recon.domain.SimulationMode;
import com.ntt.recon.repository.ReconciliationRepository;
import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.dao.DeadlockLoserDataAccessException;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.Map;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class ReconciliationServiceTest {
    private final ReconciliationRepository repository = mock(ReconciliationRepository.class);
    private final ReconciliationService service = new ReconciliationService(repository, props(), new SimpleMeterRegistry());

    @Test
    void reconcilesValidTransactionAndPersistsRecord() {
        when(repository.existsByCorrelationId("corr-1")).thenReturn(false);

        service.reconcileWithRetry(validTransaction("txn-1"), "corr-1");

        ArgumentCaptor<ReconciliationRecord> captor = ArgumentCaptor.forClass(ReconciliationRecord.class);
        verify(repository).saveAndFlush(captor.capture());
        assertThat(captor.getValue().getCorrelationId()).isEqualTo("corr-1");
        assertThat(captor.getValue().getStatus()).isEqualTo(ReconciliationStatus.RECONCILED);
    }

    @Test
    void marksInvalidTransactionAsInvalid() {
        when(repository.existsByCorrelationId("corr-invalid")).thenReturn(false);

        service.reconcileWithRetry(invalidTransaction(), "corr-invalid");

        ArgumentCaptor<ReconciliationRecord> captor = ArgumentCaptor.forClass(ReconciliationRecord.class);
        verify(repository).saveAndFlush(captor.capture());
        assertThat(captor.getValue().getStatus()).isEqualTo(ReconciliationStatus.INVALID);
        assertThat(captor.getValue().getFailureReason()).isEqualTo("Invalid transaction payload");
    }

    @Test
    void marksNonPositiveAmountAsInvalid() {
        when(repository.existsByCorrelationId("corr-zero")).thenReturn(false);

        service.reconcileWithRetry(transaction("txn-zero", BigDecimal.ZERO, "SGD", false, SimulationMode.NORMAL), "corr-zero");

        ArgumentCaptor<ReconciliationRecord> captor = ArgumentCaptor.forClass(ReconciliationRecord.class);
        verify(repository).saveAndFlush(captor.capture());
        assertThat(captor.getValue().getStatus()).isEqualTo(ReconciliationStatus.INVALID);
    }

    @Test
    void marksUnsupportedCurrencyAsInvalid() {
        when(repository.existsByCorrelationId("corr-currency")).thenReturn(false);

        service.reconcileWithRetry(transaction("txn-currency", BigDecimal.TEN, "XXX", false, SimulationMode.NORMAL), "corr-currency");

        ArgumentCaptor<ReconciliationRecord> captor = ArgumentCaptor.forClass(ReconciliationRecord.class);
        verify(repository).saveAndFlush(captor.capture());
        assertThat(captor.getValue().getStatus()).isEqualTo(ReconciliationStatus.INVALID);
    }

    @Test
    void ignoresDuplicateCorrelationIdWithoutPersistingAgain() {
        when(repository.existsByCorrelationId("corr-duplicate")).thenReturn(true);

        service.reconcileWithRetry(validTransaction("txn-duplicate"), "corr-duplicate");

        verify(repository, never()).saveAndFlush(any(ReconciliationRecord.class));
    }

    @Test
    void treatsUniqueConstraintRaceAsDuplicateWithoutFailingMessage() {
        ReconciliationTransaction transaction = validTransaction("txn-race");
        when(repository.existsByCorrelationId("corr-race")).thenReturn(false);
        when(repository.saveAndFlush(any(ReconciliationRecord.class)))
                .thenThrow(new DataIntegrityViolationException("duplicate correlation"));

        service.reconcileWithRetry(transaction, "corr-race");

        verify(repository).saveAndFlush(any(ReconciliationRecord.class));
    }

    @Test
    void persistsAfterSlowDatabaseSimulationCompletes() {
        when(repository.existsByCorrelationId("corr-slow")).thenReturn(false);

        service.reconcileWithRetry(transaction("txn-slow", BigDecimal.TEN, "SGD", false, SimulationMode.SLOW_DATABASE), "corr-slow");

        verify(repository).saveAndFlush(any(ReconciliationRecord.class));
    }

    @Test
    void retriesDeadlockAndThrowsAfterConfiguredAttempts() {
        assertThatThrownBy(() -> service.reconcileWithRetry(deadlockTransaction(), "corr-deadlock"))
                .isInstanceOf(DeadlockLoserDataAccessException.class);

        verify(repository, never()).saveAndFlush(any(ReconciliationRecord.class));
    }

    @Test
    void degradeThrowsSoMessageCanBeRetriedByListener() {
        assertThatThrownBy(() -> service.degrade(validTransaction("txn-degrade"), "corr-degrade", new RuntimeException("circuit open")))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("Database circuit is open");
    }

    @Test
    void recordsTechnicalFailureForFailedTransactionView() {
        ReconciliationTransaction transaction = validTransaction("txn-failed");
        when(repository.findByCorrelationId("corr-failed")).thenReturn(Optional.empty());

        service.recordFailure(transaction, "corr-failed", ReconciliationStatus.FAILED, "Retries exhausted");

        ArgumentCaptor<ReconciliationRecord> captor = ArgumentCaptor.forClass(ReconciliationRecord.class);
        verify(repository).saveAndFlush(captor.capture());
        assertThat(captor.getValue().getCorrelationId()).isEqualTo("corr-failed");
        assertThat(captor.getValue().getStatus()).isEqualTo(ReconciliationStatus.FAILED);
        assertThat(captor.getValue().getFailureReason()).isEqualTo("Retries exhausted");
    }

    @Test
    void recordsFailureOnExistingRecord() {
        ReconciliationRecord existing = ReconciliationRecord.from(validTransaction("txn-existing"), "corr-existing");
        when(repository.findByCorrelationId("corr-existing")).thenReturn(Optional.of(existing));

        service.recordFailure(validTransaction("txn-existing"), "corr-existing", ReconciliationStatus.FAILED, "Backout");

        verify(repository).saveAndFlush(existing);
        assertThat(existing.getStatus()).isEqualTo(ReconciliationStatus.FAILED);
        assertThat(existing.getFailureReason()).isEqualTo("Backout");
    }

    @Test
    void skipsFailurePersistenceForNullPoisonPayload() {
        service.recordFailure(null, "corr-null", ReconciliationStatus.FAILED, "Null payload");

        verify(repository, never()).saveAndFlush(any(ReconciliationRecord.class));
    }

    private static ReconciliationProperties props() {
        return new ReconciliationProperties("RECON.IN", "RECON.RETRY", "RECON.BACKOUT", "SYSTEM.DEAD.LETTER.QUEUE", "RECON.REPLAY", 1, 0, 1, 1, 2, 1);
    }

    private static ReconciliationTransaction validTransaction(String transactionId) {
        return transaction(transactionId, BigDecimal.TEN, "SGD", false, SimulationMode.NORMAL);
    }

    private static ReconciliationTransaction invalidTransaction() {
        return transaction("txn-invalid", BigDecimal.valueOf(-1), "XX", true, SimulationMode.NORMAL);
    }

    private static ReconciliationTransaction deadlockTransaction() {
        return transaction("txn-deadlock", BigDecimal.TEN, "SGD", false, SimulationMode.DB_DEADLOCK);
    }

    private static ReconciliationTransaction transaction(String transactionId, BigDecimal amount, String currency, boolean invalid, SimulationMode mode) {
        return new ReconciliationTransaction(transactionId, "CARD", "ACCT-1", amount, currency, Instant.now(), invalid, mode, Map.of());
    }
}
