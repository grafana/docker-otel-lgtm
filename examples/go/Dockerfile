FROM golang:1.26@sha256:a9c4aaca2982a34e9e5b8d5e906f29cf797a893655182bcf8b90d65071a730ea

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY *.go ./

# Build
RUN CGO_ENABLED=0 GOOS=linux go build -o /rolldice

EXPOSE 8081

# Run
CMD ["/rolldice"]
