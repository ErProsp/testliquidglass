// lib/shared/widgets.dart
//
// Shared UI widgets used across pages.

import 'dart:ui' show ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import 'theme.dart';
import 'models.dart';

bool get _isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

double textScale(BuildContext context) =>
    (MediaQuery.textScalerOf(context).scale(16) / 16).clamp(1.0, 1.6);

/// Liquid Glass surface. Native on iOS 26+, blur fallback everywhere else.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    required this.radius,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.native = false,
    super.key,
  });

  final double radius;
  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Use the platform-view glass. Keep it for a few static surfaces only:
  /// platform views are expensive inside long scrolling lists.
  final bool native;

  @override
  Widget build(BuildContext context) {
    if (native && _isIOS && PlatformVersion.shouldUseNativeGlass) {
      return LiquidGlassContainer(
        config: LiquidGlassConfig(
          effect: CNGlassEffect.regular,
          shape: CNGlassEffectShape.rect,
          cornerRadius: radius,
          interactive: false,
        ),
        child: Padding(padding: padding, child: child),
      );
    }
    final p = AppPalette.of(context);
    final shape = BorderRadius.circular(radius);
    // FALLBACK: blur + translucent fill.
    return ClipRRect(
      borderRadius: shape,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: p.glassFill,
            borderRadius: shape,
            border: Border.all(color: p.glassBorder, width: 0.5),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class CoverImage extends StatelessWidget {
  const CoverImage({
    required this.url,
    required this.size,
    this.radius = AppRadius.s,
    this.circular = false,
    super.key,
  });

  final String url;
  final double size;
  final double radius;
  final bool circular;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(circular ? size / 2 : radius),
      child: CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, _) => SizedBox(
          width: size,
          height: size,
          child: ColoredBox(color: p.surface),
        ),
        errorWidget: (_, _, _) => SizedBox(
          width: size,
          height: size,
          child: ColoredBox(
            color: p.surface,
            child: Icon(
              CupertinoIcons.music_note,
              size: size * 0.4,
              color: p.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.l,
        AppSpacing.xl,
        AppSpacing.l,
        AppSpacing.s,
      ),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(title, style: AppTextStyles.sectionTitle(p)),
            ),
          ),
          if (actionLabel != null)
            CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: const Size(44, 44),
              onPressed: onAction,
              child: Text(actionLabel!, style: AppTextStyles.link(p)),
            ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xxl * 2,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: p.textSecondary),
          const SizedBox(height: AppSpacing.l),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.sectionTitle(p),
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.rowSubtitle(p),
          ),
        ],
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({
    required this.message,
    required this.onRetry,
    super.key,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        EmptyState(
          icon: CupertinoIcons.wifi_exclamationmark,
          title: 'Connection problem',
          subtitle: message,
        ),
        CNButton(
          label: 'Try again',
          config: const CNButtonConfig(style: CNButtonStyle.prominentGlass),
          onPressed: onRetry,
        ),
      ],
    );
  }
}

class Shimmer extends StatefulWidget {
  const Shimmer({required this.child, super.key});
  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppDurations.shimmer,
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) => LinearGradient(
          colors: [p.shimmerBase, p.shimmerHighlight, p.shimmerBase],
          stops: const [0.35, 0.5, 0.65],
          transform: _SlideGradient(-1 + 2 * _controller.value),
        ).createShader(bounds),
        child: child,
      ),
    );
  }
}

class _SlideGradient extends GradientTransform {
  const _SlideGradient(this.percent);
  final double percent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * percent, 0, 0);
}

class Marquee extends StatefulWidget {
  const Marquee({required this.text, required this.style, super.key});
  final String text;
  final TextStyle style;

  @override
  State<Marquee> createState() => _MarqueeState();
}

class _MarqueeState extends State<Marquee> {
  final ScrollController _scroll = ScrollController();
  int _run = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loop(++_run));
  }

  @override
  void didUpdateWidget(covariant Marquee oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      if (_scroll.hasClients) _scroll.jumpTo(0);
      WidgetsBinding.instance.addPostFrameCallback((_) => _loop(++_run));
    }
  }

  Future<void> _loop(int run) async {
    while (mounted && run == _run) {
      await Future<void>.delayed(const Duration(seconds: 2));
      if (!mounted || run != _run || !_scroll.hasClients) return;
      final extent = _scroll.position.maxScrollExtent;
      if (extent <= 0) return; // fits: nothing to scroll
      await _scroll.animateTo(
        extent,
        duration: Duration(milliseconds: (extent * 40).round()),
        curve: Curves.linear,
      );
      await Future<void>.delayed(const Duration(seconds: 1));
      if (!mounted || run != _run || !_scroll.hasClients) return;
      _scroll.jumpTo(0);
    }
  }

  @override
  void dispose() {
    _run++;
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    controller: _scroll,
    scrollDirection: Axis.horizontal,
    physics: const NeverScrollableScrollPhysics(),
    child: Text(widget.text, maxLines: 1, softWrap: false, style: widget.style),
  );
}

class CircleButton extends StatelessWidget {
  const CircleButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.fill,
    this.iconColor,
    this.diameter = 40,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? fill;
  final Color? iconColor;
  final double diameter;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: AppSizes.iconButton,
          height: AppSizes.iconButton,
          child: Center(
            child: Container(
              width: diameter,
              height: diameter,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: fill ?? p.glassFill,
                border: Border.all(color: p.glassBorder, width: 0.5),
              ),
              child: Icon(
                icon,
                size: diameter * 0.5,
                color: iconColor ?? p.text,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ExplicitBadge extends StatelessWidget {
  const ExplicitBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Semantics(
      label: 'Explicit',
      child: Container(
        margin: const EdgeInsets.only(right: AppSpacing.xs),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: p.textSecondary,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(
          'E',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: p.background,
          ),
        ),
      ),
    );
  }
}

class GlassMiniPlayer extends StatelessWidget {
  const GlassMiniPlayer({
    required this.track,
    required this.playing,
    required this.progress,
    required this.onToggle,
    required this.onOpen,
    required this.onDevices,
    super.key,
  });

  final Track track;
  final bool playing;
  final double progress;
  final VoidCallback onToggle;
  final VoidCallback onOpen;
  final VoidCallback onDevices;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return SizedBox(
      height: AppSizes.miniPlayer,
      child: GlassSurface(
        radius: AppRadius.pill,
        native: true,
        child: Stack(
          children: [
            Positioned.fill(
              child: Semantics(
                button: true,
                label:
                    'Now playing ${track.title} by ${track.artist}. Open player',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onOpen,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.m,
                    ),
                    child: Row(
                      children: [
                        CoverImage(
                          url: track.imageUrl,
                          size: AppSizes.miniCover,
                          radius: AppRadius.m,
                        ),
                        const SizedBox(width: AppSpacing.m),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Marquee(
                                text: track.title,
                                style: AppTextStyles.cardTitle(p),
                              ),
                              Text(
                                track.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.caption(p),
                              ),
                            ],
                          ),
                        ),
                        CircleButton(
                          icon: CupertinoIcons.device_laptop,
                          label: 'Connect to a device',
                          onTap: onDevices,
                          fill: const Color(0x00000000),
                        ),
                        CircleButton(
                          icon: playing
                              ? CupertinoIcons.pause_fill
                              : CupertinoIcons.play_fill,
                          label: playing ? 'Pause' : 'Play',
                          onTap: onToggle,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: AppSpacing.xl,
              right: AppSpacing.xl,
              bottom: AppSpacing.xs,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(1),
                child: SizedBox(
                  height: 2,
                  child: Stack(
                    children: [
                      Positioned.fill(child: ColoredBox(color: p.divider)),
                      FractionallySizedBox(
                        widthFactor: progress.clamp(0.0, 1.0),
                        child: ColoredBox(color: p.accent),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BottomTabBar extends StatelessWidget {
  const BottomTabBar({
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const List<CNTabBarItem> _items = [
    CNTabBarItem(
      label: 'Home',
      icon: CNSymbol('house'),
      activeIcon: CNSymbol('house.fill'),
    ),
    CNTabBarItem(label: 'Search', icon: CNSymbol('magnifyingglass')),
    CNTabBarItem(
      label: 'Library',
      icon: CNSymbol('books.vertical'),
      activeIcon: CNSymbol('books.vertical.fill'),
    ),
    CNTabBarItem(
      label: 'Premium',
      icon: CNSymbol('crown'),
      activeIcon: CNSymbol('crown.fill'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final inset = MediaQuery.paddingOf(context).bottom;
    final height = AppSizes.tabBar + inset;

    if (_isIOS) {
      return SizedBox(
        height: height,
        child: CNTabBar(
          items: _items,
          currentIndex: currentIndex,
          onTap: onTap,
        ),
      );
    }
    // FALLBACK: non-iOS platforms.
    return CupertinoTabBar(
      currentIndex: currentIndex,
      onTap: onTap,
      activeColor: p.accent,
      inactiveColor: p.textSecondary,
      backgroundColor: p.background.withValues(alpha: 0.85),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.house),
          activeIcon: Icon(CupertinoIcons.house_fill),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.search),
          label: 'Search',
        ),
        BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.music_albums),
          activeIcon: Icon(CupertinoIcons.music_albums_fill),
          label: 'Library',
        ),
        BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.star),
          activeIcon: Icon(CupertinoIcons.star_fill),
          label: 'Premium',
        ),
      ],
    );
  }
}

class ToastPill extends StatelessWidget {
  const ToastPill(this.message, {super.key});
  final String message;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return GlassSurface(
      radius: AppRadius.pill,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.m,
      ),
      child: DefaultTextStyle(
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: p.text,
          decoration: TextDecoration.none,
        ),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}

class Carousel extends StatelessWidget {
  const Carousel({
    required this.height,
    required this.itemCount,
    required this.itemBuilder,
    super.key,
  });

  final double height;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.m),
      itemBuilder: itemBuilder,
    ),
  );
}

class WrapGrid extends StatelessWidget {
  const WrapGrid({required this.children, super.key});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.l,
      AppSpacing.l,
      AppSpacing.l,
      0,
    ),
    child: Wrap(
      spacing: AppSpacing.m,
      runSpacing: AppSpacing.l,
      children: children,
    ),
  );
}