// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class SEn extends S {
  SEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'WhatToEat';

  @override
  String get tabSpin => 'Spin';

  @override
  String get tabPlaces => 'Places';

  @override
  String get tabUrgent => 'Starving';

  @override
  String get tabYou => 'You';

  @override
  String get ctaSpin => 'Spin';

  @override
  String get ctaSpinLoading => 'Spinning';

  @override
  String get ctaSpinAgain => 'Spin again';

  @override
  String get ctaFilters => 'Filters';

  @override
  String get ctaApply => 'Apply';

  @override
  String get ctaNavigate => 'Directions';

  @override
  String get ctaNavOpening => 'Opening maps';

  @override
  String get ctaArrived => 'I arrived';

  @override
  String get ctaArrivedDone => 'Saved';

  @override
  String get ctaDismiss => 'Skip';

  @override
  String get ctaDismissed => 'Skipped';

  @override
  String get ctaSave => 'Save';

  @override
  String get ctaSaved => 'Saved';

  @override
  String get ctaReport => 'Report issue';

  @override
  String get ctaReportSent => 'Report sent';

  @override
  String get ctaUrgent => 'Starving';

  @override
  String get ctaRetry => 'Try again';

  @override
  String get ctaEnterAddress => 'Enter address';

  @override
  String get ctaClose => 'Close';

  @override
  String get ctaWhy => 'Why this place?';

  @override
  String get ctaSkip => 'Skip';

  @override
  String get ctaNext => 'Continue';

  @override
  String get ctaDone => 'Done';

  @override
  String get ctaUpdateLocation => 'Update';

  @override
  String resultToday(Object dish) {
    return 'Today: $dish';
  }

  @override
  String resultUrgentPick(Object place) {
    return 'Picked for you: $place';
  }

  @override
  String resultSpinCountdown(int seconds) {
    return 'Wait ${seconds}s';
  }

  @override
  String get hubHint => 'No idea what to eat? Leave it to the spin.';

  @override
  String get badgeOpen => 'OPEN';

  @override
  String badgeClosingSoon(int minutes) {
    return 'CLOSING · $minutes′ left';
  }

  @override
  String get badgeClosed => 'CLOSED';

  @override
  String get badgeBestMatch => 'BEST MATCH';

  @override
  String get badgeAd => 'AD';

  @override
  String get badgeCachedData => 'SAVED DATA';

  @override
  String get badgeVerified => 'VERIFIED';

  @override
  String get badgeTopRated => 'TOP RATED';

  @override
  String get badgeNew => 'NEW';

  @override
  String get badgeCheap => 'CHEAP';

  @override
  String get noteHoliday => 'HOLIDAY';

  @override
  String get noteClosedForHoliday => 'CLOSED FOR HOLIDAY';

  @override
  String dqCached(int age) {
    return 'Saved data · ${age}s ago';
  }

  @override
  String get dqStale => 'Older data, lower trust';

  @override
  String dqProviderDegraded(Object providers) {
    return 'Place source is down · using $providers';
  }

  @override
  String get dqOfflineBundle =>
      'Offline · spun on device, places from last save';

  @override
  String get emptyMatchesHeadline => 'No place fits nearby';

  @override
  String get emptyMatchesBody => 'Try loosening one step below.';

  @override
  String relaxStep(Object to, int extra) {
    return 'Expand to $to · $extra more places';
  }

  @override
  String get relaxRadiusLabel => 'radius';

  @override
  String get relaxPriceLabel => 'price level';

  @override
  String get relaxDietLabel => 'diet';

  @override
  String get substituteHeading => 'Try something close';

  @override
  String get urgentNoneHeadline => 'Nothing is open near you right now';

  @override
  String get urgentNoneBody => 'Places opening soon:';

  @override
  String get genericEmpty => 'Nothing here yet';

  @override
  String get errValidation =>
      'Something needs fixing, see the hints in the form.';

  @override
  String get errBudgetTooLow => 'Budget must be at least 10,000₫';

  @override
  String get errDietEmptyPool => 'Your diet rules removed every dish';

  @override
  String get errDietConflictWithType =>
      'The dish you avoid is not in the selected type';

  @override
  String get errFilterContradiction => 'Two filters disagree with each other';

  @override
  String get errPoolTooSmall => 'Too few dishes left to spin';

  @override
  String errRateLimited(int seconds) {
    return 'You are spinning fast, wait ${seconds}s';
  }

  @override
  String get errUnauthenticated => 'Session expired. Retrying.';

  @override
  String get errConsentRequired => 'Allow location access to find places';

  @override
  String get errNotFound => 'Not found';

  @override
  String get errDishNotFound => 'This dish is no longer in the catalogue';

  @override
  String get errIdempotencyReplay => 'Already saved, no duplicate created';

  @override
  String get errRoomExpired => 'Room closed';

  @override
  String get errRoomUpdated => 'Room changed, refreshed';

  @override
  String get errProviderUnavailable =>
      'Place source is down · showing saved data';

  @override
  String get errDegradedNoResult => 'Could not load results yet';

  @override
  String get errReportLimit => 'You reached 5 reports for today';

  @override
  String get errReportDuplicate => 'You already reported this';

  @override
  String get errOutsideServiceArea => 'No place data for this area yet';

  @override
  String get errLocationRequired => 'Tell the app where you are';

  @override
  String get errFutureDate => 'Future dates are not accepted';

  @override
  String get errUnknown => 'Something went wrong';

  @override
  String get errOff => 'Turned off for this session';

  @override
  String get filterGroupMeal => 'Meal';

  @override
  String get filterGroupMoney => 'Money';

  @override
  String get filterGroupTypeRegion => 'Type / Region';

  @override
  String get filterGroupMoodParty => 'Mood / People';

  @override
  String get filterBudget => 'Budget per meal';

  @override
  String get filterPriceMax => 'Max price level';

  @override
  String get filterTemp => 'Hot or cold';

  @override
  String get filterPartySize => 'People';

  @override
  String get filterAntiRepeat => 'No repeats for';

  @override
  String filterDaysN(int days) {
    return '$days days';
  }

  @override
  String get filterDaysOff => 'Off';

  @override
  String get filterLockedHint => 'Wheel is locked';

  @override
  String get filterDietTitle => 'Diet and allergies';

  @override
  String get filterDietLockedHint =>
      'Saved rules can only be removed under You';

  @override
  String get filterDietAdd => 'Add a rule for this spin';

  @override
  String filterPoolLine(int initial, int remaining) {
    return '$initial dishes, $remaining left after diet and skips';
  }

  @override
  String filterPoolRemoved(
    int diet,
    int excluded,
    int locked,
    int filters,
    int antiRepeat,
  ) {
    return 'Removed: diet $diet · manual $excluded · locked $locked · filters $filters · repeats $antiRepeat';
  }

  @override
  String get filterSeedDebug => 'client_seed (debug build only)';

  @override
  String get mealBreakfast => 'Breakfast';

  @override
  String get mealLunch => 'Lunch';

  @override
  String get mealDinner => 'Dinner';

  @override
  String get mealLateNight => 'Late night';

  @override
  String get regionNorth => 'North';

  @override
  String get regionCentral => 'Central';

  @override
  String get regionSouth => 'South';

  @override
  String get regionAll => 'Everywhere';

  @override
  String get tempHot => 'Hot';

  @override
  String get tempWarm => 'Warm';

  @override
  String get tempCold => 'Cold';

  @override
  String get tempAny => 'Anything';

  @override
  String get moodComfort => 'Filling';

  @override
  String get moodLight => 'Light';

  @override
  String get moodGreedy => 'Indulgent';

  @override
  String get moodFresh => 'Fresh';

  @override
  String get moodLocalSpecialty => 'Local speciality';

  @override
  String get moodQuick => 'Quick';

  @override
  String get typeNoodle => 'Noodle';

  @override
  String get typeRice => 'Rice';

  @override
  String get typeBread => 'Bread';

  @override
  String get typeSweet => 'Sweet';

  @override
  String get typeGrill => 'Grill';

  @override
  String get typeSalad => 'Salad / veg';

  @override
  String get typeDrink => 'Drink';

  @override
  String get typeSnack => 'Snack';

  @override
  String get dietVegetarian => 'Vegetarian';

  @override
  String get dietVegan => 'Vegan';

  @override
  String get dietHalal => 'Halal';

  @override
  String get dietNoPork => 'No pork';

  @override
  String get dietNoBeef => 'No beef';

  @override
  String distanceMeters(int m) {
    return '$m m';
  }

  @override
  String distanceKm(Object km) {
    return '$km km';
  }

  @override
  String priceVnd(String vnd) {
    return '$vnd₫';
  }

  @override
  String ratingValue(Object rating) {
    return '$rating★';
  }

  @override
  String ratingWithCount(Object rating, int count) {
    return '$rating★ from $count reviews';
  }

  @override
  String rawRatingHint(Object rating) {
    return 'Raw average $rating, before small-sample shrink';
  }

  @override
  String whyHeadline(Object rating, int count, Object distance) {
    return '$rating★ from $count reviews · $distance m away';
  }

  @override
  String whyQTop(Object rating, int count) {
    return 'High score from $rating★ across $count reviews';
  }

  @override
  String whyQFewReviews(int count) {
    return 'Score is shaky, only $count reviews';
  }

  @override
  String whyDTop(Object distance) {
    return '$distance m from you';
  }

  @override
  String whyPInBudget(Object avg_price, Object budget) {
    return '$avg_price fits your $budget budget';
  }

  @override
  String whyPNearBudget(Object avg_price) {
    return '$avg_price is close to budget';
  }

  @override
  String whyOOpen45m(int minutes) {
    return 'Open for another $minutes minutes';
  }

  @override
  String whyOClosingSoon(int minutes) {
    return 'Closes in $minutes minutes';
  }

  @override
  String get whyUExplore => 'You have not eaten here, give it a go';

  @override
  String whyWeights(Object q, Object d, Object p, Object o, Object u) {
    return 'Q $q% · D $d% · P $p% · O $o% · U $u%';
  }

  @override
  String whyFormulaVersion(Object version) {
    return 'formula $version';
  }

  @override
  String whyPenalty(Object value, Object reason) {
    return 'Minus $value: $reason';
  }

  @override
  String penaltyStaleVerification(int days) {
    return 'Verification is $days days old';
  }

  @override
  String get penaltyLowDataConfidence => 'Low source confidence';

  @override
  String get penaltyReported => 'Recently reported, awaiting review';

  @override
  String relaxRadius(Object to) {
    return 'Widen radius to $to';
  }

  @override
  String relaxPrice(Object to) {
    return 'Raise price level to $to';
  }

  @override
  String get relaxDiet => 'Drop one diet rule';

  @override
  String get substituteSimilarCategory => 'Same dish family';

  @override
  String get substituteSameMealSlot => 'Same meal slot';

  @override
  String get urgentNearbyMatch => 'Matches what you just spun';

  @override
  String urgentNoneOpen(int radius) {
    return 'No place open within $radius m';
  }

  @override
  String get vetoTriedAndDisliked => 'You disliked this dish before';

  @override
  String get grpTieSpun => 'Tied vote, spin decided it';

  @override
  String get promptRateAfterVisit => 'How was it?';

  @override
  String get budgetNearLimit => 'Close to your weekly budget';

  @override
  String urgentDecision(Object radius, int count) {
    return 'Widened to $radius km · checked $count places';
  }

  @override
  String get urgentHeading => 'Closest and open now';

  @override
  String get alternativesHeading => 'Two other options';

  @override
  String altClosing(Object distance, Object minutes) {
    return '$distance m away, closes in $minutes min';
  }

  @override
  String altOpenLater(Object opens_at, Object distance) {
    return 'Opens at $opens_at, $distance m away';
  }

  @override
  String altFarther(Object distance, Object minutes) {
    return '$distance m away, open for $minutes min';
  }

  @override
  String get amenityParking => 'Parking';

  @override
  String get amenityAc => 'Air conditioning';

  @override
  String get amenityGroupFriendly => 'Groups welcome';

  @override
  String get amenityTakeaway => 'Takeaway';

  @override
  String get amenityWifi => 'Wi-Fi';

  @override
  String get detailHours => 'Opening hours';

  @override
  String get detailMenu => 'Menu';

  @override
  String get detailPhotos => 'Photos';

  @override
  String detailReviewSplit(int good, int ok, int bad) {
    return '$good good · $ok okay · $bad bad';
  }

  @override
  String get detailCall => 'Call';

  @override
  String get detailBook => 'Book a table';

  @override
  String get detailDelivery => 'Delivery';

  @override
  String detailCredit(Object credit) {
    return 'Photo: $credit';
  }

  @override
  String detailReportCount(int count, int pending) {
    return '$count reports in 30 days, $pending pending';
  }

  @override
  String get reportSheetTitle => 'Report wrong information';

  @override
  String get reportKindClosed => 'Place closed';

  @override
  String get reportKindWrongHours => 'Wrong hours';

  @override
  String get reportKindWrongPrice => 'Wrong price';

  @override
  String get reportKindWrongLocation => 'Wrong location';

  @override
  String get reportKindWrongName => 'Wrong name';

  @override
  String get reportKindDuplicate => 'Duplicate place';

  @override
  String get reportKindOther => 'Other';

  @override
  String get reportDetailHint => 'Add detail if needed (max 500 characters)';

  @override
  String reportCooldown(int seconds) {
    return 'Wait ${seconds}s to report again';
  }

  @override
  String get onboardStep1Title => 'Where do you eat?';

  @override
  String get onboardStep1Body =>
      'Pick a location or type an address. Declining GPS still works.';

  @override
  String get onboardStep2Title => 'Anything you avoid?';

  @override
  String get onboardStep2Body =>
      'Hard rules can only be added, never switched off from the spin screen.';

  @override
  String get onboardStep3Title => 'Budget per meal?';

  @override
  String get onboardStep3Body => 'Used for the fits-your-pocket score.';

  @override
  String get onboardDone => 'Done, let\'s spin';

  @override
  String get settingsTheme => 'Light or dark';

  @override
  String get settingsThemeSystem => 'Follow system';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsReduceMotion => 'Reduce motion';

  @override
  String get settingsReduceMotionHint =>
      'Skip the wheel, show the result at once';

  @override
  String get settingsSound => 'Sound';

  @override
  String get settingsSoundHint => 'Click when the wheel stops';

  @override
  String get settingsHaptics => 'Haptics';

  @override
  String get settingsHapticsHint => 'A short buzz when the result locks';

  @override
  String get settingsMotionSection => 'Motion & sound';

  @override
  String get proofCopy => 'Copy';

  @override
  String get proofCopied => 'Copied';

  @override
  String get settingsHighContrast => 'High contrast';

  @override
  String get settingsLocation => 'Location';

  @override
  String get settingsProof => 'Verify this spin';

  @override
  String settingsProofSeed(Object seed) {
    return 'seed $seed';
  }

  @override
  String settingsProofHash(Object hash) {
    return 'sha256 $hash';
  }

  @override
  String get settingsLocationChanged => 'Location changed · Update?';

  @override
  String get settingsForceUpgrade =>
      'This build is too old, update to continue';

  @override
  String get semSpinButton => 'Spin for a dish';

  @override
  String semRowLabel(
    Object name,
    int distance,
    Object rating,
    Object openState,
  ) {
    return '$name, $distance metres away, $rating points, $openState';
  }

  @override
  String get semOpen => 'open now';

  @override
  String get semClosingSoon => 'closing soon';

  @override
  String get semClosed => 'closed';

  @override
  String get semWheelUnfocusable =>
      'The wheel is decoration, the result is below';

  @override
  String semDisabledHint(Object reason) {
    return 'Not available: $reason';
  }

  @override
  String get hubQuestion => 'What to eat today?';

  @override
  String get hubSub => 'One spin, no overthinking.';

  @override
  String get hubWheelHint => 'Eight food groups, one spin.';

  @override
  String hubFilterSummary(Object count) {
    return '$count filters on';
  }

  @override
  String get hubFilterNone => 'No filters yet';

  @override
  String get hubLocationMissing => 'Pick where you are';

  @override
  String get hubLocationDemo => 'Tap to change location';

  @override
  String matchCount(Object count) {
    return '$count places near you';
  }

  @override
  String get matchNote => 'Ranked by how well they fit you';

  @override
  String get matchBack => 'Back to spin';

  @override
  String get whyTitle => 'Why this place?';

  @override
  String get whyPenaltyTitle => 'Points removed';

  @override
  String whyContribution(Object value) {
    return '+$value';
  }

  @override
  String get filterTitle => 'Filters';

  @override
  String get filterReset => 'Clear all';

  @override
  String filterLock(Object type) {
    return 'Lock $type';
  }

  @override
  String get filterUnlock => 'Unlock';

  @override
  String get filterLockHint => 'Lock one group, spin the rest.';

  @override
  String get detailAddress => 'Address';

  @override
  String get detailAmenities => 'Amenities';

  @override
  String get detailSimilar => 'Similar places';

  @override
  String get detailToday => 'Today';

  @override
  String get detailClosedDay => 'Closed';

  @override
  String get detailOpen => 'Open';

  @override
  String get detailPrice => 'Average price';

  @override
  String get detailDistance => 'From you';

  @override
  String detailReviews(Object count) {
    return '$count reviews';
  }

  @override
  String get discoverTitle => 'Around you';

  @override
  String discoverRadius(Object radius) {
    return 'Within $radius';
  }

  @override
  String get youTitle => 'You';

  @override
  String get youGuest => 'You are using a guest session';

  @override
  String get youProofEmpty => 'No spins yet';

  @override
  String youVersion(Object version) {
    return 'Version $version';
  }

  @override
  String get urgentOneTap => 'One tap, go.';

  @override
  String get reportKindLabel => 'What is wrong?';

  @override
  String get reportSubmit => 'Send report';

  @override
  String get visitSaved => 'Saved to your journal';

  @override
  String get loading => 'Loading';

  @override
  String get languageVi => 'Tiếng Việt';

  @override
  String get languageEn => 'English';

  @override
  String get themeLabel => 'Appearance';

  @override
  String get onboardSkipHint => 'You can skip and change this later in You.';

  @override
  String get onboardAddressHint => 'Enter your address';

  @override
  String get onboardAddressPick => 'Or pick one';

  @override
  String budgetPerMeal(Object vnd) {
    return '$vnd per meal';
  }

  @override
  String get matchDishLabel => 'Today\'s dish';

  @override
  String get detailReported => 'Report this place';

  @override
  String get detailCallNow => 'Call the place';

  @override
  String get actionClose => 'Close';

  @override
  String get spinOfflineNote => 'No network, you can still spin.';

  @override
  String get wheelIdleHint => 'Tap Spin to start';

  @override
  String get hubStamp => 'SPIN IT';

  @override
  String get viewPlaces => 'See places';

  @override
  String detailHoursToday(Object from, Object to) {
    return 'Today $from to $to';
  }

  @override
  String get filterBudgetOff => 'No limit';

  @override
  String get priceLevel1 => '≤ 25k';

  @override
  String get priceLevel2 => '25–50k';

  @override
  String get priceLevel3 => '50–150k';

  @override
  String get priceLevel4 => '> 150k';

  @override
  String filterLockedChip(Object type) {
    return 'Lock $type';
  }

  @override
  String get whyShort => 'Why';

  @override
  String get matchClose => 'Close results';
}
