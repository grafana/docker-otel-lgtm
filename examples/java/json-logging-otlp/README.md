# Exporting Application logs using JSON logging in Kubernetes

## Running the example

1. Build the Docker image using using `build.sh`
2. Deploy the manifest using `kubectl apply -f k8s/` (e.g. using [k3d.sh](k3d.sh))
3. Generate traffic using [generate-traffic.sh](../../../generate-traffic.sh)
4. Log in to [http://localhost:3000](http://localhost:3000) with user _admin_ and password _admin_.
5. Go to "Explore"
6. Select "Loki" as data source
