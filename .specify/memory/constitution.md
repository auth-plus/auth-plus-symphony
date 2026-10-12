<!--
Sync Impact Report:
- Version change: Initial adoption (Template -> v1.0.0)
- Modified principles:
  - [PRINCIPLE_1_NAME] -> I. Orchestrator-Only Boundary
  - [PRINCIPLE_2_NAME] -> II. Strict Database-per-Service Isolation
  - [PRINCIPLE_3_NAME] -> III. Event-Driven Backbone & Asynchronous Contracts
  - [PRINCIPLE_4_NAME] -> IV. End-to-End Distributed Tracing & Observability
  - [PRINCIPLE_5_NAME] -> V. Reproducible Environment & Makefile-Driven Automation
- Added sections:
  - Architectural & Infrastructure Constraints (replacing [SECTION_2_NAME])
  - Development Workflow & Quality Gates (replacing [SECTION_3_NAME])
  - Governance (populated from template scaffold)
- Removed sections: None
- Follow-up TODOs: None
-->

# Auth+ Symphony Constitution

## Core Principles

### I. Orchestrator-Only Boundary (NON-NEGOTIABLE)
The root repository `auth-plus-symphony` MUST function strictly as an architectural orchestrator, local environment harness, and E2E simulation ground. Application business logic, domain models, controllers, and service implementations MUST NOT be written or modified in the root directory. All business capabilities MUST reside exclusively inside their designated submodule repositories (`auth-plus-authentication`, `auth-plus-billing`, `auth-plus-monetization`, `auth-plus-notification`, `auth-plus-client`).
*Rationale: Preserves bounded contexts and architectural hygiene, preventing orchestration configuration and microservice implementations from becoming tightly coupled.*

### II. Strict Database-per-Service Isolation
Each microservice MUST strictly own its persistent schema. Cross-service database queries, joins, or shared credentials are strictly forbidden: the billing service MUST NOT connect to the authentication database, and vice versa. Inter-service data synchronization and coordination MUST occur exclusively through synchronous HTTP/REST APIs or asynchronous Kafka events. Database schema changes MUST be managed per submodule under `db/` and executed through `dbmate`.
*Rationale: Enforces autonomy and failure isolation between microservices, preventing hidden data-level couplings.*

### III. Event-Driven Backbone & Asynchronous Contracts
Cross-service events (such as user creation, MFA verification, invoicing, and transactional alerts) MUST be published to Apache Kafka (KRaft mode). Event payloads MUST follow backward-compatible schemas and MUST NOT leak raw database internals or secrets. Message consumers (such as the notification service) MUST be designed to be idempotent and resilient to out-of-order execution or duplicate delivery.
*Rationale: Decouples service lifecycles, enables horizontal scalability, and ensures resilient asynchronous processing.*

### IV. End-to-End Distributed Tracing & Observability
All inter-service interactions (HTTP REST calls and Kafka message topics) MUST propagate W3C Trace Context headers (`traceparent` and `tracestate`). Publishers MUST inject trace metadata into Kafka message headers, and consumers MUST extract and continue the distributed span. Telemetry (spans, metrics, and structured logs) MUST be emitted via OpenTelemetry (OTLP) to the centralized collector (`otelcol:4317`/`4318`) and verified in Uptrace. Critical domain actions, latency bottlenecks, and failures MUST be observable.
*Rationale: Essential for end-to-end diagnostics and root-cause analysis across a heterogeneous polyglot architecture (TypeScript, Rust, Python, Go).*

### V. Reproducible Environment & Makefile-Driven Automation
The entire distributed ecosystem MUST be runnable and testable locally via Docker Compose on the `symphony-net` bridge network. Standard lifecycle operations MUST be executed via the central `makefile` (`make dev`, `make stop`, `make reset`, `make migration/up`). Direct local host execution that bypasses container networking or shared configuration is discouraged unless explicitly isolated.
*Rationale: Guarantees zero-drift reproducibility between developer workstations, CI workflows, and staging environments.*

## Architectural & Infrastructure Constraints

The ecosystem is strictly polyglot, organized via Git submodules and containerized services:
- **Service Runtimes & Ports**:
  - `auth-plus-authentication`: Node.js (TypeScript) — Host: `5000` | Container: `5000`
  - `auth-plus-billing`: Rust (Cargo) — Host: `5002` | Container: `5002`
  - `auth-plus-monetization`: Python (Poetry / FastAPI) — Host: `5004` | Container: `8000`
  - `auth-plus-notification`: Go (Golang) — Host: `5001` | Container: `5001`
  - `auth-plus-client`: Frontend SPA/Web — Host: `5003` | Container: `3000`
- **Shared Infrastructure**:
  - **Database Engine**: PostgreSQL 17.6 (`database:5432`), logical separation (`auth`, `billing`, `monetization`, `uptrace_db`). Migrations executed via `dbmate`.
  - **Cache & Key-Value**: Valkey 7.2 (`cache:6379`) with Valkey Admin (`:8081`).
  - **Message Broker**: Apache Kafka KRaft (`kafka:9092`) with Kafka UI (`:8080`).
  - **Observability Stack**: Uptrace APM (`:14318`), OpenTelemetry Collector (`otelcol:4317`/`4318`), and ClickHouse (`:9000`/`:8123`).
- **Networking**:
  - Inter-service calls inside containers MUST use service DNS names over `symphony-net` (e.g., `http://database:5432`, `http://kafka:9092`, `http://otelcol:4317`).
  - External host traffic MUST connect via mapped host ports on `localhost`.

## Development Workflow & Quality Gates

- **Submodule Synchronization**: All submodules MUST be kept in sync using `git submodule update --init --remote --recursive`.
- **Database Migrations**: Every schema modification MUST be committed within the respective submodule's `db/` folder as a standard migration file and validated via `make migration/up`.
- **Trace & Flow Verification**: Any new inter-service endpoint or event producer/consumer MUST be validated end-to-end in Uptrace ([http://localhost:14318](http://localhost:14318)) to ensure unbroken distributed trace journeys.
- **Contract & Integration Testing**: New cross-service workflows MUST include integration and contract tests verifying API responses, Kafka event consumption, and error handling.

## Governance

This Constitution supersedes all informal conventions and ad-hoc practices across `auth-plus-symphony`. Every pull request, architectural revision, and automated agent workflow MUST verify compliance against the Core Principles.
- **Amendment Procedure**: Amendments to this Constitution require documentation of rationale, a corresponding semantic version bump, and an impact assessment for existing submodules and infrastructure.
- **Versioning Policy**:
  - **MAJOR**: Incompatible principle removals or foundational architectural shifts.
  - **MINOR**: Addition of new principles, governance sections, or expanded standards.
  - **PATCH**: Non-semantic clarifications, typo corrections, or wording refinements.
- **Compliance Review**: Code reviews and spec-driven planning phases (`/speckit-plan`, `/speckit-tasks`) MUST explicitly validate compliance with these principles, particularly orchestrator boundaries, database isolation, and W3C trace context propagation.

**Version**: 1.0.0 | **Ratified**: 2026-10-12 | **Last Amended**: 2026-10-12
