import 'dart:async';
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
  /// Si mañana agregan más impuestos, solo se agregan aquí
  static const impuestos = {
    "adelantoGanancias": 0.30,
  };

  double calcularDolarTarjeta(double dolarOficial) {
    double total = dolarOficial;
    for (final porcentaje in impuestos.values) {
      total += dolarOficial * porcentaje;
    }
    return total;
  }

  Map<String, double> obtenerDetalle(double dolarOficial) {
    final detalles = <String, double>{};
    for (final entry in impuestos.entries) {
      detalles[entry.key] = dolarOficial * entry.value;
    }
    return detalles;
  }
}

// MARK: - ViewModel
class DolarNetworkManager extends ChangeNotifier {
  List<DolarDataModel> _dolarData = [];
  List<DolarDataModel> _filteredData = [];
  bool isLoading = false;
  DolarNetworkError? error;
  DolarFilter _currentFilter = DolarFilter.all;
  DateTime? _lastUpdateTime;
  Timer? _refreshTimer;

  final _favoritesKey = "FavoriteDolarTypes";
  final _lastUpdateKey = "LastDolarUpdate";
  final _cacheKey = "CachedDolarData";
  final _apiURL = "https://dolarapi.com/v1/dolares";
  final _updateInterval = const Duration(minutes: 5);

  late SharedPreferences _prefs;
  final _tarjetaCalculator = DolarTarjetaCalculator();

  DolarNetworkManager() {
    _init();
  }

  // Getters públicos
  List<DolarDataModel> get filteredData => List.unmodifiable(_filteredData);
  DolarFilter get currentFilter => _currentFilter;
  bool get hasFavorites => _dolarData.any((d) => d.isFavorite);
  bool get shouldRefresh => _lastUpdateTime == null || DateTime.now().difference(_lastUpdateTime!) > _updateInterval;

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadCachedData();
    _startAutoRefresh();
    notifyListeners();
  }

  // MARK: - Fetch
  Future<void> fetchData({bool forceRefresh = false}) async {
    if (isLoading && !forceRefresh) return;
    if (!shouldRefresh && !forceRefresh) {
      _applyFilter();
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
        final newData = jsonList.map((e) => DolarDataModel.fromJson(e)).toList();
        _processNewData(newData);
        _lastUpdateTime = DateTime.now();
        await _saveToCache();
      } else if (response.statusCode == 404) {
        _handleError(DolarNetworkError.noData);
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

  // MARK: - Procesar datos nuevos
  void _processNewData(List<DolarDataModel> newData) {
    final favorites = _prefs.getStringList(_favoritesKey) ?? [];

    // Actualizamos favoritos y agregamos dolar tarjeta
    _dolarData = newData.map((d) {
      return d.copyWith(isFavorite: favorites.contains(d.id));
    }).toList();

    _updateDolarTarjeta();
    _applyFilter();
  }

  void _updateDolarTarjeta() {
    final dolarOficial = _dolarData.firstWhere(
      (d) => d.casa.toLowerCase() == "oficial",
      orElse: () => DolarDataModel(
        id: "oficial_usd",
        casa: "Oficial",
        nombre: "Oficial",
        moneda: "USD",
        fechaActualizacion: '',
      ),
    );

    if (dolarOficial.venta != null) {
      final total = _tarjetaCalculator.calcularDolarTarjeta(dolarOficial.venta!);
      final dolarTarjeta = DolarDataModel(
        id: "tarjeta_usd",
        venta: total,
        casa: "Tarjeta",
        nombre: "Tarjeta",
        moneda: "USD",
        fechaActualizacion: dolarOficial.fechaActualizacion,
        isFavorite: _prefs.getStringList(_favoritesKey)?.contains("tarjeta_usd") ?? false,
      );

      _dolarData.removeWhere((d) => d.id == "tarjeta_usd");
      _dolarData.add(dolarTarjeta);
    }
  }

  // MARK: - Favoritos
  void toggleFavorite(String id) {
    final index = _dolarData.indexWhere((d) => d.id == id);
    if (index != -1) {
      final updated = _dolarData[index].copyWith(isFavorite: !_dolarData[index].isFavorite);
      _dolarData[index] = updated;
      _saveFavorites();
      _applyFilter();
      notifyListeners();
    }
  }

  void _saveFavorites() {
    final favorites = _dolarData.where((d) => d.isFavorite).map((d) => d.id).toList();
    _prefs.setStringList(_favoritesKey, favorites);
  }

  // MARK: - Filtros
  void setFilter(DolarFilter filter) {
    if (_currentFilter == filter) return;
    _currentFilter = filter;
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    switch (_currentFilter) {
      case DolarFilter.all:
        _filteredData = List.from(_dolarData);
        break;
      case DolarFilter.favorites:
        _filteredData = _dolarData.where((d) => d.isFavorite).toList();
        break;
      case DolarFilter.official:
        _filteredData = _dolarData.where((d) => d.casa.toLowerCase() == "oficial").toList();
        break;
      case DolarFilter.blue:
        _filteredData = _dolarData.where((d) => d.casa.toLowerCase() == "blue").toList();
        break;
      case DolarFilter.popular:
        const popularTypes = ["oficial", "blue", "mep", "ccl", "tarjeta"];
        _filteredData = _dolarData.where((d) => popularTypes.contains(d.casa.toLowerCase())).toList();
        break;
    }
  }

  // MARK: - Cache
  Future<void> _saveToCache() async {
    try {
      final dataToCache = _dolarData.where((d) => d.casa.toLowerCase() != "tarjeta").toList();
      final encoded = jsonEncode(dataToCache.map((e) => e.toJson()).toList());
      await _prefs.setString(_cacheKey, encoded);
      if (_lastUpdateTime != null) {
        await _prefs.setString(_lastUpdateKey, _lastUpdateTime!.toIso8601String());
      }
    } catch (e) {
      if (kDebugMode) print("Error al guardar cache: $e");
    }
  }

  Future<void> _loadCachedData() async {
    final data = _prefs.getString(_cacheKey);
    if (data == null) return;

    try {
      final List<dynamic> jsonList = jsonDecode(data);
      _dolarData = jsonList.map((e) => DolarDataModel.fromJson(e)).toList();

      final lastUpdateString = _prefs.getString(_lastUpdateKey);
      _lastUpdateTime = lastUpdateString != null ? DateTime.tryParse(lastUpdateString) : null;

      _updateDolarTarjeta();
      _applyFilter();
    } catch (e) {
      if (kDebugMode) print("Error al cargar cache: $e");
      await _prefs.remove(_cacheKey);
      await _prefs.remove(_lastUpdateKey);
    }
  }

  // MARK: - Auto Refresh
  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(_updateInterval, (_) {
      if (shouldRefresh) fetchData();
    });
  }

  // MARK: - Errores
  void _handleError(DolarNetworkError newError) {
    error = newError;
    isLoading = false;
    if (kDebugMode) print("Error: ${newError.errorDescription}");
  }

  DolarNetworkError _getNetworkError(dynamic e) {
    if (e is http.ClientException) return DolarNetworkError.networkError;
    if (e is FormatException) return DolarNetworkError.decodingError;
    return DolarNetworkError.networkError;
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
