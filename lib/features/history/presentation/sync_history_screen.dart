import 'package:flutter/material.dart';

import '../application/sync_history_controller.dart';
import '../domain/sync_history_entry.dart';

class SyncHistoryScreen extends StatefulWidget {
  const SyncHistoryScreen({
    required this.controller,
    super.key,
  });

  final SyncHistoryController controller;

  @override
  State<SyncHistoryScreen> createState() =>
      _SyncHistoryScreenState();
}

class _SyncHistoryScreenState extends State<SyncHistoryScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.load();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('ประวัติการซิงก์'),
          ),
          body: _buildBody(),
        );
      },
    );
  }

  Widget _buildBody() {
    if (widget.controller.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (widget.controller.message != null) {
      return Center(
        child: Text(widget.controller.message!),
      );
    }

    if (widget.controller.entries.isEmpty) {
      return const Center(
        child: Text('ยังไม่มีประวัติการซิงก์'),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: widget.controller.entries.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final entry = widget.controller.entries[index];

        return Card(
          child: ListTile(
            leading: Icon(_iconFor(entry.status)),
            title: Text(_labelFor(entry.status)),
            subtitle: Text(
              'เริ่ม: ${entry.startedAt.toLocal()}\n'
              'เพิ่ม ${entry.inserted} · '
              'แก้ไข ${entry.updated} · '
              'ลบ ${entry.deleted} · '
              'ล้มเหลว ${entry.failed}',
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  IconData _iconFor(SyncHistoryStatus status) {
    return switch (status) {
      SyncHistoryStatus.running =>
        Icons.sync,
      SyncHistoryStatus.success =>
        Icons.check_circle_outline,
      SyncHistoryStatus.partialSuccess =>
        Icons.warning_amber_outlined,
      SyncHistoryStatus.failure =>
        Icons.error_outline,
    };
  }

  String _labelFor(SyncHistoryStatus status) {
    return switch (status) {
      SyncHistoryStatus.running =>
        'กำลังซิงก์',
      SyncHistoryStatus.success =>
        'สำเร็จ',
      SyncHistoryStatus.partialSuccess =>
        'สำเร็จบางส่วน',
      SyncHistoryStatus.failure =>
        'ไม่สำเร็จ',
    };
  }
}
