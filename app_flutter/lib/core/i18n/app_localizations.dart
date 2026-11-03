import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of S
/// returned by `S.of(context)`.
///
/// Applications need to include `S.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'i18n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: S.localizationsDelegates,
///   supportedLocales: S.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the S.supportedLocales
/// property.
abstract class S {
  S(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static S of(BuildContext context) {
    return Localizations.of<S>(context, S)!;
  }

  static const LocalizationsDelegate<S> delegate = _SDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In vi, this message translates to:
  /// **'ĂnGìĐây'**
  String get appTitle;

  /// No description provided for @tabSpin.
  ///
  /// In vi, this message translates to:
  /// **'Quay'**
  String get tabSpin;

  /// No description provided for @tabPlaces.
  ///
  /// In vi, this message translates to:
  /// **'Quán'**
  String get tabPlaces;

  /// No description provided for @tabUrgent.
  ///
  /// In vi, this message translates to:
  /// **'Đói gấp'**
  String get tabUrgent;

  /// No description provided for @tabYou.
  ///
  /// In vi, this message translates to:
  /// **'Của bạn'**
  String get tabYou;

  /// No description provided for @ctaSpin.
  ///
  /// In vi, this message translates to:
  /// **'Quay'**
  String get ctaSpin;

  /// No description provided for @ctaSpinLoading.
  ///
  /// In vi, this message translates to:
  /// **'Đang quay'**
  String get ctaSpinLoading;

  /// No description provided for @ctaSpinAgain.
  ///
  /// In vi, this message translates to:
  /// **'Quay lại'**
  String get ctaSpinAgain;

  /// No description provided for @ctaFilters.
  ///
  /// In vi, this message translates to:
  /// **'Bộ lọc'**
  String get ctaFilters;

  /// No description provided for @ctaApply.
  ///
  /// In vi, this message translates to:
  /// **'Áp dụng'**
  String get ctaApply;

  /// No description provided for @ctaNavigate.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ đường'**
  String get ctaNavigate;

  /// No description provided for @ctaNavOpening.
  ///
  /// In vi, this message translates to:
  /// **'Đang mở bản đồ'**
  String get ctaNavOpening;

  /// No description provided for @ctaArrived.
  ///
  /// In vi, this message translates to:
  /// **'Tôi đã đến'**
  String get ctaArrived;

  /// No description provided for @ctaArrivedDone.
  ///
  /// In vi, this message translates to:
  /// **'Đã ghi'**
  String get ctaArrivedDone;

  /// No description provided for @ctaDismiss.
  ///
  /// In vi, this message translates to:
  /// **'Loại'**
  String get ctaDismiss;

  /// No description provided for @ctaDismissed.
  ///
  /// In vi, this message translates to:
  /// **'Đã loại'**
  String get ctaDismissed;

  /// No description provided for @ctaSave.
  ///
  /// In vi, this message translates to:
  /// **'Lưu'**
  String get ctaSave;

  /// No description provided for @ctaSaved.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu'**
  String get ctaSaved;

  /// No description provided for @ctaReport.
  ///
  /// In vi, this message translates to:
  /// **'Báo sai'**
  String get ctaReport;

  /// No description provided for @ctaReportSent.
  ///
  /// In vi, this message translates to:
  /// **'Đã gửi báo sai'**
  String get ctaReportSent;

  /// No description provided for @ctaUrgent.
  ///
  /// In vi, this message translates to:
  /// **'Đói gấp'**
  String get ctaUrgent;

  /// No description provided for @ctaRetry.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get ctaRetry;

  /// No description provided for @ctaEnterAddress.
  ///
  /// In vi, this message translates to:
  /// **'Nhập địa chỉ'**
  String get ctaEnterAddress;

  /// No description provided for @ctaClose.
  ///
  /// In vi, this message translates to:
  /// **'Đóng'**
  String get ctaClose;

  /// No description provided for @ctaWhy.
  ///
  /// In vi, this message translates to:
  /// **'Vì sao gợi ý quán này?'**
  String get ctaWhy;

  /// No description provided for @ctaSkip.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ qua'**
  String get ctaSkip;

  /// No description provided for @ctaNext.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục'**
  String get ctaNext;

  /// No description provided for @ctaDone.
  ///
  /// In vi, this message translates to:
  /// **'Xong'**
  String get ctaDone;

  /// No description provided for @ctaUpdateLocation.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật'**
  String get ctaUpdateLocation;

  /// No description provided for @resultToday.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay: {dish}'**
  String resultToday(Object dish);

  /// No description provided for @resultUrgentPick.
  ///
  /// In vi, this message translates to:
  /// **'Chọn giúp bạn: {place}'**
  String resultUrgentPick(Object place);

  /// No description provided for @resultSpinCountdown.
  ///
  /// In vi, this message translates to:
  /// **'Chờ {seconds}s'**
  String resultSpinCountdown(int seconds);

  /// No description provided for @hubHint.
  ///
  /// In vi, this message translates to:
  /// **'Không biết ăn gì? Để đây quay giúp.'**
  String get hubHint;

  /// No description provided for @badgeOpen.
  ///
  /// In vi, this message translates to:
  /// **'ĐANG MỞ'**
  String get badgeOpen;

  /// No description provided for @badgeClosingSoon.
  ///
  /// In vi, this message translates to:
  /// **'SẮP ĐÓNG · còn {minutes}′'**
  String badgeClosingSoon(int minutes);

  /// No description provided for @badgeClosed.
  ///
  /// In vi, this message translates to:
  /// **'ĐÓNG CỬA'**
  String get badgeClosed;

  /// No description provided for @badgeBestMatch.
  ///
  /// In vi, this message translates to:
  /// **'HỢP NHẤT'**
  String get badgeBestMatch;

  /// No description provided for @badgeAd.
  ///
  /// In vi, this message translates to:
  /// **'QUẢNG CÁO'**
  String get badgeAd;

  /// No description provided for @badgeCachedData.
  ///
  /// In vi, this message translates to:
  /// **'DỮ LIỆU LƯU'**
  String get badgeCachedData;

  /// No description provided for @badgeVerified.
  ///
  /// In vi, this message translates to:
  /// **'ĐÃ XÁC MINH'**
  String get badgeVerified;

  /// No description provided for @badgeTopRated.
  ///
  /// In vi, this message translates to:
  /// **'ĐÁNH GIÁ CAO'**
  String get badgeTopRated;

  /// No description provided for @badgeNew.
  ///
  /// In vi, this message translates to:
  /// **'MỚI'**
  String get badgeNew;

  /// No description provided for @badgeCheap.
  ///
  /// In vi, this message translates to:
  /// **'RẺ'**
  String get badgeCheap;

  /// No description provided for @noteHoliday.
  ///
  /// In vi, this message translates to:
  /// **'NGHỈ LỄ'**
  String get noteHoliday;

  /// No description provided for @noteClosedForHoliday.
  ///
  /// In vi, this message translates to:
  /// **'QUÁN NGHỈ LỄ'**
  String get noteClosedForHoliday;

  /// No description provided for @dqCached.
  ///
  /// In vi, this message translates to:
  /// **'Dữ liệu lưu · {age}s trước'**
  String dqCached(int age);

  /// No description provided for @dqStale.
  ///
  /// In vi, this message translates to:
  /// **'Dữ liệu cũ, độ tin giảm'**
  String get dqStale;

  /// No description provided for @dqProviderDegraded.
  ///
  /// In vi, this message translates to:
  /// **'Nguồn quán đang lỗi · dùng {providers}'**
  String dqProviderDegraded(Object providers);

  /// No description provided for @dqOfflineBundle.
  ///
  /// In vi, this message translates to:
  /// **'Không có mạng · quay từ máy, quán từ lần lưu gần nhất'**
  String get dqOfflineBundle;

  /// No description provided for @emptyMatchesHeadline.
  ///
  /// In vi, this message translates to:
  /// **'Không có quán phù hợp gần bạn'**
  String get emptyMatchesHeadline;

  /// No description provided for @emptyMatchesBody.
  ///
  /// In vi, this message translates to:
  /// **'Thử nới một bước dưới đây.'**
  String get emptyMatchesBody;

  /// No description provided for @relaxStep.
  ///
  /// In vi, this message translates to:
  /// **'Mở rộng tới {to} · thêm {extra} quán'**
  String relaxStep(Object to, int extra);

  /// No description provided for @relaxRadiusLabel.
  ///
  /// In vi, this message translates to:
  /// **'bán kính'**
  String get relaxRadiusLabel;

  /// No description provided for @relaxPriceLabel.
  ///
  /// In vi, this message translates to:
  /// **'mức giá'**
  String get relaxPriceLabel;

  /// No description provided for @relaxDietLabel.
  ///
  /// In vi, this message translates to:
  /// **'kiêng'**
  String get relaxDietLabel;

  /// No description provided for @substituteHeading.
  ///
  /// In vi, this message translates to:
  /// **'Thử món gần giống'**
  String get substituteHeading;

  /// No description provided for @urgentNoneHeadline.
  ///
  /// In vi, this message translates to:
  /// **'Bây giờ chưa có quán mở gần bạn'**
  String get urgentNoneHeadline;

  /// No description provided for @urgentNoneBody.
  ///
  /// In vi, this message translates to:
  /// **'Đây là mấy quán sắp mở:'**
  String get urgentNoneBody;

  /// No description provided for @genericEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có gì ở đây'**
  String get genericEmpty;

  /// No description provided for @errValidation.
  ///
  /// In vi, this message translates to:
  /// **'Có chỗ chưa ổn, xem gợi ý trong form.'**
  String get errValidation;

  /// No description provided for @errBudgetTooLow.
  ///
  /// In vi, this message translates to:
  /// **'Ngân sách tối thiểu 10.000₫'**
  String get errBudgetTooLow;

  /// No description provided for @errDietEmptyPool.
  ///
  /// In vi, this message translates to:
  /// **'Ràng buộc kiêng loại hết kho món'**
  String get errDietEmptyPool;

  /// No description provided for @errDietConflictWithType.
  ///
  /// In vi, this message translates to:
  /// **'Món bạn kiêng không nằm trong loại đã chọn'**
  String get errDietConflictWithType;

  /// No description provided for @errFilterContradiction.
  ///
  /// In vi, this message translates to:
  /// **'Hai bộ lọc đang cãi nhau'**
  String get errFilterContradiction;

  /// No description provided for @errPoolTooSmall.
  ///
  /// In vi, this message translates to:
  /// **'Số món còn lại quá ít để quay'**
  String get errPoolTooSmall;

  /// No description provided for @errRateLimited.
  ///
  /// In vi, this message translates to:
  /// **'Bạn quay nhanh quá, chờ {seconds}s'**
  String errRateLimited(int seconds);

  /// No description provided for @errUnauthenticated.
  ///
  /// In vi, this message translates to:
  /// **'Phiên hết hạn. Đang thử lại.'**
  String get errUnauthenticated;

  /// No description provided for @errConsentRequired.
  ///
  /// In vi, this message translates to:
  /// **'Cần bạn đồng ý dùng vị trí mới tìm được quán'**
  String get errConsentRequired;

  /// No description provided for @errNotFound.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy'**
  String get errNotFound;

  /// No description provided for @errDishNotFound.
  ///
  /// In vi, this message translates to:
  /// **'Món này không còn trong kho'**
  String get errDishNotFound;

  /// No description provided for @errIdempotencyReplay.
  ///
  /// In vi, this message translates to:
  /// **'Đã ghi rồi, không tạo bản trùng'**
  String get errIdempotencyReplay;

  /// No description provided for @errRoomExpired.
  ///
  /// In vi, this message translates to:
  /// **'Phòng đã đóng'**
  String get errRoomExpired;

  /// No description provided for @errRoomUpdated.
  ///
  /// In vi, this message translates to:
  /// **'Phòng vừa thay đổi, đã cập nhật'**
  String get errRoomUpdated;

  /// No description provided for @errProviderUnavailable.
  ///
  /// In vi, this message translates to:
  /// **'Nguồn quán đang lỗi · dùng dữ liệu lưu'**
  String get errProviderUnavailable;

  /// No description provided for @errDegradedNoResult.
  ///
  /// In vi, this message translates to:
  /// **'Hiện chưa lấy được kết quả'**
  String get errDegradedNoResult;

  /// No description provided for @errReportLimit.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay bạn báo đủ 5 lần rồi'**
  String get errReportLimit;

  /// No description provided for @errReportDuplicate.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã báo rồi'**
  String get errReportDuplicate;

  /// No description provided for @errOutsideServiceArea.
  ///
  /// In vi, this message translates to:
  /// **'Khu này chưa có dữ liệu quán'**
  String get errOutsideServiceArea;

  /// No description provided for @errLocationRequired.
  ///
  /// In vi, this message translates to:
  /// **'Cho app biết bạn đang ở đâu'**
  String get errLocationRequired;

  /// No description provided for @errFutureDate.
  ///
  /// In vi, this message translates to:
  /// **'Không nhận ngày trong tương lai'**
  String get errFutureDate;

  /// No description provided for @errUnknown.
  ///
  /// In vi, this message translates to:
  /// **'Có gì đó không ổn'**
  String get errUnknown;

  /// No description provided for @errOff.
  ///
  /// In vi, this message translates to:
  /// **'Đã tắt cho phiên này'**
  String get errOff;

  /// No description provided for @filterGroupMeal.
  ///
  /// In vi, this message translates to:
  /// **'Bữa'**
  String get filterGroupMeal;

  /// No description provided for @filterGroupMoney.
  ///
  /// In vi, this message translates to:
  /// **'Tiền'**
  String get filterGroupMoney;

  /// No description provided for @filterGroupTypeRegion.
  ///
  /// In vi, this message translates to:
  /// **'Loại / Vùng'**
  String get filterGroupTypeRegion;

  /// No description provided for @filterGroupMoodParty.
  ///
  /// In vi, this message translates to:
  /// **'Tâm trạng / Số người'**
  String get filterGroupMoodParty;

  /// No description provided for @filterBudget.
  ///
  /// In vi, this message translates to:
  /// **'Ngân sách mỗi bữa'**
  String get filterBudget;

  /// No description provided for @filterPriceMax.
  ///
  /// In vi, this message translates to:
  /// **'Mức giá tối đa'**
  String get filterPriceMax;

  /// No description provided for @filterTemp.
  ///
  /// In vi, this message translates to:
  /// **'Nóng hay lạnh'**
  String get filterTemp;

  /// No description provided for @filterPartySize.
  ///
  /// In vi, this message translates to:
  /// **'Số người'**
  String get filterPartySize;

  /// No description provided for @filterAntiRepeat.
  ///
  /// In vi, this message translates to:
  /// **'Không lặp lại trong'**
  String get filterAntiRepeat;

  /// No description provided for @filterDaysN.
  ///
  /// In vi, this message translates to:
  /// **'{days} ngày'**
  String filterDaysN(int days);

  /// No description provided for @filterDaysOff.
  ///
  /// In vi, this message translates to:
  /// **'Tắt'**
  String get filterDaysOff;

  /// No description provided for @filterLockedHint.
  ///
  /// In vi, this message translates to:
  /// **'Đang khoá vòng quay'**
  String get filterLockedHint;

  /// No description provided for @filterDietTitle.
  ///
  /// In vi, this message translates to:
  /// **'Kiêng và dị ứng'**
  String get filterDietTitle;

  /// No description provided for @filterDietLockedHint.
  ///
  /// In vi, this message translates to:
  /// **'Ràng buộc đã lưu chỉ bỏ được trong phần Của bạn'**
  String get filterDietLockedHint;

  /// No description provided for @filterDietAdd.
  ///
  /// In vi, this message translates to:
  /// **'Thêm ràng buộc cho lượt này'**
  String get filterDietAdd;

  /// No description provided for @filterPoolLine.
  ///
  /// In vi, this message translates to:
  /// **'{initial} món, còn {remaining} sau kiêng và loại'**
  String filterPoolLine(int initial, int remaining);

  /// No description provided for @filterPoolRemoved.
  ///
  /// In vi, this message translates to:
  /// **'Bị loại: kiêng {diet} · thủ công {excluded} · khoá {locked} · bộ lọc {filters} · lặp lại {antiRepeat}'**
  String filterPoolRemoved(
    int diet,
    int excluded,
    int locked,
    int filters,
    int antiRepeat,
  );

  /// No description provided for @filterSeedDebug.
  ///
  /// In vi, this message translates to:
  /// **'client_seed (chỉ bản debug)'**
  String get filterSeedDebug;

  /// No description provided for @mealBreakfast.
  ///
  /// In vi, this message translates to:
  /// **'Sáng'**
  String get mealBreakfast;

  /// No description provided for @mealLunch.
  ///
  /// In vi, this message translates to:
  /// **'Trưa'**
  String get mealLunch;

  /// No description provided for @mealDinner.
  ///
  /// In vi, this message translates to:
  /// **'Chiều'**
  String get mealDinner;

  /// No description provided for @mealLateNight.
  ///
  /// In vi, this message translates to:
  /// **'Đêm'**
  String get mealLateNight;

  /// No description provided for @regionNorth.
  ///
  /// In vi, this message translates to:
  /// **'Bắc'**
  String get regionNorth;

  /// No description provided for @regionCentral.
  ///
  /// In vi, this message translates to:
  /// **'Trung'**
  String get regionCentral;

  /// No description provided for @regionSouth.
  ///
  /// In vi, this message translates to:
  /// **'Nam'**
  String get regionSouth;

  /// No description provided for @regionAll.
  ///
  /// In vi, this message translates to:
  /// **'Cả nước'**
  String get regionAll;

  /// No description provided for @tempHot.
  ///
  /// In vi, this message translates to:
  /// **'Nóng'**
  String get tempHot;

  /// No description provided for @tempWarm.
  ///
  /// In vi, this message translates to:
  /// **'Ấm'**
  String get tempWarm;

  /// No description provided for @tempCold.
  ///
  /// In vi, this message translates to:
  /// **'Lạnh'**
  String get tempCold;

  /// No description provided for @tempAny.
  ///
  /// In vi, this message translates to:
  /// **'Gì cũng được'**
  String get tempAny;

  /// No description provided for @moodComfort.
  ///
  /// In vi, this message translates to:
  /// **'Ăn no'**
  String get moodComfort;

  /// No description provided for @moodLight.
  ///
  /// In vi, this message translates to:
  /// **'Nhẹ bụng'**
  String get moodLight;

  /// No description provided for @moodGreedy.
  ///
  /// In vi, this message translates to:
  /// **'Hảo hám'**
  String get moodGreedy;

  /// No description provided for @moodFresh.
  ///
  /// In vi, this message translates to:
  /// **'Mát'**
  String get moodFresh;

  /// No description provided for @moodLocalSpecialty.
  ///
  /// In vi, this message translates to:
  /// **'Đặc sản'**
  String get moodLocalSpecialty;

  /// No description provided for @moodQuick.
  ///
  /// In vi, this message translates to:
  /// **'Nhanh'**
  String get moodQuick;

  /// No description provided for @typeNoodle.
  ///
  /// In vi, this message translates to:
  /// **'Món nước'**
  String get typeNoodle;

  /// No description provided for @typeRice.
  ///
  /// In vi, this message translates to:
  /// **'Cơm'**
  String get typeRice;

  /// No description provided for @typeBread.
  ///
  /// In vi, this message translates to:
  /// **'Bánh'**
  String get typeBread;

  /// No description provided for @typeSweet.
  ///
  /// In vi, this message translates to:
  /// **'Ngọt'**
  String get typeSweet;

  /// No description provided for @typeGrill.
  ///
  /// In vi, this message translates to:
  /// **'Nướng'**
  String get typeGrill;

  /// No description provided for @typeSalad.
  ///
  /// In vi, this message translates to:
  /// **'Rau / chay'**
  String get typeSalad;

  /// No description provided for @typeDrink.
  ///
  /// In vi, this message translates to:
  /// **'Đồ uống'**
  String get typeDrink;

  /// No description provided for @typeSnack.
  ///
  /// In vi, this message translates to:
  /// **'Ăn vặt'**
  String get typeSnack;

  /// No description provided for @dietVegetarian.
  ///
  /// In vi, this message translates to:
  /// **'Ăn chay'**
  String get dietVegetarian;

  /// No description provided for @dietVegan.
  ///
  /// In vi, this message translates to:
  /// **'Thuần chay'**
  String get dietVegan;

  /// No description provided for @dietHalal.
  ///
  /// In vi, this message translates to:
  /// **'Halal'**
  String get dietHalal;

  /// No description provided for @dietNoPork.
  ///
  /// In vi, this message translates to:
  /// **'Không heo'**
  String get dietNoPork;

  /// No description provided for @dietNoBeef.
  ///
  /// In vi, this message translates to:
  /// **'Không bò'**
  String get dietNoBeef;

  /// No description provided for @distanceMeters.
  ///
  /// In vi, this message translates to:
  /// **'{m} m'**
  String distanceMeters(int m);

  /// No description provided for @distanceKm.
  ///
  /// In vi, this message translates to:
  /// **'{km} km'**
  String distanceKm(Object km);

  /// No description provided for @priceVnd.
  ///
  /// In vi, this message translates to:
  /// **'{vnd}₫'**
  String priceVnd(String vnd);

  /// No description provided for @ratingValue.
  ///
  /// In vi, this message translates to:
  /// **'{rating}★'**
  String ratingValue(Object rating);

  /// No description provided for @ratingWithCount.
  ///
  /// In vi, this message translates to:
  /// **'{rating}★ từ {count} đánh giá'**
  String ratingWithCount(Object rating, int count);

  /// No description provided for @rawRatingHint.
  ///
  /// In vi, this message translates to:
  /// **'Trung bình thô {rating} (chưa trừ điểm quán ít đánh giá)'**
  String rawRatingHint(Object rating);

  /// No description provided for @whyHeadline.
  ///
  /// In vi, this message translates to:
  /// **'{rating}★ từ {count} đánh giá · cách {distance} m'**
  String whyHeadline(Object rating, int count, Object distance);

  /// No description provided for @whyQTop.
  ///
  /// In vi, this message translates to:
  /// **'Điểm cao nhờ {rating}★ từ {count} đánh giá'**
  String whyQTop(Object rating, int count);

  /// No description provided for @whyQFewReviews.
  ///
  /// In vi, this message translates to:
  /// **'Điểm chưa chắc vì mới {count} đánh giá'**
  String whyQFewReviews(int count);

  /// No description provided for @whyDTop.
  ///
  /// In vi, this message translates to:
  /// **'Cách bạn {distance} m'**
  String whyDTop(Object distance);

  /// No description provided for @whyPInBudget.
  ///
  /// In vi, this message translates to:
  /// **'{avg_price} nằm trong ngân sách {budget}'**
  String whyPInBudget(Object avg_price, Object budget);

  /// No description provided for @whyPNearBudget.
  ///
  /// In vi, this message translates to:
  /// **'{avg_price} sát ngân sách'**
  String whyPNearBudget(Object avg_price);

  /// No description provided for @whyOOpen45m.
  ///
  /// In vi, this message translates to:
  /// **'Còn mở {minutes} phút nữa'**
  String whyOOpen45m(int minutes);

  /// No description provided for @whyOClosingSoon.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ còn {minutes} phút nữa đóng'**
  String whyOClosingSoon(int minutes);

  /// No description provided for @whyUExplore.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chưa ăn ở đây, thử cho biết'**
  String get whyUExplore;

  /// No description provided for @whyWeights.
  ///
  /// In vi, this message translates to:
  /// **'Q {q}% · D {d}% · P {p}% · O {o}% · U {u}%'**
  String whyWeights(Object q, Object d, Object p, Object o, Object u);

  /// No description provided for @whyFormulaVersion.
  ///
  /// In vi, this message translates to:
  /// **'công thức {version}'**
  String whyFormulaVersion(Object version);

  /// No description provided for @whyPenalty.
  ///
  /// In vi, this message translates to:
  /// **'Trừ {value} điểm: {reason}'**
  String whyPenalty(Object value, Object reason);

  /// No description provided for @penaltyStaleVerification.
  ///
  /// In vi, this message translates to:
  /// **'Dữ liệu xác minh cũ {days} ngày'**
  String penaltyStaleVerification(int days);

  /// No description provided for @penaltyLowDataConfidence.
  ///
  /// In vi, this message translates to:
  /// **'Độ tin nguồn thấp'**
  String get penaltyLowDataConfidence;

  /// No description provided for @penaltyReported.
  ///
  /// In vi, this message translates to:
  /// **'Vừa bị báo sai, đang chờ kiểm'**
  String get penaltyReported;

  /// No description provided for @relaxRadius.
  ///
  /// In vi, this message translates to:
  /// **'Nới bán kính lên {to}'**
  String relaxRadius(Object to);

  /// No description provided for @relaxPrice.
  ///
  /// In vi, this message translates to:
  /// **'Nới mức giá lên {to}'**
  String relaxPrice(Object to);

  /// No description provided for @relaxDiet.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ một ràng buộc kiêng'**
  String get relaxDiet;

  /// No description provided for @substituteSimilarCategory.
  ///
  /// In vi, this message translates to:
  /// **'Cùng nhóm món'**
  String get substituteSimilarCategory;

  /// No description provided for @substituteSameMealSlot.
  ///
  /// In vi, this message translates to:
  /// **'Cùng khung bữa'**
  String get substituteSameMealSlot;

  /// No description provided for @urgentNearbyMatch.
  ///
  /// In vi, this message translates to:
  /// **'Hợp món bạn vừa quay'**
  String get urgentNearbyMatch;

  /// No description provided for @urgentNoneOpen.
  ///
  /// In vi, this message translates to:
  /// **'Chưa quán nào mở trong {radius} m'**
  String urgentNoneOpen(int radius);

  /// No description provided for @vetoTriedAndDisliked.
  ///
  /// In vi, this message translates to:
  /// **'Bạn từng chê món này'**
  String get vetoTriedAndDisliked;

  /// No description provided for @grpTieSpun.
  ///
  /// In vi, this message translates to:
  /// **'Hoà phiếu, quay quyết định'**
  String get grpTieSpun;

  /// No description provided for @promptRateAfterVisit.
  ///
  /// In vi, this message translates to:
  /// **'Quán này thế nào?'**
  String get promptRateAfterVisit;

  /// No description provided for @budgetNearLimit.
  ///
  /// In vi, this message translates to:
  /// **'Sắp hết ngân sách tuần'**
  String get budgetNearLimit;

  /// No description provided for @urgentDecision.
  ///
  /// In vi, this message translates to:
  /// **'Đã mở rộng tới {radius} km · đã xét {count} quán'**
  String urgentDecision(Object radius, int count);

  /// No description provided for @urgentHeading.
  ///
  /// In vi, this message translates to:
  /// **'Gần nhất và đang mở'**
  String get urgentHeading;

  /// No description provided for @alternativesHeading.
  ///
  /// In vi, this message translates to:
  /// **'Còn hai lựa chọn khác'**
  String get alternativesHeading;

  /// No description provided for @altClosing.
  ///
  /// In vi, this message translates to:
  /// **'Cách {distance} m, đóng trong {minutes} phút'**
  String altClosing(Object distance, Object minutes);

  /// No description provided for @altOpenLater.
  ///
  /// In vi, this message translates to:
  /// **'Mở lúc {opens_at}, cách {distance} m'**
  String altOpenLater(Object opens_at, Object distance);

  /// No description provided for @altFarther.
  ///
  /// In vi, this message translates to:
  /// **'Cách {distance} m, còn mở {minutes} phút'**
  String altFarther(Object distance, Object minutes);

  /// No description provided for @amenityParking.
  ///
  /// In vi, this message translates to:
  /// **'Có chỗ để xe'**
  String get amenityParking;

  /// No description provided for @amenityAc.
  ///
  /// In vi, this message translates to:
  /// **'Máy lạnh'**
  String get amenityAc;

  /// No description provided for @amenityGroupFriendly.
  ///
  /// In vi, this message translates to:
  /// **'Nhóm đông được'**
  String get amenityGroupFriendly;

  /// No description provided for @amenityTakeaway.
  ///
  /// In vi, this message translates to:
  /// **'Mua mang đi'**
  String get amenityTakeaway;

  /// No description provided for @amenityWifi.
  ///
  /// In vi, this message translates to:
  /// **'Wi-Fi'**
  String get amenityWifi;

  /// No description provided for @detailHours.
  ///
  /// In vi, this message translates to:
  /// **'Giờ mở'**
  String get detailHours;

  /// No description provided for @detailMenu.
  ///
  /// In vi, this message translates to:
  /// **'Thực đơn'**
  String get detailMenu;

  /// No description provided for @detailPhotos.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh'**
  String get detailPhotos;

  /// No description provided for @detailReviewSplit.
  ///
  /// In vi, this message translates to:
  /// **'{good} khen · {ok} bình thường · {bad} chê'**
  String detailReviewSplit(int good, int ok, int bad);

  /// No description provided for @detailCall.
  ///
  /// In vi, this message translates to:
  /// **'Gọi'**
  String get detailCall;

  /// No description provided for @detailBook.
  ///
  /// In vi, this message translates to:
  /// **'Đặt bàn'**
  String get detailBook;

  /// No description provided for @detailDelivery.
  ///
  /// In vi, this message translates to:
  /// **'Giao tận nơi'**
  String get detailDelivery;

  /// No description provided for @detailCredit.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh: {credit}'**
  String detailCredit(Object credit);

  /// No description provided for @detailReportCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} báo sai trong 30 ngày, {pending} đang chờ'**
  String detailReportCount(int count, int pending);

  /// No description provided for @reportSheetTitle.
  ///
  /// In vi, this message translates to:
  /// **'Báo sai thông tin'**
  String get reportSheetTitle;

  /// No description provided for @reportKindClosed.
  ///
  /// In vi, this message translates to:
  /// **'Quán đã đóng'**
  String get reportKindClosed;

  /// No description provided for @reportKindWrongHours.
  ///
  /// In vi, this message translates to:
  /// **'Giờ sai'**
  String get reportKindWrongHours;

  /// No description provided for @reportKindWrongPrice.
  ///
  /// In vi, this message translates to:
  /// **'Giá sai'**
  String get reportKindWrongPrice;

  /// No description provided for @reportKindWrongLocation.
  ///
  /// In vi, this message translates to:
  /// **'Vị trí sai'**
  String get reportKindWrongLocation;

  /// No description provided for @reportKindWrongName.
  ///
  /// In vi, this message translates to:
  /// **'Tên sai'**
  String get reportKindWrongName;

  /// No description provided for @reportKindDuplicate.
  ///
  /// In vi, this message translates to:
  /// **'Trùng quán'**
  String get reportKindDuplicate;

  /// No description provided for @reportKindOther.
  ///
  /// In vi, this message translates to:
  /// **'Khác'**
  String get reportKindOther;

  /// No description provided for @reportDetailHint.
  ///
  /// In vi, this message translates to:
  /// **'Viết thêm nếu cần (tối đa 500 ký tự)'**
  String get reportDetailHint;

  /// No description provided for @reportCooldown.
  ///
  /// In vi, this message translates to:
  /// **'Chờ {seconds}s để báo tiếp'**
  String reportCooldown(int seconds);

  /// No description provided for @onboardStep1Title.
  ///
  /// In vi, this message translates to:
  /// **'Bạn ăn ở đâu?'**
  String get onboardStep1Title;

  /// No description provided for @onboardStep1Body.
  ///
  /// In vi, this message translates to:
  /// **'Chọn vị trí hoặc nhập địa chỉ. Từ chối định vị vẫn dùng được.'**
  String get onboardStep1Body;

  /// No description provided for @onboardStep2Title.
  ///
  /// In vi, this message translates to:
  /// **'Kiêng gì không?'**
  String get onboardStep2Title;

  /// No description provided for @onboardStep2Body.
  ///
  /// In vi, this message translates to:
  /// **'Ràng buộc cứng chỉ thêm, không tắt từ màn quay.'**
  String get onboardStep2Body;

  /// No description provided for @onboardStep3Title.
  ///
  /// In vi, this message translates to:
  /// **'Ngân sách một bữa?'**
  String get onboardStep3Title;

  /// No description provided for @onboardStep3Body.
  ///
  /// In vi, this message translates to:
  /// **'Dùng để tính điểm hợp túi tiền.'**
  String get onboardStep3Body;

  /// No description provided for @onboardDone.
  ///
  /// In vi, this message translates to:
  /// **'Xong, quay thôi'**
  String get onboardDone;

  /// No description provided for @settingsTheme.
  ///
  /// In vi, this message translates to:
  /// **'Sáng tối'**
  String get settingsTheme;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In vi, this message translates to:
  /// **'Theo máy'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In vi, this message translates to:
  /// **'Sáng'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In vi, this message translates to:
  /// **'Tối'**
  String get settingsThemeDark;

  /// No description provided for @settingsLanguage.
  ///
  /// In vi, this message translates to:
  /// **'Ngôn ngữ'**
  String get settingsLanguage;

  /// No description provided for @settingsReduceMotion.
  ///
  /// In vi, this message translates to:
  /// **'Giảm chuyển động'**
  String get settingsReduceMotion;

  /// No description provided for @settingsReduceMotionHint.
  ///
  /// In vi, this message translates to:
  /// **'Tắt vòng quay, hiện kết quả ngay'**
  String get settingsReduceMotionHint;

  /// No description provided for @settingsSound.
  ///
  /// In vi, this message translates to:
  /// **'Âm thanh'**
  String get settingsSound;

  /// No description provided for @settingsSoundHint.
  ///
  /// In vi, this message translates to:
  /// **'Tiếng khi bánh dừng'**
  String get settingsSoundHint;

  /// No description provided for @settingsHaptics.
  ///
  /// In vi, this message translates to:
  /// **'Rung'**
  String get settingsHaptics;

  /// No description provided for @settingsHapticsHint.
  ///
  /// In vi, this message translates to:
  /// **'Rung nhẹ khi chốt kết quả'**
  String get settingsHapticsHint;

  /// No description provided for @settingsMotionSection.
  ///
  /// In vi, this message translates to:
  /// **'Chuyển động & âm thanh'**
  String get settingsMotionSection;

  /// No description provided for @proofCopy.
  ///
  /// In vi, this message translates to:
  /// **'Sao chép'**
  String get proofCopy;

  /// No description provided for @proofCopied.
  ///
  /// In vi, this message translates to:
  /// **'Đã sao chép'**
  String get proofCopied;

  /// No description provided for @settingsHighContrast.
  ///
  /// In vi, this message translates to:
  /// **'Tương phản cao'**
  String get settingsHighContrast;

  /// No description provided for @settingsLocation.
  ///
  /// In vi, this message translates to:
  /// **'Vị trí'**
  String get settingsLocation;

  /// No description provided for @settingsProof.
  ///
  /// In vi, this message translates to:
  /// **'Kiểm chứng lần quay'**
  String get settingsProof;

  /// No description provided for @settingsProofSeed.
  ///
  /// In vi, this message translates to:
  /// **'seed {seed}'**
  String settingsProofSeed(Object seed);

  /// No description provided for @settingsProofHash.
  ///
  /// In vi, this message translates to:
  /// **'sha256 {hash}'**
  String settingsProofHash(Object hash);

  /// No description provided for @settingsLocationChanged.
  ///
  /// In vi, this message translates to:
  /// **'Vị trí thay đổi · Cập nhật?'**
  String get settingsLocationChanged;

  /// No description provided for @settingsForceUpgrade.
  ///
  /// In vi, this message translates to:
  /// **'Bản app này quá cũ, cập nhật để tiếp tục'**
  String get settingsForceUpgrade;

  /// No description provided for @semSpinButton.
  ///
  /// In vi, this message translates to:
  /// **'Quay món'**
  String get semSpinButton;

  /// No description provided for @semRowLabel.
  ///
  /// In vi, this message translates to:
  /// **'{name}, cách {distance} mét, {rating} điểm, {openState}'**
  String semRowLabel(
    Object name,
    int distance,
    Object rating,
    Object openState,
  );

  /// No description provided for @semOpen.
  ///
  /// In vi, this message translates to:
  /// **'đang mở'**
  String get semOpen;

  /// No description provided for @semClosingSoon.
  ///
  /// In vi, this message translates to:
  /// **'sắp đóng'**
  String get semClosingSoon;

  /// No description provided for @semClosed.
  ///
  /// In vi, this message translates to:
  /// **'đã đóng'**
  String get semClosed;

  /// No description provided for @semWheelUnfocusable.
  ///
  /// In vi, this message translates to:
  /// **'Vòng quay chỉ minh hoạ, kết quả đã có bên dưới'**
  String get semWheelUnfocusable;

  /// No description provided for @semDisabledHint.
  ///
  /// In vi, this message translates to:
  /// **'Không bấm được: {reason}'**
  String semDisabledHint(Object reason);

  /// No description provided for @hubQuestion.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay ăn gì?'**
  String get hubQuestion;

  /// No description provided for @hubSub.
  ///
  /// In vi, this message translates to:
  /// **'Quay một cái, khỏi nghĩ.'**
  String get hubSub;

  /// No description provided for @hubWheelHint.
  ///
  /// In vi, this message translates to:
  /// **'Tám nhóm món, một cú quay.'**
  String get hubWheelHint;

  /// No description provided for @hubFilterSummary.
  ///
  /// In vi, this message translates to:
  /// **'{count} bộ lọc đang bật'**
  String hubFilterSummary(Object count);

  /// No description provided for @hubFilterNone.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có bộ lọc'**
  String get hubFilterNone;

  /// No description provided for @hubLocationMissing.
  ///
  /// In vi, this message translates to:
  /// **'Chọn chỗ bạn đang đứng'**
  String get hubLocationMissing;

  /// No description provided for @hubLocationDemo.
  ///
  /// In vi, this message translates to:
  /// **'Chạm để đổi vị trí'**
  String get hubLocationDemo;

  /// No description provided for @matchCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} quán gần bạn'**
  String matchCount(Object count);

  /// No description provided for @matchNote.
  ///
  /// In vi, this message translates to:
  /// **'Xếp theo độ hợp với bạn'**
  String get matchNote;

  /// No description provided for @matchBack.
  ///
  /// In vi, this message translates to:
  /// **'Về quay'**
  String get matchBack;

  /// No description provided for @whyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Vì sao gợi ý quán này?'**
  String get whyTitle;

  /// No description provided for @whyPenaltyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Điểm bị trừ'**
  String get whyPenaltyTitle;

  /// No description provided for @whyContribution.
  ///
  /// In vi, this message translates to:
  /// **'+{value}'**
  String whyContribution(Object value);

  /// No description provided for @filterTitle.
  ///
  /// In vi, this message translates to:
  /// **'Bộ lọc'**
  String get filterTitle;

  /// No description provided for @filterReset.
  ///
  /// In vi, this message translates to:
  /// **'Xoá hết'**
  String get filterReset;

  /// No description provided for @filterLock.
  ///
  /// In vi, this message translates to:
  /// **'Khoá {type}'**
  String filterLock(Object type);

  /// No description provided for @filterUnlock.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ khoá'**
  String get filterUnlock;

  /// No description provided for @filterLockHint.
  ///
  /// In vi, this message translates to:
  /// **'Khoá một loại, quay phần còn lại.'**
  String get filterLockHint;

  /// No description provided for @detailAddress.
  ///
  /// In vi, this message translates to:
  /// **'Địa chỉ'**
  String get detailAddress;

  /// No description provided for @detailAmenities.
  ///
  /// In vi, this message translates to:
  /// **'Tiện ích'**
  String get detailAmenities;

  /// No description provided for @detailSimilar.
  ///
  /// In vi, this message translates to:
  /// **'Quán tương tự'**
  String get detailSimilar;

  /// No description provided for @detailToday.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay'**
  String get detailToday;

  /// No description provided for @detailClosedDay.
  ///
  /// In vi, this message translates to:
  /// **'Nghỉ'**
  String get detailClosedDay;

  /// No description provided for @detailOpen.
  ///
  /// In vi, this message translates to:
  /// **'Đang mở'**
  String get detailOpen;

  /// No description provided for @detailPrice.
  ///
  /// In vi, this message translates to:
  /// **'Giá trung bình'**
  String get detailPrice;

  /// No description provided for @detailDistance.
  ///
  /// In vi, this message translates to:
  /// **'Cách bạn'**
  String get detailDistance;

  /// No description provided for @detailReviews.
  ///
  /// In vi, this message translates to:
  /// **'{count} đánh giá'**
  String detailReviews(Object count);

  /// No description provided for @discoverTitle.
  ///
  /// In vi, this message translates to:
  /// **'Quanh bạn'**
  String get discoverTitle;

  /// No description provided for @discoverRadius.
  ///
  /// In vi, this message translates to:
  /// **'Trong {radius}'**
  String discoverRadius(Object radius);

  /// No description provided for @youTitle.
  ///
  /// In vi, this message translates to:
  /// **'Của bạn'**
  String get youTitle;

  /// No description provided for @youGuest.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đang dùng khách'**
  String get youGuest;

  /// No description provided for @youProofEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có lần quay nào'**
  String get youProofEmpty;

  /// No description provided for @youVersion.
  ///
  /// In vi, this message translates to:
  /// **'Bản {version}'**
  String youVersion(Object version);

  /// No description provided for @urgentOneTap.
  ///
  /// In vi, this message translates to:
  /// **'Một chạm, đi luôn.'**
  String get urgentOneTap;

  /// No description provided for @reportKindLabel.
  ///
  /// In vi, this message translates to:
  /// **'Chuyện gì sai?'**
  String get reportKindLabel;

  /// No description provided for @reportSubmit.
  ///
  /// In vi, this message translates to:
  /// **'Gửi báo sai'**
  String get reportSubmit;

  /// No description provided for @visitSaved.
  ///
  /// In vi, this message translates to:
  /// **'Đã ghi vào nhật ký'**
  String get visitSaved;

  /// No description provided for @loading.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải'**
  String get loading;

  /// No description provided for @languageVi.
  ///
  /// In vi, this message translates to:
  /// **'Tiếng Việt'**
  String get languageVi;

  /// No description provided for @languageEn.
  ///
  /// In vi, this message translates to:
  /// **'English'**
  String get languageEn;

  /// No description provided for @themeLabel.
  ///
  /// In vi, this message translates to:
  /// **'Giao diện'**
  String get themeLabel;

  /// No description provided for @onboardSkipHint.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ qua được, chỉnh sau trong Của bạn.'**
  String get onboardSkipHint;

  /// No description provided for @onboardAddressHint.
  ///
  /// In vi, this message translates to:
  /// **'Nhập địa chỉ của bạn'**
  String get onboardAddressHint;

  /// No description provided for @onboardAddressPick.
  ///
  /// In vi, this message translates to:
  /// **'Hoặc chọn nhanh'**
  String get onboardAddressPick;

  /// No description provided for @budgetPerMeal.
  ///
  /// In vi, this message translates to:
  /// **'{vnd} mỗi bữa'**
  String budgetPerMeal(Object vnd);

  /// No description provided for @matchDishLabel.
  ///
  /// In vi, this message translates to:
  /// **'Món hôm nay'**
  String get matchDishLabel;

  /// No description provided for @detailReported.
  ///
  /// In vi, this message translates to:
  /// **'Báo sai cho quán này'**
  String get detailReported;

  /// No description provided for @detailCallNow.
  ///
  /// In vi, this message translates to:
  /// **'Gọi quán'**
  String get detailCallNow;

  /// No description provided for @actionClose.
  ///
  /// In vi, this message translates to:
  /// **'Đóng'**
  String get actionClose;

  /// No description provided for @spinOfflineNote.
  ///
  /// In vi, this message translates to:
  /// **'Không có mạng, vẫn quay được.'**
  String get spinOfflineNote;

  /// No description provided for @wheelIdleHint.
  ///
  /// In vi, this message translates to:
  /// **'Chạm Quay để bắt đầu'**
  String get wheelIdleHint;

  /// No description provided for @hubStamp.
  ///
  /// In vi, this message translates to:
  /// **'QUAY LÀ RA'**
  String get hubStamp;

  /// No description provided for @viewPlaces.
  ///
  /// In vi, this message translates to:
  /// **'Xem quán'**
  String get viewPlaces;

  /// No description provided for @detailHoursToday.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay mở {from} tới {to}'**
  String detailHoursToday(Object from, Object to);

  /// No description provided for @filterBudgetOff.
  ///
  /// In vi, this message translates to:
  /// **'Không giới hạn'**
  String get filterBudgetOff;

  /// No description provided for @priceLevel1.
  ///
  /// In vi, this message translates to:
  /// **'≤ 25k'**
  String get priceLevel1;

  /// No description provided for @priceLevel2.
  ///
  /// In vi, this message translates to:
  /// **'25–50k'**
  String get priceLevel2;

  /// No description provided for @priceLevel3.
  ///
  /// In vi, this message translates to:
  /// **'50–150k'**
  String get priceLevel3;

  /// No description provided for @priceLevel4.
  ///
  /// In vi, this message translates to:
  /// **'> 150k'**
  String get priceLevel4;

  /// No description provided for @filterLockedChip.
  ///
  /// In vi, this message translates to:
  /// **'Khoá {type}'**
  String filterLockedChip(Object type);

  /// No description provided for @whyShort.
  ///
  /// In vi, this message translates to:
  /// **'Vì sao'**
  String get whyShort;

  /// No description provided for @matchClose.
  ///
  /// In vi, this message translates to:
  /// **'Đóng kết quả'**
  String get matchClose;
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  Future<S> load(Locale locale) {
    return SynchronousFuture<S>(lookupS(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_SDelegate old) => false;
}

S lookupS(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return SEn();
    case 'vi':
      return SVi();
  }

  throw FlutterError(
    'S.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
