FROM golang:1.26@sha256:d184d9be4c13614e28498d632eeaaac704d662f18ad357e1df74a44424236cea

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY *.go ./

# Build
RUN CGO_ENABLED=0 GOOS=linux go build -o /rolldice

EXPOSE 8081

# Run
CMD ["/rolldice"]
