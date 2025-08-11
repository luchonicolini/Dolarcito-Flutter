// screens/main_tab_view.dart

import 'package:flutter/cupertino.dart';
import 'package:dolarcito/widgets/custom_tab_bar.dart'; // Importa tu widget
import 'home_screen.dart';
import 'converter_screen.dart';

class MainTabView extends StatefulWidget {
  const MainTabView({super.key});

  @override
  State<MainTabView> createState() => _MainTabViewState();
}

class _MainTabViewState extends State<MainTabView> {
  int _currentIndex = 0; // Estado que guarda la pestaña actual

  // Lista de las pantallas que se mostrarán
  final List<Widget> _screens = [
    const HomeScreen(),
    const ConverterScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Usamos un Stack para poder superponer la barra de navegación
    // sobre las pantallas, logrando el efecto "flotante".
    return Stack(
      children: [
        // La pantalla activa ocupa todo el fondo
        _screens[_currentIndex],

        // La barra de navegación se alinea en la parte inferior
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: CustomAnimatedTabBar( // Usamos tu widget personalizado
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
        ),
      ],
    );
  }
}