import 'package:shared_preferences/shared_preferences.dart';

class OnboardingPreferences {
  const OnboardingPreferences();

  static const _completedKey = 'intro_onboarding_completed_v1';
  static const _widgetIntroEligibleKey = 'quran_widget_intro_eligible_v1';

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
      // Only installations completing this onboarding are eligible for the
      // first-run widget introduction. This keeps upgrades from surprising
      // existing users who completed onboarding in an older app version.
      await preferences.setBool(_widgetIntroEligibleKey, true);
    } catch (_) {
      // Continue into the app even if saving the flag fails.
    }
  }

  Future<bool> isWidgetIntroEligible() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      return preferences.getBool(_widgetIntroEligibleKey) ?? false;
    } catch (_) {
      return false;
    }
  }
}
