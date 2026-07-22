class AuditEntry {
  const AuditEntry({
    required this.timestamp,
    required this.action,
    required this.message,
    required this.success,
  });

  final DateTime timestamp;
  final String action;
  final String message;
  final bool success;

  Map<String, Object?> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'action': action,
    'message': message,
    'success': success,
  };

  factory AuditEntry.fromJson(Map<String, Object?> json) => AuditEntry(
    timestamp:
        DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
    action: json['action']?.toString() ?? '-',
    message: json['message']?.toString() ?? '-',
    success: json['success'] == true,
  );
}
