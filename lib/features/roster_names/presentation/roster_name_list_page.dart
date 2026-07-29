import 'dart:async';

import 'package:flutter/material.dart';

import '../domain/roster_name_entry.dart';

class RosterNameListPage extends StatefulWidget {
  const RosterNameListPage({super.key});

  @override
  State<RosterNameListPage> createState() => _RosterNameListPageState();
}

class _RosterNameListPageState extends State<RosterNameListPage> {
  final repository = RosterNameRepository();
  final search = TextEditingController();
  List<RosterNameEntry> entries = const [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final loaded = await repository.load();
    if (mounted) {
      setState(() {
        entries = loaded;
        loading = false;
      });
    }
  }

  Future<void> _edit([RosterNameEntry? current]) async {
    final result = await showDialog<RosterNameEntry>(
      context: context,
      builder: (context) => _RosterNameDialog(entry: current),
    );
    if (result == null) return;
    final updated = [...entries];
    final index = updated.indexWhere((entry) => entry.id == result.id);
    if (index == -1) {
      updated.add(result);
    } else {
      updated[index] = result;
    }
    updated.sort((left, right) => left.name.compareTo(right.name));
    await repository.saveAll(updated);
    if (mounted) setState(() => entries = List.unmodifiable(updated));
  }

  Future<void> _addList() async {
    final names = await showDialog<List<String>>(
      context: context,
      builder: (context) => const _RosterNameBulkDialog(),
    );
    if (names == null || names.isEmpty) return;
    final existingNames = entries
        .map((entry) => entry.name.toLowerCase())
        .toSet();
    final now = DateTime.now().microsecondsSinceEpoch;
    final additions = [
      for (var index = 0; index < names.length; index++)
        if (existingNames.add(names[index].toLowerCase()))
          RosterNameEntry(
            id: 'roster-name-$now-$index',
            name: names[index],
            statuses: const [],
          ),
    ];
    final updated = [...entries, ...additions]
      ..sort((left, right) => left.name.compareTo(right.name));
    await repository.saveAll(updated);
    if (mounted) setState(() => entries = List.unmodifiable(updated));
  }

  Future<void> _toggleLock(RosterNameEntry entry, bool locked) async {
    String? point;
    if (locked) {
      point = await showDialog<String>(
        context: context,
        builder: (context) =>
            _DutyPointDialog(initialValue: entry.lockedDutyPoint),
      );
      if (point == null) return;
    }
    final updated = [
      for (final item in entries)
        if (item.id == entry.id)
          RosterNameEntry(
            id: item.id,
            name: item.name,
            statuses: item.statuses,
            lockedDutyPoint: point,
          )
        else
          item,
    ];
    await repository.saveAll(updated);
    if (mounted) setState(() => entries = List.unmodifiable(updated));
  }

  Future<void> _delete(RosterNameEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ลบรายชื่อ?'),
        content: Text('ลบ “${entry.name}” จากรายการในเครื่องนี้'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final updated = entries
        .where((item) => item.id != entry.id)
        .toList(growable: false);
    await repository.saveAll(updated);
    if (mounted) setState(() => entries = updated);
  }

  @override
  Widget build(BuildContext context) {
    final query = search.text.trim().toLowerCase();
    final visible = entries
        .where(
          (entry) =>
              query.isEmpty ||
              entry.name.toLowerCase().contains(query) ||
              entry.statuses.any(
                (status) => status.toLowerCase().contains(query),
              ),
        )
        .toList(growable: false);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'รายชื่อ',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            IconButton.filled(
              onPressed: loading ? null : _addList,
              icon: const Icon(Icons.playlist_add),
              tooltip: 'เพิ่มลิสต์รายชื่อ',
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text('รายชื่อและสถานะสำหรับใช้อ้างอิงในตารางเวรรายวัน'),
        const SizedBox(height: 16),
        TextField(
          controller: search,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'ค้นหาชื่อหรือสถานะ',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 16),
        if (loading)
          const LinearProgressIndicator()
        else if (visible.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Column(
              children: [
                Icon(Icons.badge_outlined, size: 48),
                SizedBox(height: 12),
                Text('ยังไม่มีรายชื่อ'),
              ],
            ),
          )
        else
          RosterNameStatusList(
            entries: visible,
            onEdit: _edit,
            onDelete: _delete,
            onLockChanged: _toggleLock,
          ),
      ],
    );
  }
}

class RosterNameStatusList extends StatelessWidget {
  const RosterNameStatusList({
    super.key,
    required this.entries,
    this.onEdit,
    this.onDelete,
    this.onLockChanged,
  });

  final List<RosterNameEntry> entries;
  final ValueChanged<RosterNameEntry>? onEdit;
  final ValueChanged<RosterNameEntry>? onDelete;
  final void Function(RosterNameEntry entry, bool locked)? onLockChanged;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var index = 0; index < entries.length; index++) ...[
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          leading: CircleAvatar(
            child: Text(entries[index].name.characters.firstOrNull ?? '?'),
          ),
          title: Row(
            children: [
              Expanded(child: Text(entries[index].name)),
              if (onLockChanged != null) ...[
                Checkbox(
                  value: entries[index].lockedDutyPoint != null,
                  onChanged: (value) =>
                      onLockChanged?.call(entries[index], value ?? false),
                ),
                const Text('ล็อก'),
                const SizedBox(width: 8),
              ],
              ActionChip(
                avatar: const Icon(Icons.label_outline, size: 16),
                label: const Text('สถานะ'),
                onPressed: onEdit == null
                    ? null
                    : () => onEdit?.call(entries[index]),
              ),
              if (onEdit != null || onDelete != null)
                PopupMenuButton<String>(
                  tooltip: 'จัดการรายชื่อ',
                  onSelected: (value) => value == 'edit'
                      ? onEdit?.call(entries[index])
                      : onDelete?.call(entries[index]),
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('แก้ไข')),
                    PopupMenuItem(value: 'delete', child: Text('ลบ')),
                  ],
                ),
            ],
          ),
          subtitle: entries[index].statuses.isEmpty
              ? entries[index].lockedDutyPoint == null
                    ? const Text('ยังไม่ได้กำหนดสถานะ')
                    : _RosterNameLabels(entry: entries[index])
              : Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: _RosterNameLabels(entry: entries[index]),
                ),
        ),
        if (index != entries.length - 1) const Divider(height: 1),
      ],
    ],
  );
}

class _RosterNameLabels extends StatelessWidget {
  const _RosterNameLabels({required this.entry});

  final RosterNameEntry entry;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 6,
    runSpacing: 6,
    children: [
      if (entry.lockedDutyPoint case final point?)
        Chip(
          avatar: const Icon(Icons.lock_outline, size: 16),
          label: Text('ล็อก: $point'),
        ),
      for (final status in entry.statuses) Chip(label: Text(status)),
    ],
  );
}

class _RosterNameBulkDialog extends StatefulWidget {
  const _RosterNameBulkDialog();

  @override
  State<_RosterNameBulkDialog> createState() => _RosterNameBulkDialogState();
}

class _RosterNameBulkDialogState extends State<_RosterNameBulkDialog> {
  final names = TextEditingController();

  @override
  void dispose() {
    names.dispose();
    super.dispose();
  }

  void _submit() {
    final values = names.text
        .split(RegExp(r'[\r\n,]+'))
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (values.isEmpty) return;
    Navigator.pop(context, values);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('เพิ่มลิสต์รายชื่อ'),
    content: SizedBox(
      width: 520,
      child: TextField(
        controller: names,
        autofocus: true,
        minLines: 6,
        maxLines: 12,
        decoration: const InputDecoration(
          labelText: 'รายชื่อเจ้าหน้าที่',
          hintText: 'หนึ่งคนต่อหนึ่งบรรทัด',
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('ยกเลิก'),
      ),
      FilledButton.icon(
        onPressed: _submit,
        icon: const Icon(Icons.playlist_add),
        label: const Text('เพิ่มรายชื่อ'),
      ),
    ],
  );
}

class _DutyPointDialog extends StatefulWidget {
  const _DutyPointDialog({this.initialValue});

  final String? initialValue;

  @override
  State<_DutyPointDialog> createState() => _DutyPointDialogState();
}

class _DutyPointDialogState extends State<_DutyPointDialog> {
  late final point = TextEditingController(text: widget.initialValue ?? '');

  @override
  void dispose() {
    point.dispose();
    super.dispose();
  }

  void _submit() {
    final value = point.text.trim();
    if (value.isNotEmpty) Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('ล็อกบุคคลไว้ที่จุดเวร'),
    content: TextField(
      controller: point,
      autofocus: true,
      onSubmitted: (_) => _submit(),
      decoration: const InputDecoration(labelText: 'ชื่อจุดเวร'),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('ยกเลิก'),
      ),
      FilledButton(onPressed: _submit, child: const Text('ล็อก')),
    ],
  );
}

class _RosterNameDialog extends StatefulWidget {
  const _RosterNameDialog({this.entry});

  final RosterNameEntry? entry;

  @override
  State<_RosterNameDialog> createState() => _RosterNameDialogState();
}

class _RosterNameDialogState extends State<_RosterNameDialog> {
  late final name = TextEditingController(text: widget.entry?.name ?? '');
  late final status = TextEditingController();
  late final lockedDutyPoint = TextEditingController(
    text: widget.entry?.lockedDutyPoint ?? '',
  );
  late final List<String> statuses = [...?widget.entry?.statuses];

  @override
  void dispose() {
    name.dispose();
    status.dispose();
    lockedDutyPoint.dispose();
    super.dispose();
  }

  void _addStatus() {
    final value = status.text.trim();
    if (value.isEmpty || statuses.contains(value)) return;
    setState(() {
      statuses.add(value);
      status.clear();
    });
  }

  void _submit() {
    final displayName = name.text.trim();
    if (displayName.isEmpty) return;
    Navigator.pop(
      context,
      RosterNameEntry(
        id:
            widget.entry?.id ??
            'roster-name-${DateTime.now().microsecondsSinceEpoch}',
        name: displayName,
        statuses: List.unmodifiable(statuses),
        lockedDutyPoint: lockedDutyPoint.text.trim().isEmpty
            ? null
            : lockedDutyPoint.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.entry == null ? 'เพิ่มรายชื่อ' : 'แก้ไขรายชื่อ'),
    content: SizedBox(
      width: 520,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: name,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'ชื่อ'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: lockedDutyPoint,
            decoration: const InputDecoration(
              labelText: 'ล็อกจุดเวร',
              hintText: 'เว้นว่างหากไม่ต้องการล็อก',
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: status,
                  onSubmitted: (_) => _addStatus(),
                  decoration: const InputDecoration(
                    labelText: 'สถานะ',
                    hintText: 'เช่น เช้า, OFF, เวร, แทนเวร',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: _addStatus,
                icon: const Icon(Icons.add),
                tooltip: 'เพิ่มสถานะ',
              ),
            ],
          ),
          if (statuses.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final value in statuses)
                  InputChip(
                    label: Text(value),
                    onDeleted: () => setState(() => statuses.remove(value)),
                  ),
              ],
            ),
          ],
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('ยกเลิก'),
      ),
      FilledButton.icon(
        onPressed: _submit,
        icon: const Icon(Icons.save_outlined),
        label: const Text('บันทึก'),
      ),
    ],
  );
}

class DailyRosterNameStatusPanel extends StatefulWidget {
  const DailyRosterNameStatusPanel({super.key});

  @override
  State<DailyRosterNameStatusPanel> createState() =>
      _DailyRosterNameStatusPanelState();
}

class _DailyRosterNameStatusPanelState
    extends State<DailyRosterNameStatusPanel> {
  List<RosterNameEntry> entries = const [];

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final loaded = await RosterNameRepository().load();
    if (mounted) setState(() => entries = loaded);
  }

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Text(
                'รายชื่อและสถานะ',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            IconButton(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              tooltip: 'อ่านรายชื่อใหม่',
            ),
          ],
        ),
        RosterNameStatusList(entries: entries),
      ],
    );
  }
}
