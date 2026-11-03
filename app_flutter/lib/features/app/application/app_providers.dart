import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../bootstrap.dart';
import '../../../core/api/models/config.dart';
import '../../../core/api/models/misc.dart';
import '../../../core/config/feature_flags.dart';
import '../../../core/config/remote_config.dart';
import '../../../core/geo/anchor_store.dart';
import '../../../core/telemetry/analytics.dart';

/// Provider đọc thẳng singleton đã đăng ký trong `bootstrap()` (get_it).
final configProvider = ChangeNotifierProvider<ConfigService>((ref) => sl<ConfigService>());

final analyticsProvider = Provider<Analytics>((ref) => sl<Analytics>());

/// `AppConfig` đang sống: safe defaults cho tới khi `/v1/config` về.
final appConfigProvider = Provider<AppConfig>((ref) {
  final service = ref.watch(configProvider);
  return service.config;
});

final featureFlagsProvider = Provider<FeatureFlags>((ref) => FeatureFlags(ref.watch(appConfigProvider)));

/// Anchor hiện hành. Đổi ⇒ UI phải hỏi re-query chứ không tự nhảy (spec §Edge cases).
final anchorProvider = StateProvider<Anchor>((ref) => sl<AnchorStore>().read());

/// Cài đặt người dùng, persist máy-local. Không phải dữ liệu tài khoản: khách vẫn có.
class AppSettings extends ChangeNotifier {
  AppSettings(this._prefs) : _value = _read(_prefs);

  static const String _kSettings = 'angi.settings';
  static const String _kOnboarded = 'angi.onboarded';

  final SharedPreferences _prefs;
  UserSettings _value;

  UserSettings get value => _value;

  ThemeMode get themeMode => switch (_value.theme) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  Locale get locale => Locale(_value.locale);

  bool get onboarded => _prefs.getBool(_kOnboarded) ?? false;

  Future<void> setOnboarded() async {
    await _prefs.setBool(_kOnboarded, true);
  }

  Future<void> setTheme(String theme) async {
    _value = UserSettings(
      theme: theme,
      locale: _value.locale,
      fontScale: _value.fontScale,
      reduceMotion: _value.reduceMotion,
      sound: _value.sound,
      haptics: _value.haptics,
      animationStyle: _value.animationStyle,
    );
    await _persist();
  }

  Future<void> setLocale(String locale) async {
    _value = UserSettings(
      theme: _value.theme,
      locale: locale,
      fontScale: _value.fontScale,
      reduceMotion: _value.reduceMotion,
      sound: _value.sound,
      haptics: _value.haptics,
      animationStyle: _value.animationStyle,
    );
    await _persist();
  }

  Future<void> setReduceMotion(bool value) async {
    _value = UserSettings(
      theme: _value.theme,
      locale: _value.locale,
      fontScale: _value.fontScale,
      reduceMotion: value,
      sound: _value.sound,
      haptics: _value.haptics,
      animationStyle: _value.animationStyle,
    );
    await _persist();
  }

  Future<void> setSound(bool value) async {
    _value = UserSettings(
      theme: _value.theme,
      locale: _value.locale,
      fontScale: _value.fontScale,
      reduceMotion: _value.reduceMotion,
      sound: value,
      haptics: _value.haptics,
      animationStyle: _value.animationStyle,
    );
    await _persist();
  }

  Future<void> setHaptics(bool value) async {
    _value = UserSettings(
      theme: _value.theme,
      locale: _value.locale,
      fontScale: _value.fontScale,
      reduceMotion: _value.reduceMotion,
      sound: _value.sound,
      haptics: value,
      animationStyle: _value.animationStyle,
    );
    await _persist();
  }

  Future<void> _persist() async {
    notifyListeners();
    await _prefs.setString(_kSettings, jsonEncode(_value.toJson()));
  }

  static UserSettings _read(SharedPreferences prefs) {
    final raw = prefs.getString(_kSettings);
    if (raw == null || raw.isEmpty) return const UserSettings();
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? UserSettings.fromJson(decoded) : const UserSettings();
    } catch (_) {
      return const UserSettings();
    }
  }
}

final settingsProvider = ChangeNotifierProvider<AppSettings>((ref) => AppSettings(sl<SharedPreferences>()));

final themeModeProvider = Provider<ThemeMode>((ref) => ref.watch(settingsProvider).themeMode);
