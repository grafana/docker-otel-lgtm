FROM golang:1.27@sha256:fe517acaa580cc7915457080f850c37e618b3c1e750f98b58fc6429b605147a1

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY *.go ./

# Build
RUN CGO_ENABLED=0 GOOS=linux go build -o /rolldice

EXPOSE 8081

# Run
CMD ["/rolldice"]
