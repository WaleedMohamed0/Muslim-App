import 'package:flutter/material.dart';

@immutable
class TajweedLesson {
  const TajweedLesson({
    required this.title,
    required this.description,
    required this.level,
    required this.icon,
    required this.introduction,
    required this.rules,
    required this.example,
    required this.reference,
    this.exampleSurahNumber,
    this.exampleAyahNumber,
    this.exampleHighlight,
  });

  final String title;
  final String description;
  final String level;
  final IconData icon;
  final String introduction;
  final List<String> rules;
  final String example;
  final String reference;
  final int? exampleSurahNumber;
  final int? exampleAyahNumber;
  final String? exampleHighlight;
}
