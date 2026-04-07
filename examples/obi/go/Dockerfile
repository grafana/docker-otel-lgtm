FROM golang:1.26@sha256:42ebbf7958e4caa4c95fd8bb2ec57dd7c668af769dcafb70a62ab8739a70f8a9

WORKDIR /app

COPY go.mod ./

COPY *.go ./

# Build
RUN CGO_ENABLED=0 GOOS=linux go build -o /rolldice

EXPOSE 8081

# Run
CMD ["/rolldice"]
