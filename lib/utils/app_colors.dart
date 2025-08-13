import 'package:flutter/cupertino.dart';

// EXTENSIÓN PARA COLORES GLOBALES
extension AppColors on BuildContext {
  // Colores del gradiente que se adaptan al tema
  List<Color> get gradientColors {
    final isDark = CupertinoTheme.brightnessOf(this) == Brightness.dark;
    
    if (isDark) {
      return [
        const Color(0xFF2C2C2E), // Gris oscuro Apple
        const Color(0xFF3A3A3C), // Gris medio Apple  
        const Color(0xFF1C1C1E), // Negro Apple
      ];
    } else {
      return [
        const Color(0xFF007AFF), // Azul iOS
        const Color(0xFF5856D6), // Púrpura iOS
        const Color(0xFFAF52DE), // Rosa-púrpura iOS
      ];
    }
  }
  
  // Color de fondo adaptativo
  Color get adaptiveBackgroundColor {
    return CupertinoTheme.brightnessOf(this) == Brightness.dark
        ? const Color(0xFF1C1C1E)
        : const Color(0xFFFFFFFF);
  }
  
  // Color de texto adaptativo
  Color get adaptiveTextColor {
    return CupertinoTheme.brightnessOf(this) == Brightness.dark
        ? CupertinoColors.white
        : CupertinoColors.black;
  }
}