import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/quran.dart' as quran;
import 'package:muslim/core/widgets/app_widgets.dart';
import 'package:muslim/features/quran/domain/entities/quran_downloaded_audio.dart';
import 'package:muslim/features/quran/presentation/cubit/quran_cubit.dart';
import 'package:muslim/features/quran/presentation/cubit/quran_state.dart';
import 'package:muslim/features/quran/presentation/pages/surah_screen.dart';
import 'package:muslim/features/app/presentation/widgets/settings_page_app_bar.dart';

class QuranDownloadsScreen extends StatefulWidget {
  const QuranDownloadsScreen({super.key});

  @override
  State<QuranDownloadsScreen> createState() => _QuranDownloadsScreenState();
}

class _QuranDownloadsScreenState extends State<QuranDownloadsScreen> {
  List<QuranDownloadedAudio>? _downloads;
  final Set<String> _deletingAudioUrls = <String>{};
  late int _observedDownloadRevision;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<QuranCubit>();
    _observedDownloadRevision = cubit.downloadRevision;
    _refreshDownloads();
  }

  Future<void> _refreshDownloads() async {
    final downloads = await context.read<QuranCubit>().downloadedAudios();
    if (!mounted) return;
    setState(() => _downloads = downloads);
  }

  Future<void> _remove(QuranDownloadedAudio audio) async {
    if (_deletingAudioUrls.contains(audio.url)) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          icon: Icon(
            Icons.delete_outline_rounded,
            color: Theme.of(dialogContext).colorScheme.error,
          ),
          title: const Text('حذف التسجيل'),
          content: const Text(
            'هل أنت متأكد أنك تريد حذف التسجيل الصوتي لهذه السورة؟',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actionsPadding: const EdgeInsetsDirectional.fromSTEB(24, 0, 24, 16),
          actionsOverflowButtonSpacing: 12,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('إلغاء'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              icon: const Icon(Icons.delete_rounded),
              label: const Text('حذف'),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(dialogContext).colorScheme.error,
                foregroundColor: Theme.of(dialogContext).colorScheme.onError,
              ),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true ||
        !mounted ||
        _deletingAudioUrls.contains(audio.url)) {
      return;
    }

    setState(() => _deletingAudioUrls.add(audio.url));
    try {
      await context.read<QuranCubit>().deleteDownloadedAudio(audio.url);
      if (!mounted) return;
      setState(() {
        _downloads = _downloads
            ?.where((download) => download.url != audio.url)
            .toList(growable: false);
      });
      AppSnackBar.show(message: 'تم حذف التسجيل بنجاح', success: true);
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.show(message: 'تعذر حذف التسجيل، حاول مجددًا');
    } finally {
      if (mounted) setState(() => _deletingAudioUrls.remove(audio.url));
    }
  }

  Future<void> _openDownloadedSurah(QuranDownloadedAudio audio) async {
    final cubit = context.read<QuranCubit>();
    final rawName = quran.getSurahNameArabic(audio.surahNumber);
    final surahName = rawName == 'اللهب' ? 'المسد' : rawName;
    final savedAyah = cubit.lastAyahForSurah(audio.surahNumber) ?? 1;

    // Use this download's reciter for the next playback when changing it will
    // not interrupt an active shared audio session.
    if (!cubit.hasActivePlaybackSession &&
        cubit.selectedReciter.id != audio.reciter.id) {
      await cubit.selectReciter(audio.reciter);
    }
    await cubit.selectSurah(
      audio.surahNumber,
      surahName,
      online: cubit.isOnline,
      startAyah: savedAyah,
    );
    if (!mounted) return;
    navigateTo(
      context,
      SurahScreen(
        surahNumber: audio.surahNumber,
        initialAyah: savedAyah,
      ),
    );
  }

  Widget _offlinePlaybackHint(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 4),
      padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 14, 10),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.cloud_download_outlined,
              size: 19,
              color: colors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'التشغيل بدون إنترنت',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colors.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'يمكنك تنزيل التسجيلات الصوتية للسور والاحتفاظ بها على جهازك للاستماع إليها في أي وقت بدون الحاجة إلى اتصال بالإنترنت.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onPrimaryContainer,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocListener<QuranCubit, QuranState>(
      listener: (context, state) {
        final cubit = context.read<QuranCubit>();
        if (cubit.downloadRevision == _observedDownloadRevision) return;
        _observedDownloadRevision = cubit.downloadRevision;
        _refreshDownloads();
      },
      child: Scaffold(
        appBar: const SettingsPageAppBar(
          title: 'إدارة التنزيلات',
          showThemeAction: false,
        ),
        body: SafeArea(
          child: _downloads == null
              ? Center(
                  child: CircularProgressIndicator(
                    color: theme.colorScheme.primary,
                  ),
                )
              : Builder(
                  builder: (context) {
                    final items = _downloads!;
                    return Column(
                      children: [
                        _offlinePlaybackHint(context),
                        Expanded(
                          child: items.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(28),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.download_for_offline_outlined,
                                          size: 42,
                                          color: theme
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'لا توجد سور محفوظة حاليًا',
                                          textAlign: TextAlign.center,
                                          style: theme.textTheme.titleMedium,
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  padding: const EdgeInsetsDirectional.fromSTEB(
                                    16,
                                    8,
                                    16,
                                    28,
                                  ),
                                  itemCount: items.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    final audio = items[index];
                                    final name = quran.getSurahNameArabic(
                                      audio.surahNumber,
                                    );
                                    final isDeleting = _deletingAudioUrls
                                        .contains(audio.url);
                                    return Card(
                                      clipBehavior: Clip.antiAlias,
                                      child: ListTile(
                                        onTap: isDeleting
                                            ? null
                                            : () => _openDownloadedSurah(audio),
                                        leading: Icon(
                                          Icons.audiotrack_rounded,
                                          color: theme.colorScheme.primary,
                                        ),
                                        title: Text(
                                          'سورة ${name == 'اللهب' ? 'المسد' : name}',
                                        ),
                                        subtitle: Text(audio.reciter.nameArabic),
                                        trailing: IconButton(
                                          tooltip: 'حذف التنزيل',
                                          onPressed: isDeleting
                                              ? null
                                              : () => _remove(audio),
                                          icon: isDeleting
                                              ? SizedBox.square(
                                                  dimension: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color:
                                                        theme.colorScheme.error,
                                                  ),
                                                )
                                              : Icon(
                                                  Icons.delete_outline_rounded,
                                                  color:
                                                      theme.colorScheme.error,
                                                ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    );
                  },
                ),
        ),
      ),
    );
  }
}
