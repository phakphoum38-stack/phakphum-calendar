import 'package:flutter/material.dart';

import '../app.dart';

/// Production entrypoint for constructing and starting the Flutter application.
///
/// Keeping platform startup here prevents `main.dart` from becoming a second
/// composition root as the application grows.
void runShiftToolsApp() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ShiftToolsApp());
}
