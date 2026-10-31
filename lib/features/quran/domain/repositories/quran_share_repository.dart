abstract interface class QuranShareRepository {
  Future<void> shareText({required String text, required String title});
}
