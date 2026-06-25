-- Example queries demonstrating key model capabilities.
-- Run after starting the database: docker compose up -d

-- 1. Researchers and their roles on a project
SELECT
    p.title AS project,
    r.first_name,
    r.last_name,
    pr.role,
    pr.joined_at
FROM project_researchers pr
JOIN researchers r ON r.id = pr.researcher_id
JOIN projects p ON p.id = pr.project_id
ORDER BY p.title, pr.role;

-- 2. Experiment follow-up chain
SELECT
    e.title AS experiment,
    e.status,
    prev.title AS follows_experiment
FROM experiments e
LEFT JOIN experiments prev ON prev.id = e.previous_experiment_id
ORDER BY e.start_date;

-- 3. Samples used across multiple experiments
SELECT
    s.lab_sample_id,
    s.specimen_type,
    array_agg(e.title ORDER BY e.start_date) AS used_in_experiments,
    count(*) AS experiment_count
FROM samples s
JOIN experiment_samples es ON es.sample_id = s.id
JOIN experiments e ON e.id = es.experiment_id
GROUP BY s.id, s.lab_sample_id, s.specimen_type
HAVING count(*) > 1;

-- 4. Measurements grouped by value kind
SELECT
    mt.name AS measurement_type,
    mt.value_kind,
    e.title AS experiment,
    s.lab_sample_id,
    m.numeric_value,
    m.unit,
    m.categorical_value,
    m.text_value,
    m.measured_at
FROM measurements m
JOIN measurement_types mt ON mt.id = m.measurement_type_id
JOIN experiments e ON e.id = m.experiment_id
LEFT JOIN samples s ON s.id = m.sample_id
ORDER BY e.title, m.measured_at;

-- 5. Full experiment context for a project
SELECT
    p.title AS project,
    e.title AS experiment,
    e.hypothesis,
    e.status,
    s.lab_sample_id,
    es.notes AS sample_usage_notes
FROM projects p
JOIN experiments e ON e.project_id = p.id
LEFT JOIN experiment_samples es ON es.experiment_id = e.id
LEFT JOIN samples s ON s.id = es.sample_id
WHERE p.title = 'Glycemic Response Study'
ORDER BY e.start_date, s.lab_sample_id;
