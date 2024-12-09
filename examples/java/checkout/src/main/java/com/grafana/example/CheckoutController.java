package com.grafana.example;

import io.opentelemetry.api.GlobalOpenTelemetry;
import io.opentelemetry.api.trace.Span;
import io.opentelemetry.api.trace.StatusCode;
import io.opentelemetry.api.trace.Tracer;
import io.opentelemetry.context.Scope;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.RestTemplate;

import java.security.MessageDigest;
import java.util.Optional;
import java.util.Random;

@RestController
public class CheckoutController {

    private final RestTemplate checkOutRestTemplate = new RestTemplate();
    private final Random random = new Random(0);

    @GetMapping("/checkout")
    public String index(@RequestParam("customer") Optional<String> customerId) throws InterruptedException {
        // call cart before and after internal call to simulate a more realistic scenario
        // 1. if an error occurs in the internal call, the second call to cart should be sampled, but not the first
        //    (because we don't know that the trace is interesting yet)
        // 2. if we keep 10 traces per minute per service, we should see 10 traces for the check service
        //    but 20 traces for the cart service
        callCart(customerId);

        // 10ms base request rate with 0-10ms fluctuation
        Thread.sleep((long) (10 + Math.abs((random.nextGaussian() + 1.0) * 10)));

        // 0.1% of requests
        if (random.nextInt(10000) <= 1) {
            Thread.sleep((long) (Math.abs((random.nextGaussian() + 1.0) * 100.0)));
        }

        // 0.1% of requests
        if (random.nextInt(20000) <= 1) {
            try {
                // 10 million
                for (int i = 1; i <= 1000000; i++) {
                    MessageDigest digest = MessageDigest.getInstance("SHA-256");
                    digest.update(("" + random.nextInt()).getBytes());
                }
            }
            catch(Exception ex){
                throw new RuntimeException(ex);
            }
        }

        try {
            // todo why did this not work?
            // ((ExtendedSpanBuilder) GlobalOpenTelemetry.getTracer("app").spanBuilder("internal")).startAndRun(() -> {
            //     if (random.nextInt(10) < 2) {
            //         throw new RuntimeException("Simulating application error");
            //     }
            // });

            Tracer tracer = GlobalOpenTelemetry.getTracer("app");
            Span span = tracer.spanBuilder("internal").startSpan();

            try (Scope scope = span.makeCurrent()) {
                // 1% error rate
                if (random.nextInt(100) <= 1) {
                    throw new RuntimeException("Simulating application error");
                }
            }
            catch (RuntimeException e) {
                span.recordException(e);
                span.setStatus(StatusCode.ERROR);
                throw e;
            }
            finally {
                span.end();
            }
        } catch (RuntimeException e) {
            // we don't want to propagate this exception to the client
            // but the whole trace should be kept
        }

        return callCart(customerId).getBody();
    }

    private ResponseEntity<String> callCart(Optional<String> customerId) {
        HttpHeaders headers = new HttpHeaders();
               headers.add("X-Customer-ID", customerId.orElse("anonymous"));

        return checkOutRestTemplate.exchange("http://localhost:8083/cart",
                HttpMethod.GET,
                new HttpEntity<>(headers), String.class);
    }
}
