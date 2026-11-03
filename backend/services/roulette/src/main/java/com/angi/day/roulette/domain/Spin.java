package com.angi.day.roulette.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.Instant;

@Entity
@Table(name = "spin")
@Getter
@Setter
@NoArgsConstructor
public class Spin {
    @Id
    private String id;
    private String userId;
    private String dishId;
    private String seed;
    private String sha256;
    private Instant createdAt;
}
