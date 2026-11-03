package com.angi.day.ranking.application;

import com.angi.day.ranking.config.RankingConfig;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

@Service
public class RankingService {
    private final RankingConfig cfg;

    public RankingService(RankingConfig cfg) {
        this.cfg = cfg;
    }

    public record CandidateScore(
        String placeId, String dishId,
        double reviewAvg, int reviewCount,
        double distanceM, String travelMode,
        long avgPriceVnd, Long budgetVnd,
        boolean open, boolean staleVerified, double reportRatio, boolean suspectFake,
        double personalU) {}

    public record ScoreComponent(String key, String messageKey, double value, double weight) {}
    public record ScoreResult(double scoreTotal, List<ScoreComponent> components, double penalty) {}

    public ScoreResult score(CandidateScore c) {
        double rmax = 5.0;
        double q = ((c.reviewCount() * c.reviewAvg() + cfg.bayesM * 4.0) / (c.reviewCount() + cfg.bayesM)) / rmax;
        double lambda = switch (c.travelMode()) {
            case "bike" -> cfg.lambdaBike;
            case "car" -> cfg.lambdaCar;
            default -> cfg.lambdaWalk;
        };
        double d = Math.exp(-c.distanceM() / lambda);
        double p = (c.budgetVnd() == null || c.avgPriceVnd() <= c.budgetVnd())
            ? 1.0 : Math.max(0, 1 - (double) (c.avgPriceVnd() - c.budgetVnd()) / c.budgetVnd());
        double o = c.open() ? 1.0 : 0.0;
        double u = c.personalU();
        double penalty = (c.staleVerified() ? cfg.penStale : 0)
            + cfg.penReport * Math.min(1, c.reportRatio())
            + (c.suspectFake() ? cfg.penFake : 0);
        double total = 100 * (cfg.wQ * q + cfg.wD * d + cfg.wP * p + cfg.wO * o + cfg.wU * u) - penalty;
        total = Math.max(0, Math.min(100, total));
        List<ScoreComponent> comps = new ArrayList<>();
        comps.add(new ScoreComponent("Q", "err.score.q", q, cfg.wQ));
        comps.add(new ScoreComponent("D", "err.score.d", d, cfg.wD));
        comps.add(new ScoreComponent("P", "err.score.p", p, cfg.wP));
        comps.add(new ScoreComponent("O", "err.score.o", o, cfg.wO));
        comps.add(new ScoreComponent("U", "err.score.u", u, cfg.wU));
        return new ScoreResult(round2(total), comps, round2(penalty));
    }

    private double round2(double x) {
        return Math.round(x * 100.0) / 100.0;
    }
}
