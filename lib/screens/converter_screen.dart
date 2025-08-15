import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/dolar_data_model.dart';
import '../models/dolar_network_manager.dart';

class PolishedConverterScreen extends StatefulWidget {
  const PolishedConverterScreen({super.key});

  @override
  State<PolishedConverterScreen> createState() => _PolishedConverterScreenState();
}

class _PolishedConverterScreenState extends State<PolishedConverterScreen> with TickerProviderStateMixin {
  final ValueNotifier<String> _amountNotifier = ValueNotifier('0');
  final ValueNotifier<String> _convertedAmountNotifier = ValueNotifier('0.00');
  late AnimationController _swapAnimationController;
  late AnimationController _fadeAnimationController;

  String? _selectedDolarId;
  bool _isUSDToPesos = false;

  @override
  void initState() {
    super.initState();
    _amountNotifier.addListener(_updateConvertedAmount);
    _swapAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimationController.forward();
  }

  void _updateConvertedAmount() {
    final networkManager = Provider.of<DolarNetworkManager>(context, listen: false);
    if (!mounted || _selectedDolarId == null || networkManager.filteredData.isEmpty) {
      _convertedAmountNotifier.value = '0.00';
      return;
    }

    final selectedDolar = networkManager.filteredData.firstWhere((d) => d.id == _selectedDolarId, orElse: () => networkManager.filteredData.first);
    final amount = double.tryParse(_amountNotifier.value) ?? 0.0;
    
    if (amount == 0.0) {
      _convertedAmountNotifier.value = '0.00';
      return;
    }

    double? rate;
    if (_isUSDToPesos) {
      rate = selectedDolar.compra ?? selectedDolar.venta;
    } else {
      rate = selectedDolar.venta ?? selectedDolar.compra;
    }

    if (rate == null || rate == 0.0) {
      _convertedAmountNotifier.value = 'N/A';
      return;
    }

    final converted = _isUSDToPesos ? (amount * rate) : (amount / rate);
    _convertedAmountNotifier.value = converted.toStringAsFixed(2);
  }

  void _swapCurrencies() {
    if (mounted) {
      _swapAnimationController.forward().then((_) {
        _swapAnimationController.reverse();
      });
      setState(() {
        _isUSDToPesos = !_isUSDToPesos;
      });
    }
    _updateConvertedAmount(); 
    HapticFeedback.mediumImpact();
  }

  void _onNumberPressed(String number) {
    String currentAmount = _amountNotifier.value;
    if (number == '.' && currentAmount.contains('.')) return;
    if (currentAmount == '0' && number != '.') {
      _amountNotifier.value = number;
    } else {
      if(currentAmount.length < 12) {
        _amountNotifier.value = currentAmount + number;
      }
    }
  }

  void _onBackspacePressed() {
    String currentAmount = _amountNotifier.value;
    if (currentAmount.length > 1) {
      _amountNotifier.value = currentAmount.substring(0, currentAmount.length - 1);
    } else {
      _amountNotifier.value = '0';
    }
  }

  void _onClearPressed() {
    _amountNotifier.value = '0';
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(context),
      child: Consumer<DolarNetworkManager>(
        builder: (context, networkManager, child) {
          if (networkManager.isLoading && networkManager.filteredData.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CupertinoActivityIndicator(radius: 20),
                  const SizedBox(height: 16),
                  Text(
                    'Cargando tipos de cambio...',
                    style: TextStyle(
                      color: CupertinoColors.systemGrey.resolveFrom(context),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          final availableTypes = networkManager.filteredData.where((d) =>
            ["oficial", "blue", "mep", "ccl", "tarjeta"].contains(d.casa.toLowerCase())
          ).toList();

          if (availableTypes.isEmpty) {
             return const Center(child: Text("No hay tipos de dólar disponibles."));
          }

          if (_selectedDolarId == null || !availableTypes.any((d) => d.id == _selectedDolarId)) {
            _selectedDolarId = availableTypes.first.id;
          }
          
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if(mounted) _updateConvertedAmount();
          });

          return FadeTransition(
            opacity: _fadeAnimationController,
            child: SafeArea(
              bottom: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: Column(
                          children: [
                            _buildHeader(),
                            const SizedBox(height: 24),
                            _buildDolarTypeSelector(availableTypes),
                            const SizedBox(height: 32),
                            _buildConverterSection(),
                            const Spacer(),
                            _buildKeyboard(),
                            const SizedBox(height: 90),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          Text(
            'Conversor de Divisas',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: CupertinoColors.label.resolveFrom(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Conversión instantánea ARS ↔ USD',
            style: TextStyle(
              fontSize: 16,
              color: CupertinoColors.systemGrey.resolveFrom(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDolarTypeSelector(List<DolarDataModel> availableTypes) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'Tipo de cambio',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.label.resolveFrom(context),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: CupertinoColors.tertiarySystemGroupedBackground.resolveFrom(context),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.systemGrey4.resolveFrom(context).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: availableTypes.map((dolar) {
                final isSelected = _selectedDolarId == dolar.id;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (mounted) setState(() => _selectedDolarId = dolar.id);
                      HapticFeedback.selectionClick();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                      decoration: BoxDecoration(
                        gradient: isSelected ? LinearGradient(
                          colors: [
                            CupertinoColors.systemBlue.resolveFrom(context),
                            CupertinoColors.systemBlue.resolveFrom(context).withOpacity(0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ) : null,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: isSelected ? [
                          BoxShadow(
                            color: CupertinoColors.systemBlue.resolveFrom(context).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ] : null,
                      ),
                      child: Text(
                        _getDolarDisplayName(dolar.nombre),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected ? CupertinoColors.white : CupertinoColors.label.resolveFrom(context),
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConverterSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildInputCard(),
          const SizedBox(height: 16),
          _buildSwapButton(),
          const SizedBox(height: 16),
          _buildOutputCard(),
        ],
      ),
    );
  }

  String _getDolarDisplayName(String nombre) {
    switch (nombre.toLowerCase()) {
      case 'contado con liquidación': return 'CCL';
      default: return nombre;
    }
  }

  Widget _buildInputCard() {
    final currencyName = _isUSDToPesos ? 'Dólar Estadounidense' : 'Peso Argentino';
    final currencySymbol = _isUSDToPesos ? 'USD' : 'ARS';
    final flagEmoji = _isUSDToPesos ? '🇺🇸' : '🇦🇷';
    
    return _buildCurrencyCard(
      label: 'Envías',
      currencyName: currencyName,
      currencySymbol: currencySymbol,
      flagEmoji: flagEmoji,
      notifier: _amountNotifier,
      isPrimary: true,
    );
  }

  Widget _buildOutputCard() {
    final currencyName = _isUSDToPesos ? 'Peso Argentino' : 'Dólar Estadounidense';
    final currencySymbol = _isUSDToPesos ? 'ARS' : 'USD';
    final flagEmoji = _isUSDToPesos ? '🇦🇷' : '🇺🇸';

    return _buildCurrencyCard(
      label: 'Recibes',
      currencyName: currencyName,
      currencySymbol: currencySymbol,
      flagEmoji: flagEmoji,
      notifier: _convertedAmountNotifier,
      isPrimary: false,
    );
  }
  
  Widget _buildCurrencyCard({
    required String label,
    required String currencyName,
    required String currencySymbol,
    required String flagEmoji,
    required ValueNotifier<String> notifier,
    required bool isPrimary,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isPrimary 
          ? CupertinoColors.systemBackground.resolveFrom(context)
          : CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(20),
        border: isPrimary ? Border.all(
          color: CupertinoColors.systemBlue.resolveFrom(context).withOpacity(0.3),
          width: 2,
        ) : null,
        boxShadow: [
          BoxShadow(
            color: isPrimary 
              ? CupertinoColors.systemBlue.resolveFrom(context).withOpacity(0.1)
              : CupertinoColors.systemGrey4.resolveFrom(context).withOpacity(0.3),
            blurRadius: isPrimary ? 15 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPrimary 
                    ? CupertinoColors.systemBlue.resolveFrom(context).withOpacity(0.1)
                    : CupertinoColors.systemGreen.resolveFrom(context).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    color: isPrimary 
                      ? CupertinoColors.systemBlue.resolveFrom(context)
                      : CupertinoColors.systemGreen.resolveFrom(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                flagEmoji,
                style: const TextStyle(fontSize: 24),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currencyName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: CupertinoColors.secondaryLabel.resolveFrom(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currencySymbol,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                      ),
                    ),
                  ],
                ),
              ),
              ValueListenableBuilder<String>(
                valueListenable: notifier,
                builder: (context, amount, child) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        amount == '0' ? '0' : amount,
                        style: TextStyle(
                          fontSize: isPrimary ? 32 : 28,
                          fontWeight: FontWeight.w700,
                          color: isPrimary 
                            ? CupertinoColors.label.resolveFrom(context)
                            : CupertinoColors.systemGreen.resolveFrom(context),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSwapButton() {
    return RotationTransition(
      turns: _swapAnimationController,
      child: GestureDetector(
        onTap: _swapCurrencies,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                CupertinoColors.systemBlue.resolveFrom(context),
                CupertinoColors.systemBlue.resolveFrom(context).withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.systemBlue.resolveFrom(context).withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            CupertinoIcons.arrow_up_arrow_down,
            color: CupertinoColors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildKeyboard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _ModernCalculatorKey(text: '1', onTap: () => _onNumberPressed('1')),
              _ModernCalculatorKey(text: '2', onTap: () => _onNumberPressed('2')),
              _ModernCalculatorKey(text: '3', onTap: () => _onNumberPressed('3')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _ModernCalculatorKey(text: '4', onTap: () => _onNumberPressed('4')),
              _ModernCalculatorKey(text: '5', onTap: () => _onNumberPressed('5')),
              _ModernCalculatorKey(text: '6', onTap: () => _onNumberPressed('6')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _ModernCalculatorKey(text: '7', onTap: () => _onNumberPressed('7')),
              _ModernCalculatorKey(text: '8', onTap: () => _onNumberPressed('8')),
              _ModernCalculatorKey(text: '9', onTap: () => _onNumberPressed('9')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _ModernCalculatorKey(text: '.', onTap: () => _onNumberPressed('.')),
              _ModernCalculatorKey(text: '0', onTap: () => _onNumberPressed('0')),
              _ModernCalculatorKey(
                icon: CupertinoIcons.delete_left,
                isSpecial: true,
                onTap: _onBackspacePressed,
                onLongPress: _onClearPressed,
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _amountNotifier.removeListener(_updateConvertedAmount);
    _amountNotifier.dispose();
    _convertedAmountNotifier.dispose();
    _swapAnimationController.dispose();
    _fadeAnimationController.dispose();
    super.dispose();
  }
}

class _ModernCalculatorKey extends StatefulWidget {
  final String? text;
  final IconData? icon;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isSpecial;

  const _ModernCalculatorKey({
    this.text,
    this.icon,
    required this.onTap,
    this.onLongPress,
    this.isSpecial = false,
  });

  @override
  _ModernCalculatorKeyState createState() => _ModernCalculatorKeyState();
}

class _ModernCalculatorKeyState extends State<_ModernCalculatorKey> with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
  }

  void _onTapDown(TapDownDetails details) {
    if (mounted) {
      setState(() => _isPressed = true);
      _scaleController.forward();
    }
    HapticFeedback.lightImpact();
  }

  void _onTapUp(TapUpDetails details) {
    if (mounted) {
      setState(() => _isPressed = false);
      _scaleController.reverse();
    }
    widget.onTap();
  }

  void _onTapCancel() {
    if (mounted) {
      setState(() => _isPressed = false);
      _scaleController.reverse();
    }
  }
  
  void _onLongPress() {
    HapticFeedback.mediumImpact();
    widget.onLongPress?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: GestureDetector(
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          onLongPress: widget.onLongPress != null ? _onLongPress : null,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            height: 70,
            decoration: BoxDecoration(
              color: widget.isSpecial 
                ? CupertinoColors.systemOrange.resolveFrom(context).withOpacity(_isPressed ? 0.3 : 0.1)
                : CupertinoColors.systemBackground.resolveFrom(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: widget.isSpecial 
                  ? CupertinoColors.systemOrange.resolveFrom(context).withOpacity(0.3)
                  : CupertinoColors.separator.resolveFrom(context),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.systemGrey4.resolveFrom(context).withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: widget.text != null
                  ? Text(
                      widget.text!,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w500,
                        color: widget.isSpecial 
                          ? CupertinoColors.systemOrange.resolveFrom(context)
                          : CupertinoColors.label.resolveFrom(context),
                      ),
                    )
                  : Icon(
                      widget.icon,
                      size: 24,
                      color: widget.isSpecial 
                        ? CupertinoColors.systemOrange.resolveFrom(context)
                        : CupertinoColors.label.resolveFrom(context),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }
}