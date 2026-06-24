# knevo-backend

Spring Boot 3.5 REST API for the Knevo rehabilitation system. Serves the iOS patient app and React doctor portal.

## Prerequisites

- Java 21
- Docker (for PostgreSQL)
- Gradle (wrapper included)

## Run for development

**1. Start PostgreSQL:**

```bash
docker compose up -d
```

This starts PostgreSQL 16 on port 5432, database `knevo`, user `knevo`, password `knevo`. The `docker-compose.yml` is in the repo root.

**2. Start the backend:**

```bash
./gradlew bootRun
```

The server starts on `http://localhost:8080`. Flyway runs migrations automatically on startup.

**3. Verify:**

```bash
curl http://localhost:8080/api/health
# → {"status":"ok"}
```

**Default admin account** (seeded by migration V3):
- Email: `admin@knevo.com`
- Password: `Admin1234!`

## Environment variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DB_URL` | `jdbc:postgresql://localhost:5432/knevo?stringtype=unspecified` | JDBC URL |
| `DB_USER` | `knevo` | Database user |
| `DB_PASSWORD` | `knevo` | Database password |
| `JWT_SECRET` | `dev-secret-key-at-least-256-bits-long-for-hs256-algorithm` | HMAC-SHA256 signing key — **change in production** |

## Run tests

```bash
./gradlew test
```

Tests require a running PostgreSQL instance (the Docker Compose one is sufficient). 10 integration test classes cover all M0–M9 scenarios.

To see test output:

```bash
./gradlew test --info
```

## Lint

The project uses [ktlint](https://pinterest.github.io/ktlint/) via the Gradle plugin. However, the source is Java not Kotlin, so this check does not apply to application code. No lint tool is configured for Java source at this time.

```bash
./gradlew ktlintCheck   # currently a no-op for Java source
```

## Database migrations

Flyway migrations live in `src/main/resources/db/migration/`. They run automatically on startup.

| Migration | Contents |
|-----------|----------|
| `V1__init_schema.sql` | Full schema (17 tables, 22 types, indexes) |
| `V2__convert_role_columns_to_varchar.sql` | Enum → VARCHAR for JPA |
| `V3__seed_admin.sql` | Admin account |
| `V4__seed_exercises.sql` | 15 rehabilitation exercises |
| `V5__session_schema_additions.sql` | Set record status, more enum conversions |

To reset the database and re-run migrations:

```bash
docker compose down -v   # drops the PostgreSQL volume
docker compose up -d
./gradlew bootRun        # migrations run from scratch
```

## Project structure

```
src/main/java/com/knevo/
├── config/        SecurityConfig, WebSocketConfig
├── controller/    8 REST controllers
├── service/       7 service classes
├── repository/    11 JPA repositories
├── model/         11 JPA entities
├── security/      JwtService, JwtAuthFilter
├── dto/           40 request/response DTOs
└── util/          EnrollmentCodeGenerator

src/main/resources/
├── application.yml
└── db/migration/  Flyway SQL files
```

## Contributing

1. Write a Flyway migration for any schema change — never modify `ddl-auto` to `create` or `update`.
2. Every new endpoint needs at least one integration test in `src/test/java/com/knevo/controller/`.
3. Service methods that write to the database must be `@Transactional`.
4. Run `./gradlew test` before committing. All tests must pass.
5. Commit message format: `feat(M<N>): <one-line summary>` matching the milestone.

## Known issues

See `docs/codebase-backend.md` for a full issue list. Critical items before any deployment:
- All endpoints currently lack authorization (`@PreAuthorize`) — this is a known gap.
- Controllers use `X-User-Id` header instead of JWT principal — a security risk in production.
