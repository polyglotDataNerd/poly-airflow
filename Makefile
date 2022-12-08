airflow:
	docker-compose --file compose/docker-compose.yml up

# Login to AWS registry (must have docker running)
docker-login:
	aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin 712639424220.dkr.ecr.us-west-2.amazonaws.com

# Build docker target
docker-build:
	docker build -f Dockerfile -t 712639424220.dkr.ecr.us-west-2.amazonaws.com/poly/airflow:latest-test5 --force-rm --no-cache .

# Push to registry
docker-push:
	docker push 712639424220.dkr.ecr.us-west-2.amazonaws.com/poly/airflow:latest-test5

# Build docker image and push to AWS registry
docker-build-and-push: docker-login docker-build docker-push

down:
	#kafka-topics.sh --bootstrap-server localhost:2181 --topic test --delete
	docker-compose --file compose/docker-compose.yml down --remove-orphans

stop:
	#kafka-topics.sh --bootstrap-server localhost:2181 --topic test --delete
	docker-compose --file compose/docker-compose.yml stop