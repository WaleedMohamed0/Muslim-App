import 'package:flutter/material.dart';
import 'package:muslim/core/assets/app_assets.dart';

class AppSplashScreen extends StatelessWidget {
  const AppSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? theme.scaffoldBackgroundColor : colors.primaryContainer,
      body: SafeArea(
        child: Stack(
          children: [
            PositionedDirectional(
              top: -112,
              end: -82,
              child: _OutlineCircle(
                size: 300,
                color: colors.primary.withValues(alpha: isDark ? .07 : .12),
              ),
            ),
            PositionedDirectional(
              bottom: -142,
              start: -95,
              child: _OutlineCircle(
                size: 330,
                color: colors.secondary.withValues(alpha: isDark ? .08 : .14),
              ),
            ),
            Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: .82, end: 1),
                duration: const Duration(milliseconds: 850),
                curve: Curves.easeOutBack,
                builder:
                    (context, scale, child) =>
                        Transform.scale(scale: scale, child: child),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 184,
                        height: 184,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? null : colors.surface,
                          gradient:
                              isDark
                                  ? LinearGradient(
                                    begin: AlignmentDirectional.topStart,
                                    end: AlignmentDirectional.bottomEnd,
                                    colors: [
                                      colors.primary.withValues(alpha: .16),
                                      colors.secondary.withValues(alpha: .12),
                                    ],
                                  )
                                  : null,
                          border: Border.all(
                            color: colors.primary.withValues(
                              alpha: isDark ? .14 : .28,
                            ),
                          ),
                        ),
                        child: Center(
                          child: Image.asset(
                            AppAssets.quranLogo,
                            width: 142,
                            height: 142,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'مُسْلِم',
                        textDirection: TextDirection.rtl,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'رفيقك اليومي للذكر والصلاة والطمأنينة',
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 36),
                      SizedBox(
                        width: 34,
                        height: 34,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutlineCircle extends StatelessWidget {
  const _OutlineCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.2),
      ),
    ),
  );
}
