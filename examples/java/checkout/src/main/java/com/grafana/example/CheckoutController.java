package com.grafana.example;

import io.opentelemetry.api.GlobalOpenTelemetry;
import io.opentelemetry.api.trace.Span;
import io.opentelemetry.api.trace.StatusCode;
import io.opentelemetry.api.trace.Tracer;
import io.opentelemetry.context.Scope;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.RestTemplate;

import java.util.Optional;
import java.util.Random;

@RestController
public class CheckoutController {

    private final RestTemplate checkOutRestTemplate = new RestTemplate();
    private final Random random = new Random(0);

    @GetMapping("/checkout")
    public String index(@RequestParam("customer") Optional<String> customerId) throws InterruptedException {
        HttpHeaders headers = new HttpHeaders();
        headers.add("X-Customer-ID", customerId.orElse("anonymous"));

        Thread.sleep((long) (Math.abs((random.nextGaussian() + 1.0) * 200.0)));

        try {
            // todo why did this not work?
//            ((ExtendedSpanBuilder) GlobalOpenTelemetry.getTracer("app").spanBuilder("internal")).startAndRun(() -> {
//                            if (random.nextInt(10) < 2) {
//                                throw new RuntimeException("Simulating application error");
//                            }
//                        });

            Tracer tracer = GlobalOpenTelemetry.getTracer("app");
            Span span = tracer.spanBuilder("internal").startSpan();
            try (Scope scope = span.makeCurrent()) {
                if (random.nextInt(10) < 2) {
                    throw new RuntimeException("Simulating application error");
                }
            } catch (RuntimeException e) {
                span.recordException(e);
                span.setStatus(StatusCode.ERROR);
                throw e;
            } finally {
                span.end();
            };
        } catch (RuntimeException e) {
            // we don't want to propagate this exception to the client
            // but the whole trace should be kept
        }

        return checkOutRestTemplate.exchange("http://localhost:8083/cart",
                HttpMethod.GET,
                new HttpEntity<>(headers), String.class).getBody();
    }
}
