-- Measurement type catalog and measurement records

CREATE TABLE measurement_types (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name         TEXT NOT NULL UNIQUE,
    value_kind   measurement_value_kind NOT NULL,
    default_unit TEXT,
    description  TEXT,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE measurements (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    experiment_id       UUID NOT NULL REFERENCES experiments (id) ON DELETE CASCADE,
    sample_id           UUID REFERENCES samples (id) ON DELETE SET NULL,
    measurement_type_id UUID NOT NULL REFERENCES measurement_types (id) ON DELETE RESTRICT,
    numeric_value       NUMERIC,
    unit                TEXT,
    categorical_value   TEXT,
    text_value          TEXT,
    measured_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    notes               TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON COLUMN measurements.sample_id IS
    'Optional reference to the sample measured; some measurements are experiment-level.';
