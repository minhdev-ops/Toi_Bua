package com.angi.day.place.infrastructure;

import com.angi.day.place.domain.Report;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface ReportRepository extends JpaRepository<Report, String> {

    @Query("select r from Report r where r.dedupKey = :key and r.status <> 'resolved' order by r.createdAt desc")
    Optional<Report> findActiveByDedupKey(@Param("key") String key);
}
