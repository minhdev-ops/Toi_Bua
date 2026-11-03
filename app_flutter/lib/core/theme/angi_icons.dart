import 'package:flutter/material.dart';

/// Họ icon đã chốt là **Material Symbols Rounded** (DESIGN.md §Iconography). Font chưa
/// vendored vào pubspec nên P1 ánh xạ sang MaterialIcons có sẵn trong SDK; khi thêm
/// `MaterialSymbolsRounded.ttf` chỉ cần sửa bảng này, không đổi tên ngữ nghĩa ở widget.
abstract final class AngiIcons {
  static const IconData scheduleOpen = Icons.schedule;
  static const IconData timerAlert = Icons.timer_outlined;
  static const IconData storeOff = Icons.storefront_outlined;
  static const IconData eventBusy = Icons.event_busy;
  static const IconData warning = Icons.warning_amber_rounded;
  static const IconData offline = Icons.cloud_off;
  static const IconData cached = Icons.download_for_offline_outlined;
  static const IconData stale = Icons.update_disabled;
  static const IconData close = Icons.close;
  static const IconData chevronRight = Icons.chevron_right;
  static const IconData chevronLeft = Icons.chevron_left;
  static const IconData retry = Icons.refresh;
  static const IconData navigate = Icons.near_me;
  static const IconData why = Icons.help_outline;
  static const IconData bestMatch = Icons.verified;
  static const IconData bolt = Icons.bolt;
  static const IconData boltOutlined = Icons.bolt_outlined;
  static const IconData place = Icons.place;
  static const IconData tune = Icons.tune;
  static const IconData lock = Icons.lock_outline;
  static const IconData lockOpen = Icons.lock_open;
  static const IconData star = Icons.star_rounded;
  static const IconData call = Icons.call_outlined;
  static const IconData directions = Icons.directions_walk;
  static const IconData save = Icons.bookmark_add_outlined;
  static const IconData saved = Icons.bookmark_added;
  static const IconData report = Icons.flag_outlined;
  static const IconData check = Icons.check;
  static const IconData camera = Icons.photo_camera_outlined;
  static const IconData parking = Icons.local_parking;
  static const IconData ac = Icons.ac_unit;
  static const IconData group = Icons.groups_outlined;
  static const IconData takeaway = Icons.takeout_dining_outlined;
  static const IconData wifi = Icons.wifi;
  static const IconData phone = Icons.phone_outlined;
  static const IconData menuBook = Icons.menu_book_outlined;
  static const IconData sun = Icons.light_mode_outlined;
  static const IconData moon = Icons.dark_mode_outlined;
  static const IconData auto = Icons.brightness_auto_outlined;
  static const IconData leaf = Icons.eco_outlined;
  static const IconData wallet = Icons.account_balance_wallet_outlined;

  /// weight 600 / size 24 là chuẩn đã khoá (20 trong dòng chữ, 32 trong stamp).
  static const double size = 24;
  static const double sizeInline = 20;
  static const double sizeStamp = 32;
  static const FontWeight weight = FontWeight.w600;
}
