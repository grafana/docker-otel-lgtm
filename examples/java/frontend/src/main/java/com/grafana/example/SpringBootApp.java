package com.grafana.example;

import jakarta.servlet.http.HttpServletResponse;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@SpringBootApplication
@RestController
public class SpringBootApp {

    /**
     * Redirect to {@link FrontendController}
     */
    @GetMapping("/")
    public void redirect(HttpServletResponse httpServletResponse) {
        httpServletResponse.setHeader("Location", "/rolldice");
        httpServletResponse.setStatus(302);
    }

    public static void main(String[] args) {
        SpringApplication.run(SpringBootApp.class, args);
    }

}
