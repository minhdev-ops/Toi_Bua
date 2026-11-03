package com.angi.day.place.api;

import com.angi.day.common.headers.Headers;
import com.angi.day.place.api.dto.PlaceDtos.NearbyResponse;
import com.angi.day.place.api.dto.PlaceDtos.UrgentResponse;
import com.angi.day.place.api.dto.PlaceDtos.PlaceDetailResponse;
import com.angi.day.place.api.dto.PlaceDtos.ReportResponse;
import com.angi.day.place.api.dto.PlaceDtos.MatchesResponse;
import com.angi.day.place.api.dto.PlaceRequests.GeoResponse;
import com.angi.day.place.api.dto.PlaceRequests.NearbyQuery;
import com.angi.day.place.api.dto.PlaceRequests.MatchesRequest;
import com.angi.day.place.api.dto.PlaceRequests.ReportRequest;
import com.angi.day.place.api.dto.PlaceRequests.GeocodeRequest;
import com.angi.day.place.api.dto.PlaceRequests.UserLocationRequest;
import com.angi.day.place.application.PlaceService;
import com.angi.day.place.domain.UserLocation;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/v1")
public class PlaceController {

    private final PlaceService service;

    public PlaceController(PlaceService service) {
        this.service = service;
    }

    @GetMapping("/places/nearby")
    public ResponseEntity<NearbyResponse> nearby(
        @RequestParam(required = false) String geo,
        @RequestParam(name = "user_location_id", required = false) String userLocationId,
        @RequestParam(required = false) String address,
        @RequestParam(name = "radius_m", required = false) Integer radiusM,
        @RequestParam(name = "dish_id", required = false) java.util.List<String> dishIds,
        @RequestParam(name = "open_now", required = false) Boolean openNow,
        @RequestParam(name = "budget_vnd", required = false) Long budgetVnd,
        @RequestParam(name = "travel_mode", required = false) String travelMode,
        @RequestParam(required = false) String sort,
        @RequestParam(required = false) String view,
        @RequestParam(required = false) Integer limit,
        @RequestParam(required = false) String cursor,
        HttpServletRequest req) {
        NearbyQuery q = new NearbyQuery(geo, userLocationId, address, radiusM, dishIds,
            openNow, budgetVnd, travelMode, sort, view, limit, cursor);
        NearbyResponse r = service.nearby(q, userId(req));
        return ResponseEntity.ok().header(Headers.X_DATA_QUALITY, "fresh").body(r);
    }

    @PostMapping("/matches")
    public ResponseEntity<MatchesResponse> matches(@RequestBody MatchesRequest body, HttpServletRequest req) {
        MatchesResponse r = service.matches(body, userId(req));
        return ResponseEntity.ok().header(Headers.X_DATA_QUALITY, "fresh").body(r);
    }

    @GetMapping("/places/urgent")
    public ResponseEntity<UrgentResponse> urgent(
        @RequestParam(required = false) String geo,
        @RequestParam(required = false) String user_location_id,
        @RequestParam(required = false) String address,
        @RequestParam(required = false) Integer radius_m,
        @RequestParam(required = false) String travel_mode,
        @RequestParam(required = false) Long budget_vnd,
        @RequestParam(required = false) String dish_id,
        HttpServletRequest req) {
        UrgentResponse r = service.urgent(geo, user_location_id, address, radius_m, travel_mode, budget_vnd, dish_id, userId(req));
        return ResponseEntity.ok().header(Headers.X_DATA_QUALITY, "fresh").body(r);
    }

    @GetMapping("/places/{id}")
    public ResponseEntity<PlaceDetailResponse> detail(@PathVariable String id,
                                                      @RequestParam(required = false) String sections,
                                                      HttpServletRequest req) {
        return ResponseEntity.ok(service.detail(id, sections));
    }

    @PostMapping("/places/{id}/reports")
    public ResponseEntity<ReportResponse> report(@PathVariable String id,
                                                @RequestBody ReportRequest body,
                                                HttpServletRequest req) {
        ReportResponse r = service.report(id, body, req.getHeader(Headers.X_IDEMPOTENCY_KEY), userId(req), deviceId(req));
        return ResponseEntity.status(201).body(r);
    }

    @GetMapping("/geocode")
    public ResponseEntity<GeoResponse> geocode(@RequestParam String address) {
        return ResponseEntity.ok(service.geocode(address));
    }

    @GetMapping("/user-locations")
    public ResponseEntity<java.util.List<UserLocation>> listUserLocations(HttpServletRequest req) {
        return ResponseEntity.ok(service.listUserLocations(userId(req)));
    }

    @PostMapping("/user-locations")
    public ResponseEntity<UserLocation> createUserLocation(@RequestBody UserLocationRequest body, HttpServletRequest req) {
        return ResponseEntity.status(201).body(service.createUserLocation(body, userId(req)));
    }

    @DeleteMapping("/user-locations/{id}")
    public ResponseEntity<Void> deleteUserLocation(@PathVariable String id, HttpServletRequest req) {
        service.deleteUserLocation(id, userId(req));
        return ResponseEntity.noContent().build();
    }

    private String userId(HttpServletRequest req) { return req.getHeader(Headers.X_USER_ID); }
    private String deviceId(HttpServletRequest req) { return req.getHeader(Headers.X_DEVICE_ID); }
}
