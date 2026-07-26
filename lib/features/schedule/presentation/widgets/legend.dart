import 'package:flutter/material.dart';

import '../../domain/shift.dart';

class Legend extends StatelessWidget {
  const Legend({required this.shifts, super.key});

  final List<Shift> shifts;

  @override
  Widget build(BuildContext context) {
    if (shifts.isEmpty) {
      return const SizedBox.shrink();
    }
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        for (final shift in shifts)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Color(shift.color),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 6),
              Text('${shift.code} — ${shift.name}'),
            ],
          ),
      ],
    );
  }
}
