class LocalAzkarDataSource {
  LocalAzkarDataSource(this._categories);
  final Map<String, dynamic> _categories;

  List<String> readCategory(String name) => ((_categories[name] ?? []) as List)
      .map((item) => item['content'] as String)
      .toList(growable: false);
}
