import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

enum AppEdition { personal, organization }

extension AppEditionLabel on AppEdition {
  String get label => switch (this) {
    AppEdition.personal => 'บุคคลทั่วไป',
    AppEdition.organization => 'องค์กร',
  };

  String get description => switch (this) {
    AppEdition.personal =>
      'ตารางเวรส่วนตัว รายเดือน รายงาน และ Google Calendar',
    AppEdition.organization => 'รายชื่อ บุคลากร แลกเวร บทบาท และ Admin Console',
  };
}

class AppEditionRepository {
  AppEditionRepository([this._preferences]);

  static const storageKey = 'shift_tools.app_edition.v1';
  static const _storageTimeout = Duration(seconds: 6);
  SharedPreferences? _preferences;

  Future<SharedPreferences> get _store async =>
      _preferences ??= await SharedPreferences.getInstance().timeout(
        _storageTimeout,
      );

  Future<AppEdition?> load() async {
    try {
      final value = (await _store).getString(storageKey);
      if (value == null) return null;
      return AppEdition.values
          .where((edition) => edition.name == value)
          .firstOrNull;
    } on TimeoutException {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> save(AppEdition edition) async {
    final store = await _store;
    await store.setString(storageKey, edition.name).timeout(_storageTimeout);
  }
}
