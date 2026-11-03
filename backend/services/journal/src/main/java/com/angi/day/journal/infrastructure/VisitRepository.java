package com.angi.day.journal.infrastructure;

import com.angi.day.journal.domain.Visit;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface VisitRepository extends JpaRepository<Visit, String> {
    Optional<Visit> findByIdempotencyKey(String key);
}
