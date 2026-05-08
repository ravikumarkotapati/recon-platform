CREATE TABLE IF NOT EXISTS reconciliation_record (
    id UUID PRIMARY KEY,
    transaction_id VARCHAR(255) NOT NULL,
    correlation_id VARCHAR(255) NOT NULL,
    source_system VARCHAR(255) NOT NULL,
    account_number VARCHAR(255) NOT NULL,
    amount NUMERIC(19, 4) NOT NULL,
    currency VARCHAR(3) NOT NULL,
    transaction_time TIMESTAMPTZ NOT NULL,
    status VARCHAR(255) NOT NULL,
    failure_reason VARCHAR(2048),
    retry_count INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    version BIGINT NOT NULL DEFAULT 0,
    CONSTRAINT uk_reconciliation_correlation UNIQUE (correlation_id),
    CONSTRAINT uk_reconciliation_transaction UNIQUE (transaction_id)
);

CREATE INDEX IF NOT EXISTS idx_reconciliation_status ON reconciliation_record(status);
CREATE INDEX IF NOT EXISTS idx_reconciliation_updated_at ON reconciliation_record(updated_at);
