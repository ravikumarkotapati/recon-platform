package com.ntt.recon.domain;

public enum SimulationMode {
    NORMAL,
    DB_DEADLOCK,
    MQ_OUTAGE,
    CONSUMER_CRASH,
    SLOW_DATABASE,
    DUPLICATE_MESSAGE
}

