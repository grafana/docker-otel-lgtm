FROM golang:1.26@sha256:5e69504bb541a36b859ee1c3daeb670b544b74b3dfd054aea934814e9107f6eb

WORKDIR /app

COPY go.mod ./

COPY *.go ./

# Build
RUN CGO_ENABLED=0 GOOS=linux go build -o /rolldice

EXPOSE 8081

# Run
CMD ["/rolldice"]
