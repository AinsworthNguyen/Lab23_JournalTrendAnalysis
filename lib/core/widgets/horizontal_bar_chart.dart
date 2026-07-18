import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

class HorizontalBarChart extends StatelessWidget {
  final List<String> labels;
  final List<double> values;
  final String title;
  final Color barColor;

  const HorizontalBarChart({
    super.key,
    required this.labels,
    required this.values,
    required this.title,
    required this.barColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxValue = values.isEmpty ? 1.0 : values.reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: labels.length,
          itemBuilder: (context, index) {
            final label = labels[index];
            final value = values[index];
            final pct = maxValue == 0 ? 0.0 : value / maxValue;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        overflow: TextOverflow.ellipsis,
                      ),
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 6,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: pct),
                        duration: const Duration(milliseconds: 1000),
                        curve: Curves.easeOutCubic,
                        builder: (context, val, child) {
                          return Container(
                            height: 16,
                            width: MediaQuery.of(context).size.width * 0.45 * val,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  barColor.withValues(alpha: 0.6),
                                  barColor,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 50,
                    child: Text(
                      intl.NumberFormat.compact().format(value),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
