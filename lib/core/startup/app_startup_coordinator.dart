import 'dart:async';

/// Outcome of one application startup operation.
enum AppStartupStatus { ready, degraded, failed }

/// Immutable result returned by [AppStartupCoordinator].
class AppStartupResult {
  const AppStartupResult({
    required this.status,
    this.message,
    this.error,
  });

  final AppStartupStatus status;
  final String? message;
  final Object? error;

  bool get canOpenApp => status != AppStartupStatus.failed;
}

/// Runs startup work with a bounded timeout and a degraded-mode fallback.
///
/// Features should provide their initialization callback instead of putting
/// provider-specific startup logic in widgets or `main.dart`.
class AppStartupCoordinator {
  const AppStartupCoordinator({
    this.timeout = const Duration(seconds: 12),
  });

  final Duration timeout;

  Future<AppStartupResult> start(Future<void> Function() initialize) async {
    try {
      await initialize().timeout(timeout);
      return const AppStartupResult(status: AppStartupStatus.ready);
    } on TimeoutException catch (error) {
      return AppStartupResult(
        status: AppStartupStatus.degraded,
        message: 'เริ่มต้นบางบริการไม่ทันเวลา แอพจะเปิดในโหมดจำกัด',
        error: error,
      );
    } catch (error) {
      return AppStartupResult(
        status: AppStartupStatus.degraded,
        message: 'เริ่มต้นบางบริการไม่สำเร็จ แอพจะเปิดในโหมดจำกัด',
        error: error,
      );
    }
  }
}
