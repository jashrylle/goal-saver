import 'package:flutter/material.dart';

/// Responsive 2-column grid on wide screens; stacked column on narrow ones.
class ResponsiveChartGrid extends StatelessWidget {
  const ResponsiveChartGrid({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 640) {
      return Column(
        children: children
            .map((child) => Padding(padding: const EdgeInsets.only(bottom: 12), child: child))
            .toList(),
      );
    }
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.25,
      children: children,
    );
  }
}
