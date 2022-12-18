# Auth+ Symphony

This for orchestrate all services of auth-plus. For this work you should clone this repository and then clone others repository. like this

```bash
git clone git@github.com:auth-plus/auth-plus-symphony.git
cd auth-plus-symphony
git clone git@github.com:auth-plus/auth-plus-authentication.git
git clone git@github.com:auth-plus/auth-plus-billing.git
git clone git@github.com:auth-plus/auth-plus-notification.git
```

## Commands

```bash
# rise all containers
make start

# rise all containers
make stop
```

## Link after infra build up

### Services

- Authentication: <http://localhost:5000/>
- Billing: <http://localhost:5002/>
- Notification: <http://localhost:5001/>

### Storage

- Postgres(Authentication): <http://localhost:5432/>
- Postgres(Billing): <http://localhost:5433/>
- Redis: <http://localhost:6379/>
- Redis-Commander: <http://localhost:8081/>

### Message Broker

- Kafka: <http://localhost:9092/>
- Kafdrop: <http://localhost:19000/>

### Observability

- Prometheus: <http://localhost:9090/>
- Grafana: <http://localhost:3000/>
- Kibana: <http://localhost:5601/>
- Jaeger: <http://localhost:16686/>

## TODO

- [ ] Add Vault from HashiCorp
- [ ] Local simulation with minikube
