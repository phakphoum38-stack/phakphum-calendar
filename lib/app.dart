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
    if (ownsController) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFF0F5F5C);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Phakphum Calendar v4.1',
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFF4F7F7),
        appBarTheme: AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 1,
          centerTitle: false,
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.onSurface,
          surfaceTintColor: Colors.transparent,
        ),
        navigationRailTheme: NavigationRailThemeData(
          backgroundColor: colorScheme.surface,
          indicatorColor: colorScheme.primaryContainer,
          selectedIconTheme: IconThemeData(
            color: colorScheme.onPrimaryContainer,
          ),
          selectedLabelTextStyle: TextStyle(
            color: colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          height: 72,
          elevation: 0,
          backgroundColor: colorScheme.surface,
          indicatorColor: colorScheme.primaryContainer,
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          color: colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 48),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 48),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: colorScheme.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: colorScheme.outlineVariant),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: colorScheme.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: colorScheme.primary, width: 2),
          ),
        ),
        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        dividerTheme: DividerThemeData(
          color: colorScheme.outlineVariant,
          thickness: 1,
        ),
      ),
      home: AppShell(controller: controller),
    );
  }
}
