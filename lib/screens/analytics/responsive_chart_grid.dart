import 'package:flutter/material.dart';

/// Responsive 2-column grid on wide screens; stacked column on narrow ones.
/// Uses intrinsic sizing instead of a fixed aspect ratio to prevent overflow.
class ResponsiveChartGrid extends StatelessWidget {
  const ResponsiveChartGrid({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 640) {
      return Column(
        children: children
            .map((child) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: child,
                ))
            .toList(),
      );
    }
    // Wide screen: two-column row layout (avoids fixed aspect ratio overflow)
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children.asMap().entries.map((entry) {
        final isLast = entry.key == children.length - 1;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : 12),
            child: entry.value,
          ),
        );
      }).toList(),
    );
  }
}
