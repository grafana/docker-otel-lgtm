# docker-otel-lgtm

This is work in progress, don't use it.

## Build and run the Docker image

```
cd docker
docker build . -t grafana/otel-lgtm
docker run -p 3000:3000 -p 4317:4317 --rm -ti grafana/otel-lgtm
```

## Build and run the example app

```
./run-example.sh
```

## Generate traffic

```
./generate-traffic.sh
```

## View in Grafana

Log in to [http://localhost:3000](http://localhost:3000) with user _admin_ and password _admin_.
