package com.grafana.example;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.Optional;
import java.util.concurrent.ThreadLocalRandom;

@RestController
public class RollController {
    private static final Logger logger = LoggerFactory.getLogger(RollController.class);

    @GetMapping("/rolldice")
    public String index(@RequestParam("player") Optional<String> player) {
        if (ThreadLocalRandom.current().nextInt(10) < 3) {
            throw new RuntimeException("simulating an error");
        }

        int result = this.getRandomNumber(1, 6);
        if (player.isPresent()) {
            logger.info("{} is rolling the dice: {}", player.get(), result);
        } else {
            logger.info("Anonymous player is rolling the dice: {}", result);
        }
        return Integer.toString(result);
    }

    public int getRandomNumber(int min, int max) {
        return ThreadLocalRandom.current().nextInt(min, max + 1);
    }
}
