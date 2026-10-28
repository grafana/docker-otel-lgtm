FROM golang:1.27@sha256:b76020929b709ddb6202afc05410a0faefae20ae05e27ad548b3870092688a69

WORKDIR /app

COPY go.mod ./

COPY *.go ./

# Build
RUN CGO_ENABLED=0 GOOS=linux go build -o /rolldice

EXPOSE 8081

# Run
CMD ["/rolldice"]
