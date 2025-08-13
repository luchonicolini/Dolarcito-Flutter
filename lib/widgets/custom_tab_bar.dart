import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

// 1. Un pequeño modelo para definir cada pestaña de forma ordenada.
class _TabItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final CupertinoDynamicColor color;

  const _TabItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.color,
  });
}

class CustomAnimatedTabBar extends StatelessWidget {
  // 2. Nombres de parámetros más estándar (currentIndex y onTap).
  final int currentIndex;
  final ValueChanged<int> onTap;

  CustomAnimatedTabBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  // 3. Lista de pestañas. Ahora es súper fácil añadir o quitar elementos.
  final List<_TabItem> _tabs = [
    const _TabItem(
      icon: CupertinoIcons.house,
      selectedIcon: CupertinoIcons.house_fill,
      label: "Inicio",
      color: CupertinoColors.activeBlue,
    ),
    const _TabItem(
      icon: CupertinoIcons.arrow_2_squarepath,
      selectedIcon: CupertinoIcons.arrow_2_squarepath,
      label: "Conversión",
      color: CupertinoColors.systemGreen,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20), // Ajustado para SafeArea
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6.resolveFrom(context).withOpacity(0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: CupertinoColors.systemGrey4.resolveFrom(context).withOpacity(0.4),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              // 4. Iteramos sobre la lista de pestañas en lugar de usar List.generate.
              children: _tabs.asMap().entries.map((entry) {
                final index = entry.key;
                final tab = entry.value;
                final isSelected = currentIndex == index;
                return _buildTabItem(context, tab, isSelected, index);
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  // 5. Widget de ayuda para construir cada pestaña, haciendo el código más limpio.
  Widget _buildTabItem(BuildContext context, _TabItem tab, bool isSelected, int index) {
    final resolvedColor = CupertinoDynamicColor.resolve(tab.color, context);
    final inactiveColor = CupertinoColors.inactiveGray.resolveFrom(context);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.lightImpact();
          onTap(index);
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  width: isSelected ? 50 : 0,
                  height: isSelected ? 50 : 0,
                  decoration: BoxDecoration(
                    // 6. ADVERTENCIA CORREGIDA: Usando el patrón correcto.
               color: resolvedColor.withValues(alpha: 0.2), 
                    shape: BoxShape.circle,
                  ),
                ),
                Icon(
                  isSelected ? tab.selectedIcon : tab.icon,
                  size: 22,
                  color: isSelected ? resolvedColor : inactiveColor,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              tab.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isSelected ? resolvedColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

