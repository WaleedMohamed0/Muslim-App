import 'package:flutter/material.dart';
import 'package:muslim/features/quran/domain/entities/quran_reciter.dart';
import 'package:muslim/features/quran/presentation/cubit/quran_cubit.dart';
import 'package:muslim/features/quran/presentation/widgets/quran_reader_palette.dart';
import 'package:muslim/features/quran/presentation/widgets/quran_reciter_avatar.dart';

Future<void> showQuranReciterPicker(
  BuildContext context,
  QuranCubit cubit,
) async {
  final palette = QuranReaderPalette.fromTheme(context);
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: palette.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder:
        (sheetContext) => SafeArea(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(sheetContext).height * .72,
              ),
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 20),
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: palette.muted.withValues(alpha: .45),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'اختر القارئ',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: palette.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...QuranReciter.all.map((reciter) {
                    final selected = cubit.selectedReciter.id == reciter.id;
                    return ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      selected: selected,
                      selectedTileColor: palette.highlight,
                      leading: QuranReciterAvatar(reciter: reciter, size: 42),
                      title: Text(
                        reciter.nameArabic,
                        style: TextStyle(
                          color: palette.text,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        reciter.nameEnglish,
                        textDirection: TextDirection.ltr,
                        style: TextStyle(color: palette.muted, fontSize: 12),
                      ),
                      trailing: Icon(
                        selected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        color: selected ? palette.accent : palette.muted,
                      ),
                      onTap: () async {
                        Navigator.of(sheetContext).pop();
                        await cubit.selectReciter(reciter);
                      },
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
  );
}
