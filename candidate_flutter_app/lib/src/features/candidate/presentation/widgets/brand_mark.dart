import 'package:flutter/material.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * .28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [theme.colorScheme.primary, theme.colorScheme.tertiary],
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: .22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            'SM',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontSize: size * .34,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class SmartHireLockup extends StatelessWidget {
  const SmartHireLockup({super.key, this.center = false, this.markSize = 52});

  final bool center;
  final double markSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment:
          center ? MainAxisAlignment.center : MainAxisAlignment.start,
      children: [
        BrandMark(size: markSize),
        const SizedBox(width: 12),
        // Flexible(
        //   child: Column(
        //     crossAxisAlignment:
        //         center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        //     children: [
        //       Text(
        //         'SmartHire',
        //         style: theme.textTheme.titleLarge?.copyWith(
        //           fontWeight: FontWeight.w900,
        //         ),
        //       ),
        //       Text(
        //         'AI-powered hiring portal',
        //         style: theme.textTheme.bodySmall?.copyWith(
        //           color: theme.colorScheme.onSurfaceVariant,
        //           fontWeight: FontWeight.w700,
        //         ),
        //       ),
        //     ],
        //   ),
        // ),
      ],
    );
  }
}
