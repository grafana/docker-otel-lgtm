FROM python:alpine3.19

WORKDIR /app

COPY requirements.txt .

# How to get the requirements.txt file?
# 1. Follow https://opentelemetry.io/docs/languages/python/getting-started/
# 2. Run `pip freeze > requirements.txt` in the same directory as your app.py file
RUN pip install -r requirements.txt

RUN pip install opentelemetry-distro[otlp]
RUN opentelemetry-bootstrap -a install

COPY app.py .

# Logging support is still in alpha, so we need to enable it explicitly
ENV OTEL_PYTHON_LOGGING_AUTO_INSTRUMENTATION_ENABLED=true
ENV OTEL_LOGS_EXPORTER=otlp

EXPOSE 8082

CMD ["opentelemetry-instrument", "flask", "run", "--host", "0.0.0.0", "--port", "8082"]



