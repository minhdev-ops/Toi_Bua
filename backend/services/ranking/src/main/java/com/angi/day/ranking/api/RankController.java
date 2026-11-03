package com.angi.day.ranking.api;

import com.angi.day.ranking.application.RankingService;
import com.angi.day.ranking.application.RankingService.CandidateScore;
import com.angi.day.ranking.application.RankingService.ScoreResult;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/v1/rank")
public class RankController {
    private final RankingService rankingService;

    public RankController(RankingService rankingService) {
        this.rankingService = rankingService;
    }

    @PostMapping("/score")
    public ScoreResult score(@RequestBody CandidateScore c) {
        return rankingService.score(c);
    }
}
