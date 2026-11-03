package com.angi.day.place.application;

import com.angi.day.place.domain.Place;
import com.angi.day.place.infrastructure.PlaceRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class SeedData implements CommandLineRunner {

    private final PlaceRepository repo;

    public SeedData(PlaceRepository repo) {
        this.repo = repo;
    }

    @Override
    public void run(String... args) {
        if (repo.count() > 0) return;

        repo.saveAll(List.of(
            place("plc_01J8A00000000000000001", "Bun bo O Xuan", "12 Le Loi, Q.1", 10.7761, 106.7039,
                2, 35000L, 55000L, 42000L, 4.41, 182, true, 47, false, "Mon nuoc|Bun bo", "top_rated",
                dishJson("dsh_01", "Bun bo Hue", 0.93, 45000), "Mon nuoc|Bun|Bun bo"),
            place("plc_01J8A00000000000000002", "Com tam Ba Ghien", "84 Dang Van Ngu, Q.Phu Nhuan", 10.7989, 106.6669,
                2, 40000L, 70000L, 55000L, 4.55, 540, true, 95, false, "Com tam|Quan com", "popular",
                dishJson("dsh_02", "Com tam suon", 0.88, 55000), "Com tam|Com tam"),
            place("plc_01J8A00000000000000003", "Pho Hoa", "260C Pasteur, Q.3", 10.7865, 106.6956,
                2, 50000L, 90000L, 65000L, 4.32, 312, true, 30, true, "Mon nuoc|Pho", "top_rated",
                dishJson("dsh_03", "Pho bo tai", 0.9, 65000), "Mon nuoc|Pho"),
            place("plc_01J8A00000000000000004", "Banh mi Huynh Hoa", "26 Le Thi Rieng, Q.1", 10.7720, 106.6990,
                1, 20000L, 40000L, 28000L, 4.6, 1012, true, 120, false, "Banh mi|Fast food", "popular",
                dishJson("dsh_04", "Banh mi thit nuong", 0.85, 28000), "Banh mi|Fast food"),
            place("plc_01J8A00000000000000005", "Nha hang chay Huong Duong", "123 Vo Van Tan, Q.3", 10.7840, 106.6900,
                3, 60000L, 150000L, 95000L, 4.2, 88, false, 0, false, "Chay|Nha hang", "",
                dishJson("dsh_05", "Com chay thap cam", 0.8, 95000), "Chay|Nha hang"),
            place("plc_01J8A00000000000000006", "Hu tieu Nam Vang Tam", "50 Nguyen Trai, Q.1", 10.7705, 106.6945,
                2, 45000L, 80000L, 60000L, 4.38, 247, true, 15, true, "Mon nuoc|Hu tieu", "",
                dishJson("dsh_06", "Hu tieu Nam Vang", 0.87, 60000), "Mon nuoc|Hu tieu"),
            place("plc_01J8A00000000000000007", "Banh xeo 46A", "46A Dinh Cong Trang, Q.1", 10.7700, 106.7010,
                2, 40000L, 90000L, 60000L, 4.28, 430, true, 70, false, "Banh xeo|Quan an", "top_rated",
                dishJson("dsh_01", "Bun bo Hue", 0.6, 60000), "Banh xeo|Quan an"),
            place("plc_01J8A00000000000000008", "Quan nhau Ngon", "9 Nguyen Thi Minh Khai, Q.1", 10.7780, 106.6980,
                3, 80000L, 200000L, 130000L, 3.9, 56, false, 0, false, "Nhau|Quan an", "",
                "[]", "Nhau|Quan an")
        ));
    }

    private Place place(String id, String name, String address, double lat, double lng,
                        int priceLevel, long min, long max, long avg, double rating, int reviews,
                        boolean open, int closesIn, boolean closingSoon, String cuisine, String badges,
                        String dishJson, String categoryPath) {
        Place p = new Place();
        p.setId(id);
        p.setName(name);
        p.setAddress(address);
        p.setLat(lat);
        p.setLng(lng);
        p.setPriceLevel(priceLevel);
        p.setPriceMinVnd(min);
        p.setPriceMaxVnd(max);
        p.setAvgPriceVnd(avg);
        p.setRatingRaw(rating);
        p.setReviewCount(reviews);
        p.setOpenNow(open);
        p.setClosesInMin(closesIn);
        p.setClosingSoon(closingSoon);
        p.setTz("Asia/Ho_Chi_Minh");
        p.setSourceProvider("osm+community");
        p.setSourceVerifiedAt("2026-08-14T00:00:00Z");
        p.setDataConfidence(0.81);
        p.setReportCount30d(0);
        p.setStaleVerified(false);
        p.setSuspectFake(false);
        p.setActive(true);
        p.setCuisineTags(cuisine);
        p.setBadges(badges);
        p.setDishHighlightsJson(dishJson);
        p.setCategoryPath(categoryPath);
        return p;
    }

    private String dishJson(String dishId, String name, double confidence, long priceVnd) {
        char q = (char) 34;
        return "[" + q + "dishId" + q + ":" + q + dishId + q + ","
            + q + "name" + q + ":" + q + name + q + ","
            + q + "confidence" + q + ":" + confidence + ","
            + q + "priceVnd" + q + ":" + priceVnd + "}]";
    }
}
