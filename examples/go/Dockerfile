FROM golang:1.26@sha256:4039008348701774eb9d513d88fe16fcc518514ba6afc5e2fff5db3c55a32999

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY *.go ./

# Build
RUN CGO_ENABLED=0 GOOS=linux go build -o /rolldice

EXPOSE 8081

# Run
CMD ["/rolldice"]
