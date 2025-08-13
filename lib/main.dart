import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart'; // Necesario para SystemChrome
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart'; // Importa la librería de localización
import 'models/dolar_network_manager.dart';
import 'screens/main_tab_view.dart';

// Es buena práctica hacer que la función main sea asíncrona para poder
// esperar a que las inicializaciones se completen.
Future<void> main() async {
  // Asegura que los bindings de Flutter estén inicializados antes de correr la app.
  // Es necesario cuando se llama a código nativo antes de runApp.
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Inicializa la localización de fechas para español (Argentina) aquí.
  // Esto asegura que el formato de fechas esté disponible en toda la app
  // desde el principio y evita tener que llamarlo en cada widget.
  await initializeDateFormatting('es_AR', null);

  // 2. (Opcional) Fija la orientación de la app a vertical.
  // Es muy común en apps de iOS para mantener una UI consistente.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DolarNetworkManager()..fetchData(),
      child: const CupertinoApp(
        debugShowCheckedModeBanner: false,
        title: 'Dolarcito',
        // Tema que se adapta automáticamente al sistema
        theme: CupertinoThemeData(
          primaryColor: CupertinoColors.systemBlue,
          scaffoldBackgroundColor: CupertinoColors.systemBackground,
          barBackgroundColor: CupertinoColors.systemBackground,
          textTheme: CupertinoTextThemeData(
            primaryColor: CupertinoColors.label,
            textStyle: TextStyle(
              color: CupertinoColors.label,
            ),
          ),
        ),
        home: MainTabView(),
      ),
    );
  }
}

