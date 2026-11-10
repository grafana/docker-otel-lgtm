FROM golang:1.27@sha256:01aa404fa56b604b6f48e90c1d6e2c79fe5cd78f9592f78d80303fbe171cdcc0

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY *.go ./

# Build
RUN CGO_ENABLED=0 GOOS=linux go build -o /rolldice

EXPOSE 8081

# Run
CMD ["/rolldice"]
