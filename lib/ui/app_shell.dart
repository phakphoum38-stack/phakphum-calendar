import 'dart:async';

import 'package:flutter/material.dart';

import '../controller/app_controller.dart';
import '../models/saved_sheet.dart';
import '../models/shift.dart';
import '../models/shift_alert.dart';
import '../models/tool_definition.dart';
import '../services/calendar_service.dart';
import '../services/drive_ownership_service.dart';
import '../services/google_auth_service.dart';
import '../services/shift_color_service.dart';
import 'google_sign_in_button.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.controller});

  final AppController controller;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int selectedIndex = 0;
  bool _permissionDialogOpen = false;
  String? _permissionDialogShownForEmail;

  List<NavigationDestination> _destinations(AppController controller) => [
    const NavigationDestination(
      icon: Icon(Icons.dashboard_outlined),
      label: 'หน้าแรก',
    ),
    const NavigationDestination(
      icon: Icon(Icons.event_note_outlined),
      label: 'ตัวอย่าง',
    ),
    NavigationDestination(
      icon: Badge(
        isLabelVisible: controller.pendingAlertCount > 0,
        label: Text('${controller.pendingAlertCount}'),
        child: const Icon(Icons.notifications_outlined),
      ),
      selectedIcon: Badge(
        isLabelVisible: controller.pendingAlertCount > 0,
        label: Text('${controller.pendingAlertCount}'),
        child: const Icon(Icons.notifications),
      ),
      label: 'แจ้งเตือน',
    ),
    const NavigationDestination(
      icon: Icon(Icons.history_outlined),
      label: 'บันทึก',
    ),
    const NavigationDestination(
      icon: Icon(Icons.settings_outlined),
      label: 'ตั้งค่า',
    ),
    const NavigationDestination(
      icon: Icon(Icons.apps_outlined),
      label: 'เครื่องมือ',
    ),
  ];

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    super.dispose();
  }

  void _handleControllerChanged() {
    final auth = widget.controller.auth;
    final account = auth.account;
    if (account == null) {
      _permissionDialogShownForEmail = null;
      return;
    }
    if (_permissionDialogOpen ||
        auth.checkingReadAccess ||
        auth.readAccessGranted ||
        _permissionDialogShownForEmail == account.email) {
      return;
    }
    _permissionDialogShownForEmail = account.email;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_showReadAccessDialog(account.email));
    });
  }

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
          final destinations = _destinations(controller);
          final pages = <Widget>[
            _DashboardPage(
              controller: controller,
              perform: _perform,
              compareCalendar: _compareCalendar,
              sync: _sync,
              openAlerts: () => setState(() => selectedIndex = 2),
              configureGoogleOAuth: _configureGoogleOAuth,
            ),
            _PreviewPage(controller: controller),
            _NotificationsPage(controller: controller, perform: _perform),
            _AuditPage(
              controller: controller,
              saveCurrentSheet: _saveCurrentSheet,
              activateSavedSheet: _activateSavedSheet,
              openSavedSheet: _openSavedSheet,
              deleteSavedSheet: _deleteSavedSheet,
            ),
            _SettingsPage(
              controller: controller,
              createFutureSheet: _createFutureSheet,
            ),
            _ToolsPage(
              controller: controller,
              openTool: _openTool,
              togglePinned: _togglePinnedTool,
            ),
          ];
          final content = IndexedStack(index: selectedIndex, children: pages);
          final mainContent = wide
              ? Row(
                  children: [
                    NavigationRail(
                      selectedIndex: selectedIndex,
                      onDestinationSelected: (index) =>
                          setState(() => selectedIndex = index),
                      labelType: NavigationRailLabelType.all,
                      leading: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: CircleAvatar(child: Icon(Icons.calendar_month)),
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
              : content;
          return Scaffold(
            appBar: AppBar(
              titleSpacing: 16,
              title: const Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    child: Icon(Icons.calendar_month_rounded),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Phakphum Calendar',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Version 4.0 • Hospital Workspace',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
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
            body: Column(
              children: [
                _PinnedToolsBar(
                  tools: controller.pinnedTools.toList(),
                  openTool: _openTool,
                  manageTools: () => setState(() => selectedIndex = 5),
                ),
                const Divider(height: 1),
                Expanded(child: mainContent),
              ],
            ),
            bottomNavigationBar: wide
                ? null
                : NavigationBar(
                    selectedIndex: selectedIndex,
                    labelBehavior:
                        NavigationDestinationLabelBehavior.onlyShowSelected,
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
    await _performWithResult(action);
  }

  Future<bool> _performWithResult(Future<void> Function() action) async {
    try {
      await action();
      if (!mounted) return false;
      final status = widget.controller.status;
      if (status != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(status)));
      }
      return true;
    } catch (error) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Bad state: ', '')),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return false;
    }
  }

  Future<void> _showReadAccessDialog(String email) async {
    if (_permissionDialogOpen || !mounted) return;
    _permissionDialogOpen = true;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('อนุญาตการเข้าถึง Google'),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('บัญชี $email'),
              const SizedBox(height: 12),
              const Text(
                'แอปจะเปิดหน้าต่าง Google เพื่อขอสิทธิ์อ่านข้อมูลที่จำเป็น:',
              ),
              const SizedBox(height: 12),
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.table_chart_outlined),
                title: Text('Google Sheets แบบอ่านอย่างเดียว'),
                subtitle: Text('ใช้ค้นหาเวร โดยไม่แก้ไขชีตต้นฉบับ'),
              ),
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.calendar_month_outlined),
                title: Text('Google Calendar แบบอ่านอย่างเดียว'),
                subtitle: Text('ใช้ตรวจรายการซ้ำก่อนบันทึก'),
              ),
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.badge_outlined),
                title: Text(
                  'ข้อมูลเจ้าของไฟล์ใน Google Drive แบบอ่านอย่างเดียว',
                ),
                subtitle: Text('ใช้ยืนยันว่าชีตหลักเป็นของบัญชีที่ล็อกอิน'),
              ),
              const Text(
                'สิทธิ์เขียน Calendar, Drive และ Sheets จะยังไม่ถูกขอในขั้นตอนนี้',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('ไว้ภายหลัง'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              unawaited(_perform(widget.controller.authorizeReadAccess));
            },
            icon: const Icon(Icons.verified_user_outlined),
            label: const Text('อนุญาตการเข้าถึง'),
          ),
        ],
      ),
    );
    _permissionDialogOpen = false;
  }

  Future<void> _openTool(ToolDefinition tool) =>
      _perform(() => widget.controller.openTool(tool));

  Future<void> _togglePinnedTool(ToolDefinition tool) =>
      _perform(() => widget.controller.toggleToolPinned(tool));

  Future<void> _saveCurrentSheet() =>
      _perform(widget.controller.saveCurrentSheet);

  Future<void> _activateSavedSheet(SavedSheet sheet) => _perform(() async {
    await widget.controller.activateSavedSheet(sheet);
    await widget.controller.loadRoster();
  });

  Future<void> _openSavedSheet(SavedSheet sheet) =>
      _perform(() => widget.controller.openSavedSheet(sheet));

  Future<void> _deleteSavedSheet(SavedSheet sheet) async {
    final confirmed = await _showConfirmationDialog(
      title: 'ลบออกจากรายการบันทึก',
      message:
          'จะลบ “${sheet.displayTitle}” ออกจากรายการในเครื่องนี้เท่านั้น '
          'ไฟล์และแท็บจริงใน Google Sheets จะไม่ถูกลบ',
    );
    if (confirmed != true) return;
    await _perform(() => widget.controller.deleteSavedSheet(sheet));
  }

  Future<void> _sync() async {
    final compared = await _performWithResult(
      widget.controller.compareCalendar,
    );
    if (!compared) return;
    if (widget.controller.pendingAlertCount > 0) {
      await _showConflictWarningDialog();
      return;
    }
    final confirmed = await _showSyncConfirmationDialog();
    if (confirmed != true) return;
    final synced = await _performWithResult(widget.controller.syncCalendar);
    if (!synced && widget.controller.pendingAlertCount > 0) {
      await _showConflictWarningDialog();
    }
  }

  Future<void> _compareCalendar() async {
    final compared = await _performWithResult(
      widget.controller.compareCalendar,
    );
    if (compared && widget.controller.pendingAlertCount > 0) {
      await _showConflictWarningDialog();
    }
  }

  Future<void> _showConflictWarningDialog() async {
    final pending = widget.controller.alerts
        .where((alert) => alert.isPending)
        .toList();
    if (!mounted || pending.isEmpty) return;
    final inspect = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          Icons.warning_amber_rounded,
          color: Theme.of(dialogContext).colorScheme.error,
          size: 34,
        ),
        title: Text('พบรายการชนกัน ${pending.length} รายการ'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540, maxHeight: 420),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ยังไม่มีข้อมูลใดถูกเขียนลง Google Calendar '
                  'กรุณาตรวจและตัดสินใจรายการต่อไปนี้ก่อน',
                ),
                const SizedBox(height: 12),
                for (final alert in pending.take(5)) ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event_busy_outlined),
                    title: Text(alert.title),
                    subtitle: Text(alert.message),
                  ),
                  const Divider(height: 1),
                ],
                if (pending.length > 5) ...[
                  const SizedBox(height: 10),
                  Text('และอีก ${pending.length - 5} รายการ'),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('ปิด'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.notifications_active_outlined),
            label: const Text('ตรวจและตัดสินใจ'),
          ),
        ],
      ),
    );
    if (inspect == true && mounted) {
      setState(() => selectedIndex = 2);
    }
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
                    ? 'จะสร้าง/ตรวจสำเนาต้นฉบับใน Drive ของบัญชีที่ล็อกอินก่อน'
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

class _PinnedToolsBar extends StatelessWidget {
  const _PinnedToolsBar({
    required this.tools,
    required this.openTool,
    required this.manageTools,
  });

  final List<ToolDefinition> tools;
  final Future<void> Function(ToolDefinition tool) openTool;
  final VoidCallback manageTools;

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surface,
    child: SizedBox(
      height: 66,
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 16, right: 8),
            child: Icon(Icons.apps_outlined),
          ),
          Expanded(
            child: tools.isEmpty
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: manageTools,
                      icon: const Icon(Icons.add),
                      label: const Text('ติดตั้งเครื่องมือในแถบ'),
                    ),
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    itemCount: tools.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final tool = tools[index];
                      return ActionChip(
                        tooltip: 'เปิด ${tool.name}',
                        avatar: CircleAvatar(
                          backgroundColor: tool.color.withValues(alpha: 0.14),
                          child: Icon(tool.icon, size: 18, color: tool.color),
                        ),
                        label: Text(tool.name),
                        onPressed: () => unawaited(openTool(tool)),
                      );
                    },
                  ),
          ),
          IconButton(
            onPressed: manageTools,
            tooltip: 'จัดการเครื่องมือ',
            icon: const Icon(Icons.add_circle_outline),
          ),
          const SizedBox(width: 8),
        ],
      ),
    ),
  );
}

class _ToolsPage extends StatefulWidget {
  const _ToolsPage({
    required this.controller,
    required this.openTool,
    required this.togglePinned,
  });

  final AppController controller;
  final Future<void> Function(ToolDefinition tool) openTool;
  final Future<void> Function(ToolDefinition tool) togglePinned;

  @override
  State<_ToolsPage> createState() => _ToolsPageState();
}

class _ToolsPageState extends State<_ToolsPage> {
  final search = TextEditingController();
  ToolGroup? selectedGroup;

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = search.text.trim().toLowerCase();
    final tools = toolCatalog.where((tool) {
      final matchesGroup = selectedGroup == null || tool.group == selectedGroup;
      final matchesQuery =
          query.isEmpty ||
          tool.name.toLowerCase().contains(query) ||
          tool.description.toLowerCase().contains(query);
      return matchesGroup && matchesQuery;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'คลังเครื่องมือ',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              const Text(
                'ติดตั้งทางลัดลงแถบ แล้วเปิดด้วยบัญชีที่เลือกในแต่ละบริการได้ทุกระบบ',
              ),
              const SizedBox(height: 16),
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.privacy_tip_outlined),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'แอปเก็บเฉพาะรายการทางลัดที่ติดตั้งในเครื่องนี้ '
                          'ไม่เก็บอีเมล รหัสผ่าน หรือ token ของ Google, GitHub, AI และบริการอื่น',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: search,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'ค้นหาเครื่องมือ',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('ทั้งหมด'),
                      selected: selectedGroup == null,
                      onSelected: (_) => setState(() => selectedGroup = null),
                    ),
                    const SizedBox(width: 8),
                    for (final group in ToolGroup.values) ...[
                      FilterChip(
                        label: Text(_toolGroupLabel(group)),
                        selected: selectedGroup == group,
                        onSelected: (_) =>
                            setState(() => selectedGroup = group),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 980
                      ? 3
                      : constraints.maxWidth >= 620
                      ? 2
                      : 1;
                  const spacing = 16.0;
                  final width =
                      (constraints.maxWidth - (columns - 1) * spacing) /
                      columns;
                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: [
                      for (final tool in tools)
                        SizedBox(
                          width: width,
                          child: _ToolCard(
                            tool: tool,
                            pinned: widget.controller.isToolPinned(tool.id),
                            openTool: widget.openTool,
                            togglePinned: widget.togglePinned,
                          ),
                        ),
                    ],
                  );
                },
              ),
              if (tools.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: Text('ไม่พบเครื่องมือที่ค้นหา')),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({
    required this.tool,
    required this.pinned,
    required this.openTool,
    required this.togglePinned,
  });

  final ToolDefinition tool;
  final bool pinned;
  final Future<void> Function(ToolDefinition tool) openTool;
  final Future<void> Function(ToolDefinition tool) togglePinned;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: tool.color.withValues(alpha: 0.14),
                child: Icon(tool.icon, color: tool.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  tool.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (pinned)
                const Tooltip(
                  message: 'ติดตั้งในแถบแล้ว',
                  child: Icon(Icons.push_pin, size: 20),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(tool.description),
          const SizedBox(height: 10),
          Text(
            tool.usesGoogleAccountChooser
                ? 'เลือกบัญชี Google ก่อนเปิดบริการ'
                : 'ใช้ระบบบัญชีของบริการนั้นโดยตรง',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: () => unawaited(openTool(tool)),
                icon: const Icon(Icons.open_in_new),
                label: const Text('เปิด'),
              ),
              OutlinedButton.icon(
                onPressed: () => unawaited(togglePinned(tool)),
                icon: Icon(pinned ? Icons.remove : Icons.add),
                label: Text(pinned ? 'นำออกจากแถบ' : 'ติดตั้งในแถบ'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

String _toolGroupLabel(ToolGroup group) => switch (group) {
  ToolGroup.google => 'Google',
  ToolGroup.ai => 'AI',
  ToolGroup.developer => 'นักพัฒนา',
  ToolGroup.productivity => 'งานและเอกสาร',
};

class _DashboardPage extends StatefulWidget {
  const _DashboardPage({
    required this.controller,
    required this.perform,
    required this.compareCalendar,
    required this.sync,
    required this.openAlerts,
    required this.configureGoogleOAuth,
  });

  final AppController controller;
  final Future<void> Function(Future<void> Function()) perform;
  final Future<void> Function() compareCalendar;
  final Future<void> Function() sync;
  final VoidCallback openAlerts;
  final Future<void> Function() configureGoogleOAuth;

  @override
  State<_DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<_DashboardPage> {
  late final searchName = TextEditingController(
    text: widget.controller.settings.targetName,
  );
  late String? sourceAccountId = widget.controller.auth.account?.id;
  late int? month = widget.controller.settings.month;
  late int? year = widget.controller.settings.year;

  List<int> get selectableYears {
    final currentYear = DateTime.now().year;
    final values = <int>{
      for (var value = currentYear - 5; value <= currentYear + 10; value++)
        value,
      ?year,
    }.toList()..sort();
    return values;
  }

  @override
  void didUpdateWidget(covariant _DashboardPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextAccountId = widget.controller.auth.account?.id;
    final accountChanged = nextAccountId != sourceAccountId;
    if (accountChanged) {
      sourceAccountId = nextAccountId;
    }
    if (accountChanged) {
      searchName.text = widget.controller.settings.targetName;
      month = widget.controller.settings.month;
      year = widget.controller.settings.year;
    }
  }

  @override
  void dispose() {
    searchName.dispose();
    super.dispose();
  }

  Future<void> _saveSettings({bool? autoRefresh, int? refreshSeconds}) =>
      widget.controller.updateSettings(
        widget.controller.settings.copyWith(
          targetName: searchName.text.trim(),
          year: year,
          month: month,
          autoRefresh: autoRefresh,
          refreshSeconds: refreshSeconds,
        ),
      );

  Future<void> _pickGoogleSheet() async {
    final controller = widget.controller;

    if (!controller.auth.isSignedIn) {
      throw StateError('กรุณาเข้าสู่ระบบ Google ก่อนเลือกไฟล์');
    }

    await controller.findAvailableSourceSheets();
    if (!mounted) return;

    if (controller.recentOwnedSheets.isEmpty) {
      throw StateError('ไม่พบ Google Sheets ที่บัญชีนี้เป็นเจ้าของ');
    }

    final selected = await showDialog<List<RecentOwnedSheet>>(
      context: context,
      builder: (context) => _GoogleSheetPickerDialog(
        files: controller.recentOwnedSheets,
        alreadyAddedSpreadsheetIds: controller.savedSheetsForCurrentAccount
            .map((sheet) => sheet.spreadsheetId)
            .toSet(),
      ),
    );

    if (selected == null || selected.isEmpty || !mounted) return;
    await controller.selectRecentSourceSheets(selected);
  }

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
              _VersionFourHero(
                controller: controller,
                openAlerts: widget.openAlerts,
              ),
              const SizedBox(height: 16),
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
                        'ไฟล์หลักต้องเป็น Google Sheets ของบัญชีที่ล็อกอิน '
                        'แอปอ่านเซลล์และสีแบบ read-only',
                      ),
                      const SizedBox(height: 16),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                child: Icon(Icons.table_chart_outlined),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      controller.selectedSourceSheetTitle,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleSmall,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      controller.hasSelectedSourceSheet
                                          ? 'ไฟล์หลักสำหรับอ่านตารางเวร • บันทึกไว้ ${controller.savedSheetsForCurrentAccount.length} ไฟล์'
                                          : 'เลือกไฟล์จาก Google Drive โดยไม่ต้องวางลิงก์',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              if (controller.hasSelectedSourceSheet)
                                const Icon(Icons.check_circle_outline),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      FilledButton.icon(
                        onPressed:
                            controller.auth.isSignedIn && !controller.busy
                            ? () => widget.perform(_pickGoogleSheet)
                            : null,
                        icon: controller.busy
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.add_to_drive_outlined),
                        label: Text(
                          controller.hasSelectedSourceSheet
                              ? 'เพิ่ม Google Sheets'
                              : 'เลือก Google Sheets',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: searchName,
                        enabled: controller.auth.isSignedIn && !controller.busy,
                        decoration: const InputDecoration(
                          labelText: 'ชื่อที่ต้องค้นหา',
                          hintText: 'กรอกชื่อให้ตรงกับชื่อในตารางเวร',
                          helperText:
                              'เริ่มต้นว่าง ใช้เฉพาะรอบนี้; ถ้าไม่กรอกจะใช้ชื่อโปรไฟล์ Google',
                          prefixIcon: Icon(Icons.person_search_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.account_circle_outlined, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              controller.auth.account?.displayName
                                          ?.trim()
                                          .isNotEmpty ==
                                      true
                                  ? 'ชื่อสำรองจากบัญชี Google: ${controller.auth.account!.displayName!.trim()}'
                                  : 'กรอกชื่อด้านบนเพื่อใช้ค้นหาเวรในชีต',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final narrow = constraints.maxWidth < 420;
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
                            onChanged: (value) => setState(() => month = value),
                          );
                          final yearField = DropdownButtonFormField<int>(
                            initialValue: year,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'ปี ค.ศ.',
                            ),
                            items: [
                              for (final value in selectableYears)
                                DropdownMenuItem(
                                  value: value,
                                  child: Text('$value'),
                                ),
                            ],
                            onChanged: (value) => setState(() => year = value),
                          );
                          if (narrow) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                monthField,
                                const SizedBox(height: 12),
                                yearField,
                              ],
                            );
                          }
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: monthField),
                              const SizedBox(width: 12),
                              Expanded(child: yearField),
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
                                    if (!controller.hasSelectedSourceSheet) {
                                      throw StateError(
                                        'กรุณาเลือก Google Sheets ก่อนอ่านตารางเวร',
                                      );
                                    }
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
                                ? widget.compareCalendar
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
              if (controller.pendingAlertCount > 0) ...[
                const SizedBox(height: 16),
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: ListTile(
                    onTap: widget.openAlerts,
                    leading: const Icon(Icons.notification_important_outlined),
                    title: Text(
                      'มี ${controller.pendingAlertCount} รายการชนกันที่ต้องตัดสินใจ',
                    ),
                    subtitle: const Text(
                      'ระบบจะยังไม่เขียน Google Calendar จนกว่าจะตรวจครบ',
                    ),
                    trailing: const Icon(Icons.arrow_forward),
                  ),
                ),
              ],
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
                    'เก็บสำเนาต้นฉบับใน Drive ของบัญชีที่ล็อกอิน',
                  ),
                  subtitle: const Text(
                    'สร้างครั้งเดียวต่อเดือนก่อนซิงก์ ไม่แก้หรือลบไฟล์ต้นฉบับ',
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

class _GoogleSheetPickerDialog extends StatefulWidget {
  const _GoogleSheetPickerDialog({
    required this.files,
    required this.alreadyAddedSpreadsheetIds,
  });

  final List<RecentOwnedSheet> files;
  final Set<String> alreadyAddedSpreadsheetIds;

  @override
  State<_GoogleSheetPickerDialog> createState() =>
      _GoogleSheetPickerDialogState();
}

class _GoogleSheetPickerDialogState extends State<_GoogleSheetPickerDialog> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedIds = <String>{};
  String _query = '';

  List<RecentOwnedSheet> get _filteredFiles {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return widget.files;
    return widget.files
        .where((file) => file.name.toLowerCase().contains(query))
        .toList(growable: false);
  }

  List<RecentOwnedSheet> get _selectedFiles => widget.files
      .where((file) => _selectedIds.contains(file.id))
      .toList(growable: false);

  void _toggle(RecentOwnedSheet file) {
    if (widget.alreadyAddedSpreadsheetIds.contains(file.id)) return;
    setState(() {
      if (!_selectedIds.add(file.id)) {
        _selectedIds.remove(file.id);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final files = _filteredFiles;
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.table_chart_outlined),
          SizedBox(width: 10),
          Expanded(child: Text('เลือก Google Sheets หลายไฟล์')),
        ],
      ),
      content: SizedBox(
        width: 660,
        height: 520,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'ค้นหาชื่อไฟล์',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'เลือกใหม่ ${_selectedIds.length} ไฟล์ • '
                'เพิ่มไว้แล้ว ${widget.alreadyAddedSpreadsheetIds.length} ไฟล์',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: files.isEmpty
                  ? const Center(child: Text('ไม่พบ Google Sheets'))
                  : ListView.separated(
                      itemCount: files.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final file = files[index];
                        final alreadyAdded = widget.alreadyAddedSpreadsheetIds
                            .contains(file.id);
                        final selected = _selectedIds.contains(file.id);
                        return CheckboxListTile(
                          value: alreadyAdded || selected,
                          onChanged: alreadyAdded ? null : (_) => _toggle(file),
                          secondary: const CircleAvatar(
                            child: Icon(Icons.table_chart_outlined),
                          ),
                          title: Text(
                            file.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            alreadyAdded
                                ? 'เพิ่มไว้แล้ว'
                                : file.modifiedAt == null
                                ? 'ไม่พบเวลาแก้ไขล่าสุด'
                                : 'แก้ไขล่าสุด ${_thaiDate(file.modifiedAt!)} '
                                      '${_clock(file.modifiedAt!)}',
                          ),
                          controlAffinity: ListTileControlAffinity.trailing,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('ยกเลิก'),
        ),
        FilledButton.icon(
          onPressed: _selectedIds.isEmpty
              ? null
              : () => Navigator.of(context).pop(_selectedFiles),
          icon: const Icon(Icons.add),
          label: Text('เพิ่ม ${_selectedIds.length} ไฟล์'),
        ),
      ],
    );
  }
}

class _VersionFourHero extends StatelessWidget {
  const _VersionFourHero({required this.controller, required this.openAlerts});

  final AppController controller;
  final VoidCallback openAlerts;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer,
            colorScheme.secondaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 700;

          final information = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Chip(
                    avatar: Icon(Icons.auto_awesome, size: 18),
                    label: Text('VERSION 4.0'),
                  ),
                  Chip(
                    avatar: Icon(Icons.verified_outlined, size: 18),
                    label: Text('Hospital Workspace'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'จัดการตารางเวรในที่เดียว',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'อ่านเวรจาก Google Sheets ตรวจรายการซ้ำ '
                'จัดการการแจ้งเตือน และบันทึกลง Google Calendar '
                'ด้วยขั้นตอนที่ตรวจสอบได้',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.icon(
                    onPressed: controller.pendingAlertCount > 0
                        ? openAlerts
                        : null,
                    icon: const Icon(Icons.notifications_active_outlined),
                    label: Text(
                      controller.pendingAlertCount > 0
                          ? 'ตรวจ ${controller.pendingAlertCount} การแจ้งเตือน'
                          : 'ไม่มีการแจ้งเตือนค้าง',
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: null,
                    icon: Icon(
                      controller.auth.isSignedIn
                          ? Icons.cloud_done_outlined
                          : Icons.cloud_off_outlined,
                    ),
                    label: Text(
                      controller.auth.isSignedIn
                          ? 'เชื่อมต่อ Google แล้ว'
                          : 'ยังไม่ได้เชื่อมต่อ Google',
                    ),
                  ),
                ],
              ),
            ],
          );

          final illustration = Container(
            width: 190,
            height: 170,
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.calendar_month_rounded,
                  size: 108,
                  color: colorScheme.primary,
                ),
                Positioned(
                  right: 24,
                  bottom: 24,
                  child: CircleAvatar(
                    radius: 26,
                    backgroundColor: colorScheme.tertiaryContainer,
                    child: Icon(
                      Icons.medical_services_outlined,
                      color: colorScheme.onTertiaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                information,
                const SizedBox(height: 20),
                Align(child: illustration),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: information),
              const SizedBox(width: 24),
              illustration,
            ],
          );
        },
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
            : Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                runSpacing: 12,
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
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 180),
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
                  if (controller.auth.checkingReadAccess)
                    const Chip(
                      avatar: SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      label: Text('กำลังตรวจสิทธิ์'),
                    )
                  else if (controller.auth.readAccessGranted)
                    const Chip(
                      avatar: Icon(Icons.verified_outlined, size: 18),
                      label: Text('พร้อมอ่าน Sheets และ Calendar'),
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: controller.busy
                          ? null
                          : () => perform(controller.authorizeReadAccess),
                      icon: const Icon(Icons.verified_user_outlined),
                      label: const Text('อนุญาตสิทธิ์อ่าน'),
                    ),
                  TextButton(
                    onPressed: controller.busy
                        ? null
                        : () => perform(controller.signOut),
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
      _StatCard(
        label: 'แจ้งเตือนค้าง',
        value: controller.pendingAlertCount,
        icon: Icons.notification_important_outlined,
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
        final sourceColor = ShiftColorService.classify(shift.sourceColorValue);
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
                    labelText: 'ประเภท/สี Calendar',
                    isDense: true,
                  ),
                  items: [
                    for (final category in ShiftCategory.values)
                      DropdownMenuItem(
                        value: category,
                        child: Text(
                          '${category.label} • ${category.colorName}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: shift.generated
                      ? null
                      : (value) {
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
                          shift.displayName,
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
                        if (shift.generated)
                          const Chip(
                            visualDensity: VisualDensity.compact,
                            avatar: Icon(Icons.bedtime_outlined, size: 16),
                            label: Text('OFF อัตโนมัติ'),
                          ),
                        if (shift.sourceColorValue != null)
                          Chip(
                            visualDensity: VisualDensity.compact,
                            avatar: CircleAvatar(
                              backgroundColor: Color(shift.sourceColorValue!),
                              radius: 8,
                            ),
                            label: Text(
                              'สีไฟล์หลัก: '
                              '${sourceColor?.sourceName ?? shift.sourceColorHex}',
                            ),
                          ),
                        if (sourceColor?.requiresReview == true)
                          const Chip(
                            visualDensity: VisualDensity.compact,
                            avatar: Icon(Icons.info_outline, size: 16),
                            label: Text(
                              'ลาเวนเดอร์: ตรวจว่าแลกเวรใหญ่หรือยกเวร',
                            ),
                          ),
                      ],
                    ),
                    Text(
                      '${_thaiDate(shift.start)} • ${_time(shift.start)}–${_time(shift.end)}',
                    ),
                    Text(
                      '${shift.sheetTitle} • ${shift.cell} • ${shift.assignedName}',
                    ),
                    if (shift.generated)
                      const Text('ช่วงพัก 08:00–16:00 หลังเวรดึก'),
                  ],
                );
                final check = Checkbox(
                  value: !shift.excluded,
                  onChanged: shift.generated
                      ? null
                      : (value) => controller.updateShift(
                          index,
                          excluded: value != true,
                        ),
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

class _NotificationsPage extends StatelessWidget {
  const _NotificationsPage({required this.controller, required this.perform});

  final AppController controller;
  final Future<void> Function(Future<void> Function()) perform;

  @override
  Widget build(BuildContext context) {
    if (controller.alerts.isEmpty) {
      return const _EmptyState(
        icon: Icons.notifications_none,
        title: 'ยังไม่มีการแจ้งเตือน',
        message:
            'เมื่ออ่านเวรและเปรียบเทียบ Calendar แอปจะตรวจเวรซ้อนและช่วง OFF ให้อัตโนมัติ',
      );
    }
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          color: controller.pendingAlertCount > 0
              ? Theme.of(context).colorScheme.errorContainer
              : Theme.of(context).colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ศูนย์แจ้งเตือนเวร',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  'รอตัดสินใจ ${controller.pendingAlertCount} รายการ • '
                  'พบรายการชน ${controller.conflictAlertCount} รายการ',
                ),
                const SizedBox(height: 8),
                const Text(
                  'รับทราบและคงไว้ = เขียนตามรายการเดิม • ยืนยันรายการ = '
                  'ยืนยันรายการที่เลือก • ไม่นำเข้าปฏิทิน = ตัดรายการที่ชนออก',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        for (final alert in controller.alerts) ...[
          _AlertCard(
            alert: alert,
            onDecision: (decision) =>
                perform(() => controller.resolveAlert(alert.id, decision)),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert, required this.onDecision});

  final ShiftAlert alert;
  final Future<void> Function(ShiftAlertDecision decision) onDecision;

  @override
  Widget build(BuildContext context) {
    final color = switch (alert.type) {
      ShiftAlertType.offAfterNight => Colors.indigo,
      ShiftAlertType.offConflict => Colors.deepOrange,
      ShiftAlertType.shiftOverlap => Colors.red,
      ShiftAlertType.calendarOverlap => Colors.purple,
    };
    final icon = switch (alert.type) {
      ShiftAlertType.offAfterNight => Icons.bedtime_outlined,
      ShiftAlertType.offConflict => Icons.do_not_disturb_on_outlined,
      ShiftAlertType.shiftOverlap => Icons.warning_amber_rounded,
      ShiftAlertType.calendarOverlap => Icons.event_busy_outlined,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        alert.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Chip(
                        visualDensity: VisualDensity.compact,
                        avatar: Icon(
                          alert.isPending
                              ? Icons.schedule
                              : Icons.check_circle_outline,
                          size: 16,
                        ),
                        label: Text(alert.decision.label),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(alert.message),
                  const SizedBox(height: 4),
                  Text(
                    '${_thaiDate(alert.start)} • '
                    '${_time(alert.start)}–${_time(alert.end)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (alert.requiresDecision) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () =>
                              onDecision(ShiftAlertDecision.acknowledged),
                          icon: const Icon(Icons.done),
                          label: const Text('รับทราบและคงไว้'),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: () =>
                              onDecision(ShiftAlertDecision.accepted),
                          icon: const Icon(Icons.add_task),
                          label: const Text('ยืนยันรายการ'),
                        ),
                        TextButton.icon(
                          onPressed: () =>
                              onDecision(ShiftAlertDecision.cancelled),
                          icon: const Icon(Icons.cancel_outlined),
                          label: const Text('ไม่นำเข้าปฏิทิน'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuditPage extends StatelessWidget {
  const _AuditPage({
    required this.controller,
    required this.saveCurrentSheet,
    required this.activateSavedSheet,
    required this.openSavedSheet,
    required this.deleteSavedSheet,
  });

  final AppController controller;
  final Future<void> Function() saveCurrentSheet;
  final Future<void> Function(SavedSheet sheet) activateSavedSheet;
  final Future<void> Function(SavedSheet sheet) openSavedSheet;
  final Future<void> Function(SavedSheet sheet) deleteSavedSheet;

  @override
  Widget build(BuildContext context) {
    final account = controller.auth.account;
    final sheets = controller.savedSheetsForCurrentAccount;
    final canSave =
        account != null &&
        controller.currentSourceUrl.isNotEmpty &&
        !controller.busy;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final heading = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ชีตที่บันทึก',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'เปิดดูชีตที่สร้างหรือบันทึกไว้ แยกตามบัญชี Google ที่ล็อกอิน',
                        ),
                      ],
                    );
                    final button = FilledButton.icon(
                      onPressed: canSave
                          ? () => unawaited(saveCurrentSheet())
                          : null,
                      icon: const Icon(Icons.bookmark_add_outlined),
                      label: const Text('บันทึกชีตปัจจุบัน'),
                    );
                    if (constraints.maxWidth < 720) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          heading,
                          const SizedBox(height: 12),
                          Align(alignment: Alignment.centerLeft, child: button),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: heading),
                        const SizedBox(width: 16),
                        button,
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                const Text(
                  'เก็บเฉพาะลิงก์และชื่อชีตในเครื่องนี้ ไม่เก็บอีเมลหรือ token และไม่ส่งขึ้น GitHub',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 16),
                if (account == null)
                  const _SavedSheetNotice(
                    icon: Icons.account_circle_outlined,
                    text: 'ล็อกอิน Google เพื่อดูรายการของบัญชีนี้',
                  )
                else if (sheets.isEmpty)
                  const _SavedSheetNotice(
                    icon: Icons.link_off_outlined,
                    text:
                        'เลือก Google Sheets จาก Google Drive ในหน้าแรก '
                        'แล้วกดรีเฟรชเพื่ออ่านตารางเวร',
                  )
                else
                  for (final sheet in sheets)
                    _SavedSheetCard(
                      sheet: sheet,
                      active: controller.currentSourceSheet?.key == sheet.key,
                      disabled: controller.busy,
                      activate: activateSavedSheet,
                      open: openSavedSheet,
                      delete: deleteSavedSheet,
                    ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text('ประวัติการทำงาน', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (controller.auditEntries.isEmpty)
          const Card(
            child: ListTile(
              leading: Icon(Icons.history_outlined),
              title: Text('ยังไม่มี Audit log'),
              subtitle: Text(
                'การอ่าน สำเนา และการเขียนจะบันทึกไว้ในเครื่องนี้',
              ),
            ),
          )
        else
          for (final entry in controller.auditEntries)
            Card(
              child: ListTile(
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
              ),
            ),
      ],
    );
  }
}

class _SavedSheetNotice extends StatelessWidget {
  const _SavedSheetNotice({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    ),
  );
}

class _SavedSheetCard extends StatelessWidget {
  const _SavedSheetCard({
    required this.sheet,
    required this.active,
    required this.disabled,
    required this.activate,
    required this.open,
    required this.delete,
  });

  final SavedSheet sheet;
  final bool active;
  final bool disabled;
  final Future<void> Function(SavedSheet sheet) activate;
  final Future<void> Function(SavedSheet sheet) open;
  final Future<void> Function(SavedSheet sheet) delete;

  @override
  Widget build(BuildContext context) => Card.outlined(
    margin: const EdgeInsets.only(bottom: 10),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final details = Row(
                children: [
                  const CircleAvatar(child: Icon(Icons.table_chart_outlined)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sheet.displayTitle,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (active)
                          Text(
                            'ไฟล์หลักของบัญชีนี้',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        const SizedBox(height: 2),
                        Text(
                          '${sheet.contextLabel} • บันทึก ${_thaiDate(sheet.savedAt)} ${_clock(sheet.savedAt)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions = Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: disabled || active
                        ? null
                        : () => unawaited(activate(sheet)),
                    icon: Icon(active ? Icons.check_circle : Icons.swap_horiz),
                    label: Text(active ? 'กำลังใช้งาน' : 'ใช้ไฟล์นี้'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: disabled ? null : () => unawaited(open(sheet)),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('เปิดดู'),
                  ),
                  TextButton.icon(
                    onPressed: disabled ? null : () => unawaited(delete(sheet)),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('ลบ'),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              );
          if (constraints.maxWidth < 620) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [details, const SizedBox(height: 12), actions],
            );
          }
          return Row(
            children: [
              Expanded(child: details),
              const SizedBox(width: 12),
              actions,
            ],
          );
        },
      ),
    ),
  );
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
    text: _suggestedFutureSheetTitle(widget.controller),
  );

  @override
  void didUpdateWidget(covariant _FutureSheetCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (template.text.trim().isEmpty &&
        widget.controller.sheetTitles.isNotEmpty) {
      template.text = widget.controller.sheetTitles.last;
    }
    final suggestedTitle = _suggestedFutureSheetTitle(widget.controller);
    if (newTitle.text.trim().isEmpty && suggestedTitle.isNotEmpty) {
      newTitle.text = suggestedTitle;
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

String _suggestedFutureSheetTitle(AppController controller) {
  final month = controller.settings.month;
  final year = controller.settings.year;
  if (month == null || year == null) return '';
  return 'เวร ${_thaiMonths[month - 1]} ${year + 543}';
}
