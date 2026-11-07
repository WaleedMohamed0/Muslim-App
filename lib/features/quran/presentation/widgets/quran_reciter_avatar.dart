import 'package:flutter/material.dart';
import '../../domain/entities/quran_reciter.dart';

/// Reciter identity image shared by the reader's mini players and sheets.
/// Uses the bundled portrait when one exists, otherwise a stable, reciter-
/// specific name mark from the centralized reciter catalog.
class QuranReciterAvatar extends StatelessWidget {
  const QuranReciterAvatar({
    required this.reciter,
    required this.size,
    super.key,
  });

  final QuranReciter reciter;
  final double size;

  @override
  Widget build(BuildContext context) {
    Widget fallback() => Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Color(reciter.avatarColorValue),
        shape: BoxShape.circle,
      ),
      child: Text(
        reciter.avatarLabel,
        textDirection: TextDirection.rtl,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: size * .31,
        ),
      ),
    );

    final image = reciter.avatarAsset;
    if (image == null) return fallback();
    return ClipOval(
      child: Image.asset(
        image,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback(),
      ),
    );
  }
}
