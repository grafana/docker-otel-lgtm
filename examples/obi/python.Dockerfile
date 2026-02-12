# Same Flask app as ../python but WITHOUT the OpenTelemetry Python distro.
# OBI (eBPF Instrumentation) provides observability at the kernel level instead.

# hadolint global ignore=DL3059
FROM python:alpine3.19

WORKDIR /app

COPY requirements.txt .

RUN apk add --no-cache build-base
RUN pip install --upgrade pip
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

EXPOSE 8082

CMD ["flask", "run", "--host", "0.0.0.0", "--port", "8082"]
