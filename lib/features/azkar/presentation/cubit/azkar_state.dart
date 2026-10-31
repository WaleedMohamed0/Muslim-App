class AzkarState {
  const AzkarState({this.counters = const [], this.revision = 0, this.isLoading = false, this.error});
  final List<int> counters;
  final int revision;
  final bool isLoading;
  final String? error;
}
