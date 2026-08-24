import 'package:flutter/material.dart';

class ShiftSummaryCard extends StatelessWidget {
  const ShiftSummaryCard({super.key, required this.shiftCount});

  final int shiftCount;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(Icons.event_available_outlined),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'จำนวนเวรที่พบ',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Text(
              '$shiftCount',
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
