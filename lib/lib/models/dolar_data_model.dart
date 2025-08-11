import 'package:intl/intl.dart';

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

  /// Conversión segura de dynamic a double
  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value.replaceAll(",", "."));
    return null;
  }

  /// Factory constructor desde JSON
  factory DolarDataModel.fromJson(Map<String, dynamic> json) {
    final casa = (json['casa'] ?? '').toString();
    final moneda = (json['moneda'] ?? '').toString();

    return DolarDataModel(
      id: '${casa}_$moneda'.toLowerCase(), // ID más único
      compra: _toDouble(json['compra']),
      venta: _toDouble(json['venta']),
      casa: casa,
      nombre: (json['nombre'] ?? '').toString(),
      moneda: moneda,
      fechaActualizacion: (json['fechaActualizacion'] ?? '').toString(),
      isFavorite: json['isFavorite'] == true,
    );
  }

  /// Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'compra': compra,
      'venta': venta,
      'casa': casa,
      'nombre': nombre,
      'moneda': moneda,
      'fechaActualizacion': fechaActualizacion,
      'isFavorite': isFavorite,
    };
  }

  /// Formatear fecha de manera flexible
  String get formattedLastUpdate {
    try {
      final date = DateTime.tryParse(fechaActualizacion);
      if (date == null) return 'Fecha no disponible';
      return DateFormat('dd/MM/yyyy HH:mm', 'es_AR').format(date);
    } catch (_) {
      return 'Fecha no disponible';
    }
  }

  /// Tiene tasas válidas
  bool get hasValidRates => compra != null || venta != null;

  /// Tasa promedio
  double? get averageRate {
    if (compra != null && venta != null) {
      return (compra! + venta!) / 2;
    }
    return compra ?? venta;
  }

  /// Actualizar parcialmente desde JSON
  DolarDataModel updateFromJson(Map<String, dynamic> json) {
    return copyWith(
      compra: _toDouble(json['compra']) ?? compra,
      venta: _toDouble(json['venta']) ?? venta,
      fechaActualizacion: (json['fechaActualizacion'] ?? fechaActualizacion).toString(),
      isFavorite: json['isFavorite'] ?? isFavorite,
    );
  }

  /// copyWith
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
  bool operator ==(Object other) => identical(this, other) || (other is DolarDataModel && other.id == id);

  @override
  int get hashCode => id.hashCode;

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
