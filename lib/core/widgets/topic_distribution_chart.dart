import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class TopicDistributionChart extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> topicData; // [{'name': 'AI', 'value': 45.0, 'color': Color}, ...]

  const TopicDistributionChart({
    super.key,
    required this.title,
    required this.topicData,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = topicData.fold<double>(0, (sum, item) => sum + (item['value'] as double? ?? 0));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              // Pie Chart
              SizedBox(
                width: 130,
                height: 130,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: 32,
                    sections: topicData.map((item) {
                      final val = item['value'] as double? ?? 0;
                      final color = item['color'] as Color? ?? theme.colorScheme.primary;
                      final pct = total > 0 ? (val / total * 100).toStringAsFixed(0) : '0';
                      return PieChartSectionData(
                        color: color,
                        value: val,
                        title: '$pct%',
                        radius: 28,
                        titleStyle: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // Legend
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: topicData.map((item) {
                    final name = item['name'] as String? ?? '';
                    final val = item['value'] as double? ?? 0;
                    final color = item['color'] as Color? ?? theme.colorScheme.primary;
                    final pct = total > 0 ? (val / total * 100).toStringAsFixed(1) : '0';

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              name,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '$pct%',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
