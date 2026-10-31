import '../../domain/entities/allah_name.dart';

class LocalAllahNamesDataSource {
  LocalAllahNamesDataSource(this._json);
  final Map<String, dynamic> _json;

  List<AllahName> read() => ((_json['data'] ?? []) as List)
      .map((item) => AllahName(name: item['name'] as String, meaning: item['text'] as String))
      .toList(growable: false);
}
