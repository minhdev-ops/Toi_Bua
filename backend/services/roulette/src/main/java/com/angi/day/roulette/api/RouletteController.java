package com.angi.day.roulette.api;

import com.angi.day.common.error.ApiException;
import com.angi.day.common.error.ApiErrorCode;
import com.angi.day.common.page.CursorPage;
import com.angi.day.roulette.application.RouletteService;
import com.angi.day.roulette.application.RouletteService.BundleResponse;
import com.angi.day.roulette.application.RouletteService.ExclusionSet;
import com.angi.day.roulette.application.RouletteService.SpinRequest;
import com.angi.day.roulette.application.RouletteService.SpinResult;
import com.angi.day.roulette.application.RouletteService.SpinView;
import com.angi.day.roulette.application.RouletteService.TaxonomyResponse;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/v1")
public class RouletteController {
    private final RouletteService svc;
    public RouletteController(RouletteService svc) { this.svc = svc; }

    @GetMapping("/dishes/taxonomy")
    public TaxonomyResponse taxonomy() { return svc.taxonomy(); }

    @GetMapping("/dishes/bundle")
    public BundleResponse bundle(@RequestParam(required = false) String sinceVersion) { return svc.bundle(sinceVersion); }

    @PostMapping("/spins")
    public SpinResult spin(@RequestHeader(value = "X-User-Id", required = false) String userId, @RequestBody SpinRequest req) {
        if (userId == null) throw new ApiException(ApiErrorCode.UNAUTHENTICATED, "missing user");
        return svc.spin(userId, req);
    }

    @GetMapping("/spins")
    public CursorPage<SpinView> list(@RequestHeader("X-User-Id") String userId,
                                     @RequestParam(required = false) String cursor,
                                     @RequestParam(defaultValue = "20") int limit) {
        return svc.list(userId, cursor, limit);
    }

    @GetMapping("/spins/{id}")
    public SpinView get(@PathVariable String id) { return svc.get(id); }

    @PostMapping("/spins/{id}/verify")
    public SpinView verify(@PathVariable String id, @RequestBody VerifyRequest v) { return svc.verify(id, v.sha256()); }

    @GetMapping("/exclusions")
    public List<String> exclusions(@RequestHeader("X-User-Id") String userId) { return svc.exclusions(userId); }

    @PutMapping("/exclusions")
    public void setExclusions(@RequestHeader("X-User-Id") String userId, @RequestBody ExclusionRequest req) {
        svc.setExclusions(userId, req.dishIds());
    }

    public record VerifyRequest(String sha256) {}
    public record ExclusionRequest(List<String> dishIds) {}
}
