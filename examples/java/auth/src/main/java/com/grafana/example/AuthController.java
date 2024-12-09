package com.grafana.example;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;
import java.util.Optional;
import java.util.UUID;

@RestController
public class AuthController {

    @GetMapping("/auth")
    public ResponseEntity<Object> index(@RequestHeader("X-Customer-ID") Optional<String> customerId) throws InterruptedException {

        Thread.sleep(100);

        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(Map.of(
                        // random positive id between 1-100,000
                        "id", UUID.randomUUID().toString()
                ));
    }
}
