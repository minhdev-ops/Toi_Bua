package com.angi.day.identity.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.Instant;

@Entity
@Table(name = "app_user")
@Getter
@Setter
@NoArgsConstructor
public class AppUser {
    @Id
    private String id;
    @Column(name = "is_guest")
    private boolean guest;
    private String installId;
    private String platform;
    private String locale;
    private boolean onboarded;
    private String dietExclusions;
    private Long budgetVnd;
    private Instant createdAt;
    private Instant updatedAt;
}
