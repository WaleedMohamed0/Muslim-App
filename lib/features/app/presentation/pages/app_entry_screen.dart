import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim/features/app/data/data_sources/onboarding_preferences.dart';
import 'package:muslim/features/app/presentation/cubit/app_entry_cubit.dart';
import 'package:muslim/features/app/presentation/pages/app_entry_navigation.dart';
import 'package:muslim/features/app/presentation/pages/onboarding_screen.dart';
import 'package:muslim/features/app/presentation/widgets/app_splash_screen.dart';

class AppEntryScreen extends StatelessWidget {
  const AppEntryScreen({
    super.key,
    this.homeBuilder,
    this.initialDestination,
    this.initialDestinationRouteName,
    this.onboardingPreferences = const OnboardingPreferences(),
  });

  final WidgetBuilder? homeBuilder;
  final Widget? initialDestination;
  final String? initialDestinationRouteName;
  final OnboardingPreferences onboardingPreferences;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) {
      final cubit = AppEntryCubit(
        onboardingPreferences: onboardingPreferences,
        hasInitialDestination: initialDestination != null,
      );
      unawaited(cubit.start());
      return cubit;
    },
    child: BlocConsumer<AppEntryCubit, AppEntryStatus>(
      listener: (context, status) {
        switch (status) {
          case AppEntryStatus.openHome:
            AppEntryNavigation.openHome(context, homeBuilder: homeBuilder);
            break;
          case AppEntryStatus.openDestination:
            AppEntryNavigation.openDestination(
              context,
              destination: initialDestination!,
              routeName: initialDestinationRouteName,
            );
            break;
          case AppEntryStatus.loading:
          case AppEntryStatus.onboarding:
            break;
        }
      },
      builder:
          (context, status) => switch (status) {
            AppEntryStatus.onboarding => OnboardingScreen(
              onComplete: context.read<AppEntryCubit>().completeOnboarding,
            ),
            AppEntryStatus.loading ||
            AppEntryStatus.openHome ||
            AppEntryStatus.openDestination => const AppSplashScreen(),
          },
    ),
  );
}
