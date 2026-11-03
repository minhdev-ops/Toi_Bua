package com.angi.day.ranking.application;

import com.angi.day.ranking.config.RankingConfig;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;

class RankingServiceTest {

    private RankingConfig config() {
        RankingConfig c = new RankingConfig();
        c.wQ = 0.35; c.wD = 0.25; c.wP = 0.15; c.wO = 0.15; c.wU = 0.10;
        c.lambdaWalk = 600; c.lambdaBike = 2500; c.lambdaCar = 6000;
        c.bayesM = 20; c.penStale = 8; c.penReport = 10; c.penFake = 15;
        return c;
    }

    @Test
    void score_formula_matches_doc_contract() {
        RankingService svc = new RankingService(config());
        RankingService.CandidateScore c = new RankingService.CandidateScore(
            "plc_1", "dsh_1", 5.0, 100,
            0.0, "walk", 50000L, 60000L,
            true, false, 0.0, false, 0.0);

        RankingService.ScoreResult r = svc.score(c);

        assertNotNull(r);
        assertEquals(5, r.components().size());
        // Q = ((100*5 + 20*4)/(120))/5 = 0.9667 ; D=1 ; P=1 ; O=1 ; U=0
        // total = 100*(0.35*0.9667 + 0.25 + 0.15 + 0.15) = 88.83
        assertEquals(88.83, r.scoreTotal(), 0.05);
        assertEquals(0.0, r.penalty(), 0.001);
    }

    @Test
    void distance_decay_reduces_score() {
        RankingService svc = new RankingService(config());
        RankingService.CandidateScore near = new RankingService.CandidateScore(
            "plc_1", "dsh_1", 4.5, 200, 0.0, "walk", 50000L, 60000L, true, false, 0.0, false, 0.0);
        RankingService.CandidateScore far = new RankingService.CandidateScore(
            "plc_1", "dsh_1", 4.5, 200, 6000.0, "walk", 50000L, 60000L, true, false, 0.0, false, 0.0);

        double nearScore = svc.score(near).scoreTotal();
        double farScore = svc.score(far).scoreTotal();
        // D decays from 1.0 toward exp(-6000/600)=exp(-10)~0
        assertEquals(1.0, Math.exp(-0.0), 0.0001);
        org.junit.jupiter.api.Assertions.assertTrue(nearScore > farScore, "near should outscore far");
    }

    @Test
    void penalty_applied_for_fake_and_report() {
        RankingService svc = new RankingService(config());
        RankingService.CandidateScore c = new RankingService.CandidateScore(
            "plc_1", "dsh_1", 5.0, 100, 0.0, "walk", 50000L, 60000L, true, true, 1.0, true, 0.0);
        RankingService.ScoreResult r = svc.score(c);
        // penalty = 8 (stale) + 10*1 (report) + 15 (fake) = 33
        assertEquals(33.0, r.penalty(), 0.001);
    }
}
