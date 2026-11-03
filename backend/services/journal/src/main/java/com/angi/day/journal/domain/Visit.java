package com.angi.day.journal.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.time.Instant;

@Entity
@Table(name = "visit")
public class Visit {

    @Id
    @Column(name = "id", length = 40)
    private String id;

    @Column(name = "place_id", length = 40)
    private String placeId;

    @Column(name = "dish_id", length = 40)
    private String dishId;

    @Column(name = "spin_id", length = 40)
    private String spinId;

    @Column(name = "status", length = 16)
    private String status;

    @Column(name = "source", length = 16)
    private String source;

    @Column(name = "spend_vnd")
    private Long spendVnd;

    @Column(name = "note", length = 500)
    private String note;

    @Column(name = "private_rating")
    private Integer privateRating;

    @Column(name = "occurred_at")
    private Instant occurredAt;

    @Column(name = "device_updated_at")
    private Instant deviceUpdatedAt;

    @Column(name = "device_version", length = 32)
    private String deviceVersion;

    @Column(name = "user_id", length = 64)
    private String userId;

    @Column(name = "idempotency_key", length = 128, unique = true)
    private String idempotencyKey;

    @Column(name = "created_at")
    private Instant createdAt = Instant.now();

    public Visit() {}

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getPlaceId() { return placeId; }
    public void setPlaceId(String v) { this.placeId = v; }
    public String getDishId() { return dishId; }
    public void setDishId(String v) { this.dishId = v; }
    public String getSpinId() { return spinId; }
    public void setSpinId(String v) { this.spinId = v; }
    public String getStatus() { return status; }
    public void setStatus(String v) { this.status = v; }
    public String getSource() { return source; }
    public void setSource(String v) { this.source = v; }
    public Long getSpendVnd() { return spendVnd; }
    public void setSpendVnd(Long v) { this.spendVnd = v; }
    public String getNote() { return note; }
    public void setNote(String v) { this.note = v; }
    public Integer getPrivateRating() { return privateRating; }
    public void setPrivateRating(Integer v) { this.privateRating = v; }
    public Instant getOccurredAt() { return occurredAt; }
    public void setOccurredAt(Instant v) { this.occurredAt = v; }
    public Instant getDeviceUpdatedAt() { return deviceUpdatedAt; }
    public void setDeviceUpdatedAt(Instant v) { this.deviceUpdatedAt = v; }
    public String getDeviceVersion() { return deviceVersion; }
    public void setDeviceVersion(String v) { this.deviceVersion = v; }
    public String getUserId() { return userId; }
    public void setUserId(String v) { this.userId = v; }
    public String getIdempotencyKey() { return idempotencyKey; }
    public void setIdempotencyKey(String v) { this.idempotencyKey = v; }
    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant v) { this.createdAt = v; }
}
