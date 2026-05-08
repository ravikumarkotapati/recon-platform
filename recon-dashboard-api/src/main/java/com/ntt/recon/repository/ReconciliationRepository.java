package com.ntt.recon.repository;

import com.ntt.recon.domain.ReconciliationRecord;
import com.ntt.recon.domain.ReconciliationStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.Optional;
import java.util.UUID;

public interface ReconciliationRepository extends JpaRepository<ReconciliationRecord, UUID> {
    Optional<ReconciliationRecord> findByCorrelationId(String correlationId);

    boolean existsByCorrelationId(String correlationId);

    Page<ReconciliationRecord> findByStatusIn(Iterable<ReconciliationStatus> statuses, Pageable pageable);

    long countByStatus(ReconciliationStatus status);

    @Query("select count(r) from ReconciliationRecord r")
    long total();
}

