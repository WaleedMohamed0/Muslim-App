import 'package:material_ui/material_ui.dart';
import 'package:muslim/core/theme/app_theme.dart';

class AppBottomNavigationBar extends StatelessWidget {
  const AppBottomNavigationBar({super.key, required this.currentIndex, required this.onDestinationSelected});

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  static const _destinations = [
    (label: 'الرئيسية', icon: Icons.home_outlined, selected: Icons.home_rounded),
    (label: 'القرآن', icon: Icons.menu_book_outlined, selected: Icons.menu_book_rounded),
    (label: 'الأذكار', icon: Icons.favorite_border_rounded, selected: Icons.favorite_rounded),
    (label: 'الصلاة', icon: Icons.access_time_rounded, selected: Icons.access_time_filled_rounded),
    (label: 'المزيد', icon: Icons.grid_view_rounded, selected: Icons.grid_view_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppRadii.card),
          border: Border.all(color: scheme.outlineVariant.withValues(alpha: .55)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: theme.brightness == Brightness.dark ? .22 : .08), blurRadius: 20, offset: const Offset(0, 6))],
        ),
        child: Row(
          children: [
            for (var index = 0; index < _destinations.length; index++)
              Expanded(child: _DestinationButton(destination: _destinations[index], selected: currentIndex == index, onTap: () => onDestinationSelected(index))),
          ],
        ),
      ),
    );
  }
}

class _DestinationButton extends StatelessWidget {
  const _DestinationButton({required this.destination, required this.selected, required this.onTap});
  final ({String label, IconData icon, IconData selected}) destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = selected ? scheme.primary : scheme.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 7),
          decoration: BoxDecoration(color: selected ? scheme.primaryContainer.withValues(alpha: .72) : Colors.transparent, borderRadius: BorderRadius.circular(AppRadii.tile)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            AnimatedSwitcher(duration: const Duration(milliseconds: 180), child: Icon(selected ? destination.selected : destination.icon, key: ValueKey(selected), color: color, size: 22)),
            const SizedBox(height: 3),
            Text(destination.label, maxLines: 1, overflow: TextOverflow.clip, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, fontSize: 10)),
          ]),
        ),
      ),
    );
  }
}
