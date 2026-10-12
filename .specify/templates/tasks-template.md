---
description: "Task list template for multi-service feature implementation"
---

# Tasks: [FEATURE NAME]

**Input**: Design documents from `specs/[###-feature-name]/` (`plan.md`, `spec.md`, `contracts/`)

**Prerequisites**: `plan.md` (required), `spec.md` (required), `contracts/` (event schemas / API definitions)

**Organization**: Tasks are grouped into logical execution phases:
1. **Contracts & Migrations** (Schema definitions and Dbmate migrations)
2. **Submodule Implementations** (Organized by service and user story)
3. **E2E Simulation & Tracing Validation** (Execution via Docker Compose & Uptrace verification)
4. **Git Submodule Bumps & Symphony Commit** (Synchronizing git pointers)

## Format: `[ID] [P?] [Service] Description`

- **[P]**: Can run in parallel (different submodules/files, no blockers)
- **[Service]**: Target submodule (e.g., `[auth]`, `[billing]`, `[notification]`, `[monetization]`, `[client]`, `[symphony]`)
- Include exact file paths in task descriptions.

---

## Phase 1: Contracts & Shared Interfaces

**Purpose**: Formalize inter-service contracts before implementing business code.

- [ ] T001 [P] [symphony] Define Kafka event schema in `specs/[feature]/contracts/events/[event].schema.json`
- [ ] T002 [P] [symphony] Define API contract / endpoints in `specs/[feature]/contracts/http/[api].yaml`

---

## Phase 2: Database Schemas & Migrations

**Purpose**: Apply required database schema changes per service before service implementation begins.

- [ ] T003 [P] [auth] Create dbmate migration in `auth-plus-authentication/db/[timestamp]_[name].sql` (if applicable)
- [ ] T004 [P] [billing] Create dbmate migration in `auth-plus-billing/db/[timestamp]_[name].sql` (if applicable)
- [ ] T005 [P] [monetization] Create dbmate migration in `auth-plus-monetization/db/[timestamp]_[name].sql` (if applicable)
- [ ] T006 [symphony] Execute `make migration/up` and verify tables across databases

**Checkpoint**: Database schemas migrated and verified.

---

## Phase 3: Submodule Implementations (by Service / Story)

### Submodule: auth-plus-authentication (Node.js)

- [ ] T007 [auth] Implement domain model / repository in `auth-plus-authentication/src/...`
- [ ] T008 [auth] Implement Kafka event producer with W3C `traceparent` injection
- [ ] T009 [auth] Add unit / service tests in `auth-plus-authentication/tests/...`

### Submodule: auth-plus-notification (Go)

- [ ] T010 [notification] Implement Kafka event consumer handler in `auth-plus-notification/internal/...`
- [ ] T011 [notification] Extract W3C trace context and link OpenTelemetry span
- [ ] T012 [notification] Implement idempotent message processing and delivery logic

### Submodule: auth-plus-billing (Rust)

- [ ] T013 [billing] Implement billing domain logic / event listener in `auth-plus-billing/src/...`
- [ ] T014 [billing] Ensure transaction safety and persistent record creation

### Submodule: auth-plus-monetization (Python)

- [ ] T015 [monetization] Implement route / service logic in `auth-plus-monetization/src/...`

### Submodule: auth-plus-client (Frontend)

- [ ] T016 [client] Implement UI trigger / API consumption in `auth-plus-client/src/...`

**Checkpoint**: All service-level implementations complete and compiled.

---

## Phase 4: E2E Simulation & Observability Verification

**Purpose**: Validate the complete distributed journey inside the containerized environment.

- [ ] T017 [symphony] Rebuild/restart affected containers via `make dev` or `docker compose up -d --build [services]`
- [ ] T018 [symphony] Simulate E2E request (via curl / Postman script) triggering the full flow
- [ ] T019 [symphony] Inspect trace graph in Uptrace (`http://localhost:14318`) — verify unbroken span from HTTP request through Kafka topics to consumers
- [ ] T020 [symphony] Verify Kafka UI (`http://localhost:8080`) — ensure messages processed without dead-letter errors

**Checkpoint**: End-to-end integration verified, telemetry unbroken in Uptrace.

---

## Phase 5: Git Submodules & Symphony Commit

**Purpose**: Commit code changes within respective submodules and update orchestrator pointers.

- [ ] T021 [P] Commit changes inside each modified submodule (`git add`, `git commit` in `auth-plus-*`)
- [ ] T022 [symphony] Stage updated submodule commit pointers and specs in `auth-plus-symphony`
- [ ] T023 [symphony] Commit feature tracking on orchestrator (`git commit -m "feat([feature]): integrate cross-service flow"`)

---

## Dependencies & Execution Order

1. **Contracts (Phase 1)** MUST precede implementation.
2. **Database Migrations (Phase 2)** MUST be executed before services can interact with new columns/tables.
3. **Producers** should be implemented before or in parallel with **Consumers**.
4. **E2E Simulation (Phase 4)** requires all containers running via `docker compose`.
5. **Submodule Commits (Phase 5)** must be performed after all tests and verifications pass.
