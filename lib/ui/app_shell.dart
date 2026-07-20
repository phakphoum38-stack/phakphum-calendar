import 'package:flutter/material.dart';

import '../controller/app_controller.dart';
import '../models/shift.dart';
import '../services/calendar_service.dart';
import '../services/google_auth_service.dart';
import 'google_sign_in_button.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.controller});

  final AppController controller;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int selectedIndex = 0;

  static const destinations = [
    NavigationDestination(
      icon: Icon(Icons.dashboard_outlined),
      label: 'หน้าแรก',
    ),
    NavigationDestination(
      icon: Icon(Icons.event_note_outlined),
      label: 'ตัวอย่าง',
    ),
    NavigationDestination(icon: Icon(Icons.history_outlined), label: 'บันทึก'),
    NavigationDestination(
      icon: Icon(Icons.settings_outlined),
      label: 'ตั้งค่า',
    ),
  ];

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) {
      final controller = widget.controller;
      if (!controller.initialized) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      return LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          final pages = <Widget>[
            _DashboardPage(
              controller: controller,
              perform: _perform,
              sync: _sync,
              configureGoogleOAuth: _configureGoogleOAuth,
            ),
            _PreviewPage(controller: controller),
            _AuditPage(controller: controller),
            _SettingsPage(
              controller: controller,
              createFutureSheet: _createFutureSheet,
            ),
          ];
          final content = IndexedStack(index: selectedIndex, children: pages);
          return Scaffold(
            appBar: AppBar(
              title: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Shift Calendar'),
                  Text(
                    'Sheets → Google Calendar',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
                  ),
                ],
              ),
              actions: [
                if (controller.auth.account != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Center(
                      child: Text(
                        controller.auth.account!.email,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
              ],
            ),
            body: wide
                ? Row(
                    children: [
                      NavigationRail(
                        selectedIndex: selectedIndex,
                        onDestinationSelected: (index) =>
                            setState(() => selectedIndex = index),
                        labelType: NavigationRailLabelType.all,
                        leading: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: CircleAvatar(
                            child: Icon(Icons.calendar_month),
                          ),
                        ),
                        destinations: [
                          for (final destination in destinations)
                            NavigationRailDestination(
                              icon: destination.icon,
                              label: Text(destination.label),
                            ),
                        ],
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(child: content),
                    ],
                  )
                : content,
            bottomNavigationBar: wide
                ? null
                : NavigationBar(
                    selectedIndex: selectedIndex,
                    onDestinationSelected: (index) =>
                        setState(() => selectedIndex = index),
                    destinations: destinations,
                  ),
          );
        },
      );
    },
  );

  Future<void> _perform(Future<void> Function() action) async {
    try {
      await action();
      if (!mounted) return;
      final status = widget.controller.status;
      if (status != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(status)));
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Bad state: ', '')),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _sync() async {
    final confirmed = await _showSyncConfirmationDialog();
    if (confirmed != true) return;
    await _perform(widget.controller.syncCalendar);
  }

  Future<void> _configureGoogleOAuth() async {
    final value = TextEditingController(
      text: widget.controller.auth.webClientId,
    );
    String? validationError;
    final clientId = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('ตั้งค่า Google OAuth สำหรับ Web'),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'วาง Web OAuth Client ID จาก Google Cloud เพื่อเปิดปุ่มล็อกอิน '
                  'Client ID เปิดเผยได้และไม่ใช่ Client Secret',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: value,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Web OAuth Client ID',
                    hintText: '123456789-abc.apps.googleusercontent.com',
                    errorText: validationError,
                    prefixIcon: const Icon(Icons.key_outlined),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Authorized JavaScript origin สำหรับหน้านี้ต้องมี '
                  '${Uri.base.origin}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ยกเลิก'),
            ),
            FilledButton(
              onPressed: () {
                final text = value.text.trim();
                if (!GoogleAuthService.isValidWebClientId(text)) {
                  setDialogState(
                    () => validationError = 'รูปแบบ Client ID ไม่ถูกต้อง',
                  );
                  return;
                }
                Navigator.pop(context, text);
              },
              child: const Text('บันทึกและเปิด Google Login'),
            ),
          ],
        ),
      ),
    );
    value.dispose();
    if (clientId == null) return;
    await _perform(
      () => widget.controller.configureGoogleWebClientId(clientId),
    );
  }

  Future<void> _createFutureSheet(String template, String newTitle) async {
    final confirmed = await _showConfirmationDialog(
      title: 'ยืนยันสร้างแท็บใหม่',
      message:
          'จะทำสำเนาแท็บ “$template” เป็น “$newTitle” '
          'โดยไม่แก้แท็บต้นแบบ',
    );
    if (confirmed != true) return;
    await _perform(
      () => widget.controller.createFutureSheet(
        templateTitle: template,
        newTitle: newTitle,
      ),
    );
  }

  Future<bool?> _showSyncConfirmationDialog() {
    final controller = widget.controller;
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการเขียนข้อมูล'),
        content: SizedBox(
          width: 430,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('จะเพิ่มใหม่ ${controller.newCount} กิจกรรม'),
              Text('ข้ามรายการที่มีแล้ว ${controller.existingCount} กิจกรรม'),
              Text(
                controller.settings.archiveOriginal
                    ? 'จะสร้าง/ตรวจสำเนาต้นฉบับประจำเดือนใน Google Drive ก่อน'
                    : 'ไม่ได้เปิดสร้างสำเนาต้นฉบับ',
              ),
              const SizedBox(height: 12),
              const Text('ไฟล์ต้นฉบับ Google Sheets จะไม่ถูกแก้ไข'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ยืนยันและทำต่อ'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showConfirmationDialog({
    required String title,
    required String message,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(width: 420, child: Text(message)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ยืนยัน'),
          ),
        ],
      ),
    );
  }
}

class _DashboardPage extends StatefulWidget {
  const _DashboardPage({
    required this.controller,
    required this.perform,
    required this.sync,
    required this.configureGoogleOAuth,
  });

  final AppController controller;
  final Future<void> Function(Future<void> Function()) perform;
  final Future<void> Function() sync;
  final Future<void> Function() configureGoogleOAuth;

  @override
  State<_DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<_DashboardPage> {
  late final source = TextEditingController(
    text: widget.controller.settings.sourceUrl,
  );
  late final name = TextEditingController(
    text: widget.controller.settings.targetName,
  );
  late final year = TextEditingController(
    text: '${widget.controller.settings.year}',
  );
  late int month = widget.controller.settings.month;

  @override
  void dispose() {
    source.dispose();
    name.dispose();
    year.dispose();
    super.dispose();
  }

  Future<void> _saveSettings({bool? autoRefresh, int? refreshSeconds}) =>
      widget.controller.updateSettings(
        widget.controller.settings.copyWith(
          sourceUrl: source.text.trim(),
          targetName: name.text.trim(),
          year: int.tryParse(year.text) ?? widget.controller.settings.year,
          month: month,
          autoRefresh: autoRefresh,
          refreshSeconds: refreshSeconds,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _GoogleAccountCard(
                controller: controller,
                perform: widget.perform,
                configureGoogleOAuth: widget.configureGoogleOAuth,
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'แหล่งข้อมูลเวร',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'ใช้ Sheets API แบบอ่านอย่างเดียว ไม่มีคำสั่งแก้ไขเซลล์',
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: source,
                        decoration: const InputDecoration(
                          labelText: 'ลิงก์ Google Sheets ต้นฉบับ',
                          prefixIcon: Icon(Icons.table_chart_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final narrow = constraints.maxWidth < 650;
                          final nameField = TextField(
                            controller: name,
                            decoration: const InputDecoration(
                              labelText: 'ชื่อที่ต้องค้นหา',
                            ),
                          );
                          final monthField = DropdownButtonFormField<int>(
                            initialValue: month,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'เดือน',
                            ),
                            items: [
                              for (var i = 1; i <= 12; i++)
                                DropdownMenuItem(
                                  value: i,
                                  child: Text(
                                    _thaiMonths[i - 1],
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                            onChanged: (value) =>
                                setState(() => month = value ?? month),
                          );
                          final yearField = TextField(
                            controller: year,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'ปี ค.ศ.',
                            ),
                          );
                          if (narrow) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                nameField,
                                const SizedBox(height: 12),
                                monthField,
                                const SizedBox(height: 12),
                                yearField,
                              ],
                            );
                          }
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: nameField),
                              const SizedBox(width: 12),
                              SizedBox(width: 210, child: monthField),
                              const SizedBox(width: 12),
                              SizedBox(width: 130, child: yearField),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _AutoRefreshControls(
                        controller: controller,
                        onChanged: (enabled, seconds) => widget.perform(
                          () => _saveSettings(
                            autoRefresh: enabled,
                            refreshSeconds: seconds,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          FilledButton.icon(
                            onPressed:
                                controller.auth.isSignedIn && !controller.busy
                                ? () => widget.perform(() async {
                                    await _saveSettings();
                                    await controller.loadRoster();
                                  })
                                : null,
                            icon: const Icon(Icons.refresh),
                            label: const Text('รีเฟรช/อ่านใหม่ตอนนี้'),
                          ),
                          OutlinedButton.icon(
                            onPressed:
                                controller.auth.isSignedIn &&
                                    controller.shifts.isNotEmpty &&
                                    !controller.busy
                                ? () =>
                                      widget.perform(controller.compareCalendar)
                                : null,
                            icon: const Icon(Icons.difference_outlined),
                            label: const Text('เปรียบเทียบ Calendar'),
                          ),
                          FilledButton.tonalIcon(
                            onPressed:
                                controller.auth.isSignedIn &&
                                    controller.shifts.isNotEmpty &&
                                    !controller.busy
                                ? widget.sync
                                : null,
                            icon: const Icon(Icons.calendar_month),
                            label: const Text('ยืนยันและบันทึก Calendar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (controller.busy) const LinearProgressIndicator(),
              if (controller.error != null) ...[
                const SizedBox(height: 10),
                _MessageBanner(message: controller.error!, error: true),
              ] else if (controller.status != null) ...[
                const SizedBox(height: 10),
                _MessageBanner(message: controller.status!),
              ],
              const SizedBox(height: 16),
              _Stats(controller: controller),
              const SizedBox(height: 16),
              Card(
                child: SwitchListTile(
                  value: controller.settings.archiveOriginal,
                  onChanged: (value) => widget.perform(
                    () => controller.updateSettings(
                      controller.settings.copyWith(archiveOriginal: value),
                    ),
                  ),
                  title: const Text(
                    'เก็บสำเนาต้นฉบับประจำเดือนใน Google Drive',
                  ),
                  subtitle: const Text(
                    'สร้างครั้งเดียวต่อเดือนก่อนซิงก์ และไม่แก้ไฟล์ต้นฉบับ',
                  ),
                  secondary: const Icon(Icons.content_copy_outlined),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleAccountCard extends StatelessWidget {
  const _GoogleAccountCard({
    required this.controller,
    required this.perform,
    required this.configureGoogleOAuth,
  });

  final AppController controller;
  final Future<void> Function(Future<void> Function()) perform;
  final Future<void> Function() configureGoogleOAuth;

  @override
  Widget build(BuildContext context) {
    final account = controller.auth.account;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: account == null
            ? Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                runSpacing: 12,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        child: Icon(Icons.account_circle_outlined),
                      ),
                      title: const Text('เชื่อมต่อบัญชี Google'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ล็อกอินก่อน แล้วค่อยอนุญาตสิทธิ์ตามปุ่มที่ใช้งาน',
                          ),
                          if (controller.auth.error != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              controller.auth.error!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (controller.auth.oauthConfigured)
                    if (controller.auth.initialized &&
                        !controller.auth.signInReady)
                      OutlinedButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.error_outline),
                        label: const Text('Google Login ไม่พร้อม'),
                      )
                    else
                      GoogleLoginButton(
                        enabled:
                            controller.auth.signInReady && !controller.busy,
                        onPressed: () => perform(controller.signIn),
                      )
                  else if (controller.auth.canConfigureWebOAuth)
                    OutlinedButton.icon(
                      onPressed: controller.busy ? null : configureGoogleOAuth,
                      icon: const Icon(Icons.settings_outlined),
                      label: const Text('ตั้งค่า Google OAuth'),
                    )
                  else
                    Tooltip(
                      message: controller.auth.oauthUnavailableMessage ?? '',
                      child: OutlinedButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.key_off_outlined),
                        label: Text(
                          controller.auth.platformSupported
                              ? 'ยังไม่ได้ตั้งค่า Google OAuth'
                              : 'Google Login ใช้ผ่าน Web',
                        ),
                      ),
                    ),
                ],
              )
            : Row(
                children: [
                  CircleAvatar(
                    backgroundImage: account.photoUrl == null
                        ? null
                        : NetworkImage(account.photoUrl!),
                    child: account.photoUrl == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account.displayName ?? 'Google Account',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(account.email),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => perform(controller.signOut),
                    child: const Text('ออกจากระบบ'),
                  ),
                ],
              ),
      ),
    );
  }
}

class _AutoRefreshControls extends StatelessWidget {
  const _AutoRefreshControls({
    required this.controller,
    required this.onChanged,
  });

  final AppController controller;
  final void Function(bool enabled, int seconds) onChanged;

  @override
  Widget build(BuildContext context) {
    final settings = controller.settings;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            Switch(
              value: settings.autoRefresh,
              onChanged: (value) => onChanged(value, settings.refreshSeconds),
            ),
            const Text('Auto refresh'),
            DropdownButton<int>(
              value: settings.refreshSeconds,
              items: [
                for (var seconds = 1; seconds <= 10; seconds++)
                  DropdownMenuItem(
                    value: seconds,
                    child: Text('$seconds วินาที'),
                  ),
              ],
              onChanged: (value) {
                if (value != null) onChanged(settings.autoRefresh, value);
              },
            ),
            if (settings.refreshSeconds == 1)
              const Text(
                '1 วินาทีอาจชนโควตา API',
                style: TextStyle(color: Colors.deepOrange),
              ),
            if (controller.lastRefresh != null)
              Text('อ่านล่าสุด ${_clock(controller.lastRefresh!)}'),
          ],
        ),
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 12,
    runSpacing: 12,
    children: [
      _StatCard(
        label: 'อ่านพบ',
        value: controller.shifts.length,
        icon: Icons.fact_check_outlined,
      ),
      _StatCard(
        label: 'เลือกไว้',
        value: controller.includedCount,
        icon: Icons.check_circle_outline,
      ),
      _StatCard(
        label: 'มีใน Calendar',
        value: controller.existingCount,
        icon: Icons.event_available_outlined,
      ),
      _StatCard(
        label: 'รอเพิ่ม',
        value: controller.newCount,
        icon: Icons.event_note_outlined,
      ),
    ],
  );
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 210,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$value',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(label, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _PreviewPage extends StatelessWidget {
  const _PreviewPage({required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.shifts.isEmpty) {
      return const _EmptyState(
        icon: Icons.event_note_outlined,
        title: 'ยังไม่มีรายการตัวอย่าง',
        message: 'ไปหน้าแรกแล้วกด “รีเฟรช/อ่านใหม่ตอนนี้”',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: controller.shifts.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final shift = controller.shifts[index];
        final exists = CalendarService.matchesExisting(
          shift,
          controller.existingKeys,
        );
        final color = Color(shift.category.colorValue);
        return Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 620;
                final selector = DropdownButtonFormField<ShiftCategory>(
                  initialValue: shift.category,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'ประเภท/สี',
                    isDense: true,
                  ),
                  items: [
                    for (final category in ShiftCategory.values)
                      DropdownMenuItem(
                        value: category,
                        child: Text(
                          category.label,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      controller.updateShift(index, category: value);
                    }
                  },
                );
                final details = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          shift.code,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Chip(
                          visualDensity: VisualDensity.compact,
                          avatar: Icon(
                            exists ? Icons.check : Icons.add,
                            size: 16,
                          ),
                          label: Text(exists ? 'มีแล้ว' : 'รายการใหม่'),
                        ),
                      ],
                    ),
                    Text(
                      '${_thaiDate(shift.start)} • ${_time(shift.start)}–${_time(shift.end)}',
                    ),
                    Text(
                      '${shift.sheetTitle} • ${shift.cell} • ${shift.assignedName}',
                    ),
                  ],
                );
                final check = Checkbox(
                  value: !shift.excluded,
                  onChanged: (value) =>
                      controller.updateShift(index, excluded: value != true),
                );
                final bar = Container(
                  width: 5,
                  height: 74,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
                if (narrow) {
                  return Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          check,
                          bar,
                          const SizedBox(width: 12),
                          Expanded(child: details),
                        ],
                      ),
                      const SizedBox(height: 10),
                      selector,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    check,
                    bar,
                    const SizedBox(width: 12),
                    Expanded(child: details),
                    const SizedBox(width: 10),
                    SizedBox(width: 190, child: selector),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _AuditPage extends StatelessWidget {
  const _AuditPage({required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.auditEntries.isEmpty) {
      return const _EmptyState(
        icon: Icons.history_outlined,
        title: 'ยังไม่มี Audit log',
        message: 'การอ่าน สำเนา และการเขียนจะบันทึกไว้ในเครื่องนี้',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: controller.auditEntries.length,
      itemBuilder: (context, index) {
        final entry = controller.auditEntries[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: entry.success
                ? Colors.green.shade50
                : Colors.red.shade50,
            child: Icon(
              entry.success ? Icons.check : Icons.error_outline,
              color: entry.success ? Colors.green : Colors.red,
            ),
          ),
          title: Text(entry.message),
          subtitle: Text(
            '${entry.action} • ${_thaiDate(entry.timestamp)} ${_clock(entry.timestamp)}',
          ),
        );
      },
    );
  }
}

class _SettingsPage extends StatelessWidget {
  const _SettingsPage({
    required this.controller,
    required this.createFutureSheet,
  });
  final AppController controller;
  final Future<void> Function(String template, String newTitle)
  createFutureSheet;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      _FutureSheetCard(controller: controller, onCreate: createFutureSheet),
      const SizedBox(height: 16),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ขอบเขตความปลอดภัย',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              const _SafetyRow(
                icon: Icons.lock_outline,
                text: 'อ่าน Google Sheets ด้วย spreadsheets.readonly',
              ),
              const _SafetyRow(
                icon: Icons.edit_off_outlined,
                text: 'ไม่มีคำสั่งแก้ไขไฟล์ต้นฉบับในขั้นตอนอ่านเวร',
              ),
              const _SafetyRow(
                icon: Icons.verified_user_outlined,
                text: 'สร้างสำเนา/เขียน Calendar ด้วยบัญชี Google ที่ล็อกอิน',
              ),
              const _SafetyRow(
                icon: Icons.people_outline,
                text: 'ไม่ส่งคำเชิญและไม่สร้าง Google Meet',
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'สี Google Calendar',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              for (final category in ShiftCategory.values)
                ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 9,
                    backgroundColor: Color(category.colorValue),
                  ),
                  title: Text(category.label),
                  trailing: Text(category.colorName),
                ),
            ],
          ),
        ),
      ),
    ],
  );
}

class _FutureSheetCard extends StatefulWidget {
  const _FutureSheetCard({required this.controller, required this.onCreate});

  final AppController controller;
  final Future<void> Function(String template, String newTitle) onCreate;

  @override
  State<_FutureSheetCard> createState() => _FutureSheetCardState();
}

class _FutureSheetCardState extends State<_FutureSheetCard> {
  late final template = TextEditingController(
    text: widget.controller.sheetTitles.lastOrNull ?? '',
  );
  late final newTitle = TextEditingController(
    text:
        'เวร ${_thaiMonths[widget.controller.settings.month - 1]} '
        '${widget.controller.settings.year + 543}',
  );

  @override
  void didUpdateWidget(covariant _FutureSheetCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (template.text.trim().isEmpty &&
        widget.controller.sheetTitles.isNotEmpty) {
      template.text = widget.controller.sheetTitles.last;
    }
  }

  @override
  void dispose() {
    template.dispose();
    newTitle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'สร้างชีตเดือนล่วงหน้า',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          const Text(
            'ทำสำเนาแท็บต้นแบบเป็นแท็บใหม่ โดยอนุญาตสิทธิ์ Sheets '
            'เฉพาะตอนกดสร้าง',
          ),
          const SizedBox(height: 14),
          TextField(
            controller: template,
            decoration: const InputDecoration(
              labelText: 'ชื่อแท็บต้นแบบ',
              prefixIcon: Icon(Icons.copy_all_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: newTitle,
            decoration: const InputDecoration(
              labelText: 'ชื่อแท็บเดือนใหม่',
              prefixIcon: Icon(Icons.add_box_outlined),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'หมายเหตุ: เป็นสำเนาเต็มของต้นแบบ ควรตรวจและปรับวันที่/รายชื่อในแท็บใหม่ก่อนใช้',
            style: TextStyle(color: Colors.deepOrange),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed:
                widget.controller.auth.isSignedIn && !widget.controller.busy
                ? () => widget.onCreate(
                    template.text.trim(),
                    newTitle.text.trim(),
                  )
                : null,
            icon: const Icon(Icons.library_add_outlined),
            label: const Text('สร้างแท็บใหม่'),
          ),
        ],
      ),
    ),
  );
}

class _SafetyRow extends StatelessWidget {
  const _SafetyRow({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
      ],
    ),
  );
}

class _MessageBanner extends StatelessWidget {
  const _MessageBanner({required this.message, this.error = false});
  final String message;
  final bool error;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: error
          ? Theme.of(context).colorScheme.errorContainer
          : Theme.of(context).colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(error ? Icons.error_outline : Icons.info_outline),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });
  final IconData icon;
  final String title;
  final String message;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

const _thaiMonths = [
  'มกราคม',
  'กุมภาพันธ์',
  'มีนาคม',
  'เมษายน',
  'พฤษภาคม',
  'มิถุนายน',
  'กรกฎาคม',
  'สิงหาคม',
  'กันยายน',
  'ตุลาคม',
  'พฤศจิกายน',
  'ธันวาคม',
];

String _thaiDate(DateTime value) =>
    '${value.day} ${_thaiMonths[value.month - 1]} ${value.year + 543}';
String _time(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
String _clock(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}:${value.second.toString().padLeft(2, '0')}';
