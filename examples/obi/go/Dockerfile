FROM golang:1.26@sha256:d52df9c279840adf958d017ebb275651ed8338b953d39817bc3633a2e6b1bbcc

WORKDIR /app

COPY go.mod ./

COPY *.go ./

# Build
RUN CGO_ENABLED=0 GOOS=linux go build -o /rolldice

EXPOSE 8081

# Run
CMD ["/rolldice"]
