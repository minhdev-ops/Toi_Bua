package com.angi.day.place.infrastructure;

import com.angi.day.place.domain.UserLocation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface UserLocationRepository extends JpaRepository<UserLocation, String> {
    List<UserLocation> findByUserId(String userId);
}
