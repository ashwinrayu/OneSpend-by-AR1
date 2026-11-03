import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class ExpenseBreakdownDonut extends StatefulWidget {
  const ExpenseBreakdownDonut({super.key});

  @override
  State<ExpenseBreakdownDonut> createState() => _ExpenseBreakdownDonutState();
}

class _ExpenseBreakdownDonutState extends State<ExpenseBreakdownDonut> {
  int touchedIndex = -1;

  final List<({String label, double value, Color color})> categories = const [
    (label: 'Food & Dining', value: 23, color: Color(0xFF10B981)),
    (label: 'Shopping', value: 22, color: Color(0xFF8B5CF6)),
    (label: 'Utilities', value: 19, color: Color(0xFFF59E0B)),
    (label: 'Transport', value: 18, color: Color(0xFF06B6D4)),
    (label: 'Entertainment', value: 8, color: Color(0xFFEC4899)),
    (label: 'Other', value: 10, color: Color(0xFF64748B)),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.desktopCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.desktopBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Expense Breakdown',
            style: TextStyle(
              color: AppColors.desktopTextPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              // Donut Chart on Left
              SizedBox(
                width: 140,
                height: 140,
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            touchedIndex = -1;
                            return;
                          }
                          touchedIndex =
                              pieTouchResponse.touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 3,
                    centerSpaceRadius: 46,
                    sections: List.generate(categories.length, (i) {
                      final isTouched = i == touchedIndex;
                      final cat = categories[i];
                      return PieChartSectionData(
                        color: cat.color,
                        value: cat.value,
                        title: '',
                        radius: isTouched ? 24 : 18,
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(width: 24),

              // Legend on Right
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: categories.map((cat) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: cat.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              cat.label,
                              style: const TextStyle(
                                color: AppColors.desktopTextPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${cat.value.toInt()}%',
                            style: const TextStyle(
                              color: AppColors.desktopTextSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
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

