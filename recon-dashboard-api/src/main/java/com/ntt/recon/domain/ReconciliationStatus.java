package com.ntt.recon.domain;

public enum ReconciliationStatus {
    RECEIVED,
    RECONCILED,
    INVALID,
    RETRYING,
    FAILED,
    DLQ,
    REPLAYED
}

