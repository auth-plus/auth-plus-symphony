# Feature Specification: [FEATURE NAME]

**Feature Branch**: `[###-feature-name]`

**Created**: [DATE]

**Status**: Draft

**Input**: User description: "$ARGUMENTS"

## Service Impact Matrix *(mandatory)*

<!--
  Identify which submodules are affected by this feature and their respective roles.
-->

| Service / Submodule | Tech Stack | Role in Feature | Impact Type |
| :--- | :--- | :--- | :--- |
| `auth-plus-authentication` | Node.js (TypeScript) | [Role, e.g., Producer of mfa.requested] | [None / Producer / Consumer / REST API / Storage] |
| `auth-plus-billing` | Rust (Cargo) | [Role, e.g., Consumer to bill SMS units] | [None / Producer / Consumer / REST API / Storage] |
| `auth-plus-monetization` | Python (FastAPI) | [Role, e.g., Plan quota checks] | [None / Producer / Consumer / REST API / Storage] |
| `auth-plus-notification` | Go (Golang) | [Role, e.g., Consumer to dispatch SMS/Email] | [None / Producer / Consumer / REST API / Storage] |
| `auth-plus-client` | Frontend (SPA/Web) | [Role, e.g., UI forms and status] | [None / UI Form / API Client] |
| `auth-plus-symphony` | Orchestrator / Compose | [Environment config, compose ports, E2E flow] | [Docker / Env / E2E Simulation] |

---

## User Scenarios & Testing *(mandatory)*

<!--
  IMPORTANT: User stories should be PRIORITIZED as user journeys ordered by importance.
  Each story must represent an independently testable cross-service journey.
-->

### User Story 1 - [Brief Title] (Priority: P1)

[Describe this user journey across the affected services in plain language]

**Why this priority**: [Explain the value and why it has this priority level]

**Independent Test**: [Describe how this journey can be triggered and verified E2E]

**Acceptance Scenarios**:

1. **Given** [initial state across services], **When** [trigger action], **Then** [expected outcome in target services]
2. **Given** [initial state], **When** [trigger action], **Then** [expected outcome]

---

### User Story 2 - [Brief Title] (Priority: P2)

[Describe this user journey in plain language]

**Why this priority**: [Explain value and priority level]

**Independent Test**: [Describe how this can be tested independently]

**Acceptance Scenarios**:

1. **Given** [initial state], **When** [action], **Then** [expected outcome]

---

### User Story 3 - [Brief Title] (Priority: P3)

[Describe this user journey in plain language]

**Why this priority**: [Explain value and priority level]

**Independent Test**: [Describe how this can be tested independently]

**Acceptance Scenarios**:

1. **Given** [initial state], **When** [action], **Then** [expected outcome]

---

## Inter-Service Contracts & Communication *(mandatory)*

<!--
  Define all asynchronous Kafka events and synchronous HTTP REST contracts involved in this feature.
-->

### Asynchronous Events (Kafka)

#### Event: `[topic.name]`
- **Publisher**: `[service-name]`
- **Consumer(s)**: `[service-name-1]`, `[service-name-2]`
- **Key**: `[Partition key, e.g. user_id]`
- **W3C Trace Context**: Producer MUST inject `traceparent` / `tracestate` into Kafka message headers.
- **Payload Schema (JSON)**:
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "properties": {
    "event_id": { "type": "string", "format": "uuid" },
    "occurred_at": { "type": "string", "format": "date-time" }
  },
  "required": ["event_id", "occurred_at"]
}
```

### Synchronous APIs (HTTP / REST)

#### Endpoint: `[METHOD /api/v1/resource]`
- **Host Service**: `[service-name]` (`:port`)
- **Caller(s)**: `[client / service-name]`
- **Headers**: `Authorization: Bearer <token>`, `traceparent: <trace>`
- **Request Body**:
```json
{}
```
- **Response**: `200 OK` / `400 Bad Request` / `500 Internal Error`

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST [specific capability across services]
- **FR-002**: System MUST [data / event propagation requirement]
- **FR-003**: Service [name] MUST [specific action or validation]
- **FR-004**: Service [name] MUST be idempotent when consuming events from topic `[topic.name]`
- **FR-005**: All services MUST propagate W3C Trace Context headers to maintain unbroken traces in Uptrace

### Edge Cases & Failure Handling

- What happens when a consumer service is temporarily down or slow?
- How is event deduplication / idempotency guaranteed on duplicate deliveries?
- What happens if an external provider (e.g. SMS provider, Stripe) fails or times out?
- How are database conflicts handled within the owning service's schema?

---

## Key Entities & Database Ownership

<!--
  Clarify which service owns which entity. Cross-service DB access is forbidden.
-->

- **[Entity 1]**: Owned strictly by `[service]`, stored in `[database]`.
- **[Entity 2]**: Owned strictly by `[service]`, stored in `[database]`.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: [Measurable business outcome, e.g., "MFA SMS dispatched within 3 seconds of login request"]
- **SC-002**: [E2E Trace integrity, e.g., "100% of transactions appear as a single unbroken trace in Uptrace"]
- **SC-003**: [Reliability metric, e.g., "Zero unhandled message rejections on Kafka consumer"]
- **SC-004**: [Performance metric, e.g., "p95 response time under 200ms across inter-service calls"]

---

## Assumptions & Dependencies

- [Assumption about network connectivity within `symphony-net`]
- [Assumption about existing database schemas or baseline migrations]
- [Third-party dependency, e.g., mock external API or credentials]
