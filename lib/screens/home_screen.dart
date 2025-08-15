import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../models/dolar_network_manager.dart';
import '../widgets/card_home.dart';
import 'package:flutter/material.dart'; 
import '../utils/app_colors.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _floatingController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<DolarNetworkManager>().fetchData();
      }
    });

    _entryController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _floatingController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeInOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));

    _entryController.forward();
  }


  @override
  void dispose() {
    _entryController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: context.gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          bottom: false, // El safe area inferior puede no ser necesario si tienes una TabBar
          child: CustomScrollView(
            slivers: [
              CupertinoSliverRefreshControl(
                onRefresh: () => context.read<DolarNetworkManager>().fetchData(forceRefresh: true),
              ),
              
              SliverToBoxAdapter(
                child: _buildHeroSection(),
              ),
              
              SliverToBoxAdapter(
                child: _buildFeaturesSection(),
              ),
              
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: _buildFilterSelector(),
                ),
              ),
              
              // ===> CAMBIO: Título actualizado <===
              SliverToBoxAdapter(
                child: _buildSectionTitle("Tipos de Cambio"),
              ),
              
              _DolarSliverList(),

              // Espacio extra al final para que la última tarjeta no quede pegada abajo
              const SliverToBoxAdapter(
                child: SizedBox(height: 40),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Stack(
      children: [
        ..._buildFloatingElements(),
        Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0), // Padding inferior a 0
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Dolarcito",
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w800,
                          color: CupertinoColors.white,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Cotizaciones del dólar\nen tiempo real",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: CupertinoColors.white.withValues(alpha: 0.8),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // ===> CAMBIO: Indicadores reemplazados por Divider <===
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Divider(
                  color: CupertinoColors.white.withValues(alpha: 0.25),
                  thickness: 1,
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildFloatingElements() {
    return [
      AnimatedBuilder(
        animation: _floatingController,
        builder: (context, child) {
          return Positioned(
            top: 40 + (_floatingController.value * 20),
            right: 30,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: CupertinoColors.white.withValues(alpha: 0.1),
                boxShadow: [
                  BoxShadow(
                    color: CupertinoColors.white.withValues(alpha: 0.1),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
            ),
          );
        },
      ),
      AnimatedBuilder(
        animation: _floatingController,
        builder: (context, child) {
          return Positioned(
            top: 150 - (_floatingController.value * 15),
            left: 20,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: CupertinoColors.white.withValues(alpha: 0.08),
              ),
            ),
          );
        },
      ),
    ];
  }

  Widget _buildFeaturesSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: _buildFeatureCard(
            icon: CupertinoIcons.info_circle_fill,
            title: "Información Completa",
            description: "Spreads, promedios y fechas de actualización detalladas",
            colors: [const Color(0xFFF57C00), const Color(0xFFE65100)],
            isWide: true,
          ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required List<Color> colors,
    bool isWide = false,
  }) {
    return Container(
      height: isWide ? 80 : 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors.map((c) => c.withValues(alpha: 0.8)).toList(),
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors[0].withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: isWide
          ? Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: CupertinoColors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: CupertinoColors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: CupertinoColors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 12,
                          color: CupertinoColors.white.withValues(alpha: 0.9),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: CupertinoColors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, color: CupertinoColors.white, size: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: CupertinoColors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11,
                    color: CupertinoColors.white.withValues(alpha: 0.9),
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: CupertinoColors.white,
        ),
      ),
    );
  }

  Widget _buildFilterSelector() {
    return Consumer<DolarNetworkManager>(
      builder: (context, manager, child) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              _buildFilterButton(
                context, 
                manager, 
                DolarFilter.all, 
                "Todos", 
                CupertinoIcons.list_bullet
              ),
              const SizedBox(width: 8),
              _buildFilterButton(
                context, 
                manager, 
                DolarFilter.official, 
                "Oficial", 
                CupertinoIcons.building_2_fill
              ),
              const SizedBox(width: 8),
              _buildFilterButton(
                context, 
                manager, 
                DolarFilter.blue, 
                "Blue", 
                CupertinoIcons.eye_solid
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterButton(
    BuildContext context,
    DolarNetworkManager manager,
    DolarFilter filter,
    String text,
    IconData icon,
  ) {
    final bool isSelected = manager.currentFilter == filter;

    return GestureDetector(
      onTap: () => manager.setFilter(filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected 
              ? CupertinoColors.systemBlue 
              : CupertinoColors.darkBackgroundGray.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon, 
              size: 16,
              color: CupertinoColors.white,
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DolarSliverList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<DolarNetworkManager>(
      builder: (context, manager, child) {
        if (manager.isLoading && manager.filteredData.isEmpty) {
          return const SliverToBoxAdapter(
            child: SizedBox(
              height: 200,
              child: Center(
                child: CupertinoActivityIndicator(
                  radius: 18,
                  color: CupertinoColors.white,
                ),
              ),
            ),
          );
        }

        if (manager.error != null && manager.filteredData.isEmpty) {
          return SliverToBoxAdapter(
            child: _ErrorView(
              message: manager.error!.errorDescription,
              onRetry: () => manager.fetchData(forceRefresh: true),
            ),
          );
        }

        if (manager.filteredData.isEmpty) {
          return const SliverToBoxAdapter(
            child: SizedBox(
              height: 200,
              child: Center(
                child: Text(
                  'No hay cotizaciones para mostrar.',
                  style: TextStyle(color: CupertinoColors.white),
                ),
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final dolar = manager.filteredData[index];
              return DolarCard(dolar: dolar);
            },
            childCount: manager.filteredData.length,
          ),
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
    return Container(
      height: 300,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CupertinoColors.systemRed.withOpacity(0.2),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                CupertinoIcons.exclamationmark_triangle,
                size: 48,
                color: CupertinoColors.systemRed,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Error de conexión',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: CupertinoColors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: CupertinoColors.white.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CupertinoButton(
              onPressed: onRetry,
              color: CupertinoColors.systemRed,
              borderRadius: BorderRadius.circular(25),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

