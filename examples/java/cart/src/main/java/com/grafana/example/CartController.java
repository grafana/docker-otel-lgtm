package com.grafana.example;

import java.util.Map;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.RestTemplate;

import java.util.Optional;

@RestController
public class CartController {

	private final RestTemplate checkOutRestTemplate = new RestTemplate();

	@GetMapping("/cart")
	public ResponseEntity<Object> index(@RequestParam("customer") Optional<String> customerId) throws InterruptedException {
		HttpHeaders headers = new HttpHeaders();
		headers.add("X-Customer-ID", customerId.orElse("anonymous"));

		return ResponseEntity
			.status(HttpStatus.CREATED)
			.header("Custom-Header", "CustomValue")
			.body(Map.of(
				"id", "1"
			));

		// checkout returns result from cart
		// cart returns result cart ID
		// customer ID "error" will cause an error in checkout service
		// this will cause the sample logic to keep this span and tell both frontend and cart to keep the span
		// for now, we need to add the "sampled" attribute to the span
	}
}
