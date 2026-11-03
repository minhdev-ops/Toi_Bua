# GRAPH_REPORT — Domain Knowledge Graph (ĂnGìĐây)

Sinh bởi skill graphify từ docs/01, docs/02, docs/03 và app_flutter. (Bản tóm tắt; chạy "graphify ." để có HTML tương tác + JSON GraphRAG.)

## God nodes
- User (usr_) — thực thể trung tâm; guest hoặc authenticated.
- Dish (dsh_) — món ăn; có taxonomy, tags, category.
- Place (plc_) — quán; geo, giờ mở, giá, reviews.
- Spin (spn_) — lượt quay; seed+sha256, dish kết quả.

## Entities (nodes)
User, Guest, Device, Dish, Category, Tag, Place, PlaceDish (pdh_), UserLocation (ulc_), Spin (spn_), Match, ScoreBreakdown, Room (rom_, P2), Vote, Veto, Visit (vst_), Report (rpt_), Review (rev_), Taxonomy, Bundle (dish_bundle), Config/FeatureFlag, RefreshToken, GeoPoint, Provider (OSM/Google/Community).

## Relationships (edges)
- User — HAS -> Device; User — GUEST_OF -> Guest session
- User — PREFERENCES -> Diet/Exclusions; User — ONBOARDED via /me/onboarding
- Spin — PICKS -> Dish (weighted, seed)
- Spin — SCOPED_BY -> Filters + Geo + Diet
- Dish — BELONGS_TO -> Category; Dish — TAGGED -> Tag
- Place — SERVES -> PlaceDish; Place — LOCATED_AT -> GeoPoint; Place — HAS -> OpenHours, Price
- Match — FOR -> (Dish, Place); Match — SCORED_BY -> Ranking -> ScoreBreakdown
- Ranking — USES -> (BayesianQuality, DistanceDecay, PriceFit, OpenNow, Personalization, Penalty)
- User — VISITS -> Place (journal); Visit — SOURCED_FROM -> nav_open
- User — REPORTS -> Place (Report)
- Room (P2) — HAS -> Members, Candidates, Votes, Vetoes; Room — FINALIZES -> Winner via WeightedTieSpin
- Place — SOURCED_FROM -> Provider (OSM/Google/Community) via PlaceProviderPort
- Config — CONTROLS -> Ranking weights, lambda, tau, m

## Communities
C1 Identity: User, Guest, Device, RefreshToken, Config.
C2 Discovery: Dish, Category, Tag, Taxonomy, Bundle, Place, PlaceDish, GeoPoint.
C3 Decision: Spin, Filters, Match, Ranking, ScoreBreakdown, Visit.
C4 Social (P2): Room, Vote, Veto, Review, Report, Community.
C5 Providers: OSM, Google, Community adapter, MapDistance, Storage.

## Notes
- App chỉ render score_breakdown, không tính (R08).
- ID prefix quy ước docs/01 muc 1.
- Chỉ đường là deep link app -> Maps, không qua backend (FR-NAV-01).
