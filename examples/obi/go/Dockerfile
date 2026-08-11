FROM golang:1.26@sha256:7caba5286b4c3613a337b709c573047d8ae62ee76106647313b61e72b99f20af

WORKDIR /app

COPY go.mod ./

COPY *.go ./

# Build
RUN CGO_ENABLED=0 GOOS=linux go build -o /rolldice

EXPOSE 8081

# Run
CMD ["/rolldice"]
