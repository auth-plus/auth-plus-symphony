# [CHECKLIST TYPE] Checklist: [FEATURE NAME]

**Purpose**: [Review quality and architectural compliance for cross-service feature]
**Created**: [DATE]
**Feature**: [Link to spec.md / plan.md]

**Note**: This checklist validates compliance with the **Auth+ Symphony Constitution** and cross-service integration criteria.
**Marker Semantics**: Mark `[x]` only when the criterion has been reviewed and verified.

---

## 1. Architectural & Scope Boundary

- [ ] CHK001 Nenhuma regra de negócio ou modelo de domínio foi adicionado na raiz do `auth-plus-symphony`.
- [ ] CHK002 Todas as alterações de código de aplicação residem estritamente dentro dos seus respectivos submódulos (`auth-plus-authentication`, `auth-plus-billing`, etc.).
- [ ] CHK003 Não há acesso direto ou cruzado entre bancos de dados (ex: serviço A nunca consulta banco do serviço B).

## 2. Contratos & Mensageria Assíncrona

- [ ] CHK004 Todos os eventos Kafka novos ou modificados possuem schema definido em `specs/[feature]/contracts/events/`.
- [ ] CHK005 Produtores de mensagens injetam os headers W3C Trace Context (`traceparent` e `tracestate`).
- [ ] CHK006 Consumidores Kafka extraem o trace context e dão continuidade aos spans.
- [ ] CHK007 Consumidores são idempotentes e tratam adequadamente reentregas ou falhas transitórias.

## 3. Banco de Dados & Migrações

- [ ] CHK008 Novas tabelas/colunas possuem arquivo de migração compatível com `dbmate` dentro de `<submodulo>/db/`.
- [ ] CHK009 As migrações foram testadas com sucesso via `make migration/up`.
- [ ] CHK010 Migrações são retrocompatíveis e não causam downtime durante o rollout.

## 4. Observabilidade & Validação E2E

- [ ] CHK011 O fluxo ponta a ponta foi simulado e verificado no ambiente local (`symphony-net`).
- [ ] CHK012 O trace completo foi verificado no Uptrace (`http://localhost:14318`) sem quebras de span entre HTTP e Kafka.
- [ ] CHK013 Logs e métricas foram emitidos via OTLP para o `otelcol`.

## 5. Governança e Controle de Versão

- [ ] CHK014 Cada submódulo modificado teve suas alterações comitadas em seu próprio repositório Git.
- [ ] CHK015 O ponteiro dos submódulos foi atualizado e registrado no commit do `auth-plus-symphony`.
- [ ] CHK016 Critérios de aceitação da feature (definidos em `spec.md`) foram todos satisfeitos.
