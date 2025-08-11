import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../models/dolar_network_manager.dart';
import '../widgets/card_home.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Cotización Dólar'),
        backgroundColor: CupertinoColors.systemBackground,
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            CupertinoSliverRefreshControl(
              onRefresh: () => context.read<DolarNetworkManager>().fetchData(forceRefresh: true),
            ),
            SliverFillRemaining(
              child: _DolarListView(),
            ),
          ],
        ),
      ),
    );
  }
}

class _DolarListView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<DolarNetworkManager>(
      builder: (context, manager, child) {
        if (manager.isLoading && manager.filteredData.isEmpty) {
          return const Center(child: CupertinoActivityIndicator(radius: 20));
        }

        if (manager.error != null && manager.filteredData.isEmpty) {
          return _ErrorView(
            message: manager.error!.errorDescription,
            onRetry: () => manager.fetchData(forceRefresh: true),
          );
        }

        if (manager.filteredData.isEmpty) {
          return const Center(
            child: Text(
              'No hay datos disponibles',
              style: TextStyle(fontSize: 18, color: CupertinoColors.systemGrey),
            ),
          );
        }

        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: manager.filteredData.length,
          itemBuilder: (context, index) {
            final dolar = manager.filteredData[index];
            return DolarCard(
              dolar: dolar,
             // onFavoriteToggle: () => manager.toggleFavorite(dolar.id),
            );
          },
        );
      },
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(CupertinoIcons.exclamationmark_triangle,
              size: 48, color: CupertinoColors.systemRed),
          const SizedBox(height: 16),
          Text(
            'Error: $message',
            style: const TextStyle(fontSize: 16, color: CupertinoColors.systemRed),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          CupertinoButton.filled(
            onPressed: onRetry,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
