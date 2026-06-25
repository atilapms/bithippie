-- Many-to-many relationships

CREATE TABLE project_researchers (
    project_id    UUID NOT NULL REFERENCES projects (id) ON DELETE CASCADE,
    researcher_id UUID NOT NULL REFERENCES researchers (id) ON DELETE CASCADE,
    role          researcher_role NOT NULL,
    joined_at     TIMESTAMPTZ NOT NULL DEFAULT now(),

    PRIMARY KEY (project_id, researcher_id)
);

CREATE TABLE experiment_samples (
    experiment_id UUID NOT NULL REFERENCES experiments (id) ON DELETE CASCADE,
    sample_id     UUID NOT NULL REFERENCES samples (id) ON DELETE CASCADE,
    notes         TEXT,

    PRIMARY KEY (experiment_id, sample_id)
);
