// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class SVi extends S {
  SVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'ĂnGìĐây';

  @override
  String get tabSpin => 'Quay';

  @override
  String get tabPlaces => 'Quán';

  @override
  String get tabUrgent => 'Đói gấp';

  @override
  String get tabYou => 'Của bạn';

  @override
  String get ctaSpin => 'Quay';

  @override
  String get ctaSpinLoading => 'Đang quay';

  @override
  String get ctaSpinAgain => 'Quay lại';

  @override
  String get ctaFilters => 'Bộ lọc';

  @override
  String get ctaApply => 'Áp dụng';

  @override
  String get ctaNavigate => 'Chỉ đường';

  @override
  String get ctaNavOpening => 'Đang mở bản đồ';

  @override
  String get ctaArrived => 'Tôi đã đến';

  @override
  String get ctaArrivedDone => 'Đã ghi';

  @override
  String get ctaDismiss => 'Loại';

  @override
  String get ctaDismissed => 'Đã loại';

  @override
  String get ctaSave => 'Lưu';

  @override
  String get ctaSaved => 'Đã lưu';

  @override
  String get ctaReport => 'Báo sai';

  @override
  String get ctaReportSent => 'Đã gửi báo sai';

  @override
  String get ctaUrgent => 'Đói gấp';

  @override
  String get ctaRetry => 'Thử lại';

  @override
  String get ctaEnterAddress => 'Nhập địa chỉ';

  @override
  String get ctaClose => 'Đóng';

  @override
  String get ctaWhy => 'Vì sao gợi ý quán này?';

  @override
  String get ctaSkip => 'Bỏ qua';

  @override
  String get ctaNext => 'Tiếp tục';

  @override
  String get ctaDone => 'Xong';

  @override
  String get ctaUpdateLocation => 'Cập nhật';

  @override
  String resultToday(Object dish) {
    return 'Hôm nay: $dish';
  }

  @override
  String resultUrgentPick(Object place) {
    return 'Chọn giúp bạn: $place';
  }

  @override
  String resultSpinCountdown(int seconds) {
    return 'Chờ ${seconds}s';
  }

  @override
  String get hubHint => 'Không biết ăn gì? Để đây quay giúp.';

  @override
  String get badgeOpen => 'ĐANG MỞ';

  @override
  String badgeClosingSoon(int minutes) {
    return 'SẮP ĐÓNG · còn $minutes′';
  }

  @override
  String get badgeClosed => 'ĐÓNG CỬA';

  @override
  String get badgeBestMatch => 'HỢP NHẤT';

  @override
  String get badgeAd => 'QUẢNG CÁO';

  @override
  String get badgeCachedData => 'DỮ LIỆU LƯU';

  @override
  String get badgeVerified => 'ĐÃ XÁC MINH';

  @override
  String get badgeTopRated => 'ĐÁNH GIÁ CAO';

  @override
  String get badgeNew => 'MỚI';

  @override
  String get badgeCheap => 'RẺ';

  @override
  String get noteHoliday => 'NGHỈ LỄ';

  @override
  String get noteClosedForHoliday => 'QUÁN NGHỈ LỄ';

  @override
  String dqCached(int age) {
    return 'Dữ liệu lưu · ${age}s trước';
  }

  @override
  String get dqStale => 'Dữ liệu cũ, độ tin giảm';

  @override
  String dqProviderDegraded(Object providers) {
    return 'Nguồn quán đang lỗi · dùng $providers';
  }

  @override
  String get dqOfflineBundle =>
      'Không có mạng · quay từ máy, quán từ lần lưu gần nhất';

  @override
  String get emptyMatchesHeadline => 'Không có quán phù hợp gần bạn';

  @override
  String get emptyMatchesBody => 'Thử nới một bước dưới đây.';

  @override
  String relaxStep(Object to, int extra) {
    return 'Mở rộng tới $to · thêm $extra quán';
  }

  @override
  String get relaxRadiusLabel => 'bán kính';

  @override
  String get relaxPriceLabel => 'mức giá';

  @override
  String get relaxDietLabel => 'kiêng';

  @override
  String get substituteHeading => 'Thử món gần giống';

  @override
  String get urgentNoneHeadline => 'Bây giờ chưa có quán mở gần bạn';

  @override
  String get urgentNoneBody => 'Đây là mấy quán sắp mở:';

  @override
  String get genericEmpty => 'Chưa có gì ở đây';

  @override
  String get errValidation => 'Có chỗ chưa ổn, xem gợi ý trong form.';

  @override
  String get errBudgetTooLow => 'Ngân sách tối thiểu 10.000₫';

  @override
  String get errDietEmptyPool => 'Ràng buộc kiêng loại hết kho món';

  @override
  String get errDietConflictWithType =>
      'Món bạn kiêng không nằm trong loại đã chọn';

  @override
  String get errFilterContradiction => 'Hai bộ lọc đang cãi nhau';

  @override
  String get errPoolTooSmall => 'Số món còn lại quá ít để quay';

  @override
  String errRateLimited(int seconds) {
    return 'Bạn quay nhanh quá, chờ ${seconds}s';
  }

  @override
  String get errUnauthenticated => 'Phiên hết hạn. Đang thử lại.';

  @override
  String get errConsentRequired =>
      'Cần bạn đồng ý dùng vị trí mới tìm được quán';

  @override
  String get errNotFound => 'Không tìm thấy';

  @override
  String get errDishNotFound => 'Món này không còn trong kho';

  @override
  String get errIdempotencyReplay => 'Đã ghi rồi, không tạo bản trùng';

  @override
  String get errRoomExpired => 'Phòng đã đóng';

  @override
  String get errRoomUpdated => 'Phòng vừa thay đổi, đã cập nhật';

  @override
  String get errProviderUnavailable => 'Nguồn quán đang lỗi · dùng dữ liệu lưu';

  @override
  String get errDegradedNoResult => 'Hiện chưa lấy được kết quả';

  @override
  String get errReportLimit => 'Hôm nay bạn báo đủ 5 lần rồi';

  @override
  String get errReportDuplicate => 'Bạn đã báo rồi';

  @override
  String get errOutsideServiceArea => 'Khu này chưa có dữ liệu quán';

  @override
  String get errLocationRequired => 'Cho app biết bạn đang ở đâu';

  @override
  String get errFutureDate => 'Không nhận ngày trong tương lai';

  @override
  String get errUnknown => 'Có gì đó không ổn';

  @override
  String get errOff => 'Đã tắt cho phiên này';

  @override
  String get filterGroupMeal => 'Bữa';

  @override
  String get filterGroupMoney => 'Tiền';

  @override
  String get filterGroupTypeRegion => 'Loại / Vùng';

  @override
  String get filterGroupMoodParty => 'Tâm trạng / Số người';

  @override
  String get filterBudget => 'Ngân sách mỗi bữa';

  @override
  String get filterPriceMax => 'Mức giá tối đa';

  @override
  String get filterTemp => 'Nóng hay lạnh';

  @override
  String get filterPartySize => 'Số người';

  @override
  String get filterAntiRepeat => 'Không lặp lại trong';

  @override
  String filterDaysN(int days) {
    return '$days ngày';
  }

  @override
  String get filterDaysOff => 'Tắt';

  @override
  String get filterLockedHint => 'Đang khoá vòng quay';

  @override
  String get filterDietTitle => 'Kiêng và dị ứng';

  @override
  String get filterDietLockedHint =>
      'Ràng buộc đã lưu chỉ bỏ được trong phần Của bạn';

  @override
  String get filterDietAdd => 'Thêm ràng buộc cho lượt này';

  @override
  String filterPoolLine(int initial, int remaining) {
    return '$initial món, còn $remaining sau kiêng và loại';
  }

  @override
  String filterPoolRemoved(
    int diet,
    int excluded,
    int locked,
    int filters,
    int antiRepeat,
  ) {
    return 'Bị loại: kiêng $diet · thủ công $excluded · khoá $locked · bộ lọc $filters · lặp lại $antiRepeat';
  }

  @override
  String get filterSeedDebug => 'client_seed (chỉ bản debug)';

  @override
  String get mealBreakfast => 'Sáng';

  @override
  String get mealLunch => 'Trưa';

  @override
  String get mealDinner => 'Chiều';

  @override
  String get mealLateNight => 'Đêm';

  @override
  String get regionNorth => 'Bắc';

  @override
  String get regionCentral => 'Trung';

  @override
  String get regionSouth => 'Nam';

  @override
  String get regionAll => 'Cả nước';

  @override
  String get tempHot => 'Nóng';

  @override
  String get tempWarm => 'Ấm';

  @override
  String get tempCold => 'Lạnh';

  @override
  String get tempAny => 'Gì cũng được';

  @override
  String get moodComfort => 'Ăn no';

  @override
  String get moodLight => 'Nhẹ bụng';

  @override
  String get moodGreedy => 'Hảo hám';

  @override
  String get moodFresh => 'Mát';

  @override
  String get moodLocalSpecialty => 'Đặc sản';

  @override
  String get moodQuick => 'Nhanh';

  @override
  String get typeNoodle => 'Món nước';

  @override
  String get typeRice => 'Cơm';

  @override
  String get typeBread => 'Bánh';

  @override
  String get typeSweet => 'Ngọt';

  @override
  String get typeGrill => 'Nướng';

  @override
  String get typeSalad => 'Rau / chay';

  @override
  String get typeDrink => 'Đồ uống';

  @override
  String get typeSnack => 'Ăn vặt';

  @override
  String get dietVegetarian => 'Ăn chay';

  @override
  String get dietVegan => 'Thuần chay';

  @override
  String get dietHalal => 'Halal';

  @override
  String get dietNoPork => 'Không heo';

  @override
  String get dietNoBeef => 'Không bò';

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
    return '$rating★ từ $count đánh giá';
  }

  @override
  String rawRatingHint(Object rating) {
    return 'Trung bình thô $rating (chưa trừ điểm quán ít đánh giá)';
  }

  @override
  String whyHeadline(Object rating, int count, Object distance) {
    return '$rating★ từ $count đánh giá · cách $distance m';
  }

  @override
  String whyQTop(Object rating, int count) {
    return 'Điểm cao nhờ $rating★ từ $count đánh giá';
  }

  @override
  String whyQFewReviews(int count) {
    return 'Điểm chưa chắc vì mới $count đánh giá';
  }

  @override
  String whyDTop(Object distance) {
    return 'Cách bạn $distance m';
  }

  @override
  String whyPInBudget(Object avg_price, Object budget) {
    return '$avg_price nằm trong ngân sách $budget';
  }

  @override
  String whyPNearBudget(Object avg_price) {
    return '$avg_price sát ngân sách';
  }

  @override
  String whyOOpen45m(int minutes) {
    return 'Còn mở $minutes phút nữa';
  }

  @override
  String whyOClosingSoon(int minutes) {
    return 'Chỉ còn $minutes phút nữa đóng';
  }

  @override
  String get whyUExplore => 'Bạn chưa ăn ở đây, thử cho biết';

  @override
  String whyWeights(Object q, Object d, Object p, Object o, Object u) {
    return 'Q $q% · D $d% · P $p% · O $o% · U $u%';
  }

  @override
  String whyFormulaVersion(Object version) {
    return 'công thức $version';
  }

  @override
  String whyPenalty(Object value, Object reason) {
    return 'Trừ $value điểm: $reason';
  }

  @override
  String penaltyStaleVerification(int days) {
    return 'Dữ liệu xác minh cũ $days ngày';
  }

  @override
  String get penaltyLowDataConfidence => 'Độ tin nguồn thấp';

  @override
  String get penaltyReported => 'Vừa bị báo sai, đang chờ kiểm';

  @override
  String relaxRadius(Object to) {
    return 'Nới bán kính lên $to';
  }

  @override
  String relaxPrice(Object to) {
    return 'Nới mức giá lên $to';
  }

  @override
  String get relaxDiet => 'Bỏ một ràng buộc kiêng';

  @override
  String get substituteSimilarCategory => 'Cùng nhóm món';

  @override
  String get substituteSameMealSlot => 'Cùng khung bữa';

  @override
  String get urgentNearbyMatch => 'Hợp món bạn vừa quay';

  @override
  String urgentNoneOpen(int radius) {
    return 'Chưa quán nào mở trong $radius m';
  }

  @override
  String get vetoTriedAndDisliked => 'Bạn từng chê món này';

  @override
  String get grpTieSpun => 'Hoà phiếu, quay quyết định';

  @override
  String get promptRateAfterVisit => 'Quán này thế nào?';

  @override
  String get budgetNearLimit => 'Sắp hết ngân sách tuần';

  @override
  String urgentDecision(Object radius, int count) {
    return 'Đã mở rộng tới $radius km · đã xét $count quán';
  }

  @override
  String get urgentHeading => 'Gần nhất và đang mở';

  @override
  String get alternativesHeading => 'Còn hai lựa chọn khác';

  @override
  String altClosing(Object distance, Object minutes) {
    return 'Cách $distance m, đóng trong $minutes phút';
  }

  @override
  String altOpenLater(Object opens_at, Object distance) {
    return 'Mở lúc $opens_at, cách $distance m';
  }

  @override
  String altFarther(Object distance, Object minutes) {
    return 'Cách $distance m, còn mở $minutes phút';
  }

  @override
  String get amenityParking => 'Có chỗ để xe';

  @override
  String get amenityAc => 'Máy lạnh';

  @override
  String get amenityGroupFriendly => 'Nhóm đông được';

  @override
  String get amenityTakeaway => 'Mua mang đi';

  @override
  String get amenityWifi => 'Wi-Fi';

  @override
  String get detailHours => 'Giờ mở';

  @override
  String get detailMenu => 'Thực đơn';

  @override
  String get detailPhotos => 'Ảnh';

  @override
  String detailReviewSplit(int good, int ok, int bad) {
    return '$good khen · $ok bình thường · $bad chê';
  }

  @override
  String get detailCall => 'Gọi';

  @override
  String get detailBook => 'Đặt bàn';

  @override
  String get detailDelivery => 'Giao tận nơi';

  @override
  String detailCredit(Object credit) {
    return 'Ảnh: $credit';
  }

  @override
  String detailReportCount(int count, int pending) {
    return '$count báo sai trong 30 ngày, $pending đang chờ';
  }

  @override
  String get reportSheetTitle => 'Báo sai thông tin';

  @override
  String get reportKindClosed => 'Quán đã đóng';

  @override
  String get reportKindWrongHours => 'Giờ sai';

  @override
  String get reportKindWrongPrice => 'Giá sai';

  @override
  String get reportKindWrongLocation => 'Vị trí sai';

  @override
  String get reportKindWrongName => 'Tên sai';

  @override
  String get reportKindDuplicate => 'Trùng quán';

  @override
  String get reportKindOther => 'Khác';

  @override
  String get reportDetailHint => 'Viết thêm nếu cần (tối đa 500 ký tự)';

  @override
  String reportCooldown(int seconds) {
    return 'Chờ ${seconds}s để báo tiếp';
  }

  @override
  String get onboardStep1Title => 'Bạn ăn ở đâu?';

  @override
  String get onboardStep1Body =>
      'Chọn vị trí hoặc nhập địa chỉ. Từ chối định vị vẫn dùng được.';

  @override
  String get onboardStep2Title => 'Kiêng gì không?';

  @override
  String get onboardStep2Body =>
      'Ràng buộc cứng chỉ thêm, không tắt từ màn quay.';

  @override
  String get onboardStep3Title => 'Ngân sách một bữa?';

  @override
  String get onboardStep3Body => 'Dùng để tính điểm hợp túi tiền.';

  @override
  String get onboardDone => 'Xong, quay thôi';

  @override
  String get settingsTheme => 'Sáng tối';

  @override
  String get settingsThemeSystem => 'Theo máy';

  @override
  String get settingsThemeLight => 'Sáng';

  @override
  String get settingsThemeDark => 'Tối';

  @override
  String get settingsLanguage => 'Ngôn ngữ';

  @override
  String get settingsReduceMotion => 'Giảm chuyển động';

  @override
  String get settingsReduceMotionHint => 'Tắt vòng quay, hiện kết quả ngay';

  @override
  String get settingsSound => 'Âm thanh';

  @override
  String get settingsSoundHint => 'Tiếng khi bánh dừng';

  @override
  String get settingsHaptics => 'Rung';

  @override
  String get settingsHapticsHint => 'Rung nhẹ khi chốt kết quả';

  @override
  String get settingsMotionSection => 'Chuyển động & âm thanh';

  @override
  String get proofCopy => 'Sao chép';

  @override
  String get proofCopied => 'Đã sao chép';

  @override
  String get settingsHighContrast => 'Tương phản cao';

  @override
  String get settingsLocation => 'Vị trí';

  @override
  String get settingsProof => 'Kiểm chứng lần quay';

  @override
  String settingsProofSeed(Object seed) {
    return 'seed $seed';
  }

  @override
  String settingsProofHash(Object hash) {
    return 'sha256 $hash';
  }

  @override
  String get settingsLocationChanged => 'Vị trí thay đổi · Cập nhật?';

  @override
  String get settingsForceUpgrade => 'Bản app này quá cũ, cập nhật để tiếp tục';

  @override
  String get semSpinButton => 'Quay món';

  @override
  String semRowLabel(
    Object name,
    int distance,
    Object rating,
    Object openState,
  ) {
    return '$name, cách $distance mét, $rating điểm, $openState';
  }

  @override
  String get semOpen => 'đang mở';

  @override
  String get semClosingSoon => 'sắp đóng';

  @override
  String get semClosed => 'đã đóng';

  @override
  String get semWheelUnfocusable =>
      'Vòng quay chỉ minh hoạ, kết quả đã có bên dưới';

  @override
  String semDisabledHint(Object reason) {
    return 'Không bấm được: $reason';
  }

  @override
  String get hubQuestion => 'Hôm nay ăn gì?';

  @override
  String get hubSub => 'Quay một cái, khỏi nghĩ.';

  @override
  String get hubWheelHint => 'Tám nhóm món, một cú quay.';

  @override
  String hubFilterSummary(Object count) {
    return '$count bộ lọc đang bật';
  }

  @override
  String get hubFilterNone => 'Chưa có bộ lọc';

  @override
  String get hubLocationMissing => 'Chọn chỗ bạn đang đứng';

  @override
  String get hubLocationDemo => 'Chạm để đổi vị trí';

  @override
  String matchCount(Object count) {
    return '$count quán gần bạn';
  }

  @override
  String get matchNote => 'Xếp theo độ hợp với bạn';

  @override
  String get matchBack => 'Về quay';

  @override
  String get whyTitle => 'Vì sao gợi ý quán này?';

  @override
  String get whyPenaltyTitle => 'Điểm bị trừ';

  @override
  String whyContribution(Object value) {
    return '+$value';
  }

  @override
  String get filterTitle => 'Bộ lọc';

  @override
  String get filterReset => 'Xoá hết';

  @override
  String filterLock(Object type) {
    return 'Khoá $type';
  }

  @override
  String get filterUnlock => 'Bỏ khoá';

  @override
  String get filterLockHint => 'Khoá một loại, quay phần còn lại.';

  @override
  String get detailAddress => 'Địa chỉ';

  @override
  String get detailAmenities => 'Tiện ích';

  @override
  String get detailSimilar => 'Quán tương tự';

  @override
  String get detailToday => 'Hôm nay';

  @override
  String get detailClosedDay => 'Nghỉ';

  @override
  String get detailOpen => 'Đang mở';

  @override
  String get detailPrice => 'Giá trung bình';

  @override
  String get detailDistance => 'Cách bạn';

  @override
  String detailReviews(Object count) {
    return '$count đánh giá';
  }

  @override
  String get discoverTitle => 'Quanh bạn';

  @override
  String discoverRadius(Object radius) {
    return 'Trong $radius';
  }

  @override
  String get youTitle => 'Của bạn';

  @override
  String get youGuest => 'Bạn đang dùng khách';

  @override
  String get youProofEmpty => 'Chưa có lần quay nào';

  @override
  String youVersion(Object version) {
    return 'Bản $version';
  }

  @override
  String get urgentOneTap => 'Một chạm, đi luôn.';

  @override
  String get reportKindLabel => 'Chuyện gì sai?';

  @override
  String get reportSubmit => 'Gửi báo sai';

  @override
  String get visitSaved => 'Đã ghi vào nhật ký';

  @override
  String get loading => 'Đang tải';

  @override
  String get languageVi => 'Tiếng Việt';

  @override
  String get languageEn => 'English';

  @override
  String get themeLabel => 'Giao diện';

  @override
  String get onboardSkipHint => 'Bỏ qua được, chỉnh sau trong Của bạn.';

  @override
  String get onboardAddressHint => 'Nhập địa chỉ của bạn';

  @override
  String get onboardAddressPick => 'Hoặc chọn nhanh';

  @override
  String budgetPerMeal(Object vnd) {
    return '$vnd mỗi bữa';
  }

  @override
  String get matchDishLabel => 'Món hôm nay';

  @override
  String get detailReported => 'Báo sai cho quán này';

  @override
  String get detailCallNow => 'Gọi quán';

  @override
  String get actionClose => 'Đóng';

  @override
  String get spinOfflineNote => 'Không có mạng, vẫn quay được.';

  @override
  String get wheelIdleHint => 'Chạm Quay để bắt đầu';

  @override
  String get hubStamp => 'QUAY LÀ RA';

  @override
  String get viewPlaces => 'Xem quán';

  @override
  String detailHoursToday(Object from, Object to) {
    return 'Hôm nay mở $from tới $to';
  }

  @override
  String get filterBudgetOff => 'Không giới hạn';

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
    return 'Khoá $type';
  }

  @override
  String get whyShort => 'Vì sao';

  @override
  String get matchClose => 'Đóng kết quả';
}
