package com.angi.day.place.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity
@Table(name = "place")
public class Place {

    @Id
    @Column(name = "id", length = 40)
    private String id;

    @Column(name = "name", nullable = false)
    private String name;

    @Column(name = "address")
    private String address;

    @Column(name = "lat")
    private Double lat;

    @Column(name = "lng")
    private Double lng;

    @Column(name = "price_level")
    private Integer priceLevel;

    @Column(name = "price_min_vnd")
    private Long priceMinVnd;

    @Column(name = "price_max_vnd")
    private Long priceMaxVnd;

    @Column(name = "avg_price_vnd")
    private Long avgPriceVnd;

    @Column(name = "rating_raw")
    private Double ratingRaw;

    @Column(name = "review_count")
    private Integer reviewCount;

    @Column(name = "open_now")
    private Boolean openNow;

    @Column(name = "closes_in_min")
    private Integer closesInMin;

    @Column(name = "closing_soon")
    private Boolean closingSoon;

    @Column(name = "tz")
    private String tz;

    @Column(name = "source_provider")
    private String sourceProvider;

    @Column(name = "source_verified_at")
    private String sourceVerifiedAt;

    @Column(name = "data_confidence")
    private Double dataConfidence;

    @Column(name = "report_count_30d")
    private Integer reportCount30d;

    @Column(name = "stale_verified")
    private Boolean staleVerified;

    @Column(name = "suspect_fake")
    private Boolean suspectFake;

    @Column(name = "active")
    private Boolean active;

    @Column(name = "cuisine_tags", length = 512)
    private String cuisineTags;

    @Column(name = "badges", length = 512)
    private String badges;

    @Column(name = "dish_highlights", length = 2048)
    private String dishHighlightsJson;

    @Column(name = "category_path", length = 256)
    private String categoryPath;

    public Place() {}

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public String getAddress() { return address; }
    public void setAddress(String address) { this.address = address; }
    public Double getLat() { return lat; }
    public void setLat(Double lat) { this.lat = lat; }
    public Double getLng() { return lng; }
    public void setLng(Double lng) { this.lng = lng; }
    public Integer getPriceLevel() { return priceLevel; }
    public void setPriceLevel(Integer priceLevel) { this.priceLevel = priceLevel; }
    public Long getPriceMinVnd() { return priceMinVnd; }
    public void setPriceMinVnd(Long v) { this.priceMinVnd = v; }
    public Long getPriceMaxVnd() { return priceMaxVnd; }
    public void setPriceMaxVnd(Long v) { this.priceMaxVnd = v; }
    public Long getAvgPriceVnd() { return avgPriceVnd; }
    public void setAvgPriceVnd(Long v) { this.avgPriceVnd = v; }
    public Double getRatingRaw() { return ratingRaw; }
    public void setRatingRaw(Double v) { this.ratingRaw = v; }
    public Integer getReviewCount() { return reviewCount; }
    public void setReviewCount(Integer v) { this.reviewCount = v; }
    public Boolean getOpenNow() { return openNow; }
    public void setOpenNow(Boolean v) { this.openNow = v; }
    public Integer getClosesInMin() { return closesInMin; }
    public void setClosesInMin(Integer v) { this.closesInMin = v; }
    public Boolean getClosingSoon() { return closingSoon; }
    public void setClosingSoon(Boolean v) { this.closingSoon = v; }
    public String getTz() { return tz; }
    public void setTz(String v) { this.tz = v; }
    public String getSourceProvider() { return sourceProvider; }
    public void setSourceProvider(String v) { this.sourceProvider = v; }
    public String getSourceVerifiedAt() { return sourceVerifiedAt; }
    public void setSourceVerifiedAt(String v) { this.sourceVerifiedAt = v; }
    public Double getDataConfidence() { return dataConfidence; }
    public void setDataConfidence(Double v) { this.dataConfidence = v; }
    public Integer getReportCount30d() { return reportCount30d; }
    public void setReportCount30d(Integer v) { this.reportCount30d = v; }
    public Boolean getStaleVerified() { return staleVerified; }
    public void setStaleVerified(Boolean v) { this.staleVerified = v; }
    public Boolean getSuspectFake() { return suspectFake; }
    public void setSuspectFake(Boolean v) { this.suspectFake = v; }
    public Boolean getActive() { return active; }
    public void setActive(Boolean v) { this.active = v; }
    public String getCuisineTags() { return cuisineTags; }
    public void setCuisineTags(String v) { this.cuisineTags = v; }
    public String getBadges() { return badges; }
    public void setBadges(String v) { this.badges = v; }
    public String getDishHighlightsJson() { return dishHighlightsJson; }
    public void setDishHighlightsJson(String v) { this.dishHighlightsJson = v; }
    public String getCategoryPath() { return categoryPath; }
    public void setCategoryPath(String v) { this.categoryPath = v; }
}
