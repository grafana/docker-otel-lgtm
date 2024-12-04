package com.grafana.example;

import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.RestTemplate;

import java.util.Optional;

@RestController
public class FrontendController {

    private final RestTemplate checkOutRestTemplate = new RestTemplate();

    @GetMapping("/shop")
    public String index(@RequestParam("customer") Optional<String> customerId) throws InterruptedException {
        HttpHeaders headers = new HttpHeaders();
        headers.add("X-Customer-ID", customerId.orElse("anonymous"));
        return checkOutRestTemplate.exchange("http://localhost:8082/checkout",
                HttpMethod.GET,
                new HttpEntity<>(headers), String.class).getBody();
    }
}
