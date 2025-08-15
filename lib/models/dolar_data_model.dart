import 'package:intl/intl.dart';

// --- NUEVO: La extensión que traduce tu código de Swift ---
// Añade el método .toFormattedCurrencyString() a cualquier variable de tipo double.
extension DoubleExtension on double {
  String toFormattedCurrencyString({int decimalDigits = 2}) {
    // NumberFormat de intl hace todo el trabajo de los separadores automáticamente
    // al indicarle el 'locale' (la región).
    final formatter = NumberFormat.decimalPatternDigits(
      locale: 'es_AR', // Esto asegura el formato 1.234,56
      decimalDigits: decimalDigits,
    );
    return formatter.format(this);
  }
}

class DolarDataModel {
  final String id;
  final double? compra;
  final double? venta;
  final String casa;
  final String nombre;
  final String moneda;
  final String fechaActualizacion;
  final bool isFavorite;

  DolarDataModel({
    required this.id,
    this.compra,
    this.venta,
    required this.casa,
    required this.nombre,
    required this.moneda,
    required this.fechaActualizacion,
    this.isFavorite = false,
  });

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value.replaceAll(",", "."));
    return null;
  }

  factory DolarDataModel.fromJson(Map<String, dynamic> json) {
    final casa = (json['casa'] ?? '').toString();
    final moneda = (json['moneda'] ?? '').toString();

    return DolarDataModel(
      id: '${casa}_$moneda'.toLowerCase(),
      compra: _toDouble(json['compra']),
      venta: _toDouble(json['venta']),
      casa: casa,
      nombre: (json['nombre'] ?? '').toString(),
      moneda: moneda,
      fechaActualizacion: (json['fechaActualizacion'] ?? '').toString(),
      isFavorite: json['isFavorite'] == true,
    );
  }
  
  // --- ACTUALIZADO: El formateador de fecha ahora incluye segundos, como en tu código Swift ---
  String get formattedLastUpdate {
    try {
      final date = DateTime.tryParse(fechaActualizacion);
      if (date == null) return 'Fecha no disponible';
      // Añadimos :ss para incluir los segundos
      return DateFormat('dd/MM/yyyy HH:mm:ss', 'es_AR').format(date);
    } catch (_) {
      return 'Fecha no disponible';
    }
  }

  // (El resto de la clase no necesita cambios)
  Map<String, dynamic> toJson() => { 'id': id, 'compra': compra, 'venta': venta, 'casa': casa, 'nombre': nombre, 'moneda': moneda, 'fechaActualizacion': fechaActualizacion, 'isFavorite': isFavorite };
  bool get hasValidRates => compra != null || venta != null;
  double? get averageRate { if (compra != null && venta != null) { return (compra! + venta!) / 2; } return compra ?? venta; }
  DolarDataModel copyWith({ String? id, double? compra, double? venta, String? casa, String? nombre, String? moneda, String? fechaActualizacion, bool? isFavorite }) => DolarDataModel( id: id ?? this.id, compra: compra ?? this.compra, venta: venta ?? this.venta, casa: casa ?? this.casa, nombre: nombre ?? this.nombre, moneda: moneda ?? this.moneda, fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion, isFavorite: isFavorite ?? this.isFavorite );
  @override bool operator ==(Object other) => identical(this, other) || (other is DolarDataModel && other.id == id);
  @override int get hashCode => id.hashCode;
  @override String toString() => 'DolarDataModel(id: $id, casa: $casa, nombre: $nombre, compra: $compra, venta: $venta, isFavorite: $isFavorite)';
}
