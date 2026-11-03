package com.angi.day.ranking.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
public class RankingConfig {
    @Value("${ranking.weights.Q:0.35}") public double wQ;
    @Value("${ranking.weights.D:0.25}") public double wD;
    @Value("${ranking.weights.P:0.15}") public double wP;
    @Value("${ranking.weights.O:0.15}") public double wO;
    @Value("${ranking.weights.U:0.10}") public double wU;
    @Value("${ranking.lambda.walk:600}") public double lambdaWalk;
    @Value("${ranking.lambda.bike:2500}") public double lambdaBike;
    @Value("${ranking.lambda.car:6000}") public double lambdaCar;
    @Value("${ranking.bayesian.m:20}") public double bayesM;
    @Value("${ranking.penalty.stale:8}") public double penStale;
    @Value("${ranking.penalty.report:10}") public double penReport;
    @Value("${ranking.penalty.fake:15}") public double penFake;
}
