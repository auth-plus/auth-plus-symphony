.PHONY: run
run:
	docker-compose up -d
	make start/authentication

.PHONY: start/authentication
start/authentication:
	cd ./auth-plus-authentication
	$(shell make infra/up)
	cd ..

.PHONY: clean/docker
clean/docker:
	make infra/down
	docker container prune -f
	docker volume prune -f
	docker image prune -f
	docker network prune -f
	rm -rf db/schema.sql
	rm -f db/schema.sql


.PHONY: k8s/up
k8s/up:
	cp ./script/minikube.sh ./minikube.sh
	chmod +x ./minikube.sh
	bash ./minikube.sh
	minikube dashboard
	
.PHONY: k8s/down
k8s/down:
	minikube kubectl delete service api
	minikube stop
	rm ./minikube.sh