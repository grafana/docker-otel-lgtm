FROM golang:1.26@sha256:16e774b791968123d6af5ba4eec19cf91c4208cb1f5849efda5d4ffaf6d1c038

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY *.go ./

# Build
RUN CGO_ENABLED=0 GOOS=linux go build -o /rolldice

EXPOSE 8081

# Run
CMD ["/rolldice"]
