import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'package:muslim/features/azkar/data/data_sources/azkar_counter_hint_preferences.dart';
import 'package:muslim/features/app/data/services/post_prayer_adhkar_reminder_service.dart';
import 'package:muslim/features/app/data/repositories/prayer_wird_progress_repository.dart';
import 'package:muslim/features/app/presentation/pages/daily_reminder_settings_screen.dart';
import 'package:muslim/features/prayer_times/data/services/prayer_adhan_service.dart';
import 'package:muslim/features/azkar/presentation/cubit/azkar_cubit.dart';
import 'package:muslim/features/azkar/presentation/cubit/azkar_state.dart';
import 'package:muslim/features/azkar/domain/entities/azkar_entry.dart';
import 'package:muslim/features/hadeeth/presentation/cubit/hadeeth_cubit.dart';
import 'package:muslim/features/hadeeth/presentation/cubit/hadeeth_state.dart';
import 'package:muslim/features/hadeeth/domain/entities/hadeeth_entry.dart';

import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/external_link_button.dart';
import 'package:muslim/features/azkar/presentation/widgets/azkar_text_card.dart';
import 'package:muslim/features/azkar/presentation/widgets/azkar_section_header.dart';
import 'package:muslim/features/travel_prayer/presentation/widgets/travel_dua_card.dart';

class AzkarAndHadeethScreen extends StatefulWidget {
  const AzkarAndHadeethScreen({super.key, required this.index});
  final int index;

  @override
  State<AzkarAndHadeethScreen> createState() => _AzkarAndHadeethScreenState();
}

class _AzkarAndHadeethScreenState extends State<AzkarAndHadeethScreen>
    with WidgetsBindingObserver {
  final ScrollController _azkarScrollController = ScrollController();
  final Map<String, GlobalKey> _entryKeys = {};
  final AzkarCounterHintPreferences _counterHintPreferences =
      AzkarCounterHintPreferences.instance;
  bool _completionDialogShown = false;
  bool _completionBaselineEstablished = false;
  bool _reminderStatusLoaded = false;
  bool _reminderEnabled = false;
  bool _notificationsAllowed = true;
  late final String title = switch (widget.index) {
    0 => 'أَذْكَارُ الصَّبَاحِ',
    1 => 'أَذْكَارُ المساءِ',
    2 => 'أَذْكَارُ النَوْم',
    3 => 'أذكار الاستيقاظ',
    4 => 'أذكار ما بعد الصَّلَاة',
    5 => 'التسابيح',
    6 => 'أدعية قرآنية',
    7 => 'أدعية الْأَنْبِيَاء',
    8 => 'أدعية من السُّنَّة النبوية',
    9 => 'أدعية للمواقف اليومية',
    10 => 'أذكار عند سماع الأذان',
    _ => 'الْأَحَادِيث النبوية',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.index != 11) {
      context.read<AzkarCubit>().loadContent();
    }
    if (widget.index == 11) context.read<HadeethCubit>().getHadeeth();
    _counterHintPreferences.shouldShow.addListener(_onCounterHintChanged);
    unawaited(_counterHintPreferences.load());
    if (widget.index == 0 || widget.index == 1) {
      final service = PrayerAdhanService.instance;
      final cachedReminders = service.cachedDailyReminders;
      if (cachedReminders != null) {
        final id = widget.index == 0 ? 'morning' : 'evening';
        final reminder = cachedReminders
            .where((item) => item['id'] == id)
            .firstOrNull;
        _reminderEnabled = reminder?['enabled'] == true;
        _notificationsAllowed =
            service.cachedPermissions?['notifications'] ?? true;
        _reminderStatusLoaded = true;
      }
      unawaited(_refreshReminderStatus());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _counterHintPreferences.shouldShow.removeListener(_onCounterHintChanged);
    _azkarScrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        (widget.index == 0 || widget.index == 1)) {
      unawaited(_refreshReminderStatus());
    }
  }

  void _onCounterHintChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _refreshReminderStatus() async {
    final service = PrayerAdhanService.instance;
    try {
      final results = await Future.wait([
        service.getDailyReminders(),
        service.permissionStatus(),
      ]);
      if (!mounted) return;
      final id = widget.index == 0 ? 'morning' : 'evening';
      final reminder = (results[0] as List<Map<String, dynamic>>)
          .where((item) => item['id'] == id)
          .firstOrNull;
      setState(() {
        _reminderEnabled = reminder?['enabled'] == true;
        _notificationsAllowed = (results[1] as Map<String, bool>)['notifications'] == true;
        _reminderStatusLoaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _reminderStatusLoaded = true);
    }
  }

  Future<void> _openReminderSettings() async {
    if (!_notificationsAllowed && _reminderEnabled) {
      await PrayerAdhanService.instance.openAppSettings();
    } else {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => const DailyReminderSettingsScreen(),
        ),
      );
    }
    await _refreshReminderStatus();
  }

  Future<void> _incrementEntry(
    AzkarCubit cubit,
    List<AzkarEntry> entries,
    int itemIndex,
    AzkarEntry entry,
  ) async {
    final wasComplete = cubit.progressFor(entry) >= (entry.repetitionCount ?? 1);
    await cubit.incrementEntry(entry);
    if (wasComplete || !mounted || cubit.progressFor(entry) < (entry.repetitionCount ?? 1)) {
      return;
    }

    // Move the following entry near the top after the counter update has rebuilt
    // its card. Adjacent list children are kept alive by ListView's cache area.
    final nextIndex = itemIndex + 1;
    if (nextIndex >= entries.length) return;
    final nextEntry = entries[nextIndex];
    final nextKey = _entryKeys[nextEntry.id];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final targetContext = nextKey?.currentContext;
      if (!mounted || targetContext == null) return;
      Scrollable.ensureVisible(
        targetContext,
        alignment: 0.08,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final category = widget.index;
    if (category == 11) {
      return BlocBuilder<HadeethCubit, HadeethState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return Scaffold(
            appBar: defaultAppBar(context: context, text: title),
            body: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        16,
                        8,
                        16,
                        24,
                      ),
                      itemCount: state.entries.isEmpty
                          ? 2
                          : state.entries.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return AzkarSectionHeader(
                            isHadith: true,
                            totalCount: state.entries.length,
                          );
                        }
                        if (state.entries.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Text(
                                state.error ?? 'لا توجد بيانات للعرض',
                                textDirection: TextDirection.rtl,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        }
                        final entry = state.entries[index - 1];
                        return AzkarTextCard(
                          text: entry.text,
                          shareCategory: title,
                          shareInsteadOfCopy: true,
                          onCopy:
                              () => Clipboard.setData(
                                ClipboardData(text: entry.text),
                              ),
                          onShare: () => const MethodChannel(
                            'com.muslim/quran_share',
                          ).invokeMethod<void>('shareText', {
                            'text': [entry.text, entry.citation]
                                .where((value) => value.trim().isNotEmpty)
                                .join('\n\n'),
                            'title': 'مشاركة حديث',
                          }),
                          onTap: () => _showHadithDetails(context, entry),
                        );
                      },
                    ),
          );
        },
      );
    }

    return BlocConsumer<AzkarCubit, AzkarState>(
      listenWhen: (previous, current) =>
          category == 4 ||
          ((category >= 0 && category <= 3 || category == 10) &&
              previous.revision != current.revision),
      listener: (context, current) {
        final cubit = context.read<AzkarCubit>();
        if ((category >= 0 && category <= 3) || category == 10) {
          if (current.isLoading) return;
          final complete = _isSectionComplete(cubit, current, category);
          if (!_completionBaselineEstablished) {
            _completionBaselineEstablished = true;
            return;
          }
          if (!complete) {
            _completionDialogShown = false;
            return;
          }
          if (_completionDialogShown) return;
          _completionDialogShown = true;
          unawaited(_showAzkarCompletion());
          return;
        }
        if (_completionDialogShown || !cubit.isPostPrayerSessionComplete()) {
          return;
        }
        _completionDialogShown = true;
        unawaited(_showPostPrayerCompletion());
      },
      builder: (context, state) {
        final cubit = context.read<AzkarCubit>();
        if (state.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (state.error != null) {
          return Scaffold(
            appBar: defaultAppBar(context: context, text: title),
            body: Center(child: Text(state.error!)),
          );
        }
        final entries = state.entriesFor(category);
        const sleepSourceUrl = 'https://www.islambook.com/app/ar/azkr/11';
        const wakingSourceUrl = 'https://www.islambook.com/app/ar/azkr/12';
        const tasbeehSourceUrl = 'https://www.islambook.com/app/ar/azkr/3';
        const morningSourceUrl = 'https://www.islambook.com/app/ar/azkr/1';
        const eveningSourceUrl = 'https://www.islambook.com/app/ar/azkr/2';
        const postPrayerSourceUrl = 'https://www.islambook.com/app/ar/azkr/9';
        const quranDuaSourceUrl = 'https://www.islambook.com/app/ar/azkr/15';
        const prophetsDuaSourceUrl = 'https://www.islambook.com/app/ar/azkr/28';
        const adhanSourceUrl = 'https://www.islambook.com/ar/azkr/5';
        return Scaffold(
          appBar: defaultAppBar(context: context, text: title),
          body: entries.isEmpty
                  ? const Center(child: Text('لا توجد بيانات للعرض'))
                  : ListView.builder(
                    controller: _azkarScrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      16,
                      8,
                      16,
                      24,
                    ),
                    itemCount:
                        entries.length +
                        1 +
                        (category == 2 ? 1 : 0) +
                        (category == 0 || category == 1 ? 1 : 0) +
                        (category == 3 || category == 4 || category == 5 || category == 6 || category == 7 || category == 10 ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return AzkarSectionHeader(
                          isHadith: false,
                          totalCount: entries.length,
                          showTasbeehHint: category == 5,
                          showTotalCount: category != 7,
                          showCounterHint: _counterHintPreferences.shouldShow.value &&
                              category != 9 &&
                                  category != 6 &&
                                  category != 7 &&
                                  entries.any(
                                    (entry) =>
                                        entry.hasPredefinedRepetitionCount,
                                  ),
                          onScheduleTap: (category == 0 || category == 1) &&
                                  _reminderStatusLoaded &&
                                  (!_reminderEnabled || !_notificationsAllowed)
                              ? _openReminderSettings
                              : null,
                          scheduleHintTitle: !_notificationsAllowed && _reminderEnabled
                              ? 'استعادة إذن الإشعارات'
                              : category == 0
                                  ? 'فعّل تذكير أذكار الصباح'
                                  : 'فعّل تذكير أذكار المساء',
                          scheduleHintMessage: !_notificationsAllowed && _reminderEnabled
                              ? 'افتح إعدادات الجهاز للسماح بالإشعارات مرة أخرى'
                              : category == 0
                                  ? 'اختر موعدًا لتذكيرك بأذكار الصباح'
                                  : 'اختر موعدًا لتذكيرك بأذكار المساء',
                        );
                      }
                      if ((category == 0 || category == 1) &&
                          index == entries.length + 1) {
                        return Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                            12,
                            8,
                            12,
                            20,
                          ),
                          child: ExternalLinkButton(
                            url: category == 0
                                ? morningSourceUrl
                                : eveningSourceUrl,
                            label:
                                'المصدر: ${category == 0 ? morningSourceUrl : eveningSourceUrl}',
                          ),
                        );
                      }
                      if (category == 3 && index == entries.length + 1) {
                        return Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                            12,
                            16,
                            12,
                            24,
                          ),
                          child: const ExternalLinkButton(
                            url: wakingSourceUrl,
                            label: 'المصدر: $wakingSourceUrl',
                          ),
                        );
                      }
                      if (category == 4 && index == entries.length + 1) {
                        return Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                            12,
                            16,
                            12,
                            24,
                          ),
                          child: const ExternalLinkButton(
                            url: postPrayerSourceUrl,
                            label: 'المصدر: $postPrayerSourceUrl',
                          ),
                        );
                      }
                      if (category == 5 && index == entries.length + 1) {
                        return Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                            12,
                            16,
                            12,
                            24,
                          ),
                          child: const ExternalLinkButton(
                            url: tasbeehSourceUrl,
                            label: 'المصدر: $tasbeehSourceUrl',
                          ),
                        );
                      }
                      if (category == 6 && index == entries.length + 1) {
                        return Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                            12,
                            16,
                            12,
                            24,
                          ),
                          child: const ExternalLinkButton(
                            url: quranDuaSourceUrl,
                            label: 'المصدر: $quranDuaSourceUrl',
                          ),
                        );
                      }
                      if (category == 7 && index == entries.length + 1) {
                        return Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                            12,
                            16,
                            12,
                            24,
                          ),
                          child: const ExternalLinkButton(
                            url: prophetsDuaSourceUrl,
                            label: 'المصدر: $prophetsDuaSourceUrl',
                          ),
                        );
                      }
                      if (category == 10 && index == entries.length + 1) {
                        return Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                            12,
                            16,
                            12,
                            24,
                          ),
                          child: const ExternalLinkButton(
                            url: adhanSourceUrl,
                            label: 'المصدر: $adhanSourceUrl',
                          ),
                        );
                      }
                      if (category == 2 && index == entries.length + 1) {
                        return Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                            12,
                            16,
                            12,
                            24,
                          ),
                          child: const ExternalLinkButton(
                            url: sleepSourceUrl,
                            label: 'المصدر: $sleepSourceUrl',
                          ),
                        );
                      }
                      final itemIndex = index - 1;
                      final entry = entries[itemIndex];
                      if (entry.id == 'situational_travel_dua') {
                        return const TravelDuaCard();
                      }
                      final text = entry.content;
                      final isUnnumberedBedtimeDhikr = entry.sourceIds
                          .contains('sleep_bismika_amutu');
                      // The legacy Quranic and Prophetic Dua lists use "01"
                      // as a display default, not as a prescribed repetition.
                      final supportsCounting =
                          entry.hasPredefinedRepetitionCount &&
                          category != 6 &&
                          category != 7;
                      final entryKey = _entryKeys.putIfAbsent(
                        entry.id,
                        GlobalKey.new,
                      );
                      return AzkarTextCard(
                        key: entryKey,
                        text: text,
                        shareCategory: title,
                        sectionLabel: category == 9 ? entry.subCategory : null,
                        repetitionCount: supportsCounting
                            ? entry.repetitionCount
                            : null,
                        counter: supportsCounting
                            ? cubit.progressFor(entry)
                            : null,
                        reference: category != 2 && entry.verified
                            ? _entryReference(entry)
                            : null,
                        instructions: entry.verified && category != 5
                            ? entry.instructions
                            : null,
                        showVirtueInfo: category == 5,
                        infoIcon: category == 10 && entry.id == 'adhan_repeat_muezzin'
                            ? Icons.volume_up_rounded
                            : category == 10 && entry.id == 'adhan_between_prayer_dua'
                                ? Icons.favorite_rounded
                                : null,
                        infoLabel: category == 10 && entry.id == 'adhan_repeat_muezzin'
                            ? 'توجيه'
                            : category == 10 && entry.id == 'adhan_between_prayer_dua'
                                ? 'تذكير'
                                : null,
                        emphasizeInfo: category == 10 && entry.id == 'adhan_between_prayer_dua',
                        showCopy: !(category == 10 &&
                            (entry.id == 'adhan_repeat_muezzin' ||
                                entry.id == 'adhan_between_prayer_dua')),
                        shareInsteadOfCopy:
                            (category >= 6 && category <= 9) ||
                            isUnnumberedBedtimeDhikr,
                        onVirtueTap: category == 5
                            ? () => _showTasbeehVirtue(context, entry)
                            : null,
                        onCopy:
                            () => Clipboard.setData(ClipboardData(text: text)),
                        onIncrement: supportsCounting
                            ? () {
                                unawaited(_incrementEntry(
                                  cubit,
                                  entries,
                                  itemIndex,
                                  entry,
                                ));
                                _counterHintPreferences.dismiss();
                              }
                            : null,
                        onReset: supportsCounting
                            ? () => cubit.resetEntry(entry)
                            : null,
                        onShare: (entry.counterEnabled && category != 9) ||
                                (category >= 6 && category <= 9) ||
                                isUnnumberedBedtimeDhikr
                            ? () => cubit.shareEntry(entry)
                            : null,
                      );
                    },
                  ),
        );
      },
    );
  }

  bool _isSectionComplete(AzkarCubit cubit, AzkarState state, int category) {
    final sectionEntries = state.entriesFor(category);
    // Adhan guidance cards are informational and have no counter. Only the
    // countable adhkar can participate in the section's completion check.
    final entries = category == 10
        ? sectionEntries.where((entry) => entry.hasPredefinedRepetitionCount)
        : sectionEntries;
    return entries.isNotEmpty && entries.every((entry) {
      final required = entry.repetitionCount ?? 1;
      return cubit.progressFor(entry) >= required;
    });
  }

  Future<void> _showAzkarCompletion() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final colors = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: colors.primary.withValues(alpha: 0.22)),
          ),
          icon: Icon(Icons.spa_rounded, color: colors.primary, size: 34),
          title: const Text('أحسنت! 🌿', textAlign: TextAlign.center),
          content: const Text(
            'أتممت أذكارك، تقبّل الله منك',
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('تم'),
            ),
          ],
        );
      },
    );
    if (!mounted) return;
    final period = await context
        .read<AzkarCubit>()
        .currentPostPrayerSessionPeriod();
    if (period != null) {
      await PostPrayerAdhkarReminderService.instance
          .cancelForCompletedPeriod(period);
      await PrayerWirdProgressRepository().markCompleted(period, 'azkar');
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  String _entryReference(AzkarEntry entry) {
    final grade = entry.authenticityGrade.trim();
    final reference = entry.reference.trim();
    if (grade.isEmpty || reference.endsWith(grade)) return reference;
    return '$reference — $grade';
  }

  Future<void> _showHadithDetails(
    BuildContext context,
    HadeethEntry entry,
  ) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      final colors = theme.colorScheme;
      return Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: EdgeInsetsDirectional.fromSTEB(
            24,
            8,
            24,
            24 + MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'تفاصيل الحديث',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                entry.text,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(height: 1.9),
              ),
              const SizedBox(height: 20),
              _HadithDetailRow(label: 'الشرح', value: entry.explanation),
              const SizedBox(height: 12),
              _HadithDetailRow(label: 'الراوي', value: entry.narrator),
              const SizedBox(height: 12),
              _HadithDetailRow(label: 'التخريج', value: entry.citation),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => launchUrl(
                  Uri.parse(entry.referenceUrl),
                  mode: LaunchMode.externalApplication,
                ),
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('فتح المرجع للتحقق'),
                iconAlignment: IconAlignment.end,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: colors.primary.withValues(alpha: 0.5)),
                  foregroundColor: colors.primary,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  Future<void> _showTasbeehVirtue(
    BuildContext context,
    AzkarEntry entry,
  ) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      final colors = theme.colorScheme;
      final virtue = entry.instructions.trim();
      final reference = entry.verified ? _entryReference(entry).trim() : '';
      return Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              24,
              4,
              24,
              24 + MediaQuery.viewInsetsOf(sheetContext).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  entry.content,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                    height: 1.7,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'فضل التسبيحة',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  virtue.isEmpty ? 'لا يتوفر نص للفضل.' : virtue,
                  style: theme.textTheme.bodyLarge?.copyWith(height: 1.8),
                ),
                if (reference.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      'المصدر: $reference',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );

  Future<void> _showPostPrayerCompletion() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final colors = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: colors.primary.withValues(alpha: 0.22)),
          ),
          icon: Icon(Icons.spa_rounded, color: colors.primary, size: 34),
          title: const Text('أحسنت! 🌿', textAlign: TextAlign.center),
          content: const Text(
            'أتممت أذكارك، تقبّل الله منك',
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('تم'),
            ),
          ],
        );
      },
    );
    if (!mounted) return;
    final period = await context
        .read<AzkarCubit>()
        .currentPostPrayerSessionPeriod();
    if (period != null) {
      await PostPrayerAdhkarReminderService.instance
          .cancelForCompletedPeriod(period);
      await PrayerWirdProgressRepository().markCompleted(period, 'azkar');
    }
    if (mounted) Navigator.of(context).pop(true);
  }

}

class _HadithDetailRow extends StatelessWidget {
  const _HadithDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.bodyLarge?.copyWith(height: 1.7)),
      ],
    );
  }
}
