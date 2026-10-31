import '../../domain/entities/hadeeth_entry.dart';

class HadeethState {
  const HadeethState({this.error, this.entries = const [], this.isLoading = false});
  final String? error;
  final List<HadeethEntry> entries;
  final bool isLoading;
}
