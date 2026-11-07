/// Parsed view of an offline Azkar record, including its source count value.
class AzkarEntry {
  const AzkarEntry({
    this.id = '',
    this.category = '',
    this.subCategory = '',
    this.countText = '',
    this.countStatus,
    this.description = '',
    this.reference = '',
    this.instructions = '',
    this.verified = false,
    this.authenticityGrade = '',
    this.alternateContent = '',
    this.sourceIds = const [],
    this.mergedSourceMetadata,
    this.content = '',
  });

  factory AzkarEntry.fromJson(Map<String, dynamic> json) => AzkarEntry(
        id: json['id'] as String? ?? _fallbackId(
          json['category'] as String? ?? '',
          json['content'] as String? ?? '',
        ),
        category: json['category'] as String? ?? '',
        subCategory: json['subcategory'] as String? ?? '',
        countText: json['count']?.toString() ?? '',
        countStatus: json['countStatus'] as String?,
        description: json['description'] as String? ?? '',
        reference: json['reference'] as String? ?? '',
        instructions: json['instructions'] as String? ?? '',
        verified: json['verified'] == true,
        authenticityGrade: json['authenticityGrade'] as String? ?? '',
        alternateContent: json['alternateContent'] as String? ?? '',
        sourceIds: (json['sourceIds'] as List?)?.cast<String>() ?? const [],
        mergedSourceMetadata: json['mergedSourceMetadata'] as Map<String, dynamic>?,
        content: json['content'] as String? ?? '',
      );

  static String _fallbackId(String category, String content) {
    var hash = 0xcbf29ce484222325;
    for (final codeUnit in '$category|$content'.codeUnits) {
      hash = ((hash ^ codeUnit) * 0x100000001b3).toUnsigned(64);
    }
    return 'legacy_${hash.toRadixString(16)}';
  }

  final String id;
  final String category;
  final String subCategory;
  final String countText;
  final String? countStatus;
  final String description;
  final String reference;
  final String instructions;
  final bool verified;
  final String authenticityGrade;
  final String alternateContent;
  final List<String> sourceIds;
  final Map<String, dynamic>? mergedSourceMetadata;
  final String content;

  /// Returns the count stored in JSON, or null when it is absent/non-numeric.
  int? get repetitionCount => int.tryParse(countText.trim());
}
