# Laboratory Experiment Tracking System

A PostgreSQL data model for tracking scientific experiments in a research laboratory. This repository contains the relational schema, seed data, and Docker setup to run everything with a single command.

## Quick start

**Prerequisites:** [Docker](https://docs.docker.com/get-docker/) and Docker Compose.

```bash
docker compose up -d
```

This starts PostgreSQL 16, applies all migrations in order, and loads seed data on first run.

**Connect to the database:**

```bash
docker exec -it lab_experiment_db psql -U lab -d lab_experiments
```

| Setting  | Value            |
|----------|------------------|
| Host     | `localhost`      |
| Port     | `5432`           |
| Database | `lab_experiments`|
| User     | `lab`            |
| Password | `lab`            |

**Reset to a clean state** (drops the volume and re-runs all migrations + seed):

```bash
docker compose down -v && docker compose up -d
```

**Run example queries:**

```bash
docker exec -i lab_experiment_db psql -U lab -d lab_experiments -f - < db/examples.sql
```

## Schema overview

The model covers six core concepts from the lab's requirements:

| Entity | Table | Description |
|--------|-------|-------------|
| Researchers | `researchers` | Scientists with contact details |
| Projects | `projects` | Research initiatives with lifecycle status |
| Project membership | `project_researchers` | Many-to-many link with per-project roles |
| Experiments | `experiments` | Individual tests belonging to one project; optional follow-up link |
| Samples | `samples` | Physical specimens with lab-assigned IDs |
| Sample usage | `experiment_samples` | Many-to-many link between experiments and samples |
| Measurement types | `measurement_types` | Extensible catalog of measurement kinds |
| Measurements | `measurements` | Data points (numeric, categorical, or text) tied to experiments |

```
researchers ──< project_researchers >── projects ──< experiments
                                              │            │
                                              │            ├──> experiments (follow-up)
                                              │            │
samples ──< experiment_samples >─────────────┘            │
  │                                                        │
  └──────────────────── measurements ──────────────────────┘
                              │
                    measurement_types
```

Migrations live in [`db/migrations/`](db/migrations/) and run automatically via [`db/init.sh`](db/init.sh) on first container start.

## Assumptions

The challenge spec leaves several points open. These are the assumptions I made and documented rather than blocking on clarification:

- **Researcher roles are per-project**, not global. A person can be PI on one project and a graduate student on another.
- **One role per researcher per project.** If someone wears two hats on the same project, we'd need a junction redesign.
- **Experiment follow-up has a single parent.** An experiment references at most one `previous_experiment_id`. Chains are supported; branching (multiple predecessors) is not.
- **Project and experiment lifecycles are independent.** A project can be `active` while individual experiments are `completed`, `failed`, etc.
- **No project-level start/end dates.** Temporal boundaries live on experiments; project status is the lifecycle indicator.
- **Sample reference on measurements is optional.** The spec says measurements "usually" reference a sample — experiment-level readings (e.g. incubation temperature) have a null `sample_id`.
- **Specimen types are free-text**, not a controlled vocabulary. Common values (blood, tissue, soil) are documented via a column comment.
- **UUID primary keys** throughout, generated with `gen_random_uuid()` via the `pgcrypto` extension.
- **Hard deletes with cascading** where ownership is clear (e.g. deleting a project removes its experiments). No soft-delete columns.
- **Lab-assigned sample IDs** (`lab_sample_id`) are separate from the internal UUID, since the lab's identifier is the meaningful business key.

## Design tradeoffs

### Measurement storage: typed columns + type catalog

**Chosen:** A `measurement_types` lookup table paired with a single `measurements` table that has nullable `numeric_value`, `categorical_value`, and `text_value` columns. A trigger enforces that only the column matching the type's `value_kind` is populated.

**Alternatives considered:**

| Approach | Why not |
|----------|---------|
| **EAV** (entity-attribute-value) | Flexible but painful to query, no type safety, poor indexing for numeric ranges |
| **JSONB `value` column** | Easy to extend but weak constraints, awkward for aggregations and unit-aware queries |
| **Separate tables per value kind** | Type-safe but requires joins across three tables for any cross-kind report |

The chosen approach lets the lab add new measurement techniques by inserting a row into `measurement_types` — no schema migration required — while keeping queryable, typed columns.

### Status fields: PostgreSQL ENUMs

**Chosen:** Native ENUM types for `project_status`, `experiment_status`, and `researcher_role`.

**Tradeoff:** ENUMs are simple and enforce valid values at the database level, but adding a new status requires `ALTER TYPE ... ADD VALUE`. If the lab needs user-defined statuses, a lookup table with a `statuses` entity would be a better fit. I kept ENUMs because the spec describes a small, stable set of lifecycle states.

### UUID vs. serial primary keys

**Chosen:** UUIDs for all primary keys.

**Tradeoff:** UUIDs are slightly larger and less human-readable than serial integers, but they avoid ID collisions across environments, make seed data portable, and simplify future federation or data merges — common in multi-lab research contexts.

### Considered but intentionally not built

- **Audit / event-sourcing tables** for tracking who changed an experiment's hypothesis or status. Valuable for compliance but out of scope for the initial data model.
- **Global researcher role table** separate from project membership. The spec ties roles to lab context per project, so a global role felt redundant.
- **Hierarchical samples** (e.g. aliquots derived from a parent sample). The spec doesn't mention sample lineage.
- **Soft deletes** (`deleted_at` columns). Lab data typically needs explicit retention policies rather than silent soft deletion.

## Open questions for the lab

Before building an application on top of this model, I'd want to clarify:

1. **Can an experiment follow multiple prior experiments?** The current model supports a single `previous_experiment_id`. If branching replication is common, a junction table (`experiment_predecessors`) would be needed.
2. **Is there a controlled vocabulary for specimen types?** Free-text works for now, but a `specimen_types` lookup table would improve consistency if the lab has a standard taxonomy.
3. **Should measurements record who entered them?** A `recorded_by` FK to `researchers` would support accountability and filtering by author.
4. **Are units standardized?** Currently free-text per measurement (with a `default_unit` on the type). If SI enforcement or unit conversion matters, a `units` reference table would help.
5. **What is the data retention policy?** Can completed projects be archived or deleted? This affects whether we need archive tables or partitioning.
6. **Do researchers need authentication?** This model is a data layer only. If the app needs login, we'd add a separate auth identity linked to `researchers`.
7. **Can a researcher hold multiple roles on the same project?** The current unique constraint on `(project_id, researcher_id)` prevents this.

## Seed data narrative

The seed data tells a short story around the **Glycemic Response Study**:

- **3 researchers** collaborate: a PI, a graduate student, and a lab technician
- **2 experiments**: a baseline glucose assay followed by a replication with extended incubation
- **Sample `SMP-2024-042`** (blood) is reused across both experiments
- **4 measurement kinds**: glucose concentration (numeric, mg/L), incubation temperature (numeric, °C), ELISA result (categorical), and a researcher observation (text)
- A second project (**Soil Microbiome Survey**) in `planning` status shows the project lifecycle

## Project structure

```
├── docker-compose.yml          # Single-command database setup
├── README.md
└── db/
    ├── init.sh                 # Runs migrations on first boot
    ├── examples.sql            # Validation and demo queries
    └── migrations/
        ├── 001_extensions_and_enums.sql
        ├── 002_core_tables.sql
        ├── 003_junction_tables.sql
        ├── 004_measurements.sql
        ├── 005_indexes_and_constraints.sql
        └── 006_seed_data.sql
```
