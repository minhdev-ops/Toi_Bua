package com.angi.day.roulette;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.ComponentScan;

@ComponentScan({"com.angi.day.common", "com.angi.day.roulette"})
@SpringBootApplication
public class RouletteApplication {
    public static void main(String[] args) {
        SpringApplication.run(RouletteApplication.class, args);
    }
}
