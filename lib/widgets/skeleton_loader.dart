import 'package:flutter/material.dart';
import '../theme.dart';

class SkeletonLoader extends StatefulWidget {
  final Widget child;
  final bool isLoading;

  const SkeletonLoader({
    required this.child,
    this.isLoading = true,
    super.key,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1.0, 0),
              end: Alignment(1.0, 0),
              colors: [
                AppTheme.cardBg,
                Colors.white.withOpacity(0.6),
                AppTheme.cardBg,
              ],
              stops: [
                0,
                _animationController.value,
                1.0,
              ],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

class SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;

  const SkeletonBox({
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: borderRadius,
      ),
    );
  }
}

class SkeletonTaskCard extends StatelessWidget {
  final bool isLoading;

  const SkeletonTaskCard({this.isLoading = true, super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      isLoading: isLoading,
      child: Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.06),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(width: 150, height: 12),
                      const SizedBox(height: 8),
                      SkeletonBox(width: 200, height: 10),
                    ],
                  ),
                ),
                SkeletonBox(
                  width: 40,
                  height: 40,
                  borderRadius: BorderRadius.circular(20),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SkeletonProfileHeader extends StatelessWidget {
  final bool isLoading;

  const SkeletonProfileHeader({this.isLoading = true, super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      isLoading: isLoading,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primary, AppTheme.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(28),
            bottomRight: Radius.circular(28),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SkeletonBox(
              width: 80,
              height: 80,
              borderRadius: BorderRadius.circular(40),
            ),
            const SizedBox(height: 12),
            SkeletonBox(width: 120, height: 14),
            const SizedBox(height: 8),
            SkeletonBox(width: 100, height: 12),
          ],
        ),
      ),
    );
  }
}

class SkeletonSettingsCard extends StatelessWidget {
  final int itemCount;
  final bool isLoading;

  const SkeletonSettingsCard({
    this.itemCount = 3,
    this.isLoading = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      isLoading: isLoading,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: List.generate(
            itemCount,
            (index) => Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonBox(width: 100, height: 12),
                          const SizedBox(height: 8),
                          SkeletonBox(width: 80, height: 10),
                        ],
                      ),
                      SkeletonBox(width: 60, height: 12),
                    ],
                  ),
                ),
                if (index < itemCount - 1)
                  const Divider(height: 1, indent: 16, endIndent: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SkeletonFamilyMembersList extends StatelessWidget {
  final int itemCount;
  final bool isLoading;

  const SkeletonFamilyMembersList({
    this.itemCount = 4,
    this.isLoading = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      isLoading: isLoading,
      child: SizedBox(
        height: 100,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: itemCount,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                children: [
                  SkeletonBox(
                    width: 60,
                    height: 60,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  const SizedBox(height: 8),
                  SkeletonBox(width: 50, height: 10),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
