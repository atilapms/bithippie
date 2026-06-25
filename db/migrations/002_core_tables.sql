-- Core entities: researchers, projects, experiments, samples

CREATE TABLE researchers (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    first_name  TEXT NOT NULL,
    last_name   TEXT NOT NULL,
    email       TEXT NOT NULL UNIQUE,
    phone       TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE projects (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title       TEXT NOT NULL,
    description TEXT,
    status      project_status NOT NULL DEFAULT 'planning',
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE experiments (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id              UUID NOT NULL REFERENCES projects (id) ON DELETE CASCADE,
    previous_experiment_id  UUID REFERENCES experiments (id) ON DELETE SET NULL,
    title                   TEXT NOT NULL,
    hypothesis              TEXT,
    status                  experiment_status NOT NULL DEFAULT 'planned',
    start_date              DATE,
    end_date                DATE,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT experiments_valid_date_range
        CHECK (end_date IS NULL OR start_date IS NULL OR end_date >= start_date)
);

CREATE TABLE samples (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lab_sample_id    TEXT NOT NULL UNIQUE,
    specimen_type    TEXT NOT NULL,
    collected_at     TIMESTAMPTZ NOT NULL,
    storage_location TEXT,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON COLUMN samples.specimen_type IS
    'Free-text specimen classification (e.g. blood, tissue, chemical compound, soil).';
