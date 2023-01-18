# Auth+ Symphony

This for orchestrate all services of auth-plus organization. This repo was created so we can simulate traffic between services. This way we can look after observability issues and execute e2e and load tests on user machine.

In the future we can use config files to create enviroments for test purpose directing link for private registry like Container Registry or AWS ECR. This way we can simulate staging enviroment locally.

## Setup

For this work you should clone this repository and then clone others repository. like this:

```bash
git clone git@github.com:auth-plus/auth-plus-symphony.git
cd auth-plus-symphony
git clone git@github.com:auth-plus/auth-plus-authentication.git
git clone git@github.com:auth-plus/auth-plus-billing.git
git clone git@github.com:auth-plus/auth-plus-client.git
git clone git@github.com:auth-plus/auth-plus-notification.git
```

## Commands

```bash
# rise all containers in production mode
make start

# rise all containers in development mode
make dev

# Attach bash to container. THIS SHOULD ONLY BE USED AFTER make start/dev
app=authentication make attach
app=notification make attach
app=billing make attach

# rise all containers
make stop

# reset all containers
make clean/docker
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
- Kafdrop: <http://localhost:9000/>

### Observability

- Prometheus: <http://localhost:9090/>
- Grafana: <http://localhost:3000/>
- Kibana: <http://localhost:5601/> (user/password: elastic/elk_password )
- Zipkin: <http://localhost:9411/>

## TODO

- [ ] Add Vault from HashiCorp
- [ ] Local simulation with minikube
- [ ] Update ELK version to 8.5 but there's some issues with elatic user
