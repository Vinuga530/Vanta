import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// ─── iOS GROUPED LIST CONTAINER ──────────────────────────────────────────────

class IOSGroup extends StatelessWidget {
  final List<Widget> children;
  final String? header;
  final String? footer;

  const IOSGroup({super.key, required this.children, this.header, this.footer});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (header != null)
          Padding(
            padding: const EdgeInsets.only(left: 20, bottom: 8, top: 24),
            child: Text(
              header!.toUpperCase(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.5,
                color: isDark
                    ? CupertinoColors.systemGrey
                    : CupertinoColors.secondaryLabel,
              ),
            ),
          ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1)
                  Divider(
                    height: 0.5,
                    thickness: 0.5,
                    indent: 16,
                    color: isDark
                        ? const Color(0xFF38383A)
                        : const Color(0xFFC6C6C8),
                  ),
              ],
            ],
          ),
        ),
        if (footer != null)
          Padding(
            padding: const EdgeInsets.only(left: 20, top: 8, right: 20),
            child: Text(
              footer!,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? CupertinoColors.systemGrey
                    : CupertinoColors.secondaryLabel,
              ),
            ),
          ),
      ],
    );
  }
}

// ─── iOS LIST TILE ───────────────────────────────────────────────────────────

class IOSListTile extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const IOSListTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 16)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DefaultTextStyle(
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      child: title,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      DefaultTextStyle(
                        style: const TextStyle(
                          fontSize: 13,
                          color: CupertinoColors.systemGrey,
                        ),
                        child: subtitle!,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                DefaultTextStyle(
                  style: const TextStyle(
                    fontSize: 17,
                    color: CupertinoColors.systemGrey,
                  ),
                  child: trailing!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── iOS SEARCH BAR ─────────────────────────────────────────────────────────

class IOSSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final ValueChanged<String>? onChanged;

  const IOSSearchBar({
    super.key,
    required this.controller,
    this.placeholder = 'Search',
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: CupertinoSearchTextField(
        controller: controller,
        placeholder: placeholder,
        onChanged: onChanged,
        style: TextStyle(color: isDark ? Colors.white : Colors.black),
        backgroundColor: isDark
            ? const Color(0xFF1C1C1E)
            : const Color(0xFFE5E5EA),
      ),
    );
  }
}

// ─── ANIMATED STAT CARD ─────────────────────────────────────────────────────

class AnimatedStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final List<Color> gradientColors;
  final String? subtitle;

  const AnimatedStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.gradientColors,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── CIRCULAR PROGRESS RING ─────────────────────────────────────────────────

class CircularProgressRing extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final String centerText;
  final String? subtitle;
  final double size;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  const CircularProgressRing({
    super.key,
    required this.progress,
    required this.centerText,
    this.subtitle,
    this.size = 120,
    this.trackColor = const Color(0xFF2C2C2E),
    this.progressColor = CupertinoColors.activeBlue,
    this.strokeWidth = 10,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(
              progress: progress.clamp(0.0, 1.0),
              trackColor: trackColor,
              progressColor: progressColor,
              strokeWidth: strokeWidth,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                centerText,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ─── GLASS CARD (FROSTED GLASS EFFECT) ──────────────────────────────────────

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;

  const GlassCard({super.key, required this.child, this.padding, this.margin});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16),
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.5),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ─── ICON BADGE (Colored icon container like iOS Settings) ──────────────────

class IOSIconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const IOSIconBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = 30,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.23),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: size * 0.6, color: Colors.white),
    );
  }
}
