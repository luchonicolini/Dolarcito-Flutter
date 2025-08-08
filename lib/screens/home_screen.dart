// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/dolar_network_manager.dart';
import '../widgets/dolar_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DolarNetworkManager>(
      builder: (context, manager, child) {
        if (manager.isLoading && manager.dolarData.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (manager.error != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.sentiment_dissatisfied, 
                    color: Theme.of(context).colorScheme.error, 
                    size: 80
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '¡Ups! Algo salió mal.',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    manager.error!.errorDescription,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => manager.fetchData(forceRefresh: true),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      textStyle: const TextStyle(fontSize: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Usar dolarData directamente en lugar de filteredData
        final dataToShow = manager.dolarData.where((dolar) => dolar.hasValidRates).toList();

        if (dataToShow.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off, 
                    color: Theme.of(context).colorScheme.onSurfaceVariant, 
                    size: 80
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No se encontraron divisas.',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Intenta refrescar la lista.',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => manager.fetchData(forceRefresh: true),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sección de bienvenida
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cotizaciones en tiempo real',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Cotizaciones del dólar en Argentina',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1, thickness: 1),
                    const SizedBox(height: 8),
                    Text(
                      'Mantente al tanto de las cotizaciones del dólar y su evolución en tiempo real.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
              
              // Lista principal de divisas
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100), // Espacio para el tab bar
                  itemCount: dataToShow.length,
                  itemBuilder: (context, index) {
                    final dolar = dataToShow[index];
                    return DolarCard(
                      dolar: dolar,
                      onTap: () {
                        // Acción al tocar la tarjeta
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Tocaste ${dolar.nombre}'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

