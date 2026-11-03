package com.angi.day.identity.infrastructure;

import com.angi.day.identity.domain.AppUser;
import org.springframework.data.jpa.repository.JpaRepository;

public interface AppUserRepository extends JpaRepository<AppUser, String> {
}
