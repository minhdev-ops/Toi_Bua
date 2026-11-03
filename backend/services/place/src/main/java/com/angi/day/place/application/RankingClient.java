package com.angi.day.place.application;

import com.angi.day.common.error.ApiException;
import com.angi.day.common.error.ApiErrorCode;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;

import java.util.List;

@Component
public class RankingClient {

    private final RestTemplate rest;
    private final String baseUrl;

    public RankingClient(RestTemplate rest,
                         @Value("${ranking.url:http://ranking:8084}") String baseUrl) {
        this.rest = rest;
        this.baseUrl = baseUrl;
    }

    public ScoreResult score(CandidateScore c) {
        try {
            return rest.postForObject(baseUrl + "/v1/rank/score", c, ScoreResult.class);
        } catch (RestClientException e) {
            throw new ApiException(ApiErrorCode.PROVIDER_UNAVAILABLE, "Ranking service unavailable: " + e.getMessage());
        }
    }

    public record CandidateScore(
        String placeId, String dishId,
        double reviewAvg, int reviewCount,
        double distanceM, String travelMode,
        long avgPriceVnd, Long budgetVnd,
        boolean open, boolean staleVerified, double reportRatio, boolean suspectFake,
        double personalU) {}

    public record ScoreComponent(String key, String messageKey, double value, double weight) {}
    public record ScoreResult(double scoreTotal, List<ScoreComponent> components, double penalty) {}
}
