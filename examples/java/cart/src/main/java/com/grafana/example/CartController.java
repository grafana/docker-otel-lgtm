package com.grafana.example;

import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.RestTemplate;

import java.util.Map;
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
	}
}
