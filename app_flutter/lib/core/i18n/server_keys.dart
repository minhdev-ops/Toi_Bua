import 'app_localizations.dart';

/// Registry các `why_key` / `message_key` / `reason_key` server trả (`docs/02` §1.4).
///
/// Quy tắc cứng: app **không bao giờ** hiển thị chuỗi thô của server (TC-I18N-01, NFR-11).
/// Key ngoài bảng ⇒ trả `null` để caller **ẩn** dòng đó, không fallback về `headline`/`bullets`.
/// Tên key ARB = camelCase của key chấm (`why.q.top` → `whyQTop`), nên bảng này soi được
/// bằng contract test với `docs/02`.
abstract final class ServerKeys {
  static int _int(String? raw) => int.tryParse((raw ?? '').replaceAll('.', '')) ?? 0;

  static String? text(S s, String? key, Map<String, String> params) {
    switch (key) {
      case 'why.headline':
        return s.whyHeadline(params['rating'] ?? '', _int(params['count']), params['distance'] ?? '');
      case 'why.q.top':
        return s.whyQTop(params['rating'] ?? '', _int(params['count']));
      case 'why.q.few_reviews':
        return s.whyQFewReviews(_int(params['count']));
      case 'why.d.top':
        return s.whyDTop(params['distance'] ?? '');
      case 'why.p.in_budget':
        return s.whyPInBudget(params['avg_price'] ?? '', params['budget'] ?? '');
      case 'why.p.near_budget':
        return s.whyPNearBudget(params['avg_price'] ?? '');
      case 'why.o.open_45m':
        return s.whyOOpen45m(_int(params['minutes']));
      case 'why.o.closing_soon':
        return s.whyOClosingSoon(_int(params['minutes']));
      case 'why.u.explore':
        return s.whyUExplore;
      case 'relax.radius':
        return s.relaxRadius(params['to'] ?? '');
      case 'relax.price':
        return s.relaxPrice(params['to'] ?? '');
      case 'relax.diet':
        return s.relaxDiet;
      case 'substitute.similar_category':
        return s.substituteSimilarCategory;
      case 'substitute.same_meal_slot':
        return s.substituteSameMealSlot;
      case 'urgent.nearby_match':
        return s.urgentNearbyMatch;
      case 'urgent.none_open':
        return s.urgentNoneOpen(_int(params['radius']));
      case 'alt.closing':
        return s.altClosing(params['distance'] ?? '', params['minutes'] ?? '');
      case 'alt.farther':
        return s.altFarther(params['distance'] ?? '', params['minutes'] ?? '');
      case 'alt.open_later':
        return s.altOpenLater(params['opens_at'] ?? '', params['distance'] ?? '');
      case 'prompt.rate_after_visit':
        return s.promptRateAfterVisit;
      case 'budget.near_limit':
        return s.budgetNearLimit;
      case 'veto.tried_and_disliked':
        return s.vetoTriedAndDisliked;
      case 'grp.tie.spun':
        return s.grpTieSpun;
      case 'hours.closed_for_holiday':
        return s.noteClosedForHoliday;
      default:
        return null;
    }
  }

  /// `score_breakdown.penalty.items[].reason` — enum **không** có dấu chấm.
  static String? penaltyReason(S s, String reason, Map<String, String> params) {
    switch (reason) {
      case 'stale_verification':
        return s.penaltyStaleVerification(_int(params['days']));
      case 'low_data_confidence':
        return s.penaltyLowDataConfidence;
      case 'reported':
        return s.penaltyReported;
      default:
        return null;
    }
  }

  /// `relaxation.steps_available[].dimension` → nhãn trong chip.
  static String? dimensionLabel(S s, String dimension) {
    switch (dimension) {
      case 'radius_m':
        return s.relaxRadiusLabel;
      case 'price_level_max':
        return s.relaxPriceLabel;
      case 'diet.strict':
      case 'diet':
        return s.relaxDietLabel;
      default:
        return null;
    }
  }

  /// `items[].badges` (docs/02 §1.4) — 4 giá trị. Ngoài bảng ⇒ **ẩn** tem, không in slug.
  static String? badge(S s, String kind) {
    switch (kind) {
      case 'verified':
        return s.badgeVerified;
      case 'top_rated':
        return s.badgeTopRated;
      case 'new':
        return s.badgeNew;
      case 'cheap':
        return s.badgeCheap;
      default:
        return null;
    }
  }
}
