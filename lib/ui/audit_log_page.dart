import 'package:flutter/material.dart';
import '../controller/app_controller.dart';
import '../models/audit_entry.dart';

class AuditLogPage extends StatelessWidget {
  const AuditLogPage({super.key, required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final entries = controller.auditEntries;
    return Scaffold(
      appBar: AppBar(title: const Text('Audit log')),
      body: entries.isEmpty
          ? const Center(child: Text('No audit entries'))
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemBuilder: (ctx, i) {
                final AuditEntry e = entries[i];
                return Card(
                  child: ListTile(
                    leading: Icon(e.success ? Icons.check_circle : Icons.error_outline, color: e.success ? Colors.green : Colors.red),
                    title: Text(e.action),
                    subtitle: Text(e.message),
                    trailing: Text('${e.timestamp.toLocal()}'),
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemCount: entries.length,
            ),
    );
  }
}
