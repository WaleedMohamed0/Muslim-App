import '../../domain/entities/allah_name.dart';

class AllahNamesState {
  const AllahNamesState({this.names = const [], this.error, this.isLoading = false});
  final List<AllahName> names;
  final String? error;
  final bool isLoading;
}
