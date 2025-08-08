import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dolar_data_model.dart'; 

// MARK: - Custom Errors
enum DolarNetworkError {
  invalidURL,
  noData,
  decodingError,
  networkError,
  serverError;

  String get errorDescription {
    switch (this) {
      case DolarNetworkError.invalidURL:
        return "URL inválida";
      case DolarNetworkError.noData:
        return "No se recibieron datos";
      case DolarNetworkError.decodingError:
        return "Error al procesar datos";
      case DolarNetworkError.networkError:
        return "Error de red";
      case DolarNetworkError.serverError:
        return "Error del servidor";
    }
  }
}

// MARK: - Filter Options
enum DolarFilter {
  all,
  favorites,
  official,
  blue,
  popular;

  String get displayName {
    switch (this) {
      case DolarFilter.all:
        return "Todos";
      case DolarFilter.favorites:
        return "Favoritos";
      case DolarFilter.official:
        return "Oficial";
      case DolarFilter.blue:
        return "Blue";
      case DolarFilter.popular:
        return "Populares";
    }
  }
}

// MARK: - Dolar Tarjeta Calculator
class DolarTarjetaCalculator {
  static const double adelantoGanancias = 0.30;

  double calcularDolarTarjeta(double dolarOficial) {
    return dolarOficial * (1 + adelantoGanancias);
  }

  DolarTarjetaDetalle obtenerDetalleImpuestos(double dolarOficial) {
    final adelantoGananciasImporte = dolarOficial * adelantoGanancias;
    final total = dolarOficial + adelantoGananciasImporte;
    return DolarTarjetaDetalle(
      dolarOficial: dolarOficial,
      adelantoGanancias: adelantoGananciasImporte,
      total: total,
      porcentajeAdelantoGanancias: adelantoGanancias * 100,
    );
  }
}

// MARK: - Supporting Structure
class DolarTarjetaDetalle {
  final double dolarOficial;
  final double adelantoGanancias;
  final double total;
  final double porcentajeAdelantoGanancias;

  DolarTarjetaDetalle({
    required this.dolarOficial,
    required this.adelantoGanancias,
    required this.total,
    required this.porcentajeAdelantoGanancias,
  });

  String get descripcionImpuestos => "Adelanto Ganancias: ${porcentajeAdelantoGanancias.toStringAsFixed(2)}%";
}

// MARK: - DolarNetworkManager
class DolarNetworkManager extends ChangeNotifier {
  // MARK: - Published Properties
  List<DolarDataModel> _dolarData = [];
  List<DolarDataModel> _filteredData = [];
  bool isLoading = false;
  DolarNetworkError? error;
  DolarFilter _currentFilter = DolarFilter.all;
  DateTime? _lastUpdateTime;

  // MARK: - Dolar Tarjeta Properties
  DolarTarjetaDetalle? dolarTarjetaDetalle;
  final DolarTarjetaCalculator _dolarTarjetaCalculator = DolarTarjetaCalculator();

  // MARK: - Private Properties
  final String _favoritesKey = "FavoriteDolarTypes";
  final String _lastUpdateKey = "LastDolarUpdate";
  final String _cacheKey = "CachedDolarData";
  final String _apiURL = "https://dolarapi.com/v1/dolares";
  final Duration _updateInterval = const Duration(minutes: 5);

  late SharedPreferences _prefs;

  DolarNetworkManager() {
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadCachedData();
    _loadFavorites();
    _setupAutoRefresh();
    notifyListeners();
  }

  // MARK: - Public Getters
  List<DolarDataModel> get filteredData => _filteredData;
  List<DolarDataModel> get dolarData => _dolarData;
  DolarFilter get currentFilter => _currentFilter;
  bool get hasFavorites => _dolarData.any((dolar) => dolar.isFavorite);
  bool get shouldRefresh => _lastUpdateTime == null || DateTime.now().difference(_lastUpdateTime!) > _updateInterval;

  // MARK: - Public Methods
  Future<void> fetchData({bool forceRefresh = false}) async {
    if (isLoading && !forceRefresh) return;
    if (!shouldRefresh && !forceRefresh) {
      notifyListeners();
      return;
    }

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final url = Uri.parse(_apiURL);
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        final List<DolarDataModel> newData = jsonList.map((e) => DolarDataModel.fromJson(e)).toList();
        _processNewData(newData);
        _lastUpdateTime = DateTime.now();
        await _saveToCache();
      } else {
        _handleError(DolarNetworkError.serverError);
      }
    } catch (e) {
      _handleError(_getNetworkError(e));
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void toggleFavorite(String id) {
    final index = _dolarData.indexWhere((element) => element.id == id);
    if (index != -1) {
      _dolarData[index] = _dolarData[index].copyWith(isFavorite: !_dolarData[index].isFavorite);
      _saveFavorites();
      _applyCurrentFilter();
      notifyListeners();
    }
  }

  void setFilter(DolarFilter filter) {
    if (_currentFilter == filter) return;
    _currentFilter = filter;
    _applyCurrentFilter();
    notifyListeners();
  }

  void clearError() {
    if (error != null) {
      error = null;
      notifyListeners();
    }
  }

  // MARK: - Private Methods
  void _processNewData(List<DolarDataModel> newData) {
    final favorites = _prefs.getStringList(_favoritesKey) ?? [];
    final updatedData = newData.map((dolar) {
      return dolar.copyWith(isFavorite: favorites.contains(dolar.id));
    }).toList();

    _dolarData = updatedData;
    _updateDolarTarjeta();
    _applyCurrentFilter();
  }

  void _updateDolarTarjeta() {
    final dolarOficial = _dolarData.firstWhere(
      (dolar) => dolar.casa.toLowerCase() == "oficial",
      orElse: () => DolarDataModel(id: '', casa: '', nombre: '', moneda: '', fechaActualizacion: ''),
    );

    if (dolarOficial.venta != null) {
      dolarTarjetaDetalle = _dolarTarjetaCalculator.obtenerDetalleImpuestos(dolarOficial.venta!);
      
      final dolarTarjetaIndex = _dolarData.indexWhere((dolar) => dolar.id == "tarjeta");
      final dolarTarjetaModel = DolarDataModel(
        id: "tarjeta",
        venta: dolarTarjetaDetalle!.total,
        casa: "tarjeta",
        nombre: "Tarjeta",
        moneda: "USD",
        fechaActualizacion: dolarOficial.fechaActualizacion,
        isFavorite: _prefs.getStringList(_favoritesKey)?.contains("tarjeta") ?? false,
      );
      
      if (dolarTarjetaIndex != -1) {
        _dolarData[dolarTarjetaIndex] = dolarTarjetaModel;
      } else {
        _dolarData.add(dolarTarjetaModel);
      }
    } else {
      dolarTarjetaDetalle = null;
      _dolarData.removeWhere((dolar) => dolar.id == "tarjeta");
    }
  }
  
  void _applyCurrentFilter() {
    switch (_currentFilter) {
      case DolarFilter.all:
        _filteredData = List.from(_dolarData);
        break;
      case DolarFilter.favorites:
        _filteredData = _dolarData.where((dolar) => dolar.isFavorite).toList();
        break;
      case DolarFilter.official:
        _filteredData = _dolarData.where((dolar) => dolar.casa.toLowerCase() == "oficial").toList();
        break;
      case DolarFilter.blue:
        _filteredData = _dolarData.where((dolar) => dolar.casa.toLowerCase() == "blue").toList();
        break;
      case DolarFilter.popular:
        const popularTypes = ["oficial", "blue", "mep", "ccl", "tarjeta"];
        _filteredData = _dolarData.where((dolar) => popularTypes.contains(dolar.casa.toLowerCase())).toList();
        break;
    }
  }
  
  void _handleError(DolarNetworkError newError) {
    error = newError;
    isLoading = false;
    if (kDebugMode) {
      print("DolarNetworkManager Error: ${newError.errorDescription}");
    }
  }

  void _loadFavorites() {
    final favorites = _prefs.getStringList(_favoritesKey) ?? [];
    for (var i = 0; i < _dolarData.length; i++) {
        if (favorites.contains(_dolarData[i].id)) {
          _dolarData[i] = _dolarData[i].copyWith(isFavorite: true);
        }
    }
    _applyCurrentFilter();
  }

  void _saveFavorites() {
    final favorites = _dolarData.where((dolar) => dolar.isFavorite).map((dolar) => dolar.id).toList();
    _prefs.setStringList(_favoritesKey, favorites);
  }

  Future<void> _saveToCache() async {
    try {
      final dataToCache = _dolarData.where((dolar) => dolar.casa.toLowerCase() != "tarjeta").toList();
      final encoded = jsonEncode(dataToCache.map((e) => e.toJson()).toList());
      await _prefs.setString(_cacheKey, encoded);
      if (_lastUpdateTime != null) {
        await _prefs.setString(_lastUpdateKey, _lastUpdateTime!.toIso8601String());
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error al guardar cache: $e");
      }
    }
  }

  Future<void> _loadCachedData() async {
    final data = _prefs.getString(_cacheKey);
    if (data == null) return;

    try {
      final List<dynamic> jsonList = jsonDecode(data);
      final List<DolarDataModel> cachedData = jsonList.map((e) => DolarDataModel.fromJson(e)).toList();
      _dolarData = cachedData;
      
      final lastUpdateString = _prefs.getString(_lastUpdateKey);
      _lastUpdateTime = lastUpdateString != null ? DateTime.parse(lastUpdateString) : null;
      _updateDolarTarjeta();
      _applyCurrentFilter();
    } catch (e) {
      if (kDebugMode) {
        print("Error al cargar cache: $e");
      }
      await _prefs.remove(_cacheKey);
      await _prefs.remove(_lastUpdateKey);
    }
  }
  
  void _setupAutoRefresh() {
    Future.delayed(_updateInterval, () {
      if (shouldRefresh) {
        fetchData();
      }
    });
  }

  DolarNetworkError _getNetworkError(dynamic e) {
    if (e is http.ClientException) {
      return DolarNetworkError.networkError;
    }
    if (e is FormatException) {
      return DolarNetworkError.decodingError;
    }
    return DolarNetworkError.networkError;
  }
}