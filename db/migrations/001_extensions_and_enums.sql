-- Extensions and enumerated types

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TYPE project_status AS ENUM (
    'planning',
    'active',
    'completed',
    'cancelled'
);

CREATE TYPE experiment_status AS ENUM (
    'planned',
    'in_progress',
    'completed',
    'failed',
    'cancelled'
);

CREATE TYPE researcher_role AS ENUM (
    'principal_investigator',
    'lab_technician',
    'graduate_student',
    'postdoc',
    'other'
);

CREATE TYPE measurement_value_kind AS ENUM (
    'numeric',
    'categorical',
    'text'
);
