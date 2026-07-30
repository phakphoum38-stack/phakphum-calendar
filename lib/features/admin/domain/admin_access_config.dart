import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../access_control/domain/access_control.dart';

class AdminUserAccess {
  const AdminUserAccess({required this.email, required this.role});

  final String email;
  final StaffRole role;
}

class AdminAccessConfig {
  const AdminAccessConfig({required this.users});

  const AdminAccessConfig.empty() : users = const [];

  final List<AdminUserAccess> users;

  bool get isConfigured => users.any((user) => user.role == StaffRole.admin);

  StaffRole roleFor(String? email) {
    final normalized = email?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return StaffRole.staff;
    return users
            .where((user) => user.email.toLowerCase() == normalized)
            .firstOrNull
            ?.role ??
        StaffRole.staff;
  }

  bool isAdmin(String? email) => roleFor(email) == StaffRole.admin;
}

class AdminAccessRepository {
  AdminAccessRepository([this._preferences]);

  static const storageKey = 'shift_tools.admin_access.v1';
  SharedPreferences? _preferences;

  Future<SharedPreferences> get _store async =>
      _preferences ??= await SharedPreferences.getInstance();

  Future<AdminAccessConfig> load() async {
    final source = (await _store).getString(storageKey);
    if (source == null) return const AdminAccessConfig.empty();
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic> ||
        decoded['formatVersion'] != 1 ||
        decoded['users'] is! List) {
      throw const FormatException('ข้อมูลสิทธิ์ Admin ไม่ถูกต้อง');
    }
    return AdminAccessConfig(
      users: List.unmodifiable(
        (decoded['users'] as List).map((raw) {
          if (raw is! Map<String, dynamic> ||
              raw['email'] is! String ||
              raw['role'] is! String) {
            throw const FormatException('ข้อมูลผู้ใช้ Admin ไม่ครบ');
          }
          final role = StaffRole.values
              .where((value) => value.name == raw['role'])
              .firstOrNull;
          if (role == null) {
            throw const FormatException('บทบาทผู้ใช้ไม่ถูกต้อง');
          }
          return AdminUserAccess(
            email: (raw['email'] as String).trim().toLowerCase(),
            role: role,
          );
        }),
      ),
    );
  }

  Future<void> save(AdminAccessConfig config) async {
    if (!config.isConfigured) {
      throw StateError('ต้องมี Admin อย่างน้อยหนึ่งบัญชี');
    }
    await (await _store).setString(
      storageKey,
      jsonEncode({
        'formatVersion': 1,
        'users': [
          for (final user in config.users)
            {'email': user.email.toLowerCase(), 'role': user.role.name},
        ],
      }),
    );
  }
}
