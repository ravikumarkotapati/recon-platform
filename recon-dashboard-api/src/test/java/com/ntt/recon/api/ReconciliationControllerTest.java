package com.ntt.recon.api;

import com.ntt.recon.config.ReconciliationProperties;
import com.ntt.recon.domain.ReconciliationRecord;
import com.ntt.recon.domain.ReconciliationStatus;
import com.ntt.recon.domain.ReconciliationTransaction;
import com.ntt.recon.domain.SimulationMode;
import com.ntt.recon.observability.QueueDepthMetrics;
import com.ntt.recon.repository.ReconciliationRepository;
import com.ntt.recon.service.ReplayService;
import org.junit.jupiter.api.Test;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.argThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class ReconciliationControllerTest {
    private final ReconciliationRepository repository = mock(ReconciliationRepository.class);
    private final ReplayService replayService = mock(ReplayService.class);
    private final QueueDepthMetrics queueDepthMetrics = mock(QueueDepthMetrics.class);
    private final ReconciliationController controller = new ReconciliationController(repository, replayService, properties(), queueDepthMetrics);

    @Test
    void statusReturnsReconciliationCounts() {
        when(repository.total()).thenReturn(10L);
        when(repository.countByStatus(ReconciliationStatus.RECONCILED)).thenReturn(7L);
        when(repository.countByStatus(ReconciliationStatus.INVALID)).thenReturn(2L);
        when(repository.countByStatus(ReconciliationStatus.FAILED)).thenReturn(1L);
        when(repository.countByStatus(ReconciliationStatus.DLQ)).thenReturn(0L);

        Map<String, Long> status = controller.status();

        assertThat(status).containsEntry("total", 10L)
                .containsEntry("reconciled", 7L)
                .containsEntry("invalid", 2L)
                .containsEntry("failed", 1L)
                .containsEntry("dlq", 0L);
    }

    @Test
    void failedTransactionsDelegatesToFailureStatuses() {
        Page<ReconciliationRecord> expected = new PageImpl<>(List.of());
        when(repository.findByStatusIn(any(), any(Pageable.class))).thenReturn(expected);

        Page<ReconciliationRecord> actual = controller.failed(0, 25);

        assertThat(actual).isSameAs(expected);
        verify(repository).findByStatusIn(
                argThat(statuses -> {
                    List<ReconciliationStatus> list = (List<ReconciliationStatus>) statuses;
                    return list.containsAll(List.of(ReconciliationStatus.INVALID, ReconciliationStatus.FAILED, ReconciliationStatus.DLQ));
                }),
                any(Pageable.class)
        );
    }

    @Test
    void replayReturnsNewReplayCorrelationId() {
        ReconciliationTransaction transaction = transaction();
        when(replayService.replay(transaction, "original-corr")).thenReturn("replay-corr");

        Map<String, String> response = controller.replay(new ReconciliationController.ReplayRequest("original-corr", transaction));

        assertThat(response).containsEntry("replayCorrelationId", "replay-corr");
    }

    @Test
    void queuesReturnsCurrentBacklogDepths() {
        when(queueDepthMetrics.depth("RECON.IN")).thenReturn(7);
        when(queueDepthMetrics.depth("RECON.RETRY")).thenReturn(1);
        when(queueDepthMetrics.depth("RECON.BACKOUT")).thenReturn(0);
        when(queueDepthMetrics.depth("SYSTEM.DEAD.LETTER.QUEUE")).thenReturn(-1);

        Map<String, Object> queues = controller.queues();

        assertThat(queues).containsKeys("inputQueue", "retryQueue", "backoutQueue", "deadLetterQueue");
        assertThat((Map<String, Object>) queues.get("inputQueue"))
                .containsEntry("name", "RECON.IN")
                .containsEntry("depth", 7)
                .containsEntry("available", true);
        assertThat((Map<String, Object>) queues.get("deadLetterQueue"))
                .containsEntry("name", "SYSTEM.DEAD.LETTER.QUEUE")
                .containsEntry("depth", -1)
                .containsEntry("available", false);
    }

    private static ReconciliationTransaction transaction() {
        return new ReconciliationTransaction("txn-1", "CARD", "ACCT-1", BigDecimal.TEN, "SGD", Instant.now(), false, SimulationMode.NORMAL, Map.of());
    }

    private static ReconciliationProperties properties() {
        return new ReconciliationProperties(
                "RECON.IN", "RECON.RETRY", "RECON.BACKOUT", "SYSTEM.DEAD.LETTER.QUEUE", "RECON.REPLAY",
                1, 0, 1, 1, 2, 1);
    }
}
