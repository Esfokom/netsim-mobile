import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class DescriptionCard extends StatelessWidget {
  final String description;

  const DescriptionCard({super.key, required this.description});

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return ShadCard(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.description_outlined,
                  color: Colors.blue[700],
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Description',
                  style: theme.textTheme.h4.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
