-- RADHA Postgres bootstrap.
--
-- Runs once on first container start. Installs the extensions every
-- BE phase relies on. Idempotent.

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS citext;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
