import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/charify_theme.dart';

/// Modern Charify-style card for displaying social cases
class CharifyCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;
  final double? elevation;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;

  const CharifyCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.color,
    this.elevation,
    this.borderRadius,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin:
          margin ??
          const EdgeInsets.symmetric(
            horizontal: CharifyTheme.space16,
            vertical: CharifyTheme.space8,
          ),
      decoration: BoxDecoration(
        color: color ?? CharifyTheme.white,
        borderRadius:
            borderRadius ?? BorderRadius.circular(CharifyTheme.radiusMedium),
        boxShadow:
            boxShadow ??
            [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(CharifyTheme.space16),
        child: child,
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius:
            borderRadius ?? BorderRadius.circular(CharifyTheme.radiusMedium),
        child: card,
      );
    }

    return card;
  }
}

/// Status chip for case statuses (Urgent, Resolved, In Progress)
class CharifyStatusChip extends StatelessWidget {
  final String label;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;

  const CharifyStatusChip({
    super.key,
    required this.label,
    this.backgroundColor,
    this.textColor,
    this.icon,
  });

  factory CharifyStatusChip.urgent(String label) {
    return CharifyStatusChip(
      label: label,
      backgroundColor: CharifyTheme.dangerRed,
      textColor: CharifyTheme.white,
      icon: Icons.warning_rounded,
    );
  }

  factory CharifyStatusChip.resolved(String label) {
    return CharifyStatusChip(
      label: label,
      backgroundColor: CharifyTheme.successGreen,
      textColor: CharifyTheme.white,
      icon: Icons.check_circle_rounded,
    );
  }

  factory CharifyStatusChip.inProgress(String label) {
    return CharifyStatusChip(
      label: label,
      backgroundColor: CharifyTheme.infoBlue,
      textColor: CharifyTheme.white,
      icon: Icons.access_time_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: CharifyTheme.space12,
        vertical: CharifyTheme.space8,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? CharifyTheme.primaryGreen,
        borderRadius: BorderRadius.circular(CharifyTheme.radiusRound),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: textColor ?? CharifyTheme.white),
            const SizedBox(width: CharifyTheme.space4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: textColor ?? CharifyTheme.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Modern network image with loading shimmer
class CharifyNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? height;
  final double? width;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const CharifyNetworkImage({
    super.key,
    required this.imageUrl,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius:
          borderRadius ?? BorderRadius.circular(CharifyTheme.radiusMedium),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        height: height,
        width: width,
        fit: fit,
        placeholder: (context, url) => Shimmer.fromColors(
          baseColor: CharifyTheme.lightGrey,
          highlightColor: CharifyTheme.white,
          child: Container(
            height: height,
            width: width,
            color: CharifyTheme.lightGrey,
          ),
        ),
        errorWidget: (context, url, error) => Container(
          height: height,
          width: width,
          color: CharifyTheme.lightGrey,
          child: const Icon(
            Icons.image_not_supported_rounded,
            color: CharifyTheme.mediumGrey,
            size: 48,
          ),
        ),
      ),
    );
  }
}

/// Empty state widget with illustration
class CharifyEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onActionPressed;

  const CharifyEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(CharifyTheme.space32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(CharifyTheme.space24),
              decoration: BoxDecoration(
                color: CharifyTheme.lightGrey,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 64, color: CharifyTheme.mediumGrey),
            ),
            const SizedBox(height: CharifyTheme.space24),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: CharifyTheme.space8),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onActionPressed != null) ...[
              const SizedBox(height: CharifyTheme.space24),
              ElevatedButton(
                onPressed: onActionPressed,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Loading shimmer for list items
class CharifyLoadingCard extends StatelessWidget {
  const CharifyLoadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return CharifyCard(
      child: Shimmer.fromColors(
        baseColor: CharifyTheme.lightGrey,
        highlightColor: CharifyTheme.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: CharifyTheme.lightGrey,
                borderRadius: BorderRadius.circular(CharifyTheme.radiusSmall),
              ),
            ),
            const SizedBox(height: CharifyTheme.space12),
            Container(
              height: 20,
              width: double.infinity,
              color: CharifyTheme.lightGrey,
            ),
            const SizedBox(height: CharifyTheme.space8),
            Container(height: 16, width: 200, color: CharifyTheme.lightGrey),
            const SizedBox(height: CharifyTheme.space8),
            Container(height: 16, width: 150, color: CharifyTheme.lightGrey),
          ],
        ),
      ),
    );
  }
}

/// Modern gradient button
class CharifyGradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Gradient? gradient;
  final bool isLoading;

  const CharifyGradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.gradient,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient ?? CharifyTheme.primaryGradient,
        borderRadius: BorderRadius.circular(CharifyTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: (gradient?.colors.first ?? CharifyTheme.primaryGreen)
                .withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(
            horizontal: CharifyTheme.space24,
            vertical: CharifyTheme.space16,
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(CharifyTheme.white),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: CharifyTheme.space8),
                  ],
                  Text(label),
                ],
              ),
      ),
    );
  }
}

/// Stat card for statistics screen
class CharifyStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? color;
  final String? subtitle;

  const CharifyStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final statColor = color ?? CharifyTheme.primaryGreen;

    return CharifyCard(
      padding: const EdgeInsets.all(CharifyTheme.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(CharifyTheme.space12),
                decoration: BoxDecoration(
                  color: statColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(CharifyTheme.radiusSmall),
                ),
                child: Icon(icon, color: statColor, size: 24),
              ),
              const Spacer(),
              if (subtitle != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: CharifyTheme.space8,
                    vertical: CharifyTheme.space4,
                  ),
                  decoration: BoxDecoration(
                    color: statColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(
                      CharifyTheme.radiusRound,
                    ),
                  ),
                  child: Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: statColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: CharifyTheme.space16),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: statColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: CharifyTheme.space4),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: CharifyTheme.mediumGrey),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
