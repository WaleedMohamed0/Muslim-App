import 'package:material_ui/material_ui.dart';
import 'package:muslim/core/utils/arabic_digits.dart';
import 'package:muslim/core/widgets/app_widgets_impl.dart';

Future<void> showQuranWidgetTutorial(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (_) => const QuranWidgetTutorialSheet(),
    );

Future<void> showPrayerTimesWidgetTutorial(BuildContext context) =>
    showAppModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (_) => const PrayerTimesWidgetTutorialSheet(),
    );

Future<void> showQuranWidgetIntroduction(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .64,
        minChildSize: .42,
        maxChildSize: .92,
        builder: (context, scrollController) => WidgetsIntroductionSheet(
          scrollController: scrollController,
          onQuranTap: () => showQuranWidgetTutorial(context),
          onPrayerTap: () => showPrayerTimesWidgetTutorial(context),
        ),
      ),
    );

class WidgetsIntroductionSheet extends StatelessWidget {
  const WidgetsIntroductionSheet({
    super.key,
    required this.scrollController,
    required this.onQuranTap,
    required this.onPrayerTap,
  });

  final ScrollController scrollController;
  final VoidCallback onQuranTap;
  final VoidCallback onPrayerTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return SingleChildScrollView(
      controller: scrollController,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'أدوات مسلم',
              textDirection: TextDirection.rtl,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'خلي أهم ما تحتاجه من مسلم متاحًا على شاشتك الرئيسية.',
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            _WidgetChoice(
              title: 'القرآن الكريم',
              description:
                  'تابع آخر سورة وآية وصلت إليها واستكمل قراءتك بسهولة.',
              preview: const _WidgetPreview(),
              icon: Icons.menu_book_rounded,
              onTap: onQuranTap,
            ),
            const SizedBox(height: 10),
            _WidgetChoice(
              title: 'مواقيت الصلاة',
              description:
                  'تابع مواقيت الصلوات واعرف الوقت المتبقي للصلاة القادمة.',
              preview: const PrayerTimesWidgetPreview(),
              icon: Icons.access_time_rounded,
              onTap: onPrayerTap,
            ),
            const SizedBox(height: 12),
            Text(
              'اضغط على الأداة لمعرفة طريقة إضافتها إلى شاشتك الرئيسية.',
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WidgetChoice extends StatelessWidget {
  const _WidgetChoice({
    required this.title,
    required this.description,
    required this.preview,
    required this.icon,
    required this.onTap,
  });

  final String title, description;
  final Widget preview;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;
    return Material(
      color:
          isLight ? colors.surfaceContainerHigh : colors.surfaceContainerLow,
      elevation: isLight ? 1.5 : 0,
      shadowColor: colors.shadow.withValues(alpha: .14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color:
              isLight
                  ? colors.outlineVariant
                  : colors.outlineVariant.withValues(alpha: .45),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(icon, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      textDirection: TextDirection.rtl,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Icon(
                      Icons.chevron_left_rounded,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                description,
                textDirection: TextDirection.rtl,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 10),
              preview,
            ],
          ),
        ),
      ),
    );
  }
}

class PrayerTimesWidgetTutorialSheet extends StatefulWidget {
  const PrayerTimesWidgetTutorialSheet({super.key});

  @override
  State<PrayerTimesWidgetTutorialSheet> createState() =>
      _PrayerTimesWidgetTutorialSheetState();
}

class _PrayerTimesWidgetTutorialSheetState
    extends State<PrayerTimesWidgetTutorialSheet> {
  static const _steps = [
    'اضغط مطولًا على مساحة فارغة في الشاشة الرئيسية.',
    'اختر الأدوات (Widgets).',
    'ابحث عن تطبيق مسلم.',
    'اختر مواقيت الصلاة.',
    'اسحب الأداة إلى الشاشة الرئيسية وحدد الحجم المناسب.',
  ];
  int _step = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(22, 12, 22, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                'إضافة ويدجت مواقيت الصلاة',
                textDirection: TextDirection.rtl,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'خلّي مواقيت الصلاة والوقت المتبقي للصلاة القادمة قدامك دائمًا.',
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.start,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            const PrayerTimesWidgetPreview(),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _steps.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _step == index ? 22 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: _step == index
                        ? colors.primary
                        : colors.outlineVariant,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'الخطوة ${toArabicIndicDigits(_step + 1)} من ${toArabicIndicDigits(_steps.length)}',
              textDirection: TextDirection.rtl,
              style: theme.textTheme.labelLarge?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _steps[_step],
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                height: 1.55,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                if (_step > 0)
                  OutlinedButton(
                    onPressed: () => setState(() => _step--),
                    child: const Text('السابق'),
                  ),
                const Spacer(),
                FilledButton(
                  onPressed: () {
                    if (_step < _steps.length - 1) {
                      setState(() => _step++);
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _step < _steps.length - 1 ? 'التالي' : 'فهمت، لنبدأ',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PrayerTimesWidgetPreview extends StatelessWidget {
  const PrayerTimesWidgetPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final surface = dark ? const Color(0xff142a23) : const Color(0xffe6f2f6f2);
    final border = dark ? const Color(0xff3a5f50) : const Color(0x8a718078);
    final primaryText = dark ? const Color(0xfff0f4f1) : const Color(0xff1d3028);
    final secondaryText = dark ? const Color(0xffb0bdb5) : const Color(0xff596960);
    final selectedSurface = dark ? const Color(0xff285343) : const Color(0xffd7e8dd);
    final selectedText = dark ? const Color(0xff82c8ac) : const Color(0xff245c43);
    return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: surface,
      border: Border.all(color: border),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      children: [
        Row(
          textDirection: TextDirection.ltr,
          children: [
            Expanded(child: _PrayerWidgetMeta(icon: Icons.nights_stay_outlined, text: '١٥ رمضان', textDirection: TextDirection.ltr, color: secondaryText)),
            Expanded(child: _PrayerWidgetMeta(icon: Icons.calendar_today_outlined, text: 'السبت، ١٥ مارس', color: secondaryText)),
          ],
        ),
        SizedBox(height: 4),
        Row(
          textDirection: TextDirection.ltr,
          children: [
            Expanded(
              child: Row(
                textDirection: TextDirection.ltr,
                children: [
                  Icon(Icons.access_time_rounded, size: 14, color: secondaryText),
                  SizedBox(width: 4),
                  Text('الظهر بعد ٠١:٢٤', textDirection: TextDirection.rtl, style: TextStyle(color: primaryText, fontSize: 11)),
                ],
              ),
            ),
            Expanded(child: _PrayerWidgetMeta(icon: Icons.location_on_outlined, text: 'القاهرة', color: secondaryText)),
          ],
        ),
        SizedBox(height: 5),
        Divider(height: 5, thickness: 1, color: border),
        SizedBox(height: 4),
        Row(
          children: [
            Expanded(child: _PrayerPreviewCell('الفجر', '٤:٣٢', primaryText: primaryText, secondaryText: secondaryText, selectedSurface: selectedSurface, selectedText: selectedText)),
            Expanded(child: _PrayerPreviewCell('الظهر', '١١:٤٢', selected: true, primaryText: primaryText, secondaryText: secondaryText, selectedSurface: selectedSurface, selectedText: selectedText)),
            Expanded(child: _PrayerPreviewCell('العصر', '٣:٠٨', primaryText: primaryText, secondaryText: secondaryText, selectedSurface: selectedSurface, selectedText: selectedText)),
            Expanded(child: _PrayerPreviewCell('المغرب', '٥:٣٦', primaryText: primaryText, secondaryText: secondaryText, selectedSurface: selectedSurface, selectedText: selectedText)),
            Expanded(child: _PrayerPreviewCell('العشاء', '٦:٥٥', primaryText: primaryText, secondaryText: secondaryText, selectedSurface: selectedSurface, selectedText: selectedText)),
          ],
        ),
      ],
    ),
  );
  }
}

class _PrayerWidgetMeta extends StatelessWidget {
  const _PrayerWidgetMeta({required this.icon, required this.text, required this.color, this.textDirection = TextDirection.rtl});

  final IconData icon;
  final String text;
  final TextDirection textDirection;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    textDirection: textDirection,
    children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 4),
      Flexible(
        child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: TextStyle(color: color, fontSize: 9)),
      ),
    ],
  );
}

class _PrayerPreviewCell extends StatelessWidget {
  const _PrayerPreviewCell(this.name, this.time, {this.selected = false, required this.primaryText, required this.secondaryText, required this.selectedSurface, required this.selectedText});

  final String name, time;
  final bool selected;
  final Color primaryText, secondaryText, selectedSurface, selectedText;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 1),
    padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 1),
    decoration: BoxDecoration(
      color: selected ? selectedSurface : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      children: [
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textDirection: TextDirection.rtl,
          style: TextStyle(color: selected ? selectedText : secondaryText, fontSize: 8),
        ),
        Text(
          time,
          textDirection: TextDirection.rtl,
          style: TextStyle(
            color: selected ? selectedText : primaryText,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

class QuranWidgetTutorialSheet extends StatefulWidget {
  const QuranWidgetTutorialSheet({super.key});

  @override
  State<QuranWidgetTutorialSheet> createState() =>
      _QuranWidgetTutorialSheetState();
}

class _QuranWidgetTutorialSheetState extends State<QuranWidgetTutorialSheet> {
  int _step = 0;

  static const _instructions = [
    'اضغط مطولًا على مساحة فارغة في الشاشة الرئيسية.',
    'اختر الأدوات (Widgets).',
    'ابحث عن تطبيق مُسلم، واضغط مطولًا على ويدجت القرآن واسحبه إلى الشاشة الرئيسية.',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return _SheetFrame(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(22, 12, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 22),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  'إضافة ويدجت القرآن',
                  textDirection: TextDirection.rtl,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                child: _TutorialIllustration(key: ValueKey(_step), step: _step),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _step == index ? 25 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _step == index
                          ? colors.primary
                          : colors.outlineVariant,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'الخطوة ${toArabicIndicDigits(_step + 1)} من ${toArabicIndicDigits(3)}',
                textDirection: TextDirection.rtl,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _instructions[_step],
                key: ValueKey('instruction-$_step'),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  height: 1.55,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  if (_step > 0)
                    OutlinedButton(
                      onPressed: () => setState(() => _step--),
                      child: const Text('السابق'),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () {
                      if (_step < 2) {
                        setState(() => _step++);
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                    child: Text(_step < 2 ? 'التالي' : 'تم'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

class _WidgetPreview extends StatelessWidget {
  const _WidgetPreview();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final surface = dark ? const Color(0xff142a23) : const Color(0xfff8fbf8);
    final control = dark ? const Color(0xff20473b) : const Color(0xffdce9e1);
    final accent = dark ? const Color(0xff82c8ac) : const Color(0xff176b55);
    final primary = dark ? const Color(0xfff0f4f1) : const Color(0xff26372f);
    final secondary = dark ? const Color(0xffb0bdb5) : const Color(0xff77847b);
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 350),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [control, surface],
        ),
        border: Border.all(color: accent.withValues(alpha: .28)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: .14),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 23,
                backgroundColor: accent.withValues(alpha: .16),
                child: Icon(Icons.menu_book_rounded, color: accent),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الْقُرْآن الكريم',
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      'اختر قارئك المفضل',
                      textDirection: TextDirection.rtl,
                      style: TextStyle(color: secondary, fontSize: 12),
                    ),
                    Text(
                      'لا توجد تلاوة نشطة',
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Text('٠:٠٠', style: TextStyle(color: secondary, fontSize: 10)),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: LinearProgressIndicator(
                    value: 0,
                    minHeight: 5,
                    color: accent,
                    backgroundColor: accent.withValues(alpha: .18),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('-٠:٠٠', style: TextStyle(color: secondary, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PreviewControl(icon: Icons.skip_next_rounded, color: accent),
              const SizedBox(width: 18),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: dark ? const Color(0xff17241d) : Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 18),
              _PreviewControl(icon: Icons.skip_previous_rounded, color: accent),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreviewControl extends StatelessWidget {
  const _PreviewControl({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 34,
    height: 34,
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      shape: BoxShape.circle,
    ),
    child: Icon(icon, color: color, size: 21),
  );
}

class _TutorialIllustration extends StatelessWidget {
  const _TutorialIllustration({super.key, required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final title = switch (step) {
      0 => 'الشاشة الرئيسية',
      1 => 'الأدوات',
      _ => 'ويدجت القرآن',
    };
    return Container(
      height: 190,
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: .55),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 118,
                height: 130,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: colors.outlineVariant),
                  boxShadow: [
                    BoxShadow(
                      color: colors.shadow.withValues(alpha: .12),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        3,
                        (_) => Container(
                          margin: const EdgeInsets.all(3),
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: colors.primaryContainer,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: colors.primaryContainer.withValues(alpha: .65),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(
                          step == 2
                              ? Icons.menu_book_rounded
                              : Icons.widgets_rounded,
                          color: colors.primary,
                          size: 29,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      textDirection: TextDirection.rtl,
                      style: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (step == 0)
            Positioned(
              bottom: 25,
              child: Icon(
                Icons.touch_app_rounded,
                color: colors.primary,
                size: 34,
              ),
            ),
          if (step == 1)
            Positioned(
              right: 35,
              top: 50,
              child: Icon(
                Icons.widgets_rounded,
                color: colors.tertiary,
                size: 30,
              ),
            ),
          if (step == 2)
            Positioned(
              right: 40,
              bottom: 50,
              child: Icon(
                Icons.open_with_rounded,
                color: colors.primary,
                size: 30,
              ),
            ),
        ],
      ),
    );
  }
}
