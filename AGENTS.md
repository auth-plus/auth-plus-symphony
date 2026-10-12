# AGENTS.md - Auth+ Symphony

> **Propósito:** Este documento serve como ponto de entrada e contexto técnico para qualquer Agente de Inteligência Artificial (e desenvolvedores) atuando no repositório `auth-plus-symphony`.
>
> ⚠️ **Aviso de Escopo:** Este repositório é estritamente o **orquestrador da arquitetura**. Ele **NÃO** define nem gerencia regras de negócio específicas dos serviços (regras de negócio residem nos respectivos submódulos/repositórios). Este arquivo descreve a **visão arquitetural sistêmica**, a infraestrutura compartilhada, a topologia de rede e os fluxos de integração.

---

## 1. Visão Geral da Arquitetura

O `auth-plus-symphony` é a espinha dorsal de orquestração do ecossistema `auth-plus`. Seu objetivo principal é:
- Integrar e orquestrar todos os microsserviços da organização via Docker Compose.
- Simular tráfego, mensageria e fluxos ponta a ponta (E2E) entre os serviços em ambiente local.
- Prover uma infraestrutura unificada de observabilidade distribuída (APM, traces, logs e métricas).
- Facilitar testes de carga e validações locais idênticas ao ambiente produtivo.

```
                    ┌─────────────────────────┐
                    │    auth-plus-client     │ (Frontend - :5003)
                    └───────────┬─────────────┘
                                │ HTTP / REST
         ┌──────────────────────┼──────────────────────┐
         ▼                      ▼                      ▼
┌──────────────────┐  ┌──────────────────┐  ┌─────────────────────┐
│  authentication  │  │     billing      │  │    monetization     │
│  (Node.js :5000) │  │  (Rust :5002)    │  │   (Python :5004)    │
└────────┬─────────┘  └────────┬─────────┘  └──────────┬──────────┘
         │                     │                       │
         │ PostgreSQL          │ PostgreSQL            │ PostgreSQL
         ▼                     ▼                       ▼
   ┌────────────────────────────────────────────────────────┐
   │               PostgreSQL 17.6 (:5432)                  │
   │      [auth]         [billing]       [monetization]     │
   └────────────────────────────────────────────────────────┘
         ▲                     ▲                       ▲
         │                     │                       │
         └──────────┬──────────┴───────────┬───────────┘
                    │                      │
           Eventos  ▼                      ▼ Eventos
   ┌────────────────────────────────────────────────────────┐
   │             Apache Kafka KRaft (:9092)                 │
   │               Kafka UI (:8080)                         │
   └────────────────────────┬───────────────────────────────┘
                            │ Consome eventos
                            ▼
               ┌──────────────────────────┐
               │       notification       │
               │        (Go :5001)        │
               └──────────────────────────┘
```

---

## 2. Inventário de Serviços (Submódulos)

Cada microsserviço é gerenciado como um submódulo Git independente:

| Serviço | Diretório Submódulo | Stack / Runtime | Porta Host | Porta Interna | Banco de Dados / Dependências |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Authentication** | `auth-plus-authentication` | Node.js (TypeScript) | `5000` | `5000` | Postgres (`auth`), Valkey (Cache), Kafka, OTel |
| **Billing** | `auth-plus-billing` | Rust (Cargo) | `5002` | `5002` | Postgres (`billing`), Valkey, Kafka, OTel |
| **Monetization** | `auth-plus-monetization` | Python (Poetry / FastAPI) | `5004` | `8000` | Postgres (`monetization`), Kafka, OTel |
| **Notification** | `auth-plus-notification` | Go (Golang) | `5001` | `5001` | Kafka (Consumer), Provedores Externos, OTel |
| **Client** | `auth-plus-client` | Frontend (SPA/Web) | `5003` | `3000` | Comunicação HTTP com os backends |

---

## 3. Infraestrutura Compartilhada e Armazenamento

### 3.1. Banco de Dados (Database per Service)
- **Engine**: PostgreSQL 17.6 (`image: postgres:17.6`)
- **Porta**: `5432`
- **Isolamento Lógico**: Embora compartilhem a mesma instância em ambiente de desenvolvimento local, cada serviço possui seu banco isolado:
  - `auth` → Banco do serviço de autenticação.
  - `billing` → Banco do serviço de faturamento.
  - `monetization` → Banco do serviço de monetização.
  - `uptrace_db` → Banco do sistema de observabilidade.
- **Gerenciamento de Migrações**: As migrações de schema utilizam **`dbmate`** e são aplicadas automaticamente no boot de desenvolvimento via script centralizado.

### 3.2. Cache & Key-Value Store
- **Engine**: Valkey 7.2 (`image: valkey/valkey:7.2-alpine3.23` - fork open-source do Redis)
- **Porta**: `6379`
- **Admin UI**: Valkey Admin (`image: valkey/valkey-admin:1.0.2`) exposto na porta `8081`.

### 3.3. Mensageria Assíncrona (Event-Driven Backbone)
- **Broker**: Apache Kafka (`image: confluentinc/cp-kafka:latest`) em modo **KRaft** (sem dependência de ZooKeeper).
- **Porta**: `9092`
- **Kafka Web UI**: Provectuslabs Kafka UI (`image: provectuslabs/kafka-ui:latest`) exposto na porta `8080`.
- **Topologia de Comunicação**: Comunicação assíncrona orientada a eventos (ex.: eventos de usuário criado, requisições de 2FA/MFA, disparo de notificações transacionais, faturas criadas).

### 3.4. Observabilidade & Distributed Tracing (OpenTelemetry + Uptrace)

O ecossistema utiliza o **Uptrace** como plataforma central de APM (Application Performance Monitoring), rastreamento distribuído (Distributed Tracing), agregação de logs e métricas.

#### Arquitetura do Pipeline de Telemetria:
```
 [ Microsserviços: Node, Rust, Python, Go ]
                     │ OTLP (gRPC :4317 / HTTP :4318)
                     ▼
     ┌───────────────────────────────┐
     │   otelcol (OTel Collector)   │ ◄── Métricas de Host e PostgreSQL
     └───────────────┬───────────────┘
                     │ OTLP / Prometheus Remote Write
                     ▼
     ┌───────────────────────────────┐
     │      uptrace (:14318 Web)     │ (UI e Processamento de Alertas)
     └───────┬───────────────┬───────┘
             │               │
    Telemetria / Spans   Metadados / Config
             ▼               ▼
     ┌──────────────┐ ┌──────────────┐
     │  ClickHouse  │ │  PostgreSQL  │
     │    (:9000)   │ │ (uptrace_db) │
     └──────────────┘ └──────────────┘
```

#### Componentes e Portas:
- **Uptrace APM Server**:
  - Web UI: [http://localhost:14318](http://localhost:14318)
  - Porta gRPC interna: `14317:4317`
  - Porta HTTP interna: `14318:80`
- **OpenTelemetry Collector Contrib (`otelcol`)**:
  - Receptor OTLP gRPC: porta `4317`
  - Receptor OTLP HTTP: porta `4318`
  - Scrapers ativos: `hostmetrics` (CPU, memória, disco, rede), `postgresql` (métricas do banco `auth`) e `httpcheck`.
- **ClickHouse Server**:
  - Banco analítico colunar de alta performance para armazenamento massivo de spans, métricas e eventos de telemetria.
  - Portas: `8123` (HTTP) e `9000` (Native Client).
  - Database: `uptrace` / Usuário: `clickhouse_uptrace`.
- **PostgreSQL (`uptrace_db`)**:
  - Armazena metadados de contas, projetos, tokens de acesso e configurações de alerta do Uptrace.
- **Cache Valkey**:
  - Armazena sessões e cache em memória do Uptrace na porta `6379`.

#### Credenciais e Acesso em Desenvolvimento Local:
- **URL da Interface**: [http://localhost:14318](http://localhost:14318)
- **E-mail do Administrador**: `admin@uptrace.local`
- **Senha**: `admin`
- **Projeto Padrão**: `Project1`
- **Project Token**: `local_development_secret_token`
- **Formato da DSN do Uptrace**:
  ```text
  http://local_development_secret_token@uptrace:80?grpc=4317
  ```

#### Integração nos Microsserviços:
Cada container no Compose possui as seguintes variáveis padronizadas para envio de telemetria:
- `OTEL_EXPORTER_OTLP_ENDPOINT`: `http://otelcol:4317` (ou `4318`)
- `OTEL_SERVICE_NAME`: Identificador único do serviço no Uptrace (ex.: `auth-service`, `billing`, etc.)
- `UPTRACE_DSN`: DSN de ingestão apontando para o pipeline de tracing.

---

## 4. Topologia de Rede & Convenções de Hostnames

- **Rede Docker Compose**: `symphony-net` (driver bridge).
- **Comunicação Inter-Serviços**:
  - Dentro dos containers, os serviços resolvem uns aos outros pelo **nome do serviço** no compose (ex.: `database:5432`, `cache:6379`, `kafka:9092`, `otelcol:4317`).
  - Chamadas originadas da máquina host (ou de testes externos) utilizam `localhost:<porta_host>`.

---

## 5. Operação e Ciclo de Vida do Ambiente

Os fluxos de orquestração são padronizados através do `makefile`:

```bash
# 1. Atualização e sincronização dos submódulos (obrigatório após clone)
git submodule update --init --remote --recursive

# 2. Inicialização completa em modo desenvolvimento (sobe containers e aplica migrations)
make dev

# 3. Acesso interativo ao shell de um container específico
app=authentication make attach
app=billing make attach
app=monetization make attach
app=notification make attach
app=client make attach

# 4. Parada dos containers
make stop

# 5. Reinicialização limpa (recria volumes e reaplica migrations)
make reset

# 6. Limpeza agressiva do Docker (containers, redes, volumes e imagens do projeto)
make clean/docker
```

---

## 6. Diretrizes Obrigatórias para Agentes de IA

Ao atuar neste repositório, o Agente de IA deve cumprir as seguintes premissas:

1. **Separação de Responsabilidades (Bounded Contexts)**:
   - Não adicione lógicas de negócios, controllers ou regras de domínio na raiz do `auth-plus-symphony`.
   - Modificações de código de um microsserviço específico devem ser feitas estritamente dentro do diretório do respectivo submódulo.
2. **Isolamento de Dados**:
   - Nunca crie dependências diretas de banco de dados entre serviços. O serviço `billing` jamais deve acessar as tabelas do banco `auth`, e vice-versa. Toda comunicação inter-serviços deve ocorrer via **API REST** ou **tópicos do Kafka**.
3. **Execução de Comandos**:
   - Prefira utilizar os targets do `makefile` (`make dev`, `make attach`, `make migration/up`).
   - Evite rodar serviços diretamente na máquina host a menos que especificamente instruído pelo usuário, pois eles dependem da rede `symphony-net` e de variáveis configuradas no `docker-compose.yml`.
4. **Persistência de Migrações de Banco**:
   - As migrações ficam dentro da pasta `db/` de cada submódulo e são executadas via ferramenta `dbmate`.
5. **Observabilidade Contínua & Rastreabilidade no Uptrace**:
   - **Propagação de Contexto (W3C Trace Context)**: Ao criar ou ajustar comunicação entre serviços (HTTP REST ou mensagens Kafka), injete e extraia os headers `traceparent` e `tracestate`. Isso garante que a jornada completa da requisição apareça vinculada em um único trace distribuído no Uptrace.
   - **Kafka Headers**: Ao publicar eventos no broker, inclua os metadados de trace nos headers do Kafka para que os consumers (ex.: `notification`) continuem o span do producer.
   - **Diagnóstico de Falhas**: Ao validar fluxos ou simular requisições locais, utilize a interface do Uptrace ([http://localhost:14318](http://localhost:14318)) para inspecionar a cascata de spans, gargalos de latência, códigos de erro e exceções registradas.
