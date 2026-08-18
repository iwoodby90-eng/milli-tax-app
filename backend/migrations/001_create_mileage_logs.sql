-- Milli mileage log persistence contract
-- PostgreSQL migration for the production backend.
-- The native iOS app can persist locally/offline first, then sync these records
-- to the authenticated user's backend mileage log.

CREATE TABLE IF NOT EXISTS mileage_logs (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL,
    source VARCHAR(24) NOT NULL CHECK (source IN ('gps', 'manual', 'navigation')),
    platform VARCHAR(64),
    business_purpose VARCHAR(160),
    started_at TIMESTAMPTZ NOT NULL,
    ended_at TIMESTAMPTZ NOT NULL,
    distance_miles NUMERIC(10,3) NOT NULL CHECK (distance_miles >= 0),
    deduction_rate NUMERIC(8,4) NOT NULL CHECK (deduction_rate >= 0),
    deduction_amount NUMERIC(12,2) NOT NULL CHECK (deduction_amount >= 0),
    start_address TEXT,
    end_address TEXT,
    start_latitude DOUBLE PRECISION,
    start_longitude DOUBLE PRECISION,
    end_latitude DOUBLE PRECISION,
    end_longitude DOUBLE PRECISION,
    route_points JSONB NOT NULL DEFAULT '[]'::jsonb,
    navigation_external_id TEXT,
    client_created_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    UNIQUE (user_id, id)
);

CREATE INDEX IF NOT EXISTS idx_mileage_logs_user_started_at
    ON mileage_logs (user_id, started_at DESC)
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_mileage_logs_user_platform
    ON mileage_logs (user_id, platform)
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_mileage_logs_navigation_external_id
    ON mileage_logs (user_id, navigation_external_id)
    WHERE navigation_external_id IS NOT NULL AND deleted_at IS NULL;

-- Row-level authorization must be enforced by the production API using the
-- authenticated user identity. The mobile client must never be allowed to write
-- a mileage row for an arbitrary user_id supplied by the client.
