FROM golang:1.26@sha256:8c5d338aa0da7e8b034efab738460793dc48d2aac8d497c8f8617d4ef964e0a7

WORKDIR /app

COPY go.mod ./

COPY *.go ./

# Build
RUN CGO_ENABLED=0 GOOS=linux go build -o /rolldice

EXPOSE 8081

# Run
CMD ["/rolldice"]
