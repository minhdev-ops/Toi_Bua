package com.angi.day.journal.application;

import com.angi.day.common.error.ApiException;
import com.angi.day.common.error.ApiErrorCode;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.client.HttpStatusCodeException;
import org.springframework.web.client.RestTemplate;

@Component
public class PlaceClient {

    private final RestTemplate rest;
    private final String baseUrl;

    public PlaceClient(RestTemplate rest,
                       @Value("${place.url:http://place:8083}") String baseUrl) {
        this.rest = rest;
        this.baseUrl = baseUrl;
    }

    public void assertExists(String placeId) {
        try {
            rest.getForObject(baseUrl + "/v1/places/" + placeId, String.class);
        } catch (HttpStatusCodeException e) {
            if (e.getStatusCode().value() == 404) {
                throw new ApiException(ApiErrorCode.NOT_FOUND, "place not found");
            }
            throw new ApiException(ApiErrorCode.PROVIDER_UNAVAILABLE, "place service unavailable");
        } catch (Exception e) {
            throw new ApiException(ApiErrorCode.PROVIDER_UNAVAILABLE, "place service unavailable");
        }
    }
}
