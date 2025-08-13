import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class ConverterScreen extends StatefulWidget {
  const ConverterScreen({super.key});

  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen> {
  final TextEditingController _pesosController = TextEditingController();
  final TextEditingController _dolaresController = TextEditingController();
  
  final double _tipoCambio = 130.75; // Valor de ejemplo
  bool _isPesosToUSD = true; // true: pesos a USD, false: USD a pesos

  @override
  void initState() {
    super.initState();
    _pesosController.addListener(_onPesosChanged);
    _dolaresController.addListener(_onDolaresChanged);
  }

  void _onPesosChanged() {
    if (_isPesosToUSD && _pesosController.text.isNotEmpty) {
      final pesos = double.tryParse(_pesosController.text) ?? 0;
      final dolares = pesos / _tipoCambio;
      _dolaresController.text = dolares.toStringAsFixed(2);
    }
  }

  void _onDolaresChanged() {
    if (!_isPesosToUSD && _dolaresController.text.isNotEmpty) {
      final dolares = double.tryParse(_dolaresController.text) ?? 0;
      final pesos = dolares * _tipoCambio;
      _pesosController.text = pesos.toStringAsFixed(2);
    }
  }

  void _swapCurrencies() {
    setState(() {
      _isPesosToUSD = !_isPesosToUSD;
      // Intercambiar valores
      final temp = _pesosController.text;
      _pesosController.text = _dolaresController.text;
      _dolaresController.text = temp;
    });
    HapticFeedback.lightImpact();
  }

  void _clearFields() {
    _pesosController.clear();
    _dolaresController.clear();
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Conversor'),
        backgroundColor: CupertinoColors.systemBackground,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              
              // Tipo de cambio actual
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      CupertinoIcons.money_dollar_circle,
                      color: CupertinoColors.systemBlue,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Tipo de cambio: \$${_tipoCambio.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: CupertinoColors.systemBlue,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Campo Pesos
              _buildCurrencyField(
                controller: _pesosController,
                label: 'Pesos Argentinos',
                symbol: '\$',
                isActive: _isPesosToUSD,
              ),
              
              const SizedBox(height: 20),
              
              // Botón de intercambio
              GestureDetector(
                onTap: _swapCurrencies,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: CupertinoColors.systemGrey6,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.arrow_up_arrow_down,
                    color: CupertinoColors.systemBlue,
                    size: 24,
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Campo Dólares
              _buildCurrencyField(
                controller: _dolaresController,
                label: 'Dólares USD',
                symbol: 'US\$',
                isActive: !_isPesosToUSD,
              ),
              
              const SizedBox(height: 40),
              
              // Botón limpiar
              CupertinoButton.filled(
                onPressed: _clearFields,
                child: const Text('Limpiar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrencyField({
    required TextEditingController controller,
    required String label,
    required String symbol,
    required bool isActive,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isActive ? CupertinoColors.systemBlue : CupertinoColors.systemGrey,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey6,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive 
                ? CupertinoColors.systemBlue.withOpacity(0.5)
                : CupertinoColors.systemGrey4,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: isActive 
                    ? CupertinoColors.systemBlue.withOpacity(0.1)
                    : CupertinoColors.systemGrey5,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(11),
                    bottomLeft: Radius.circular(11),
                  ),
                ),
                child: Text(
                  symbol,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isActive 
                      ? CupertinoColors.systemBlue
                      : CupertinoColors.systemGrey,
                  ),
                ),
              ),
              Expanded(
                child: CupertinoTextField(
                  controller: controller,
                  decoration: const BoxDecoration(),
                  placeholder: '0.00',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: isActive 
                      ? CupertinoColors.label
                      : CupertinoColors.systemGrey,
                  ),
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _pesosController.dispose();
    _dolaresController.dispose();
    super.dispose();
  }
}