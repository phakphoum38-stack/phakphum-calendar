import 'package:flutter/material.dart';

import 'controller/app_controller.dart';
import 'ui/app_shell.dart';

class PhakphumCalendarApp extends StatefulWidget {
  const PhakphumCalendarApp({super.key, this.controller});

  final AppController? controller;

  @override
  State<PhakphumCalendarApp> createState() => _PhakphumCalendarAppState();
}

class _PhakphumCalendarAppState extends State<PhakphumCalendarApp> {
  late final AppController controller = widget.controller ?? AppController();
  late final bool ownsController = widget.controller == null;

  @override
  void initState() {
    super.initState();
    controller.initialize();
  }

  @override
  void dispose() {
    if (ownsController) controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Phakphum Shift Calendar',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF155EEF),
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF7F8FC),
      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          side: BorderSide(color: Color(0xFFE2E5EC)),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
      ),
    ),
    home: AppShell(controller: controller),
  );
}
