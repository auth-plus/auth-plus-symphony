# Implementation Plan: [FEATURE]

**Branch**: `[###-feature-name]` | **Date**: [DATE] | **Spec**: [link to spec.md]

**Input**: Feature specification from `specs/[###-feature-name]/spec.md`

## Summary

[Extract from feature spec: primary cross-service capability + technical approach across submodules]

## Technical Context

<!--
  Technical details for the affected services in the Symphony ecosystem.
-->

**Affected Submodules**:
- [ ] `auth-plus-authentication` (Node.js 20+ / TypeScript / Express)
- [ ] `auth-plus-billing` (Rust / Cargo / Tokio)
- [ ] `auth-plus-monetization` (Python 3.11+ / FastAPI / Poetry)
- [ ] `auth-plus-notification` (Go 1.22+ / Goroutines)
- [ ] `auth-plus-client` (Frontend SPA / Web)
- [ ] `auth-plus-symphony` (Docker Compose / Dbmate / Network / Uptrace)

**Storage & Migrations**:
- Database: PostgreSQL 17.6 (`database:5432`)
- Migrations: `dbmate` applied to respective service database (`auth`, `billing`, `monetization`) via `make migration/up`
- Cache: Valkey 7.2 (`cache:6379`)

**Messaging & Events**:
- Apache Kafka KRaft (`kafka:9092`)
- Tópicos: `[topic.names]`

**Observability & Tracing**:
- OpenTelemetry Collector (`otelcol:4317` gRPC / `:4318` HTTP)
- Distributed APM: Uptrace (`http://localhost:14318`)
- Trace Propagation: W3C Trace Context (`traceparent` / `tracestate`)

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [ ] **Gate 1: Orchestrator Boundary**: No application business logic, models, or domain code is added to the root of `auth-plus-symphony`. All domain logic is isolated inside submodules.
- [ ] **Gate 2: Database Isolation**: No service reads or writes directly to another service's database. Cross-service data is exchanged solely via HTTP APIs or Kafka events.
- [ ] **Gate 3: Dbmate Migrations**: Any schema additions are versioned within the submodule's `db/` folder and tested via `make migration/up`.
- [ ] **Gate 4: Event-Driven Resilience**: Kafka consumers are idempotent and resilient to duplicate deliveries. Schemas are backward-compatible.
- [ ] **Gate 5: W3C Trace Context Propagation**: All HTTP client calls and Kafka message producers inject `traceparent` headers. Consumers extract and link traces into Uptrace.
- [ ] **Gate 6: Container Parity**: All new dependencies, environment variables, or ports are properly wired in `docker-compose.yml` on `symphony-net`.

---

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── spec.md              # Feature specification (/speckit-specify output)
├── plan.md              # This implementation plan (/speckit-plan output)
├── research.md          # Technical research & decisions
├── contracts/           # Integration contracts
│   ├── events/          # Kafka event JSON Schemas (*.schema.json)
│   └── http/            # OpenAPI / REST contracts (*.yaml)
└── tasks.md             # Task breakdown (/speckit-tasks output)
```

### Source Code Mapping (by Submodule)

```text
auth-plus-authentication/
├── src/                 # Business logic, routes, and controllers
└── db/                  # Dbmate schema migrations (auth db)

auth-plus-billing/
├── src/                 # Rust domain logic, handlers, and models
└── db/                  # Dbmate schema migrations (billing db)

auth-plus-monetization/
├── src/                 # Python FastAPI routes, domain, and repositories
└── db/                  # Dbmate schema migrations (monetization db)

auth-plus-notification/
├── cmd/                 # Go entrypoints
└── internal/            # Go Kafka consumer handlers and dispatchers

auth-plus-client/
└── src/                 # Frontend views, API client

auth-plus-symphony/
├── docker-compose.yml   # Infrastructure orchestration
└── makefile             # Lifecycle and migration commands
```

---

## Complexity & Deviation Tracking

> **Fill ONLY if any Constitution Gate has exceptions or requires special justification**

| Item / Gate | Deviation / Complex Choice | Why Needed | Alternative Rejected |
| :--- | :--- | :--- | :--- |
| [e.g. Sync HTTP vs Kafka] | [Synchronous REST call] | [Strict immediate consistency required] | [Kafka async event rejected due to UI block] |
