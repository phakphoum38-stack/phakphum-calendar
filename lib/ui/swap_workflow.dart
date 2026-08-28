import 'package:flutter/material.dart';
import '../features/diff_engine/domain/calendar_event_candidate.dart';
import '../models/swap_request.dart';
import '../models/audit_entry.dart';
import '../models/shift.dart';
import 'dart:convert';
import 'package:file_saver/file_saver.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/swap_request_service.dart';
import 'preview_changes.dart';

class SwapWorkflowPage extends StatefulWidget {
  const SwapWorkflowPage({
    super.key,
    required this.controller,
  });

  final dynamic controller; // AppController (avoid import cycle in this file)

  @override
  State<SwapWorkflowPage> createState() => _SwapWorkflowPageState();
}

class _SwapWorkflowPageState extends State<SwapWorkflowPage> with SingleTickerProviderStateMixin {
  late final TabController tabController = TabController(length: 3, vsync: this);
  final List<Map<String, String>> requests = [
    {
      'id': 'REQ-001',
      'requester': 'สมชาย',
      'target': 'สมศรี',
      'shift': '20 ส.ค. 08:00–16:00',
      'status': 'Pending'
    },
    {
      'id': 'REQ-002',
      'requester': 'นพพล',
      'target': 'สมชาย',
      'shift': '21 ส.ค. 16:00–00:00',
      'status': 'Approved'
    }
  ];
  int? _selectedShiftIndex;
  final _swapService = SwapRequestService();
  List<SwapRequest> _storedRequests = [];

  @override
  Widget build(BuildContext context) {
    // ensure stored requests are loaded
    if (_storedRequests.isEmpty) {
      _swapService.loadAll().then((list) {
        setState(() => _storedRequests = list);
      });
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Swap workflow'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined),
            tooltip: 'Export requests CSV',
            onPressed: _exportCsv,
          ),
        ],
        bottom: TabBar(
          controller: tabController,
          tabs: const [Tab(text: 'Requests'), Tab(text: 'Create'), Tab(text: 'History')],
        ),
      ),
      body: TabBarView(
        controller: tabController,
        children: [
          _requestsTab(context),
          _createTab(context),
          _historyTab(context),
        ],
      ),
    );
  }

  Widget _requestsTab(BuildContext context) => ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _storedRequests.length,
        itemBuilder: (context, index) {
          final r = _storedRequests[index];
          return Card(
            child: ListTile(
              leading: CircleAvatar(child: Text(r.requester.isNotEmpty ? r.requester[0] : 'U')),
              title: Text('${r.requester} → ${r.target}'),
              subtitle: Text(r.shiftRef),
              trailing: Wrap(
                spacing: 8,
                children: [
                  Chip(
                    label: Text(r.status.name),
                    backgroundColor: r.status == SwapRequestStatus.pending
                        ? Colors.orange.shade100
                        : r.status == SwapRequestStatus.approved
                            ? Colors.green.shade100
                            : Colors.red.shade100,
                  ),
                  IconButton(
                    icon: const Icon(Icons.visibility),
                    onPressed: () {
                      _openRequestPreview(r);
                    },
                  ),
                  if (r.status == SwapRequestStatus.pending) ...[
                    IconButton(
                      icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                      tooltip: 'Approve',
                      onPressed: () => _approveRequest(r),
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                      tooltip: 'Reject',
                      onPressed: () => _rejectRequest(r),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      );

  Widget _createTab(BuildContext context) {
    final reasonController = TextEditingController();
    final targetController = TextEditingController();
    final shifts = (widget.controller?.shifts as List?) ?? [];
    _selectedShiftIndex ??= shifts.isNotEmpty ? 0 : null;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (shifts.isEmpty)
              const Text('ไม่มีรายการเวรให้เลือก — กรุณาอ่านตารางก่อน')
            else
              DropdownButton<int>(
                value: _selectedShiftIndex,
                items: [
                  for (var i = 0; i < shifts.length; i++)
                    DropdownMenuItem(
                      value: i,
                      child: Text(shifts[i].displayName + ' • ${shifts[i].sheetTitle}:${shifts[i].cell}'),
                    ),
                ],
                onChanged: (v) => setState(() => _selectedShiftIndex = v),
              ),
            const SizedBox(height: 8),
            TextField(controller: targetController, decoration: const InputDecoration(labelText: 'Target (ชื่อผู้รับ)')),
            const SizedBox(height: 8),
            TextField(controller: reasonController, decoration: const InputDecoration(labelText: 'Reason')),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _selectedShiftIndex == null
                      ? null
                      : () async {
                        final shift = shifts[_selectedShiftIndex!];
                          final target = targetController.text.trim();
                          if (target.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('โปรดระบุชื่อผู้รับ')));
                            return;
                          }
                          final candidate = CalendarEventCandidate(
                            syncId: 'swap-${shift.sourceKey}-${DateTime.now().millisecondsSinceEpoch}',
                            title: '${shift.displayName} — ผู้รับ: $target',
                            start: shift.start,
                            end: shift.end,
                            shouldExist: true,
                            description: 'ต้นเวร: ${shift.assignedName}\nคำขอ: ${reasonController.text.trim()}',
                            colorId: shift.calendarColorId ?? shift.category.googleColorId,
                          );
                          try {
                            // open preview for this candidate
                            Navigator.of(context).push(MaterialPageRoute(builder: (_) => PreviewChangesPage(controller: widget.controller, desiredCandidates: [candidate])));
                          } catch (e) {
                            showDialog<void>(context: context, builder: (ctx) => AlertDialog(title: const Text('Error'), content: Text(e.toString()), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))]));
                          }
                        },
                  child: const Text('Preview changes'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _selectedShiftIndex == null
                      ? null
                      : () async {
                          final shift = shifts[_selectedShiftIndex!];
                          final target = targetController.text.trim();
                          final reason = reasonController.text.trim();
                          final id = 'REQ-${DateTime.now().millisecondsSinceEpoch}';
                          final req = SwapRequest(
                            id: id,
                            requester: widget.controller?.auth?.account?.displayName ?? 'คุณ',
                            target: target.isEmpty ? 'ไม่ระบุ' : target,
                            shiftRef: '${shift.displayName} • ${shift.sheetTitle}:${shift.cell}',
                            reason: reason,
                            createdAt: DateTime.now(),
                          );
                          try {
                            final prefs = await SharedPreferences.getInstance();
                            final strategy = prefs.getString('dev_strategy') ?? 'feature';
                            if (strategy == 'demo-backend') {
                              // send to demo backend
                              final body = {
                                'origin': req.requester,
                                'swap': req.target,
                                'receiver': req.target,
                                'shiftRef': req.shiftRef,
                                'reason': req.reason,
                                'createdAt': req.createdAt.toIso8601String(),
                              };
                              try {
                                final resp = await http.post(Uri.parse('http://localhost:8080/swap'), headers: {'Content-Type': 'application/json'}, body: jsonEncode(body)).timeout(const Duration(seconds: 5));
                                if (resp.statusCode >= 200 && resp.statusCode < 300) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ส่งคำขอไปยัง demo backend เรียบร้อย')));
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ไม่สามารถส่งไปยัง demo backend: ${resp.statusCode}')));
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ผิดพลาดขณะติดต่อ backend: $e')));
                              }
                            }
                          } catch (_) {}
                          await _swapService.save(req);
                          _storedRequests.insert(0, req);
                          setState(() {});
                          tabController.animateTo(0);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ส่งคำขอเรียบร้อย (รออนุมัติ)')));
                        },
                  child: const Text('Submit request'),
                ),
              ],
            ),
          ],
        );
      }),
    );
  }

  Widget _historyTab(BuildContext context) => ListView(
        padding: const EdgeInsets.all(12),
        children: const [
          ListTile(
            leading: Icon(Icons.history),
            title: Text('21 ส.ค. — สมศรี ↔ นพพล'),
            subtitle: Text('Approved by manager — 22 ส.ค.'),
          ),
        ],
      );

  void _openPreview() async {
    // Build a simple candidate from form inputs for preview demo.
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day, 8);
    final end = start.add(const Duration(hours: 8));
    final candidate = CalendarEventCandidate(
      syncId: 'swap-preview-${now.millisecondsSinceEpoch}',
      title: 'Swap preview',
      start: start,
      end: end,
      shouldExist: true,
      description: 'Swap preview generated from UI',
      colorId: null,
    );
    // Call controller.previewCandidates if available.
    try {
      final diff = await (widget.controller?.previewCandidates([candidate]));
      // Open PreviewChangesPage with desired candidate to show the computed diff.
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => PreviewChangesPage(
          controller: widget.controller,
          desiredCandidates: [candidate],
        ),
      ));
    } catch (e) {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Preview failed'),
          content: Text(e.toString()),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
        ),
      );
    }
  }

  Future<void> _exportCsv() async {
    if (_storedRequests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ไม่มีคำขอให้ส่งออก')));
      return;
    }
    final rows = <List<String>>[];
    rows.add(['id', 'requester', 'target', 'shiftRef', 'reason', 'createdAt', 'status']);
    for (final r in _storedRequests) {
      rows.add([
        r.id,
        r.requester,
        r.target,
        r.shiftRef,
        r.reason.replaceAll('\n', ' '),
        r.createdAt.toIso8601String(),
        r.status.name,
      ]);
    }
    final csv = rows.map((r) => r.map((c) => '"${c.replaceAll('"', '""')}"').join(',')).join('\n');
    try {
      final bytes = csv.codeUnits;
      // save to file using FileSaver if available
      await FileSaver.instance.saveFile('swap_requests', bytes, 'csv', mimeType: 'text/csv');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ส่งออกสำเร็จ')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ไม่สามารถส่งออก: $e')));
    }
  }

  void _openRequestPreview(SwapRequest r) {
    final candidate = _candidateFromRequest(r);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PreviewChangesPage(controller: widget.controller, desiredCandidates: [candidate]),
    ));
  }

  CalendarEventCandidate _candidateFromRequest(SwapRequest r) {
    final shifts = (widget.controller?.shifts as List?) ?? [];
    // attempt to find shift by sheet:cell or display name
    String? sheet;
    String? cell;
    if (r.shiftRef.contains('•')) {
      final parts = r.shiftRef.split('•');
      if (parts.length > 1) {
        final right = parts[1].trim();
        if (right.contains(':')) {
          final rc = right.split(':');
          sheet = rc[0].trim();
          cell = rc[1].trim();
        }
      }
    }
    Shift? matched;
    for (final s in shifts) {
      try {
        if (sheet != null && cell != null && s.sheetTitle == sheet && s.cell == cell) {
          matched = s as Shift;
          break;
        }
        if (r.shiftRef.contains(s.displayName)) {
          matched = s as Shift;
          break;
        }
      } catch (_) {}
    }
    if (matched != null) {
      return CalendarEventCandidate(
        syncId: 'swap-${r.id}',
        title: '${matched.displayName} — ผู้รับ: ${r.target}',
        start: matched.start,
        end: matched.end,
        shouldExist: true,
        description: 'ต้นเวร: ${r.requester}\nคำขอ: ${r.reason}',
        colorId: matched.calendarColorId ?? matched.category.googleColorId,
      );
    }
    // fallback
    final now = DateTime.now();
    return CalendarEventCandidate(
      syncId: 'swap-${r.id}',
      title: '${r.shiftRef} — ผู้รับ: ${r.target}',
      start: DateTime(now.year, now.month, now.day, 8),
      end: DateTime(now.year, now.month, now.day, 16),
      shouldExist: true,
      description: 'ต้นเวร: ${r.requester}\nคำขอ: ${r.reason}',
      colorId: null,
    );
  }

  Future<void> _approveRequest(SwapRequest r) async {
    r.status = SwapRequestStatus.approved;
    await _swapService.update(r);
    // add local audit entry for visibility
    try {
      widget.controller.auditEntries.insert(0, AuditEntry(
        timestamp: DateTime.now(),
        action: 'swap.request.approve',
        message: 'อนุมัติคำขอ ${r.id} โดย ${widget.controller.auth.account?.displayName ?? 'คุณ'}',
        success: true,
      ));
    } catch (_) {}
    // open preview for confirmation/apply
    final candidate = _candidateFromRequest(r);
    if (!mounted) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => PreviewChangesPage(controller: widget.controller, desiredCandidates: [candidate])));
    setState(() {});
  }

  Future<void> _rejectRequest(SwapRequest r) async {
    r.status = SwapRequestStatus.rejected;
    await _swapService.update(r);
    try {
      widget.controller.auditEntries.insert(0, AuditEntry(
        timestamp: DateTime.now(),
        action: 'swap.request.reject',
        message: 'ปฏิเสธคำขอ ${r.id} โดย ${widget.controller.auth.account?.displayName ?? 'คุณ'}',
        success: true,
      ));
    } catch (_) {}
    setState(() {});
  }
}
