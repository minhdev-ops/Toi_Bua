package com.angi.day.identity.api;

import com.angi.day.identity.application.ProfileService;
import com.angi.day.identity.domain.AppUser;
import com.angi.day.identity.security.JwtKeyProvider;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/v1")
public class MeController {
    private final ProfileService profile;
    private final JwtKeyProvider keys;

    public MeController(ProfileService profile, JwtKeyProvider keys) {
        this.profile = profile;
        this.keys = keys;
    }

    @GetMapping("/me")
    public AppUser me(HttpServletRequest req) {
        return profile.me(Authz.userId(req, keys));
    }

    @PutMapping("/me")
    public AppUser update(HttpServletRequest req,
                          @RequestParam(required = false) String locale,
                          @RequestParam(required = false) Boolean onboarded,
                          @RequestParam(required = false) Long budgetVnd) {
        return profile.update(Authz.userId(req, keys), locale, onboarded, budgetVnd);
    }

    @PutMapping("/me/onboarding")
    public AppUser onboarding(HttpServletRequest req,
                             @RequestParam(required = false) String locale,
                             @RequestParam(required = false) Integer step) {
        return profile.onboard(Authz.userId(req, keys), step, locale);
    }

    @PutMapping("/me/preferences")
    public AppUser preferences(HttpServletRequest req,
                             @RequestParam(required = false) String locale,
                             @RequestParam(required = false) Long budgetVnd) {
        return profile.setPreferences(Authz.userId(req, keys), locale, budgetVnd);
    }

    @PutMapping("/me/diet")
    public AppUser diet(HttpServletRequest req, @RequestParam String dietExclusions) {
        return profile.setDiet(Authz.userId(req, keys), dietExclusions);
    }

    @PostMapping("/me/consents")
    public AppUser consents(HttpServletRequest req, @RequestParam String consent) {
        return profile.addConsent(Authz.userId(req, keys), consent);
    }
}
