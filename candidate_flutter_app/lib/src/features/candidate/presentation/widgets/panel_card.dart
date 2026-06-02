import 'package:flutter/material.dart';

class PanelCard extends StatelessWidget {
  const PanelCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: isLight ? Colors.white : theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLight ? const Color(0xffedf0f7) : const Color(0xff282b3a),
        ),
        boxShadow:
            isLight
                ? [
                  BoxShadow(
                    color: const Color(0xff101828).withValues(alpha: .045),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ]
                : null,
      ),
      child: child,
    );
  }
}
