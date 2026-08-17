import 'package:flutter/material.dart';

class MeetingStatCards extends StatelessWidget {
  final String activeFilter;
  final Function(String) onFilterChanged;
  final Map<String, int> counts;
  final List<Map<String, dynamic>> filters;

  const MeetingStatCards({
    super.key,
    required this.activeFilter,
    required this.onFilterChanged,
    required this.counts,
    required this.filters,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final id = filter['id'] as String;
          final label = filter['label'] as String;
          final count = counts[id] ?? 0;
          final isActive = activeFilter == id;

          return GestureDetector(
            onTap: () => onFilterChanged(id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 140,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isActive ? Colors.deepPurple.shade50 : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isActive ? Colors.deepPurple.shade200 : Colors.grey.shade200,
                  width: isActive ? 1.5 : 1,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: Colors.deepPurple.withValues(alpha: 0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        count.toString(),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: isActive ? Colors.deepPurple.shade700 : Colors.black87,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isActive ? Colors.deepPurple.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          filter['icon'] as IconData,
                          size: 16,
                          color: isActive ? Colors.deepPurple.shade600 : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.deepPurple.shade600 : Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
