import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../models/dolar_data_model.dart';

class DolarCard extends StatefulWidget {
  final DolarDataModel dolar;

  const DolarCard({
    super.key,
    required this.dolar,
  });

  @override
  State<DolarCard> createState() => _DolarCardState();
}

class _DolarCardState extends State<DolarCard> with TickerProviderStateMixin {
  bool _isExpanded = false;
  bool _isPressed = false; // Estado para el efecto de presionar
  late AnimationController _expandIconController;
  late AnimationController _clockRotationController; // Controlador para el reloj

  // --- Mapas de Configuración ---
  final Map<String, List<Color>> _gradientMap = {
    "oficial": [const Color(0xFF4ECDC4), const Color(0xFF44A08D)], // Turquesa a verde
    "blue": [const Color(0xFF667eea), const Color(0xFF764ba2)], // Azul a púrpura
    "bolsa": [const Color(0xFFf093fb), const Color(0xFFf5576c)], // Rosa a coral
    "mep": [const Color(0xFFf093fb), const Color(0xFFf5576c)], // Rosa a coral
    "ccl": [const Color(0xFF4facfe), const Color(0xFF00f2fe)], // Azul claro a cian
    "contadoconliqui": [const Color(0xFF4facfe), const Color(0xFF00f2fe)], // Azul claro a cian
    "cripto": [const Color(0xFF43e97b), const Color(0xFF38f9d7)], // Verde a turquesa
    "tarjeta": [const Color(0xFFfa709a), const Color(0xFFfee140)], // Rosa a amarillo
    "mayorista": [const Color(0xFFa8edea), const Color(0xFFfed6e3)], // Menta a rosa suave
  };

  final Map<String, CupertinoDynamicColor> _colorMap = {
    "oficial": CupertinoColors.systemTeal,
    "blue": CupertinoColors.systemBlue,
    "bolsa": CupertinoColors.systemOrange, "mep": CupertinoColors.systemOrange,
    "ccl": CupertinoColors.systemPurple, "contadoconliqui": CupertinoColors.systemPurple,
    "cripto": CupertinoColors.systemTeal,
    "tarjeta": CupertinoColors.systemIndigo,
    "mayorista": CupertinoColors.systemBrown,
  };

  final Map<String, String> _tipoDescripcion = {
    "oficial": "Tipo de cambio oficial del BCRA",
    "blue": "Mercado paralelo e informal",
    "bolsa": "Mercado electrónico de valores", "mep": "Mercado electrónico de valores",
    "ccl": "Contado con liquidación", "contadoconliqui": "Contado con liquidación",
    "cripto": "Operaciones con criptomonedas",
    "tarjeta": "Consumos con tarjeta en el exterior",
    "mayorista": "Mercado interbancario",
  };

  final Map<String, IconData> _headerIcons = {
    "oficial": CupertinoIcons.building_2_fill,
    "blue": CupertinoIcons.lock_fill,
    "bolsa": CupertinoIcons.chart_bar_square_fill, "mep": CupertinoIcons.chart_bar_square_fill,
    "ccl": CupertinoIcons.arrow_2_circlepath, "contadoconliqui": CupertinoIcons.arrow_2_circlepath,
    "cripto": CupertinoIcons.bitcoin_circle_fill,
    "tarjeta": CupertinoIcons.creditcard_fill,
    "mayorista": CupertinoIcons.building_2_fill,
  };

  final Map<IconData, Color> _iconColors = {
    CupertinoIcons.percent: const Color(0xFF4ECDC4),
    CupertinoIcons.chart_bar_alt_fill: const Color(0xFF667eea),
    CupertinoIcons.building_2_fill: const Color(0xFFf093fb),
    CupertinoIcons.calendar: const Color(0xFF43e97b),
  };

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es_AR', null);

    _expandIconController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _clockRotationController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat(); // Inicia la rotación continua
  }

  @override
  void dispose() {
    _expandIconController.dispose();
    _clockRotationController.dispose();
    super.dispose();
  }

  // --- Getters de Ayuda ---
  List<Color> get _cardGradientColors => _gradientMap[widget.dolar.casa.toLowerCase()] ?? [const Color(0xFF4ECDC4), const Color(0xFF44A08D)];
  CupertinoDynamicColor get _cardAccentColor => _colorMap[widget.dolar.casa.toLowerCase()] ?? CupertinoColors.systemTeal;
  String get _description => _tipoDescripcion[widget.dolar.casa.toLowerCase()] ?? "Cotización del dólar";
  IconData get _headerIcon => _headerIcons[widget.dolar.casa.toLowerCase()] ?? CupertinoIcons.money_dollar_circle_fill;

  void _onTap() {
    HapticFeedback.lightImpact();
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _expandIconController.forward();
      } else {
        _expandIconController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: _cardGradientColors[0].withValues(alpha: 0.3),
                blurRadius: _isPressed ? 8 : 15,
                spreadRadius: _isPressed ? 1 : 0,
                offset: Offset(0, _isPressed ? 4 : 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
              child: Container(
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBackground.resolveFrom(context).withValues(alpha: 0.7),
                  border: Border.all(color: CupertinoColors.systemGrey.resolveFrom(context).withValues(alpha: 0.2), width: 0.5),
                ),
                child: Column(
                  children: [
                    _buildHeader(context),
                    _buildMainContent(context),
                    _buildExpandedSection(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Widgets de Construcción ---

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _cardGradientColors,
          stops: const [0.0, 1.0],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [
          BoxShadow(
            color: _cardGradientColors[0].withValues(alpha: 0.4),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Dólar ${widget.dolar.nombre}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: CupertinoColors.white)),
                const SizedBox(height: 4),
                Text(_description, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: CupertinoColors.white.withValues(alpha: 0.9))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_headerIcon, size: 16, color: CupertinoColors.white.withValues(alpha: 0.9)),
                const SizedBox(width: 4),
                RotationTransition(
                  turns: Tween(begin: 0.0, end: 0.5).animate(_expandIconController),
                  child: const Icon(CupertinoIcons.chevron_down, size: 20, color: CupertinoColors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    final compra = widget.dolar.compra;
    final venta = widget.dolar.venta;
    double? spread;
    if (compra != null && venta != null && compra > 0) {
      spread = (venta - compra) / compra * 100;
    }
    final fechaActualizacion = DateTime.tryParse(widget.dolar.fechaActualizacion);

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(children: [_buildPriceView(label: "Compra", value: widget.dolar.compra), const VerticalDivider(color: CupertinoColors.systemGrey4, thickness: 1, width: 24), _buildPriceView(label: "Venta", value: widget.dolar.venta)])
          ),
          const SizedBox(height: 16),
          _buildMetadataSection(spread, fechaActualizacion),
        ],
      ),
    );
  }

  Widget _buildPriceView({required String label, required double? value}) {
    final textColor = CupertinoTheme.of(context).textTheme.textStyle.color;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textColor?.withValues(alpha: 0.7))),
          const SizedBox(height: 4),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(animation),
                  child: child,
                ),
              );
            },
            child: Text(
              _formatPrice(value),
              key: ValueKey<double?>(value),
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: value != null ? textColor : CupertinoColors.systemGrey),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMetadataSection(double? spread, DateTime? fecha) {
    final textColor = CupertinoTheme.of(context).textTheme.textStyle.color;
    return Row(
      children: [
        RotationTransition(
          turns: _clockRotationController,
          child: Icon(CupertinoIcons.clock_fill, size: 14, color: _getTimeStatusColor(fecha).resolveFrom(context)),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text("Actualizado ${_formatRelativeDate(fecha)}", style: TextStyle(fontSize: 13, color: textColor?.withValues(alpha: 0.7)))),
        if (spread != null) _buildSpreadChip(spread),
      ],
    );
  }
  
  Widget _buildSpreadChip(double spread) {
    final color = _getSpreadColor(spread);
    final resolvedColor = color.resolveFrom(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: resolvedColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(30), border: Border.all(color: resolvedColor.withValues(alpha: 0.3), width: 1)),
      child: Text("Spread ${spread.toStringAsFixed(1)}%", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: resolvedColor)),
    );
  }

  Widget _buildExpandedSection(BuildContext context) {
    final compra = widget.dolar.compra;
    final venta = widget.dolar.venta;
    double? spread;
    if (compra != null && venta != null && compra > 0) {
      spread = (venta - compra) / compra * 100;
    }
    final fechaActualizacion = DateTime.tryParse(widget.dolar.fechaActualizacion);

    return AnimatedSize(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
      child: _isExpanded 
        ? Column(
            children: [
              const Divider(height: 1, color: CupertinoColors.systemGrey4),
              AnimatedOpacity(
                opacity: _isExpanded ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeIn,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
                  child: Column(
                    children: [
                      if (spread != null) _buildDetailRow(icon: CupertinoIcons.percent, title: "Brecha", value: "${spread.toStringAsFixed(2)}%"),
                      if (compra != null && venta != null) _buildDetailRow(icon: CupertinoIcons.chart_bar_alt_fill, title: "Promedio", value: _formatPrice((compra + venta) / 2)),
                      _buildDetailRow(icon: CupertinoIcons.building_2_fill, title: "Casa de cambio", value: widget.dolar.casa),
                      _buildDetailRow(icon: CupertinoIcons.calendar, title: "Última actualización", value: _formatFullDate(fechaActualizacion)),
                    ],
                  ),
                ),
              ),
            ],
          )
        : const SizedBox.shrink(),
    );
  }

  Widget _buildDetailRow({required IconData icon, required String title, required String value}) {
    final textColor = CupertinoTheme.of(context).textTheme.textStyle.color;
    final iconColor = _iconColors[icon] ?? _cardGradientColors[0];
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: iconColor.withValues(alpha: 0.3), width: 1),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 14),
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
        ],
      ),
    );
  }

  // --- Funciones de Formateo y Lógica ---
  
  String _formatPrice(double? price) {
    if (price == null) return "N/A";
    final formatter = NumberFormat.decimalPattern('es_AR');
    formatter.minimumFractionDigits = 2;
    formatter.maximumFractionDigits = 2;
    return '\$ ${formatter.format(price)}';
  }

  String _formatRelativeDate(DateTime? fecha) {
    if (fecha == null) return "hace un tiempo";
    final now = DateTime.now();
    final difference = now.difference(fecha);
    if (difference.inSeconds < 5) return "ahora mismo";
    if (difference.inMinutes < 1) return "hace ${difference.inSeconds} s";
    if (difference.inHours < 1) return "hace ${difference.inMinutes} min";
    if (difference.inHours < 24) return "hace ${difference.inHours} h";
    if (difference.inDays < 2 && now.day == fecha.day + 1) return "ayer";
    return "hace ${difference.inDays} días";
  }

  String _formatFullDate(DateTime? fecha) {
    if (fecha == null) return "No disponible";
    final now = DateTime.now();
    if (fecha.year == now.year) return DateFormat('EEEE, d MMM, HH:mm', 'es_AR').format(fecha);
    return DateFormat('d MMM y, HH:mm', 'es_AR').format(fecha);
  }

  CupertinoDynamicColor _getTimeStatusColor(DateTime? fecha) {
    if (fecha == null) return CupertinoColors.systemGrey;
    final minutes = DateTime.now().difference(fecha).inMinutes;
    if (minutes < 5) return CupertinoColors.systemGreen;
    if (minutes < 60) return CupertinoColors.systemOrange;
    return CupertinoColors.systemRed;
  }

  CupertinoDynamicColor _getSpreadColor(double spread) {
    if (spread < 1.0) return CupertinoColors.systemGreen;
    if (spread < 2.0) return CupertinoColors.systemCyan;
    if (spread < 4.0) return CupertinoColors.systemOrange;
    return CupertinoColors.systemRed;
  }
}
