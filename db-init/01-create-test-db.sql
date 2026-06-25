-- Isolated database for backend integration tests, so the test suite never
-- collides with manually-created data in the dev `knevo` database.
-- Runs once on first Postgres container init (docker-entrypoint-initdb.d).
-- The backend test config (knevo-backend/src/test/resources/application.yml)
-- points at this database; Flyway migrates its schema on the first test run.
CREATE DATABASE knevo_test OWNER knevo;
