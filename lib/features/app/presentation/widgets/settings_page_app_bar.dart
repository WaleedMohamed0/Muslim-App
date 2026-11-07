import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim/core/widgets/app_widgets.dart';
import 'package:muslim/features/app/presentation/cubit/app_cubit.dart';
import 'package:muslim/features/app/presentation/cubit/app_state.dart';

class SettingsPageAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SettingsPageAppBar({
    super.key,
    required this.title,
    this.showThemeAction = true,
  });

  final String title;
  final bool showThemeAction;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final actions = showThemeAction
        ? <Widget>[
            BlocBuilder<AppCubit, AppState>(
              builder: (context, state) => IconButton(
                tooltip: state.themeMode == ThemeMode.dark
                    ? 'الوضع النهاري'
                    : 'الوضع الليلي',
                onPressed: context.read<AppCubit>().toggleThemeMode,
                icon: Icon(
                  state.themeMode == ThemeMode.dark
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                ),
              ),
            ),
          ]
        : null;
    return defaultAppBar(context: context, text: title, actions: actions);
  }
}
