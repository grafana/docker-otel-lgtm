FROM golang:1.27@sha256:c292963ad0e5f51e843c726edc204a4e4c26a859ba1e4d736d91028aa3633048

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY *.go ./

# Build
RUN CGO_ENABLED=0 GOOS=linux go build -o /rolldice

EXPOSE 8081

# Run
CMD ["/rolldice"]
