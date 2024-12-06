package com.grafana.example;

import java.security.MessageDigest;
import java.util.List;
import java.util.Optional;
import java.util.Random;
import io.opentelemetry.api.trace.Span;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.RestTemplate;

@RestController
public class FrontendController {

    private final RestTemplate checkOutRestTemplate = new RestTemplate();
    private final Random random = new Random(0);

    @GetMapping("/shop")
    public String index(@RequestParam("customer") Optional<String> customerId) throws InterruptedException {
        HttpHeaders headers = new HttpHeaders();
        headers.add("X-Customer-ID", customerId.orElse("anonymous"));

        ResponseEntity<String> response = checkOutRestTemplate.exchange("http://localhost:8082/checkout",
                HttpMethod.GET,
                new HttpEntity<>(headers), String.class);

        List<String> list = response.getHeaders().get("Server-Timing");

        if (list != null) {
            for (String timing : list) {
                if (timing.endsWith("-01\"")) {
                    // sampled traces are marked with a server timing header
                    Span.current().setAttribute("sampled", true);
                    Span.current().setAttribute("sampled.comment", "child-workaround");
                }
            }
        }

        // 10ms base request rate with 0-10ms fluctuation
        Thread.sleep((long) (10 + Math.abs((random.nextGaussian() + 1.0) * 10)));

        // 1% of requests take much longer
        if (random.nextInt(100) <= 1) {
          Thread.sleep((long) (Math.abs((random.nextGaussian() + 1.0) * 100.0)));
        }

        // 1% of requests use more cpu
        if (random.nextInt(100) < 1) {
            try {
                // 10 million
                for (int i = 1; i <= 10000000; i++) {
                    MessageDigest digest = MessageDigest.getInstance("SHA-256");
                    digest.update(("" + random.nextInt()).getBytes());
                }
            }
            catch(Exception ex){
                throw new RuntimeException(ex);
            }
        }

        return response.getBody();
    }
}
