package com.grafana.example;

import java.security.MessageDigest;
import java.util.Map;
import java.util.Optional;
import java.util.Random;
import java.util.UUID;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.RestTemplate;

@RestController
public class CartController {

	private final RestTemplate checkOutRestTemplate = new RestTemplate();
    private final Random random = new Random(0);

	@GetMapping("/cart")
	public ResponseEntity<Object> index(@RequestParam("customer") Optional<String> customerId) throws InterruptedException {

        // 10ms base request rate with 0-10ms fluctuation
        Thread.sleep((long) (10 + Math.abs((random.nextGaussian() + 1.0) * 10)));

        // 0.1% of requests
        if (random.nextInt(1000) <= 1) {
          Thread.sleep((long) (Math.abs((random.nextGaussian() + 1.0) * 100.0)));
        }

        // 0.1% of requests
        if (random.nextInt(1000) <= 1) {
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

		return ResponseEntity
			.status(HttpStatus.CREATED)
			.body(Map.of(
                // random positive id between 1-100,000
				"id", UUID.randomUUID().toString()
			));
	}
}
