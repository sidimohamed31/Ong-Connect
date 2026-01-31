import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerLoading extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const ShimmerLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
      ),
    );
  }
}

// Card skeleton for case list
class CaseCardSkeleton extends StatelessWidget {
  const CaseCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image skeleton
            ShimmerLoading(
              width: double.infinity,
              height: 200,
              borderRadius: BorderRadius.circular(12),
            ),
            const SizedBox(height: 12),
            // Title skeleton
            const ShimmerLoading(width: double.infinity, height: 20),
            const SizedBox(height: 8),
            // Subtitle skeleton
            const ShimmerLoading(width: 200, height: 16),
            const SizedBox(height: 12),
            // Tags row skeleton
            Row(
              children: [
                ShimmerLoading(
                  width: 80,
                  height: 24,
                  borderRadius: BorderRadius.circular(12),
                ),
                const SizedBox(width: 8),
                ShimmerLoading(
                  width: 100,
                  height: 24,
                  borderRadius: BorderRadius.circular(12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
