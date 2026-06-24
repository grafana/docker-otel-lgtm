FROM golang:1.26@sha256:478231bfd9677835606c249208483a3c43b31e941c1040c48747b111c7ab871c

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY *.go ./

# Build
RUN CGO_ENABLED=0 GOOS=linux go build -o /rolldice

EXPOSE 8081

# Run
CMD ["/rolldice"]
