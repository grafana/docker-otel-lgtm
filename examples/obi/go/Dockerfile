FROM golang:1.27@sha256:205c7636d74e0ffbe3d007162df7d74f859f5a8c8322dfb9f907977686c126cf

WORKDIR /app

COPY go.mod ./

COPY *.go ./

# Build
RUN CGO_ENABLED=0 GOOS=linux go build -o /rolldice

EXPOSE 8081

# Run
CMD ["/rolldice"]
