import '../../domain/entities/allah_name.dart';

class LocalAllahNamesDataSource {
  const LocalAllahNamesDataSource(this._json);
  final Object? _json;

  List<AllahName> read() {
    final items = switch (_json) {
      final List<dynamic> list => list,
      final Map<String, dynamic> map when map['data'] is List => map['data'] as List<dynamic>,
      _ => throw const FormatException('Allah names data must be a JSON list or an object containing a data list.'),
    };

    return items.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Allah name entry must be a JSON object.');
      }
      final name = item['name'];
      final meaning = item['text'];
      if (name is! String || meaning is! String) {
        throw const FormatException('Allah name entries must contain string name and text fields.');
      }
      return AllahName(name: name, meaning: meaning);
    }).toList(growable: false);
  }
}
