# Auth+ Symphony

This for orchestrate all services of auth-plus organization. This repo was created so we can simulate traffic between services. This way we can look after observability issues and execute e2e and load tests on user machine.

In the future we can use config files to create enviroments for test purpose directing link for private registry like Container Registry or AWS ECR. This way we can simulate staging enviroment locally.

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
app=client make attach
app=monetization make attach

# rise all containers
make stop

# reset all containers
make clean/docker
```

## Documentation

Tutorial: [link](./docs/TUTORIAL.md)
Postaman Collections:

- Authentication: [link](./docs/Authentication.postman_collection.json)
- Billing: [link](./docs/Billing.postman_collection.json)
- Notification: [link](./docs/Notification.postman_collection.json)

## Link after infra build up

### Services

- Authentication: <http://localhost:5000/>
- Billing: <http://localhost:5002/>
- Billing(Kafka): <http://localhost:5012/>
- Client: <http://localhost:5003/>
- Notification: <http://localhost:5001/>
- Notification(Kafka): <http://localhost:5011/>
- Monetization: <http://localhost:5004/>

### Storage

- Postgres(Authentication, Billing, Monetization): <http://localhost:5432/>
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

- Add [Vault](https://www.vaultproject.io/) for managing secret
- Local simulation with minikube
- Update ELK version to 8.5 but there's some issues with elatic user
- Add Change Data Capture (CDC) like [Debezium](https://debezium.io/)
