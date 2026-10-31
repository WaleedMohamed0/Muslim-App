import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:untitled8/core/assets/app_assets.dart';
import 'package:untitled8/features/quran/presentation/cubit/quran_cubit.dart';

class ElAzanScreen extends StatelessWidget {
  const ElAzanScreen({super.key, required this.prayer});
  final String prayer;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(AppAssets.adhanBackground, fit: BoxFit.cover),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withValues(alpha: .2), Colors.black.withValues(alpha: .78)],
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Align(
                    alignment: AlignmentDirectional.topEnd,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: IconButton.filledTonal(
                        onPressed: () {
                          context.read<QuranCubit>().stopAzan();
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.nights_stay_rounded, color: Colors.white, size: 42),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Text('حان الآن موعد آذان $prayer', textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w800, height: 1.45)),
                  ),
                  const SizedBox(height: 12),
                  const Text('حيّ على الصلاة', style: TextStyle(color: Colors.white70, fontSize: 18)),
                  const Spacer(flex: 2),
                ],
              ),
            ),
          ],
        ),
      );
}
