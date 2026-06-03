FROM golang:1.26@sha256:68cb6d68bed024785b69195b89af7ac7a444f27791435f98647edff595aa0479

WORKDIR /app

COPY go.mod ./

COPY *.go ./

# Build
RUN CGO_ENABLED=0 GOOS=linux go build -o /rolldice

EXPOSE 8081

# Run
CMD ["/rolldice"]
