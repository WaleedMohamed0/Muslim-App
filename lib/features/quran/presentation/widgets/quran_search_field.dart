import 'package:flutter/material.dart';
import 'package:muslim/core/theme/app_theme.dart';

/// Search field shared by the Surah/Juz list and Mushaf Signs screens.
class QuranSearchField extends StatelessWidget {
  const QuranSearchField({
    super.key,
    required this.controller,
    required this.query,
    required this.hintText,
    required this.onChanged,
    required this.onClear,
    this.clearTooltip = 'مسح البحث',
    this.textDirection = TextDirection.rtl,
  });

  final TextEditingController controller;
  final String query;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final String clearTooltip;
  final TextDirection textDirection;

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        textDirection: textDirection,
        textInputAction: TextInputAction.search,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: query.isEmpty
              ? null
              : IconButton(
                  tooltip: clearTooltip,
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded),
                ),
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.card),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      );
}
