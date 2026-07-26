import 'package:flutter/material.dart';

import '../../domain/shift.dart';

class ShiftChip extends StatelessWidget {
  const ShiftChip({required this.shift, super.key});

  final Shift shift;

  @override
  Widget build(BuildContext context) {
    final color = Color(shift.color);
    return Tooltip(
      message: '${shift.name} • ${shift.workingHours} hours',
      child: Chip(
        avatar: CircleAvatar(backgroundColor: color, radius: 6),
        label: Text(shift.code),
        backgroundColor: color.withValues(alpha: 0.12),
        side: BorderSide(color: color.withValues(alpha: 0.45)),
      ),
    );
  }
}
