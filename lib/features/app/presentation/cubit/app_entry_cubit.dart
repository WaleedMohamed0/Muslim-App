import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim/features/app/data/data_sources/onboarding_preferences.dart';

enum AppEntryStatus { loading, onboarding, openHome, openDestination }

class AppEntryCubit extends Cubit<AppEntryStatus> {
  AppEntryCubit({
    required OnboardingPreferences onboardingPreferences,
    required bool hasInitialDestination,
  }) : _onboardingPreferences = onboardingPreferences,
       _hasInitialDestination = hasInitialDestination,
       super(AppEntryStatus.loading);

  static const _minimumSplashDuration = Duration(milliseconds: 700);

  final OnboardingPreferences _onboardingPreferences;
  final bool _hasInitialDestination;

  Future<void> start() async {
    final minimumSplashDuration = Future<void>.delayed(
      _minimumSplashDuration,
    );
    final onboardingCompleted = _onboardingPreferences
        .hasCompletedOnboarding();
    await Future.wait([minimumSplashDuration, onboardingCompleted]);
    if (isClosed) return;

    if (_hasInitialDestination) {
      emit(AppEntryStatus.openDestination);
    } else if (await onboardingCompleted) {
      emit(AppEntryStatus.openHome);
    } else {
      emit(AppEntryStatus.onboarding);
    }
  }

  Future<void> completeOnboarding() async {
    await _onboardingPreferences.markOnboardingCompleted();
    if (!isClosed) emit(AppEntryStatus.openHome);
  }
}
