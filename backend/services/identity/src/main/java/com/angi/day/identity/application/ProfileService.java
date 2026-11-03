package com.angi.day.identity.application;

import com.angi.day.identity.domain.AppUser;
import com.angi.day.identity.infrastructure.AppUserRepository;
import com.angi.day.common.error.ApiErrorCode;
import com.angi.day.common.error.ApiException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;

@Service
public class ProfileService {
    private final AppUserRepository users;

    public ProfileService(AppUserRepository users) {
        this.users = users;
    }

    public AppUser me(String userId) {
        return users.findById(userId).orElseThrow(() -> new ApiException(ApiErrorCode.NOT_FOUND, "user not found"));
    }

    @Transactional
    public AppUser update(String userId, String locale, Boolean onboarded, Long budgetVnd) {
        AppUser u = me(userId);
        if (locale != null) u.setLocale(locale);
        if (onboarded != null) u.setOnboarded(onboarded);
        if (budgetVnd != null) u.setBudgetVnd(budgetVnd);
        u.setUpdatedAt(Instant.now());
        return users.save(u);
    }

    @Transactional
    public AppUser onboard(String userId, Integer step, String locale) {
        AppUser u = me(userId);
        if (locale != null) u.setLocale(locale);
        u.setOnboarded(true);
        u.setUpdatedAt(Instant.now());
        return users.save(u);
    }

    @Transactional
    public AppUser setPreferences(String userId, String locale, Long budgetVnd) {
        return update(userId, locale, null, budgetVnd);
    }

    @Transactional
    public AppUser setDiet(String userId, String dietExclusions) {
        AppUser u = me(userId);
        u.setDietExclusions(dietExclusions);
        u.setUpdatedAt(Instant.now());
        return users.save(u);
    }

    @Transactional
    public AppUser addConsent(String userId, String consent) {
        AppUser u = me(userId);
        u.setUpdatedAt(Instant.now());
        return users.save(u);
    }
}
