import 'package:flutter/material.dart';

class StatCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final String? subtitle;
  final String? fullValue; // Nilai lengkap yang ditampilkan saat ditekan
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.iconColor = Colors.blue,
    this.subtitle,
    this.fullValue,
    this.onTap,
  });

  @override
  State<StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<StatCard> {
  bool _showFullValue = false;

  @override
  Widget build(BuildContext context) {
    final displayValue = (_showFullValue && widget.fullValue != null)
        ? widget.fullValue!
        : widget.value;

    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolvedIconColor = widget.iconColor == Colors.blue
        ? colorScheme.primary
        : widget.iconColor;
    return Card(
      elevation: isDark ? 0 : 1,
      color: isDark
          ? colorScheme.surfaceContainerHigh
          : resolvedIconColor.withValues(alpha: 0.035),
      shadowColor: isDark
          ? Colors.transparent
          : colorScheme.shadow.withValues(alpha: 0.08),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark
              ? colorScheme.outlineVariant
              : resolvedIconColor.withValues(alpha: 0.12),
        ),
      ),
      child: InkWell(
        onTap: () {
          if (widget.fullValue != null) {
            setState(() {
              _showFullValue = !_showFullValue;
            });
          } else if (widget.onTap != null) {
            widget.onTap!();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final hasBoundedHeight = constraints.hasBoundedHeight;
            final isCompact = constraints.maxHeight <= 128;
            final isMediumCompact =
                hasBoundedHeight && constraints.maxHeight <= 180;
            final isVeryCompact =
                hasBoundedHeight && constraints.maxHeight <= 150;
            final contentPadding = isVeryCompact
                ? 12.0
                : (isCompact ? 16.0 : 20.0);
            final headerSpacing = isVeryCompact
                ? 6.0
                : (isCompact ? 10.0 : 16.0);
            final subtitleSpacing = isVeryCompact
                ? 2.0
                : (isCompact ? 4.0 : 6.0);
            final indicatorSpacing = isVeryCompact
                ? 6.0
                : (isCompact ? 8.0 : 12.0);
            final titleFontSize = isVeryCompact
                ? 12.0
                : (isCompact ? 13.0 : 14.0);
            final valueFontSize = isVeryCompact
                ? 18.0
                : (isCompact ? 20.0 : 24.0);
            final subtitleFontSize = isVeryCompact
                ? 10.0
                : (isCompact ? 11.0 : 12.0);
            final iconSize = isVeryCompact ? 18.0 : (isCompact ? 20.0 : 24.0);
            final iconPadding = isVeryCompact ? 7.0 : (isCompact ? 8.0 : 10.0);
            final indicatorFontSize = isVeryCompact
                ? 9.0
                : (isCompact ? 10.0 : 11.0);
            final showSubtitle = widget.subtitle != null && !isMediumCompact;
            final showIndicator = widget.fullValue != null && !hasBoundedHeight;

            if (isVeryCompact) {
              return Padding(
                padding: EdgeInsets.all(contentPadding),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? colorScheme.onSurfaceVariant
                                  : colorScheme.onSurface,
                            ),
                          ),
                          SizedBox(height: headerSpacing),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              displayValue,
                              key: ValueKey(displayValue),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: valueFontSize,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.all(iconPadding),
                      decoration: BoxDecoration(
                        color: resolvedIconColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        widget.icon,
                        color: resolvedIconColor,
                        size: iconSize,
                      ),
                    ),
                  ],
                ),
              );
            }

            final contentSection = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: hasBoundedHeight
                  ? MainAxisSize.max
                  : MainAxisSize.min,
              mainAxisAlignment: hasBoundedHeight
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    displayValue,
                    key: ValueKey(displayValue),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: valueFontSize,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                if (showSubtitle) ...[
                  SizedBox(height: subtitleSpacing),
                  Text(
                    widget.subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: subtitleFontSize,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? colorScheme.onSurfaceVariant
                          : colorScheme.onSurfaceVariant.withValues(alpha: 0.9),
                    ),
                  ),
                ],
                if (showIndicator) ...[
                  SizedBox(height: indicatorSpacing),
                  Row(
                    children: [
                      Icon(
                        Icons.touch_app,
                        size: isCompact ? 12 : 14,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _showFullValue
                              ? 'Tekan untuk menyembunyikan'
                              : 'Tekan untuk nilai lengkap',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: indicatorFontSize,
                            color: colorScheme.primary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            );

            return Padding(
              padding: EdgeInsets.all(contentPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: hasBoundedHeight
                    ? MainAxisSize.max
                    : MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.title,
                          maxLines: isVeryCompact ? 1 : 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? colorScheme.onSurfaceVariant
                                : colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.all(iconPadding),
                        decoration: BoxDecoration(
                          color: resolvedIconColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          widget.icon,
                          color: resolvedIconColor,
                          size: iconSize,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: headerSpacing),
                  if (hasBoundedHeight)
                    Expanded(child: contentSection)
                  else
                    contentSection,
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
