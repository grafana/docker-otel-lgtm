FROM golang:1.27@sha256:e0174e51e81218523251d85d248a90d24c3d5e81543b4f07a5d66229397db190

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY *.go ./

# Build
RUN CGO_ENABLED=0 GOOS=linux go build -o /rolldice

EXPOSE 8081

# Run
CMD ["/rolldice"]
