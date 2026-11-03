package com.angi.day.place.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity
@Table(name = "user_location")
public class UserLocation {

    @Id
    @Column(name = "id", length = 40)
    private String id;

    @Column(name = "user_id", length = 64)
    private String userId;

    @Column(name = "label", length = 64)
    private String label;

    @Column(name = "lat")
    private Double lat;

    @Column(name = "lng")
    private Double lng;

    @Column(name = "address", length = 256)
    private String address;

    public UserLocation() {}

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getUserId() { return userId; }
    public void setUserId(String v) { this.userId = v; }
    public String getLabel() { return label; }
    public void setLabel(String v) { this.label = v; }
    public Double getLat() { return lat; }
    public void setLat(Double v) { this.lat = v; }
    public Double getLng() { return lng; }
    public void setLng(Double v) { this.lng = v; }
    public String getAddress() { return address; }
    public void setAddress(String v) { this.address = v; }
}
