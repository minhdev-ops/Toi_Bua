package com.angi.day.place.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.time.Instant;

@Entity
@Table(name = "place_report")
public class Report {

    @Id
    @Column(name = "id", length = 40)
    private String id;

    @Column(name = "place_id", nullable = false, length = 40)
    private String placeId;

    @Column(name = "kind", nullable = false, length = 32)
    private String kind;

    @Column(name = "detail", length = 500)
    private String detail;

    @Column(name = "suggested_value", length = 1024)
    private String suggestedValueJson;

    @Column(name = "observation_geo", length = 64)
    private String observationGeo;

    @Column(name = "observation_at")
    private Instant observationAt;

    @Column(name = "upload_ids", length = 512)
    private String uploadIdsJson;

    @Column(name = "user_id", length = 64)
    private String userId;

    @Column(name = "device_id", length = 128)
    private String deviceId;

    @Column(name = "status", length = 16)
    private String status = "open";

    @Column(name = "dedup_key", length = 200)
    private String dedupKey;

    @Column(name = "created_at")
    private Instant createdAt = Instant.now();

    public Report() {}

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getPlaceId() { return placeId; }
    public void setPlaceId(String v) { this.placeId = v; }
    public String getKind() { return kind; }
    public void setKind(String v) { this.kind = v; }
    public String getDetail() { return detail; }
    public void setDetail(String v) { this.detail = v; }
    public String getSuggestedValueJson() { return suggestedValueJson; }
    public void setSuggestedValueJson(String v) { this.suggestedValueJson = v; }
    public String getObservationGeo() { return observationGeo; }
    public void setObservationGeo(String v) { this.observationGeo = v; }
    public Instant getObservationAt() { return observationAt; }
    public void setObservationAt(Instant v) { this.observationAt = v; }
    public String getUploadIdsJson() { return uploadIdsJson; }
    public void setUploadIdsJson(String v) { this.uploadIdsJson = v; }
    public String getUserId() { return userId; }
    public void setUserId(String v) { this.userId = v; }
    public String getDeviceId() { return deviceId; }
    public void setDeviceId(String v) { this.deviceId = v; }
    public String getStatus() { return status; }
    public void setStatus(String v) { this.status = v; }
    public String getDedupKey() { return dedupKey; }
    public void setDedupKey(String v) { this.dedupKey = v; }
    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant v) { this.createdAt = v; }
}
