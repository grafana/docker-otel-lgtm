package com.grafana.example;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Random;

@SpringBootApplication
@RestController
public class HelloWorldApp {

    private final Logger logger = LoggerFactory.getLogger(HelloWorldApp.class);
    private final Random random = new Random(0);

    public static void main(String[] args) {
        SpringApplication.run(HelloWorldApp.class, args);
    }

    @GetMapping("/")
    public String sayHello() throws InterruptedException {
        logger.info("The hello world service was called.");
        Thread.sleep((long) (Math.abs((random.nextGaussian() + 1.0) * 200.0)));
        if (random.nextInt(10) < 3) {
            throw new RuntimeException("simulating an error");
        }
        return "Hello, World!\n";
    }
}
