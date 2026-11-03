/// `X-Data-Quality` / `meta.data_quality` (docs/01 §4.3, FR-PLC-08).
enum DataQuality {
  fresh,
  cached,
  stale,
  providerDegraded,
  offlineBundle;

  static DataQuality parse(String? raw) {
    switch (raw) {
      case 'cached':
        return DataQuality.cached;
      case 'stale':
        return DataQuality.stale;
      case 'provider_degraded':
        return DataQuality.providerDegraded;
      case 'offline_bundle':
        return DataQuality.offlineBundle;
      default:
        return DataQuality.fresh;
    }
  }

  /// Header vắng ⇒ `null` (không được phép đè `fresh` lên `meta` của body).
  static DataQuality? parseOrNull(String? raw) {
    if (raw == null) return null;
    return parse(raw);
  }

  String get wireValue {
    switch (this) {
      case DataQuality.providerDegraded:
        return 'provider_degraded';
      case DataQuality.offlineBundle:
        return 'offline_bundle';
      default:
        return name;
    }
  }

  bool get isSilent => this == DataQuality.fresh;
}
