import 'package:shared_preferences/shared_preferences.dart';

class OnboardingPreferences {
  const OnboardingPreferences();

  static const _completedKey = 'intro_onboarding_completed_v1';

  Future<bool> hasCompletedOnboarding() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      return preferences.getBool(_completedKey) ?? false;
    } catch (_) {
      // Keep the app usable if local preferences are temporarily unavailable.
      return true;
    }
  }

  Future<void> markOnboardingCompleted() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(_completedKey, true);
    } catch (_) {
      // Continue into the app even if saving the flag fails.
    }
  }
}
