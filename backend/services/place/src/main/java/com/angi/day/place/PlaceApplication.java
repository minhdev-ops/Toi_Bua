package com.angi.day.place;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.ComponentScan;

@SpringBootApplication
@ComponentScan({ "com.angi.day.common", "com.angi.day.place" })
public class PlaceApplication {
    public static void main(String[] args) {
        SpringApplication.run(PlaceApplication.class, args);
    }
}
