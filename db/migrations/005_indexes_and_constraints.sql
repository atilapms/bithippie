-- Indexes and data integrity constraints

-- Foreign key indexes
CREATE INDEX idx_experiments_project_id
    ON experiments (project_id);

CREATE INDEX idx_experiments_previous_experiment_id
    ON experiments (previous_experiment_id)
    WHERE previous_experiment_id IS NOT NULL;

CREATE INDEX idx_project_researchers_researcher_id
    ON project_researchers (researcher_id);

CREATE INDEX idx_experiment_samples_sample_id
    ON experiment_samples (sample_id);

CREATE INDEX idx_measurements_experiment_id
    ON measurements (experiment_id);

CREATE INDEX idx_measurements_sample_id
    ON measurements (sample_id)
    WHERE sample_id IS NOT NULL;

CREATE INDEX idx_measurements_measurement_type_id
    ON measurements (measurement_type_id);

CREATE INDEX idx_measurements_measured_at
    ON measurements (measured_at);

-- Ensure measurement value columns align with the type's value_kind
CREATE OR REPLACE FUNCTION validate_measurement_value()
RETURNS TRIGGER AS $$
DECLARE
    kind measurement_value_kind;
BEGIN
    SELECT value_kind INTO kind
    FROM measurement_types
    WHERE id = NEW.measurement_type_id;

    IF kind IS NULL THEN
        RAISE EXCEPTION 'measurement_type_id % does not exist', NEW.measurement_type_id;
    END IF;

    IF kind = 'numeric' THEN
        IF NEW.numeric_value IS NULL THEN
            RAISE EXCEPTION 'numeric measurements require numeric_value';
        END IF;
        IF NEW.categorical_value IS NOT NULL OR NEW.text_value IS NOT NULL THEN
            RAISE EXCEPTION 'numeric measurements must not set categorical_value or text_value';
        END IF;
    ELSIF kind = 'categorical' THEN
        IF NEW.categorical_value IS NULL THEN
            RAISE EXCEPTION 'categorical measurements require categorical_value';
        END IF;
        IF NEW.numeric_value IS NOT NULL OR NEW.text_value IS NOT NULL THEN
            RAISE EXCEPTION 'categorical measurements must not set numeric_value or text_value';
        END IF;
    ELSIF kind = 'text' THEN
        IF NEW.text_value IS NULL THEN
            RAISE EXCEPTION 'text measurements require text_value';
        END IF;
        IF NEW.numeric_value IS NOT NULL OR NEW.categorical_value IS NOT NULL THEN
            RAISE EXCEPTION 'text measurements must not set numeric_value or categorical_value';
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validate_measurement_value
    BEFORE INSERT OR UPDATE ON measurements
    FOR EACH ROW
    EXECUTE FUNCTION validate_measurement_value();

-- Keep updated_at current on mutable core tables
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_researchers_updated_at
    BEFORE UPDATE ON researchers
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_projects_updated_at
    BEFORE UPDATE ON projects
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_experiments_updated_at
    BEFORE UPDATE ON experiments
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_samples_updated_at
    BEFORE UPDATE ON samples
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();
