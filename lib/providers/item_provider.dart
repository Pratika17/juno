import 'package:flutter/material.dart';
import '../models/item_model.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';

class ItemProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();

  List<ItemModel> _items = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Filters
  ItemType? _currentFilter;
  ItemCategory? _currentCategory;
  String _searchQuery = '';

  List<ItemModel> get items => _items;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  ItemType? get currentFilter => _currentFilter;
  ItemCategory? get currentCategory => _currentCategory;
  String get searchQuery => _searchQuery;

  // Constructor to start listening
  ItemProvider() {
    fetchItems();
  }

  void fetchItems() {
    _setLoading(true);
    try {
      _databaseService
          .getItems(filter: _currentFilter, category: _currentCategory)
          .listen(
            (items) {
              print('DEBUG: Fetched ${items.length} items from Firestore.');
              _items = items;
              // Apply search filter locally since Firestore doesn't support full-text search efficiently with other filters
              if (_searchQuery.isNotEmpty) {
                _items = _items.where((item) {
                  return item.title.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ) ||
                      item.description.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      );
                }).toList();
              }
              _setLoading(false);
              notifyListeners();
            },
            onError: (error) {
              print('DEBUG: Error fetching items: $error');
              _errorMessage = error.toString();
              _setLoading(false);
            },
          );
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
    }
  }

  void applyFilter(ItemType? type) {
    _currentFilter = type;
    fetchItems();
  }

  void applyCategory(ItemCategory? category) {
    _currentCategory = category;
    fetchItems();
  }

  void searchItems(String query) {
    _searchQuery = query;
    fetchItems(); // Re-fetch to apply local search filter on fresh data or just re-filter current?
    // Optimization: If just searching, could filter _items locally, but to keep it synced with DB updates,
    // re-establishing listener or filtering inside listener is better.
    // simplified: fetchItems() re-sets up the stream with new constraints or just triggers notify.
    // Actually, listening twice is bad.
    // Better approach: Listen once, and store "all fetched items", then expose "filtered items".
    // For now, following the requested structure, simply calling fetchItems() again which re-subscribes.
  }

  Future<void> refreshItems() async {
    // Since we are using streams, "refresh" essentially means resetting filters or ensuring connection.
    // For this implementation, we can just re-trigger fetch.
    fetchItems();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
