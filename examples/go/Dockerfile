FROM golang:1.26@sha256:db1271a193b5b6cac1749d8d23c3b3564b37852836a5880ca0a65e1924f7feab

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY *.go ./

# Build
RUN CGO_ENABLED=0 GOOS=linux go build -o /rolldice

EXPOSE 8081

# Run
CMD ["/rolldice"]
