import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';
import 'package:muslim/core/assets/app_assets.dart';

/// Theme-tinted rendering of the notification mark for captured share cards.
class NotificationLogo extends StatelessWidget {
  const NotificationLogo({super.key, required this.color});

  static Future<void> preload() async {
    await const SvgAssetLoader(
      AppAssets.notificationLogo,
      theme: SvgTheme(),
    ).loadBytes(null);
  }

  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 28,
    child: SvgPicture.asset(
      AppAssets.notificationLogo,
      theme: const SvgTheme(),
      fit: BoxFit.contain,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    ),
  );
}
