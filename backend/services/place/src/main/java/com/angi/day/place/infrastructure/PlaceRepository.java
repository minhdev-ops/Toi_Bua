package com.angi.day.place.infrastructure;

import com.angi.day.place.domain.Place;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface PlaceRepository extends JpaRepository<Place, String> {

    List<Place> findByActiveTrue();

    List<Place> findByActiveTrueAndIdIn(List<String> ids);

    @Query("select p from Place p where p.active = true and lower(p.name) like lower(concat('%', :q, '%'))")
    List<Place> searchByName(@Param("q") String q);
}
