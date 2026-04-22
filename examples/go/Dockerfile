FROM golang:1.26@sha256:f7159064a17ccc65d0e10e342ae8783026182704bf4af8f6df8d5ba9af2be2fd

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY *.go ./

# Build
RUN CGO_ENABLED=0 GOOS=linux go build -o /rolldice

EXPOSE 8081

# Run
CMD ["/rolldice"]
