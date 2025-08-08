import 'package:intl/intl.dart';

class DolarDataModel {
  final String id;
  final double? compra;
  final double? venta;
  final String casa;
  final String nombre;
  final String moneda;
  final String fechaActualizacion;
  bool isFavorite;

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

  // Factory constructor para crear desde JSON
  factory DolarDataModel.fromJson(Map<String, dynamic> json) {
    final casa = json['casa'] as String;
    return DolarDataModel(
      id: casa, // Usar casa como ID único
      compra: json['compra']?.toDouble(),
      venta: json['venta']?.toDouble(),
      casa: casa,
      nombre: json['nombre'] as String,
      moneda: json['moneda'] as String,
      fechaActualizacion: json['fechaActualizacion'] as String,
      isFavorite: json['isFavorite'] ?? false,
    );
  }

  // Método para convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'compra': compra,
      'venta': venta,
      'casa': casa,
      'nombre': nombre,
      'moneda': moneda,
      'fechaActualizacion': fechaActualizacion,
      'isFavorite': isFavorite,
    };
  }

  // Constructor manual para casos específicos (como dólar tarjeta)
  DolarDataModel.manual({
    required this.id,
    this.compra,
    this.venta,
    required this.casa,
    required this.nombre,
    required this.moneda,
    required this.fechaActualizacion,
    this.isFavorite = false,
  });

  // Getter para fecha formateada
  String get formattedLastUpdate {
    try {
      final date = DateTime.parse(fechaActualizacion);
      final formatter = DateFormat('dd/MM/yyyy HH:mm', 'es_AR');
      return formatter.format(date);
    } catch (e) {
      return 'Fecha no disponible';
    }
  }

  // Getter para verificar si tiene tasas válidas
  bool get hasValidRates {
    return compra != null || venta != null;
  }

  // Getter para tasa promedio
  double? get averageRate {
    if (compra != null && venta != null) {
      return (compra! + venta!) / 2;
    }
    return compra ?? venta;
  }

  // Métodos para comparación y hash
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DolarDataModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // Método copyWith para inmutabilidad
  DolarDataModel copyWith({
    String? id,
    double? compra,
    double? venta,
    String? casa,
    String? nombre,
    String? moneda,
    String? fechaActualizacion,
    bool? isFavorite,
  }) {
    return DolarDataModel(
      id: id ?? this.id,
      compra: compra ?? this.compra,
      venta: venta ?? this.venta,
      casa: casa ?? this.casa,
      nombre: nombre ?? this.nombre,
      moneda: moneda ?? this.moneda,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  @override
  String toString() {
    return 'DolarDataModel(id: $id, casa: $casa, nombre: $nombre, compra: $compra, venta: $venta, isFavorite: $isFavorite)';
  }
}

extension DoubleExtension on double {
  String toFormattedDecimalString({int maximumFractionDigits = 0}) {
    final formatter = NumberFormat.decimalPattern('es_AR');
    formatter.maximumFractionDigits = maximumFractionDigits;
    formatter.minimumFractionDigits = 0;
    return formatter.format(this);
  }
}