import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/dolar_data_model.dart';
import '../models/dolar_network_manager.dart';

class _Constants {
  static const double maxInputLength = 12;
  static const double cardBorderRadius = 20.0;
  static const double keyboardHeight = 70.0;
  static const double headerFontSize = 32.0;
  static const double subtitleFontSize = 16.0;
  static const double selectorFontSize = 17.0;
  static const double primaryAmountFontSize = 32.0;
  static const double secondaryAmountFontSize = 28.0;
  static const double keyboardFontSize = 28.0;
  
  // Spacing
  static const double headerVerticalPadding = 20.0;
  static const double headerHorizontalPadding = 24.0;
  static const double cardPadding = 20.0;
  static const double keyboardMargin = 16.0;
  static const double selectorMargin = 20.0;
  // Eliminadas: tabBarSafeArea y keyboardSafeArea
  
  // Animation durations
  static const Duration animationDuration = Duration(milliseconds: 200);
  static const Duration swapAnimationDuration = Duration(milliseconds: 600);
  static const Duration fadeAnimationDuration = Duration(milliseconds: 300);
  static const Duration scaleAnimationDuration = Duration(milliseconds: 100);
  static const Duration debounceDelay = Duration(milliseconds: 300);
  
  // Decimal places
  static const int maxDecimalPlaces = 2;
  static const int displayDecimalPlaces = 2;
}

class PolishedConverterScreen extends StatefulWidget {
  const PolishedConverterScreen({super.key});

  @override
  State<PolishedConverterScreen> createState() => _PolishedConverterScreenState();
}

class _PolishedConverterScreenState extends State<PolishedConverterScreen> with TickerProviderStateMixin {
  final ValueNotifier<String> _amountNotifier = ValueNotifier('0');
  final ValueNotifier<String> _convertedAmountNotifier = ValueNotifier('0,00'); // Cambiado a formato argentino
  late AnimationController _swapAnimationController;
  late AnimationController _fadeAnimationController;
  // ELIMINADO: late NumberFormat _numberFormatter; - Ya no lo necesitamos

  String? _selectedDolarId;
  bool _isUSDToPesos = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    // ELIMINADO: _initializeFormatters(); - Ya no lo necesitamos
    _amountNotifier.addListener(_updateConvertedAmountDebounced);
    _initializeAnimations();
  }



 void _initializeAnimations() {
    _swapAnimationController = AnimationController(
      duration: _Constants.swapAnimationDuration,
      vsync: this,
    );
    _fadeAnimationController = AnimationController(
      duration: _Constants.fadeAnimationDuration,
      vsync: this,
    );
    _fadeAnimationController.forward();
  }

  void _updateConvertedAmountDebounced() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_Constants.debounceDelay, _updateConvertedAmount);
  }

  void _updateConvertedAmount() {
    try {
      final networkManager = Provider.of<DolarNetworkManager>(context, listen: false);
      if (!mounted || _selectedDolarId == null || networkManager.filteredData.isEmpty) {
        _convertedAmountNotifier.value = _formatDisplayAmount(0.0);
        return;
      }

      final selectedDolar = networkManager.filteredData.firstWhere(
        (d) => d.id == _selectedDolarId, 
        orElse: () => networkManager.filteredData.first
      );
      
      final amount = _parseAmount(_amountNotifier.value);
      
      if (amount == 0.0) {
        _convertedAmountNotifier.value = _formatDisplayAmount(0.0);
        return;
      }

      final convertedAmount = _calculateConversion(selectedDolar, amount);
      _convertedAmountNotifier.value = convertedAmount ?? 'N/A';
      
    } catch (e) {
      debugPrint('Error updating conversion: $e');
      _convertedAmountNotifier.value = 'Error';
    }
  }

  double _parseAmount(String amountStr) {
    try {
      return double.tryParse(amountStr) ?? 0.0;
    } catch (e) {
      debugPrint('Error parsing amount: $e');
      return 0.0;
    }
  }

  String? _calculateConversion(DolarDataModel selectedDolar, double amount) {
    try {
      double? rate;
      if (_isUSDToPesos) {
        rate = selectedDolar.compra ?? selectedDolar.venta;
      } else {
        rate = selectedDolar.venta ?? selectedDolar.compra;
      }

      if (rate == null || rate == 0.0) {
        return null;
      }

      final converted = _isUSDToPesos ? (amount * rate) : (amount / rate);
      return _formatDisplayAmount(converted);
      
    } catch (e) {
      debugPrint('Error calculating conversion: $e');
      return null;
    }
  }

 String _formatDisplayAmount(double amount) {
    try {
      return amount.toFormattedCurrencyString(decimalDigits: _Constants.displayDecimalPlaces);
    } catch (e) {
      debugPrint('Error formatting amount: $e');
      return amount.toStringAsFixed(_Constants.displayDecimalPlaces);
    }
  }

  void _swapCurrencies() {
    try {
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
    } catch (e) {
      debugPrint('Error swapping currencies: $e');
    }
  }

  void _onNumberPressed(String number) {
    try {
      String currentAmount = _amountNotifier.value;
      
      // Validar punto decimal
      if (number == '.' && currentAmount.contains('.')) return;
      
      // Validar que no empiece con múltiples ceros
      if (currentAmount == '0' && number == '0') return;
      
      // Validar límite de decimales
      if (currentAmount.contains('.')) {
        final parts = currentAmount.split('.');
        if (parts.length > 1 && parts[1].length >= _Constants.maxDecimalPlaces) {
          return;
        }
      }
      
      // Validar longitud máxima
      if (currentAmount.length >= _Constants.maxInputLength) return;
      
      if (currentAmount == '0' && number != '.') {
        _amountNotifier.value = number;
      } else {
        _amountNotifier.value = currentAmount + number;
      }
    } catch (e) {
      debugPrint('Error processing number input: $e');
    }
  }

  void _onBackspacePressed() {
    try {
      String currentAmount = _amountNotifier.value;
      if (currentAmount.length > 1) {
        _amountNotifier.value = currentAmount.substring(0, currentAmount.length - 1);
      } else {
        _amountNotifier.value = '0';
      }
    } catch (e) {
      debugPrint('Error processing backspace: $e');
    }
  }

  void _onClearPressed() {
    try {
      _amountNotifier.value = '0';
    } catch (e) {
      debugPrint('Error clearing input: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(context),
      child: Consumer<DolarNetworkManager>(
        builder: (context, networkManager, child) {
          if (networkManager.isLoading && networkManager.filteredData.isEmpty) {
            return _buildLoadingState();
          }

          final availableTypes = _getAvailableTypes(networkManager);

          if (availableTypes.isEmpty) {
            return _buildErrorState("No hay tipos de dólar disponibles.");
          }

          _ensureValidSelection(availableTypes);
          
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if(mounted) _updateConvertedAmount();
          });

          return _buildMainContent(availableTypes);
        },
      ),
    );
  }

  Widget _buildLoadingState() {
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
              fontSize: _Constants.subtitleFontSize,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Text(
        message,
        style: TextStyle(
          color: CupertinoColors.systemRed.resolveFrom(context),
          fontSize: _Constants.subtitleFontSize,
        ),
      ),
    );
  }

  List<DolarDataModel> _getAvailableTypes(DolarNetworkManager networkManager) {
    const allowedTypes = ["oficial", "blue", "mep", "ccl", "tarjeta"];
    return networkManager.filteredData.where((d) =>
      allowedTypes.contains(d.casa.toLowerCase())
    ).toList();
  }

  void _ensureValidSelection(List<DolarDataModel> availableTypes) {
    if (_selectedDolarId == null || !availableTypes.any((d) => d.id == _selectedDolarId)) {
      _selectedDolarId = availableTypes.first.id;
    }
  }

  Widget _buildMainContent(List<DolarDataModel> availableTypes) {
    return FadeTransition(
      opacity: _fadeAnimationController,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Obtener información del MediaQuery para calcular espacios seguros
            final mediaQuery = MediaQuery.of(context);
            final bottomPadding = mediaQuery.viewInsets.bottom > 0 
              ? mediaQuery.viewInsets.bottom + 20 // Espacio adicional cuando aparece teclado del sistema
              : mediaQuery.padding.bottom + 120; // Espacio para tab bar + margen adicional
            
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    _buildDolarTypeSelector(availableTypes),
                    const SizedBox(height: 24),
                    _buildConverterSection(),
                    const SizedBox(height: 32),
                    _buildKeyboard(),
                    SizedBox(height: bottomPadding), // Espacio dinámico para tab bar
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: _Constants.headerHorizontalPadding, 
        vertical: _Constants.headerVerticalPadding
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Conversor de Divisas',
            style: TextStyle(
              fontSize: _Constants.headerFontSize,
              fontWeight: FontWeight.w700,
              color: CupertinoColors.label.resolveFrom(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Conversión instantánea ARS ↔ USD',
            style: TextStyle(
              fontSize: _Constants.subtitleFontSize,
              fontWeight: FontWeight.w500,
              color: CupertinoColors.systemGrey.resolveFrom(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDolarTypeSelector(List<DolarDataModel> availableTypes) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: _Constants.selectorMargin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'Tipo de cambio',
              style: TextStyle(
                fontSize: _Constants.selectorFontSize,
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
                    onTap: () => _onDolarTypeSelected(dolar.id),
                    child: _buildSelectorButton(dolar, isSelected),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _onDolarTypeSelected(String dolarId) {
    try {
      if (mounted) setState(() => _selectedDolarId = dolarId);
      HapticFeedback.selectionClick();
    } catch (e) {
      debugPrint('Error selecting dolar type: $e');
    }
  }

  Widget _buildSelectorButton(DolarDataModel dolar, bool isSelected) {
    return AnimatedContainer(
      duration: _Constants.animationDuration,
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
    );
  }

  Widget _buildConverterSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: _Constants.selectorMargin),
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
    const displayNames = {
      'contado con liquidación': 'CCL',
      'tarjeta': 'Tarjeta',
      'oficial': 'Oficial',
      'blue': 'Blue',
      'mep': 'MEP',
    };
    
    return displayNames[nombre.toLowerCase()] ?? nombre;
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
      padding: const EdgeInsets.all(_Constants.cardPadding),
      decoration: BoxDecoration(
        color: isPrimary 
          ? CupertinoColors.systemBackground.resolveFrom(context)
          : CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(_Constants.cardBorderRadius),
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
                          fontSize: isPrimary ? _Constants.primaryAmountFontSize : _Constants.secondaryAmountFontSize,
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
      margin: const EdgeInsets.symmetric(horizontal: _Constants.keyboardMargin),
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
    _debounceTimer?.cancel();
    _amountNotifier.removeListener(_updateConvertedAmountDebounced);
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
      duration: _Constants.scaleAnimationDuration,
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
    try {
      if (mounted) {
        setState(() => _isPressed = true);
        _scaleController.forward();
      }
      HapticFeedback.lightImpact();
    } catch (e) {
      debugPrint('Error on tap down: $e');
    }
  }

  void _onTapUp(TapUpDetails details) {
    try {
      if (mounted) {
        setState(() => _isPressed = false);
        _scaleController.reverse();
      }
      widget.onTap();
    } catch (e) {
      debugPrint('Error on tap up: $e');
    }
  }

  void _onTapCancel() {
    try {
      if (mounted) {
        setState(() => _isPressed = false);
        _scaleController.reverse();
      }
    } catch (e) {
      debugPrint('Error on tap cancel: $e');
    }
  }
  
  void _onLongPress() {
    try {
      HapticFeedback.mediumImpact();
      widget.onLongPress?.call();
    } catch (e) {
      debugPrint('Error on long press: $e');
    }
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
            height: _Constants.keyboardHeight,
            decoration: BoxDecoration(
              color: widget.isSpecial 
                ? CupertinoColors.systemOrange.resolveFrom(context).withOpacity(_isPressed ? 0.3 : 0.1)
                : CupertinoColors.systemBackground.resolveFrom(context),
              borderRadius: BorderRadius.circular(_Constants.cardBorderRadius),
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
                        fontSize: _Constants.keyboardFontSize,
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
