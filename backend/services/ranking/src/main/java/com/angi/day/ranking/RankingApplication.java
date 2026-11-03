package com.angi.day.ranking;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.ComponentScan;

@ComponentScan({"com.angi.day.common", "com.angi.day.ranking"})
@SpringBootApplication
public class RankingApplication {
    public static void main(String[] args) {
        SpringApplication.run(RankingApplication.class, args);
    }
}
