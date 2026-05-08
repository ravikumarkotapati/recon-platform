package com.ntt.recon.api;

import com.ntt.recon.domain.ReconciliationRecord;
import com.ntt.recon.domain.ReconciliationStatus;
import com.ntt.recon.domain.ReconciliationTransaction;
import com.ntt.recon.repository.ReconciliationRepository;
import com.ntt.recon.service.ReplayService;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api")
public class ReconciliationController {
    private final ReconciliationRepository repository;
    private final ReplayService replayService;

    public ReconciliationController(ReconciliationRepository repository, ReplayService replayService) {
        this.repository = repository;
        this.replayService = replayService;
    }

    @GetMapping("/reconciliation/status")
    public Map<String, Long> status() {
        return Map.of(
                "total", repository.total(),
                "reconciled", repository.countByStatus(ReconciliationStatus.RECONCILED),
                "invalid", repository.countByStatus(ReconciliationStatus.INVALID),
                "failed", repository.countByStatus(ReconciliationStatus.FAILED),
                "dlq", repository.countByStatus(ReconciliationStatus.DLQ)
        );
    }

    @GetMapping("/reconciliation/failed")
    public Page<ReconciliationRecord> failed(@RequestParam(defaultValue = "0") int page,
                                             @RequestParam(defaultValue = "25") int size) {
        return repository.findByStatusIn(
                List.of(ReconciliationStatus.INVALID, ReconciliationStatus.FAILED, ReconciliationStatus.DLQ),
                PageRequest.of(page, size)
        );
    }

    @GetMapping("/reconciliation/queues")
    public Map<String, Object> queues() {
        return Map.of(
                "inputQueue", "see mq_queue_depth metric and MQ console",
                "retryQueue", "see mq_queue_depth metric and MQ console",
                "backoutQueue", "see mq_queue_depth metric and MQ console",
                "deadLetterQueue", "see mq_queue_depth metric and MQ console"
        );
    }

    @PostMapping("/reconciliation/replay")
    public Map<String, String> replay(@RequestBody ReplayRequest request) {
        String replayCorrelationId = replayService.replay(request.transaction(), request.originalCorrelationId());
        return Map.of("replayCorrelationId", replayCorrelationId);
    }

    public record ReplayRequest(String originalCorrelationId, ReconciliationTransaction transaction) {
    }
}
