import 'package:flutter/material.dart';

class AccountCard extends StatelessWidget {
  const AccountCard({super.key, required this.email, required this.connected});

  final String? email;
  final bool connected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: connected
                  ? colors.primaryContainer
                  : colors.surfaceContainerHighest,
              child: Icon(
                connected
                    ? Icons.cloud_done_outlined
                    : Icons.cloud_off_outlined,
                color: connected
                    ? colors.onPrimaryContainer
                    : colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'บัญชี Google',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    connected ? email! : 'ยังไม่ได้เชื่อมต่อ',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              connected ? Icons.check_circle : Icons.info_outline,
              color: connected ? colors.primary : colors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
