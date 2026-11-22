import 'package:material_ui/material_ui.dart';
import 'package:muslim/core/theme/app_theme.dart';
import 'package:muslim/core/utils/arabic_digits.dart';
import 'package:flutter/rendering.dart';

import 'azkar_share_card.dart';

import 'dart:ui' as ui;
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class AzkarTextCard extends StatefulWidget {
  const AzkarTextCard({
    super.key,
    required this.text,
    required this.onCopy,
    this.shareCategory,
    this.repetitionCount,
    this.reference,
    this.instructions,
    this.counter,
    this.onTap,
    this.onIncrement,
    this.onReset,
    this.isFavorite = false,
    this.onFavorite,
    this.onShare,
    this.sectionLabel,
    this.showVirtueInfo = false,
    this.onVirtueTap,
    this.infoIcon,
    this.infoLabel,
    this.emphasizeInfo = false,
    this.showCopy = true,
    this.shareInsteadOfCopy = false,
  });

  final String text;
  final String? shareCategory;
  final int? counter;
  final int? repetitionCount;
  final String? reference;
  final String? instructions;
  final VoidCallback? onTap;
  final VoidCallback onCopy;
  final VoidCallback? onIncrement;
  final VoidCallback? onReset;
  final bool isFavorite;
  final VoidCallback? onFavorite;
  final VoidCallback? onShare;
  final String? sectionLabel;
  final bool showVirtueInfo;
  final VoidCallback? onVirtueTap;
  final IconData? infoIcon;
  final String? infoLabel;
  final bool emphasizeInfo;
  final bool showCopy;
  final bool shareInsteadOfCopy;

  @override
  State<AzkarTextCard> createState() => _AzkarTextCardState();
}

class _AzkarTextCardState extends State<AzkarTextCard> {
  final GlobalKey _captureKey = GlobalKey();
  static const MethodChannel _shareChannel = MethodChannel(
    'com.muslim/quran_share',
  );
  bool _pulse = false;

  Future<void> _shareImage() async {
    OverlayEntry? entry;
    try {
      final overlay = Overlay.of(context, rootOverlay: true);
      entry = OverlayEntry(
        builder: (context) => Positioned.fill(
          child: Center(
            child: AzkarShareCard(
              text: widget.text,
              category: widget.shareCategory,
              captureKey: _captureKey,
            ),
          ),
        ),
      );
      overlay.insert(entry);
      await WidgetsBinding.instance.endOfFrame;
      final boundary =
          _captureKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (data == null) return;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/azkar-card.png');
      await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
      await _shareChannel.invokeMethod<void>('shareImage', {
        'path': file.path,
        'title': 'مشاركة ذكر',
      });
    } catch (_) {
    } finally {
      entry?.remove();
    }
  }

  Future<void> _showShareOptions() async {
    final option = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.text_fields_rounded),
              title: const Text('مشاركة كنص'),
              onTap: () => Navigator.pop(ctx, 'text'),
            ),
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: const Text('مشاركة كصورة'),
              onTap: () => Navigator.pop(ctx, 'image'),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (option == 'image') await _shareImage();
    if (option == 'text') widget.onShare?.call();
  }

  Future<void> _confirmReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إعادة ضبط العداد؟'),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        content: const Text('سيتم تصفير عداد هذا الذكر.'),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('إعادة ضبط'),
          ),
        ],
      ),
    );
    if (confirmed == true) widget.onReset?.call();
  }

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
    child: InkWell(
      onTap: widget.counter != null && widget.onIncrement != null
          ? () {
              widget.onIncrement!();
              setState(() => _pulse = true);
              Future<void>.delayed(const Duration(milliseconds: 170), () {
                if (mounted) setState(() => _pulse = false);
              });
            }
          : widget.onTap,
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: Padding(
        padding: EdgeInsets.all(widget.showVirtueInfo ? 10 : AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.infoIcon != null && widget.infoLabel != null) ...[
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  Icon(
                    widget.infoIcon,
                    size: 19,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.infoLabel!,
                    textDirection: TextDirection.rtl,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
            if (widget.sectionLabel != null &&
                widget.sectionLabel!.isNotEmpty) ...[
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    toArabicIndicDigits(widget.sectionLabel!),
                    textDirection: TextDirection.rtl,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
            if (widget.showVirtueInfo)
              Stack(
                alignment: Alignment.center,
                children: [
                  Padding(
                    // Keep the virtue text centered while reserving room for
                    // the info button at the edge of the card.
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: SizedBox(
                      width: double.infinity,
                      child: Text(
                        toArabicIndicDigits(widget.text),
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontSize:
                                  (Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.fontSize ??
                                      16) +
                                  1,
                              height: 1.4,
                            ),
                      ),
                    ),
                  ),
                  if (widget.onVirtueTap != null)
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: IconButton(
                        onPressed: widget.onVirtueTap,
                        tooltip: 'فضل التسبيحة والمصدر',
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints.tightFor(
                          width: 34,
                          height: 34,
                        ),
                        padding: EdgeInsets.zero,
                        style: IconButton.styleFrom(
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .primaryContainer
                              .withValues(alpha: 0.55),
                          foregroundColor: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadii.control),
                          ),
                        ),
                        icon: Icon(Icons.info_outline_rounded, size: 19),
                      ),
                    ),
                ],
              )
            else
              Text(
                toArabicIndicDigits(widget.text),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize:
                      (Theme.of(context).textTheme.titleMedium?.fontSize ??
                          16) +
                      2,
                  height: widget.emphasizeInfo ? 1.65 : 1.9,
                  fontWeight: widget.emphasizeInfo ? FontWeight.w700 : null,
                  color: widget.emphasizeInfo
                      ? Theme.of(context).colorScheme.onSurface
                      : null,
                ),
              ),
            if (!widget.showVirtueInfo &&
                widget.instructions != null &&
                widget.instructions!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                toArabicIndicDigits(widget.instructions!),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.start,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ],
            if (!widget.showVirtueInfo &&
                widget.reference != null &&
                widget.reference!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                toArabicIndicDigits('المصدر: ${widget.reference}'),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.start,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (widget.repetitionCount != null) ...[
              const SizedBox(height: 8),
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  Container(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(AppRadii.control),
                    ),
                    child: Text(
                      'عدد التكرار: ${toArabicIndicDigits(widget.repetitionCount!)}',
                      textDirection: TextDirection.rtl,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (widget.onReset == null) const Spacer(),
                ],
              ),
            ],
            SizedBox(height: widget.showVirtueInfo ? 6 : 10),
            Row(
              textDirection: TextDirection.rtl,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (widget.counter != null) ...[
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          IgnorePointer(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                toArabicIndicDigits(
                                  '${widget.counter}${widget.repetitionCount == null ? '' : ' / ${widget.repetitionCount}'}',
                                ),
                                textAlign: TextAlign.center,
                                textDirection: TextDirection.rtl,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontSize:
                                          (Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.fontSize ??
                                              16) +
                                          2,
                                      fontWeight: FontWeight.w700,
                                      color: _pulse
                                          ? Theme.of(context).colorScheme.primary
                                          : null,
                                    ),
                              ),
                            ),
                          ),
                          if (widget.onReset != null)
                            PositionedDirectional(
                              end: 0,
                              child: IconButton(
                                onPressed: _confirmReset,
                                tooltip: 'إعادة ضبط العداد',
                                visualDensity: VisualDensity.compact,
                                constraints: const BoxConstraints.tightFor(
                                  width: 40,
                                  height: 40,
                                ),
                                padding: EdgeInsets.zero,
                                style: IconButton.styleFrom(
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .errorContainer,
                                  foregroundColor: Theme.of(context)
                                      .colorScheme
                                      .onErrorContainer,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppRadii.control,
                                    ),
                                  ),
                                ),
                                icon: const Icon(Icons.restart_alt_rounded),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  if (widget.repetitionCount != null) ...[
                    Container(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(AppRadii.control),
                      ),
                      child: Text(
                        'التكرار: ${toArabicIndicDigits(widget.repetitionCount!)}',
                        textDirection: TextDirection.rtl,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    const Spacer(),
                  ] else
                    const Spacer(),
                  if (widget.showCopy)
                    _TasbeehActionButton(
                      onPressed: widget.counter == null &&
                              !widget.shareInsteadOfCopy
                          ? widget.onCopy
                          : _showShareOptions,
                      tooltip: widget.counter == null &&
                              !widget.shareInsteadOfCopy
                          ? 'نسخ الذِّكْر'
                          : 'مشاركة الذِّكْر',
                      icon: widget.counter == null &&
                              !widget.shareInsteadOfCopy
                          ? Icons.content_copy_rounded
                          : Icons.share_rounded,
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .primaryContainer,
                      foregroundColor: Theme.of(context)
                          .colorScheme
                          .onPrimaryContainer,
                    ),
                ],
              ],
            ),
            if (widget.counter != null && widget.repetitionCount != null) ...[
              SizedBox(height: widget.showVirtueInfo ? 6 : 12),
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  Expanded(
                    child: Text(
                      widget.counter! >= widget.repetitionCount!
                          ? 'اكتمل الذِّكْر'
                          : 'المتبقي: ${toArabicIndicDigits(widget.repetitionCount! - widget.counter!)}',
                      textDirection: TextDirection.rtl,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (widget.showCopy)
                    _TasbeehActionButton(
                      onPressed: _showShareOptions,
                      tooltip: 'مشاركة الذِّكْر',
                      icon: Icons.share_rounded,
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .primaryContainer,
                      foregroundColor: Theme.of(context)
                          .colorScheme
                          .onPrimaryContainer,
                    ),
                ],
              ),
            ],
            if (widget.onFavorite != null ||
                (widget.onShare != null &&
                    widget.counter == null &&
                    !widget.shareInsteadOfCopy)) ...[
              const SizedBox(height: 4),
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  if (widget.onFavorite != null)
                    IconButton(
                      onPressed: widget.onFavorite,
                      tooltip: widget.isFavorite
                          ? 'إزالة من المفضلة'
                          : 'إضافة للمفضلة',
                      icon: Icon(
                        widget.isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: widget.isFavorite
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  if (widget.onShare != null &&
                      widget.counter == null &&
                      !widget.shareInsteadOfCopy)
                    IconButton(
                      onPressed: _showShareOptions,
                      tooltip: 'مشاركة الدُّعَاء',
                      icon: const Icon(Icons.share_rounded),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _TasbeehActionButton extends StatelessWidget {
  const _TasbeehActionButton({
    required this.onPressed,
    required this.tooltip,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final VoidCallback? onPressed;
  final String tooltip;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: onPressed,
    tooltip: tooltip,
    constraints: const BoxConstraints.tightFor(width: 48, height: 48),
    padding: EdgeInsets.zero,
    style: IconButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      disabledBackgroundColor: backgroundColor.withValues(alpha: .45),
      disabledForegroundColor: foregroundColor.withValues(alpha: .55),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.control),
      ),
    ),
    icon: Icon(icon, size: 20),
  );
}
