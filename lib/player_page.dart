// lib/player_page.dart
//
// Full-screen "Now Playing" player page.
// Uses ColorScheme for theming and cupertino_native_better for glass effects.

import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'shared/shared.dart';

/// Placeholder player state - replace with AudioPlayerService integration
class _PlaceholderPlayerState extends ChangeNotifier {
  _PlaceholderPlayerState({
    required int durationSec,
  }) : _durationSec = durationSec,
       _duration = durationSec.toDouble() {
    _position = ValueNotifier(0.0);
    _isPlaying = ValueNotifier(false);
    _position.addListener(notifyListeners);
    _isPlaying.addListener(notifyListeners);
    // Simulate playback progress
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 500));
      if (_isPlaying.value && _position.value < _duration) {
        _position.value += 0.5;
      }
      return _isPlaying.value && _position.value < _duration;
    });
  }

  final double _duration;
  final int _durationSec;

  int get durationSec => _durationSec;

  late final ValueNotifier<double> _position;
  late final ValueNotifier<bool> _isPlaying;

  double get position => _position.value;
  double get duration => _duration;
  bool get isPlaying => _isPlaying.value;

  ValueNotifier<double> get positionNotifier => _position;
  ValueNotifier<bool> get isPlayingNotifier => _isPlaying;

  void seek(double value) {
    _position.value = value.clamp(0.0, _duration);
  }

  void togglePlayPause() {
    _isPlaying.value = !_isPlaying.value;
  }

  void playNext() {
    _position.value = 0.0;
    _isPlaying.value = true;
  }

  void playPrevious() {
    _position.value = 0.0;
    _isPlaying.value = true;
  }

  @override
  void dispose() {
    _position.removeListener(notifyListeners);
    _isPlaying.removeListener(notifyListeners);
    _position.dispose();
    _isPlaying.dispose();
    super.dispose();
  }
}

class PlayerPage extends StatefulWidget {
  const PlayerPage({required this.track, super.key});

  final Track track;

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  late final _PlaceholderPlayerState _playerState;

  @override
  void initState() {
    super.initState();
    _playerState = _PlaceholderPlayerState(
      durationSec: widget.track.durationSec,
    );
  }

  @override
  void dispose() {
    _playerState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = colorScheme.surfaceContainerHighest;

    return CupertinoPageScaffold(
      backgroundColor: backgroundColor,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: backgroundColor.withValues(alpha: 0.8),
        middle: const Text('NOW PLAYING'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).maybePop(),
          child: const Icon(CupertinoIcons.chevron_down),
        ),
        trailing: _QueueButton(playerState: _playerState),
      ),
      child: SafeArea(
        child: ValueListenableBuilder<double>(
          valueListenable: _playerState.positionNotifier,
          builder: (context, position, _) {
            return LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - AppSpacing.xl * 2,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: AppSpacing.xs),
                          _AlbumArtwork(
                            track: widget.track,
                            size: math.min(constraints.maxWidth * 0.8, 400),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          _TrackMetadata(track: widget.track, colorScheme: colorScheme),
                          const SizedBox(height: AppSpacing.xl),
                          _PositionSlider(
                            playerState: _playerState,
                            colorScheme: colorScheme,
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          _PlaybackControls(
                            playerState: _playerState,
                            colorScheme: colorScheme,
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                          _LyricsPanel(colorScheme: colorScheme),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _AlbumArtwork extends StatelessWidget {
  const _AlbumArtwork({
    required this.track,
    required this.size,
  });

  final Track track;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Hero(
      tag: 'player-cover-art',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: LiquidGlassContainer(
          config: LiquidGlassConfig(
            effect: CNGlassEffect.regular,
            shape: CNGlassEffectShape.rect,
            cornerRadius: AppRadius.xl,
            interactive: false,
          ),
          child: CachedNetworkImage(
            imageUrl: track.imageUrl,
            width: size,
            height: size,
            fit: BoxFit.cover,
            placeholder: (_, _) => ColoredBox(
              color: colorScheme.surfaceContainerHigh,
              child: Center(
                child: Icon(
                  CupertinoIcons.music_note,
                  size: size * 0.25,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            errorWidget: (_, _, _) => ColoredBox(
              color: colorScheme.surfaceContainerHigh,
              child: Center(
                child: Icon(
                  CupertinoIcons.music_note,
                  size: size * 0.25,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TrackMetadata extends StatelessWidget {
  const _TrackMetadata({
    required this.track,
    required this.colorScheme,
  });

  final Track track;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          track.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: Text(
                track.artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.s),
            GlassIconButton(
              icon: const Icon(CupertinoIcons.add, color: CupertinoColors.white),
              onPressed: null,
              semanticLabel: 'Add to library',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          track.album,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 14,
          ),
        ),
        if (track.explicit) ...[
          const SizedBox(height: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant,
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              'E',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: colorScheme.surface,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _PositionSlider extends StatelessWidget {
  const _PositionSlider({
    required this.playerState,
    required this.colorScheme,
  });

  final _PlaceholderPlayerState playerState;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: playerState.positionNotifier,
      builder: (context, position, _) {
        final duration = playerState.duration;
        return Column(
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                activeTrackColor: colorScheme.primary,
                inactiveTrackColor: colorScheme.onSurfaceVariant.withValues(alpha: 0.18),
                thumbColor: colorScheme.primary,
              ),
              child: Slider(
                value: position.clamp(0.0, duration),
                max: duration,
                onChanged: (value) {
                  playerState.seek(value);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(position),
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    _formatDuration(duration),
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatDuration(double seconds) {
    final value = seconds.round();
    return '${value ~/ 60}:${(value % 60).toString().padLeft(2, '0')}';
  }
}

class _PlaybackControls extends StatelessWidget {
  const _PlaybackControls({
    required this.playerState,
    required this.colorScheme,
  });

  final _PlaceholderPlayerState playerState;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: playerState.isPlayingNotifier,
      builder: (context, isPlaying, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            GlassIconButton(
              icon: const Icon(CupertinoIcons.backward_fill, color: CupertinoColors.white),
              onPressed: playerState.playPrevious,
              semanticLabel: 'Previous track',
              size: 52,
            ),
            GlassIconButton(
              icon: Icon(
                isPlaying ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill,
                color: CupertinoColors.white,
              ),
              onPressed: playerState.togglePlayPause,
              semanticLabel: isPlaying ? 'Pause' : 'Play',
              size: 76,
              iconSize: 46,
            ),
            GlassIconButton(
              icon: const Icon(CupertinoIcons.forward_fill, color: CupertinoColors.white),
              onPressed: playerState.playNext,
              semanticLabel: 'Next track',
              size: 52,
            ),
          ],
        );
      },
    );
  }
}

class _QueueButton extends StatelessWidget {
  const _QueueButton({required this.playerState});

  final _PlaceholderPlayerState playerState;

  @override
  Widget build(BuildContext context) {
    return GlassIconButton(
      icon: const Icon(CupertinoIcons.list_number, color: CupertinoColors.white),
      onPressed: () {
        showCupertinoModalPopup(
          context: context,
          builder: (context) => _QueueModal(playerState: playerState),
        );
      },
      semanticLabel: 'Queue',
      size: 44,
    );
  }
}

class _QueueModal extends StatelessWidget {
  const _QueueModal({required this.playerState});

  final _PlaceholderPlayerState playerState;

  @override
  Widget build(BuildContext context) {
    return CupertinoActionSheet(
      title: const Text('Up Next'),
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Done'),
      ),
      actions: [
        CupertinoActionSheetAction(
          onPressed: () {
            Navigator.of(context).pop();
            // Handle queue item selection
          },
          child: const Text('Queue item 1'),
        ),
        CupertinoActionSheetAction(
          onPressed: () {
            Navigator.of(context).pop();
            // Handle queue item selection
          },
          child: const Text('Queue item 2'),
        ),
      ],
    );
  }
}

class _LyricsPanel extends StatelessWidget {
  const _LyricsPanel({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return LiquidGlassContainer(
      config: LiquidGlassConfig(
        effect: CNGlassEffect.regular,
        shape: CNGlassEffectShape.rect,
        cornerRadius: AppRadius.xl,
        interactive: false,
      ),
      child: SizedBox(
        width: double.infinity,
        height: 110,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.chevron_up,
                color: colorScheme.onSurfaceVariant,
                size: 28,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Lyrics',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// GlassIconButton using cupertino_native_better's glass effects
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
    this.size = 44,
    this.iconSize = 24,
    super.key,
  });

  final Widget icon;
  final VoidCallback? onPressed;
  final String semanticLabel;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: semanticLabel,
      child: LiquidGlassContainer(
        config: LiquidGlassConfig(
          effect: CNGlassEffect.regular,
          shape: CNGlassEffectShape.circle,
          interactive: true,
        ),
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          minimumSize: Size(size, size),
          onPressed: onPressed,
          child: SizedBox(
            width: size,
            height: size,
            child: Center(
              child: IconTheme(
                data: IconThemeData(
                  size: iconSize,
                  color: colorScheme.onPrimary,
                ),
                child: DefaultTextStyle(
                  style: TextStyle(color: colorScheme.onPrimary),
                  child: icon,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}