import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim/features/quran/presentation/cubit/quran_cubit.dart';
import 'package:muslim/features/quran/presentation/cubit/quran_state.dart';
import 'package:muslim/features/quran/presentation/widgets/quran_audio_mini_player_card.dart';
import 'package:muslim/features/quran/presentation/widgets/quran_reader_palette.dart';

double estimateQuranMiniPlayerHeight(BuildContext context) =>
    (MediaQuery.sizeOf(context).width * .17 +
            MediaQuery.sizeOf(context).height * .012 +
            35 +
            MediaQuery.viewPaddingOf(context).bottom)
        .clamp(108.0, double.infinity)
        .toDouble();

double quranMiniPlayerBottomInset(
  BuildContext context, {
  required bool visible,
  required double measuredHeight,
}) {
  if (!visible) return 0;
  final playerHeight = measuredHeight > 0
      ? measuredHeight
      : estimateQuranMiniPlayerHeight(context);
  // The measured height includes the navigation inset added by the player.
  return playerHeight;
}

/// A compact Quran playback card shared by the Surah list and Quran reader.
class QuranAudioMiniPlayer extends StatelessWidget {
  const QuranAudioMiniPlayer({super.key, this.onTap, this.onHeightChanged});

  final VoidCallback? onTap;
  final ValueChanged<double>? onHeightChanged;

  @override
  Widget build(BuildContext context) => BlocBuilder<QuranCubit, QuranState>(
    builder: (context, _) {
      final cubit = context.read<QuranCubit>();
      return _SizeReporter(
        onSizeChanged: (size) => onHeightChanged?.call(size.height),
        child: cubit.quranSoundActive
            ? QuranAudioMiniPlayerCard(
                key: const ValueKey('quran-mini-player-active'),
                cubit: cubit,
                palette: QuranReaderPalette.fromTheme(context),
                onTap: onTap,
              )
            : const SizedBox.shrink(
                key: ValueKey('quran-mini-player-hidden'),
              ),
      );
    },
  );
}

class _SizeReporter extends SingleChildRenderObjectWidget {
  const _SizeReporter({required this.onSizeChanged, required super.child});

  final ValueChanged<Size> onSizeChanged;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderSizeReporter(onSizeChanged);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderSizeReporter renderObject,
  ) {
    renderObject.onSizeChanged = onSizeChanged;
  }
}

class _RenderSizeReporter extends RenderProxyBox {
  _RenderSizeReporter(this.onSizeChanged);

  ValueChanged<Size> onSizeChanged;
  Size? _reportedSize;

  @override
  void performLayout() {
    super.performLayout();
    final nextSize = child?.size ?? Size.zero;
    if (_reportedSize == nextSize) return;
    _reportedSize = nextSize;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (attached) onSizeChanged(nextSize);
    });
  }
}
