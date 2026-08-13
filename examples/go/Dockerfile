FROM golang:1.26@sha256:5822931cf78fe98a97edcf73a0c54c29fa2386b99c8136468e274ae9fab8cfba

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY *.go ./

# Build
RUN CGO_ENABLED=0 GOOS=linux go build -o /rolldice

EXPOSE 8081

# Run
CMD ["/rolldice"]
