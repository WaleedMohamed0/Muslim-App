import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim/features/app/presentation/widgets/settings_page_app_bar.dart';
import 'package:muslim/features/quran/presentation/cubit/quran_cubit.dart';
import 'package:muslim/features/quran/presentation/cubit/quran_state.dart';
import 'package:muslim/features/quran/presentation/widgets/quran_reader_background_colors.dart';
import 'package:muslim/features/quran/presentation/widgets/quran_reader_background_picker_widgets.dart';

class QuranReaderBackgroundScreen extends StatefulWidget {
  const QuranReaderBackgroundScreen({super.key});

  @override
  State<QuranReaderBackgroundScreen> createState() =>
      _QuranReaderBackgroundScreenState();
}

class _QuranReaderBackgroundScreenState
    extends State<QuranReaderBackgroundScreen> {
  bool? _targetDarkMode;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _targetDarkMode ??= Theme.of(context).brightness == Brightness.dark;
  }

  Future<void> _chooseCustomColor(
    QuranCubit cubit,
    Color currentColor,
    bool darkMode,
  ) async {
    final picked = await showModalBottomSheet<Color>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => CustomReaderColorPicker(
        initialColor: currentColor,
        darkMode: darkMode,
      ),
    );
    if (picked == null || !mounted) return;
    await cubit.setReaderBackgroundColor(darkMode: darkMode, color: picked);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<QuranCubit>();
    final darkMode = _targetDarkMode ?? false;
    final presets = QuranReaderBackgroundColors.presetsFor(darkMode);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: const SettingsPageAppBar(
        title: 'لون خلفية القراءة',
        showThemeAction: false,
      ),
      body: SafeArea(
        child: BlocBuilder<QuranCubit, QuranState>(
          builder: (context, state) {
            final storedColor = darkMode
                ? cubit.darkReaderBackgroundColorValue
                : cubit.lightReaderBackgroundColorValue;
            final selectedColor = storedColor == null
                ? QuranReaderBackgroundColors.defaultFor(darkMode)
                : Color(storedColor);
            final textColor = QuranReaderBackgroundColors.textFor(darkMode);
            final accent = QuranReaderBackgroundColors.accentFor(darkMode);
            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsetsDirectional.fromSTEB(18, 16, 18, 18),
                    children: [
                      Text(
                        'اختر لونًا مريحًا للقراءة. لكل وضع لوني اختياره الخاص.',
                        textDirection: TextDirection.rtl,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: theme.colorScheme.outline,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Row(
                          children: [
                            _buildModeOption(
                              context,
                              label: 'الوضع الفاتح',
                              icon: Icons.light_mode_rounded,
                              value: false,
                              selected: !darkMode,
                            ),
                            Container(
                              width: 1.5,
                              height: 52,
                              color: theme.colorScheme.outline,
                            ),
                            _buildModeOption(
                              context,
                              label: 'الوضع الداكن',
                              icon: Icons.dark_mode_rounded,
                              value: true,
                              selected: darkMode,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      ReaderColorPreview(
                        color: selectedColor,
                        textColor: textColor,
                        accent: accent,
                        darkMode: darkMode,
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'ألوان مقترحة',
                        textDirection: TextDirection.rtl,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final itemWidth = (constraints.maxWidth - 24) / 3;
                          return Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              for (final preset in presets)
                                SizedBox(
                                  width: itemWidth,
                                  child: PresetColorTile(
                                    preset: preset,
                                    selected: preset.color.toARGB32() ==
                                        selectedColor.toARGB32(),
                                    width: itemWidth,
                                    onTap: () => cubit.setReaderBackgroundColor(
                                      darkMode: darkMode,
                                      color: preset.color,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Card(
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          leading: const Icon(Icons.color_lens_outlined),
                          title: const Text('اختيار لون مخصص'),
                          subtitle: const Text('اضبط درجة اللون والتشبع'),
                          trailing: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: selectedColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.colorScheme.outlineVariant,
                              ),
                            ),
                          ),
                          onTap: () => _chooseCustomColor(
                            cubit,
                            selectedColor,
                            darkMode,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: TextButton.icon(
                          onPressed: () => cubit.setReaderBackgroundColor(
                            darkMode: darkMode,
                            color: null,
                          ),
                          icon: const Icon(Icons.restart_alt_rounded),
                          label: const Text('استعادة اللون الافتراضي'),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(18, 8, 18, 14),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      child: const Text('تم'),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildModeOption(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool value,
    required bool selected,
  }) {
    final theme = Theme.of(context);
    return Expanded(
      child: Material(
        color: selected
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surface,
        child: InkWell(
          onTap: () => setState(() => _targetDarkMode = value),
          child: SizedBox(
            height: 52,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: selected
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurface,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: selected
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

