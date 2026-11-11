import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// A text button that opens a URL in the device's external application.
class ExternalLinkButton extends StatelessWidget {
  const ExternalLinkButton({
    super.key,
    required this.url,
    required this.label,
    this.textDirection = TextDirection.rtl,
    this.textAlign = TextAlign.center,
  });

  final String url;
  final String label;
  final TextDirection textDirection;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return TextButton(
      onPressed: () => _open(context),
      style: TextButton.styleFrom(
        foregroundColor: colors.onSurfaceVariant,
        textStyle: Theme.of(context).textTheme.bodySmall,
      ),
      child: Text(label, textDirection: textDirection, textAlign: textAlign),
    );
  }

  Future<void> _open(BuildContext context) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } on PlatformException {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تعذّر فتح الرابط. أعد تشغيل التطبيق بالكامل ثم حاول مجددًا.',
          ),
        ),
      );
    }
  }
}
