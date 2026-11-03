package com.angi.day.roulette.infrastructure;

import com.angi.day.roulette.domain.Spin;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

public interface SpinRepository extends JpaRepository<Spin, String> {
    Page<Spin> findByUserIdOrderByCreatedAtDesc(String userId, Pageable pageable);
}
