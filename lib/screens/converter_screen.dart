// lib/screens/converter_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/dolar_data_model.dart';
import '../models/dolar_network_manager.dart';

class ConverterScreen extends StatefulWidget {
  const ConverterScreen({super.key});

  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen> {
  final TextEditingController _amountController = TextEditingController();
  String? _fromCurrencyId;
  String? _toCurrencyId;
  double _convertedAmount = 0.0;
  String _conversionError = '';

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_convertCurrency);
  }

  @override
  void dispose() {
    _amountController.removeListener(_convertCurrency);
    _amountController.dispose();
    super.dispose();
  }

  // Función para realizar la conversión de divisas
  void _convertCurrency() {
    setState(() {
      _conversionError = ''; // Limpiar errores previos
      final manager = context.read<DolarNetworkManager>();
      final amount = double.tryParse(_amountController.text);

      if (amount == null || amount <= 0) {
        _convertedAmount = 0.0;
        return;
      }
      if (_fromCurrencyId == null || _toCurrencyId == null) {
        _convertedAmount = 0.0;
        return;
      }

      // Obtener los modelos de divisa completos
      final fromDolar = manager.dolarData.firstWhere(
        (d) => d.id == _fromCurrencyId,
        orElse: () => DolarDataModel.manual(id: 'ARS', nombre: 'Peso Argentino', moneda: 'ARS', casa: 'local', fechaActualizacion: DateTime.now().toIso8601String()),
      );
      final toDolar = manager.dolarData.firstWhere(
        (d) => d.id == _toCurrencyId,
        orElse: () => DolarDataModel.manual(id: 'ARS', nombre: 'Peso Argentino', moneda: 'ARS', casa: 'local', fechaActualizacion: DateTime.now().toIso8601String()),
      );

      // Manejar el caso del Peso Argentino (ARS)
      final isFromARS = fromDolar.id == 'ARS';
      final isToARS = toDolar.id == 'ARS';

      double? rate;

      if (isFromARS && !isToARS) {
        // Convertir ARS a USD (cualquier tipo de dólar)
        // Usamos el precio de venta del dólar al que queremos convertir (lo "compramos" con pesos)
        rate = toDolar.venta;
        if (rate == null || rate == 0) {
          _conversionError = 'Tasa de venta no disponible para ${toDolar.nombre}';
          _convertedAmount = 0.0;
          return;
        }
        _convertedAmount = amount / rate;
      } else if (!isFromARS && isToARS) {
        // Convertir USD (cualquier tipo de dólar) a ARS
        // Usamos el precio de compra del dólar que tenemos (lo "vendemos" por pesos)
        rate = fromDolar.compra;
        if (rate == null || rate == 0) {
          _conversionError = 'Tasa de compra no disponible para ${fromDolar.nombre}';
          _convertedAmount = 0.0;
          return;
        }
        _convertedAmount = amount * rate;
      } else if (!isFromARS && !isToARS) {
        // Convertir entre diferentes tipos de USD (ej. Blue a Oficial)
        // Primero a ARS, luego de ARS al otro USD
        final fromRate = fromDolar.compra; // Convertir el "desde" USD a ARS
        final toRate = toDolar.venta;     // Convertir ARS al "hacia" USD

        if (fromRate == null || fromRate == 0) {
          _conversionError = 'Tasa de compra no disponible para ${fromDolar.nombre}';
          _convertedAmount = 0.0;
          return;
        }
        if (toRate == null || toRate == 0) {
          _conversionError = 'Tasa de venta no disponible para ${toDolar.nombre}';
          _convertedAmount = 0.0;
          return;
        }
        _convertedAmount = (amount * fromRate) / toRate;
      } else {
        // ARS a ARS (sin conversión)
        _convertedAmount = amount;
      }
    });
  }

  // Obtener la lista de divisas disponibles para los dropdowns
  List<DolarDataModel> _getAvailableCurrencies(List<DolarDataModel> dolarData) {
    // Incluimos el Peso Argentino manualmente
    final List<DolarDataModel> currencies = [
      DolarDataModel.manual(id: 'ARS', nombre: 'Peso Argentino', moneda: 'ARS', casa: 'local', fechaActualizacion: DateTime.now().toIso8601String()),
    ];
    // Añadimos los dólares disponibles, filtrando los que no tienen tasas válidas si es necesario
    currencies.addAll(dolarData.where((dolar) => dolar.hasValidRates || dolar.id == 'tarjeta'));
    return currencies;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DolarNetworkManager>(
      builder: (context, manager, child) {
        final availableCurrencies = _getAvailableCurrencies(manager.dolarData);

        // Si no hay datos, mostrar un mensaje
        if (manager.isLoading && manager.dolarData.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (manager.error != null) {
          return Center(
            child: Text('Error al cargar divisas: ${manager.error!.errorDescription}'),
          );
        }
        if (availableCurrencies.isEmpty) {
          return const Center(child: Text('No hay divisas disponibles para conversión.'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Conversor de Divisas',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Campo de entrada de cantidad
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Cantidad',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.attach_money),
                ),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              // Selector de divisa "Desde"
              _buildCurrencyDropdown(
                context,
                'Desde',
                _fromCurrencyId,
                availableCurrencies,
                (String? newValue) {
                  setState(() {
                    _fromCurrencyId = newValue;
                    _convertCurrency();
                  });
                },
              ),
              const SizedBox(height: 16),
              // Botón para intercambiar divisas
              Center(
                child: IconButton(
                  icon: const Icon(Icons.swap_vert, size: 36),
                  onPressed: () {
                    setState(() {
                      final temp = _fromCurrencyId;
                      _fromCurrencyId = _toCurrencyId;
                      _toCurrencyId = temp;
                      _convertCurrency();
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Selector de divisa "Hacia"
              _buildCurrencyDropdown(
                context,
                'Hacia',
                _toCurrencyId,
                availableCurrencies,
                (String? newValue) {
                  setState(() {
                    _toCurrencyId = newValue;
                    _convertCurrency();
                  });
                },
              ),
              const SizedBox(height: 32),
              // Resultado de la conversión
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resultado:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                    ),
                    const SizedBox(height: 8),
                    if (_conversionError.isNotEmpty)
                      Text(
                        _conversionError,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.error),
                      )
                    else
                      Text(
                        '${_convertedAmount.toFormattedDecimalString(maximumFractionDigits: 2)} ${_getCurrencySymbol(_toCurrencyId)}',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Widget auxiliar para construir los DropdownButtons
  Widget _buildCurrencyDropdown(
    BuildContext context,
    String label,
    String? selectedValue,
    List<DolarDataModel> currencies,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      value: selectedValue,
      hint: const Text('Selecciona una divisa'),
      onChanged: onChanged,
      items: currencies.map<DropdownMenuItem<String>>((DolarDataModel dolar) {
        return DropdownMenuItem<String>(
          value: dolar.id,
          child: Text(dolar.nombre),
        );
      }).toList(),
      isExpanded: true,
    );
  }

  // Función auxiliar para obtener el símbolo de la moneda
  String _getCurrencySymbol(String? currencyId) {
    if (currencyId == 'ARS') {
      return 'ARS';
    } else if (currencyId != null) {
      // Para cualquier tipo de dólar, mostramos USD
      return 'USD';
    }
    return '';
  }
}
