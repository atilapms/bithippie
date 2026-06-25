#!/bin/bash
set -euo pipefail

echo "Applying database migrations..."

for migration in /migrations/*.sql; do
  echo "  -> $(basename "$migration")"
  psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -f "$migration"
done

echo "All migrations applied successfully."
