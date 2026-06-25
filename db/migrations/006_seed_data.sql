-- Seed data: Glycemic Response Study narrative
-- Demonstrates multi-researcher projects, experiment follow-ups,
-- shared samples, and numeric/categorical/text measurements.

-- Measurement type catalog (extensible without schema changes)
INSERT INTO measurement_types (name, value_kind, default_unit, description) VALUES
    ('glucose_concentration', 'numeric',     'mg/L',  'Blood glucose concentration'),
    ('incubation_temperature', 'numeric',    '°C',    'Incubation chamber temperature'),
    ('elisa_result',           'categorical', NULL,   'ELISA qualitative outcome'),
    ('researcher_observation', 'text',        NULL,    'Free-text field notes from the researcher');

DO $$
DECLARE
  -- Researchers
  v_pi_id       UUID;
  v_grad_id     UUID;
  v_tech_id     UUID;
  v_solo_pi_id  UUID;

  -- Projects
  v_glycemic_project_id UUID;
  v_soil_project_id     UUID;

  -- Experiments
  v_exp1_id UUID;
  v_exp2_id UUID;

  -- Samples
  v_blood_sample_id UUID;
  v_tissue_sample_id UUID;

  -- Measurement types
  v_glucose_type_id    UUID;
  v_temp_type_id       UUID;
  v_elisa_type_id      UUID;
  v_observation_type_id UUID;
BEGIN
  -- Researchers
  INSERT INTO researchers (first_name, last_name, email, phone)
  VALUES ('Elena', 'Vasquez', 'e.vasquez@lab.example', '+1-555-0101')
  RETURNING id INTO v_pi_id;

  INSERT INTO researchers (first_name, last_name, email, phone)
  VALUES ('Marcus', 'Chen', 'm.chen@lab.example', '+1-555-0102')
  RETURNING id INTO v_grad_id;

  INSERT INTO researchers (first_name, last_name, email, phone)
  VALUES ('Priya', 'Nair', 'p.nair@lab.example', NULL)
  RETURNING id INTO v_tech_id;

  INSERT INTO researchers (first_name, last_name, email, phone)
  VALUES ('James', 'Okonkwo', 'j.okonkwo@lab.example', '+1-555-0104')
  RETURNING id INTO v_solo_pi_id;

  -- Projects
  INSERT INTO projects (title, description, status)
  VALUES (
    'Glycemic Response Study',
    'Investigating postprandial glucose dynamics in fasting blood samples under controlled incubation.',
    'active'
  )
  RETURNING id INTO v_glycemic_project_id;

  INSERT INTO projects (title, description, status)
  VALUES (
    'Soil Microbiome Survey',
    'Baseline characterization of microbial diversity across regional soil samples. Not yet started.',
    'planning'
  )
  RETURNING id INTO v_soil_project_id;

  -- Project membership: three researchers on the glycemic project
  INSERT INTO project_researchers (project_id, researcher_id, role) VALUES
    (v_glycemic_project_id, v_pi_id,   'principal_investigator'),
    (v_glycemic_project_id, v_grad_id, 'graduate_student'),
    (v_glycemic_project_id, v_tech_id, 'lab_technician');

  -- Solo PI on the planning project
  INSERT INTO project_researchers (project_id, researcher_id, role) VALUES
    (v_soil_project_id, v_solo_pi_id, 'principal_investigator');

  -- Samples
  INSERT INTO samples (lab_sample_id, specimen_type, collected_at, storage_location)
  VALUES (
    'SMP-2024-042',
    'blood',
    '2024-03-15 09:30:00+00',
    'Freezer A, Rack 2, Slot 7'
  )
  RETURNING id INTO v_blood_sample_id;

  INSERT INTO samples (lab_sample_id, specimen_type, collected_at, storage_location)
  VALUES (
    'SMP-2024-043',
    'tissue',
    '2024-03-16 14:00:00+00',
    'Freezer B, Rack 1, Slot 3'
  )
  RETURNING id INTO v_tissue_sample_id;

  -- Experiments: Exp-2 is a follow-up to Exp-1
  INSERT INTO experiments (
    project_id, title, hypothesis, status, start_date, end_date
  ) VALUES (
    v_glycemic_project_id,
    'Baseline Glucose Assay',
    'Fasting blood samples will show glucose concentrations below 100 mg/L under standard assay conditions.',
    'completed',
    '2024-03-20',
    '2024-03-22'
  )
  RETURNING id INTO v_exp1_id;

  INSERT INTO experiments (
    project_id, previous_experiment_id, title, hypothesis, status, start_date, end_date
  ) VALUES (
    v_glycemic_project_id,
    v_exp1_id,
    'Replication with Extended Incubation',
    'Extending incubation to 45 minutes will not significantly alter glucose readings, validating the baseline protocol.',
    'completed',
    '2024-04-01',
    '2024-04-03'
  )
  RETURNING id INTO v_exp2_id;

  -- Link samples to experiments (blood sample reused across both)
  INSERT INTO experiment_samples (experiment_id, sample_id, notes) VALUES
    (v_exp1_id, v_blood_sample_id,  'Primary fasting sample'),
    (v_exp1_id, v_tissue_sample_id, 'Control tissue reference'),
    (v_exp2_id, v_blood_sample_id,  'Same fasting sample — replication run'),
    (v_exp2_id, v_tissue_sample_id, 'Control tissue reference');

  -- Resolve measurement type IDs
  SELECT id INTO v_glucose_type_id
  FROM measurement_types WHERE name = 'glucose_concentration';

  SELECT id INTO v_temp_type_id
  FROM measurement_types WHERE name = 'incubation_temperature';

  SELECT id INTO v_elisa_type_id
  FROM measurement_types WHERE name = 'elisa_result';

  SELECT id INTO v_observation_type_id
  FROM measurement_types WHERE name = 'researcher_observation';

  -- Measurements for Exp-1
  INSERT INTO measurements (
    experiment_id, sample_id, measurement_type_id,
    numeric_value, unit, measured_at, notes
  ) VALUES (
    v_exp1_id, v_blood_sample_id, v_glucose_type_id,
    92.5, 'mg/L', '2024-03-21 10:15:00+00',
    'Within expected fasting range'
  );

  INSERT INTO measurements (
    experiment_id, sample_id, measurement_type_id,
    numeric_value, unit, measured_at
  ) VALUES (
    v_exp1_id, NULL, v_temp_type_id,
    37.0, '°C', '2024-03-21 09:00:00+00'
  );

  INSERT INTO measurements (
    experiment_id, sample_id, measurement_type_id,
    categorical_value, measured_at
  ) VALUES (
    v_exp1_id, v_blood_sample_id, v_elisa_type_id,
    'negative', '2024-03-21 11:00:00+00'
  );

  INSERT INTO measurements (
    experiment_id, sample_id, measurement_type_id,
    text_value, measured_at, notes
  ) VALUES (
    v_exp1_id, v_blood_sample_id, v_observation_type_id,
    'Sample showed slight hemolysis after thaw; reading may be marginally elevated.',
    '2024-03-21 10:30:00+00',
    'Logged by Marcus Chen'
  );

  -- Measurements for Exp-2 (follow-up replication)
  INSERT INTO measurements (
    experiment_id, sample_id, measurement_type_id,
    numeric_value, unit, measured_at, notes
  ) VALUES (
    v_exp2_id, v_blood_sample_id, v_glucose_type_id,
    94.1, 'mg/L', '2024-04-02 10:20:00+00',
    'Consistent with baseline assay — hypothesis supported'
  );

  INSERT INTO measurements (
    experiment_id, sample_id, measurement_type_id,
    numeric_value, unit, measured_at
  ) VALUES (
    v_exp2_id, NULL, v_temp_type_id,
    37.0, '°C', '2024-04-02 09:00:00+00'
  );

  INSERT INTO measurements (
    experiment_id, sample_id, measurement_type_id,
    categorical_value, measured_at
  ) VALUES (
    v_exp2_id, v_blood_sample_id, v_elisa_type_id,
    'negative', '2024-04-02 11:05:00+00'
  );
END $$;
