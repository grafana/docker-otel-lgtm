package com.grafana.example;

import java.util.Optional;
import java.util.Random;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/** A simple controller that simulates rolling a dice. */
@RestController
public class RollController {

  private static final Logger logger = LoggerFactory.getLogger(RollController.class);
  private final Random random = new Random(0);

  /** Simulates rolling a dice. */
  @GetMapping("/rolldice")
  public String index(@RequestParam("player") Optional<String> player) throws InterruptedException {
    Thread.sleep((long) (Math.abs((random.nextGaussian() + 1.0) * 200.0)));
    if (random.nextInt(10) < 3) {
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

  private int getRandomNumber(int min, int max) {
    return random.nextInt(min, max + 1);
  }
}
