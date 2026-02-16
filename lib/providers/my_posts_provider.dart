import 'package:flutter/material.dart';
import '../models/item_model.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';

class MyPostsProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final StorageService _storageService = StorageService();

  List<ItemModel> _myItems = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasLoaded = false;

  List<ItemModel> get myItems => _myItems;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasLoaded => _hasLoaded;

  List<ItemModel> get lostItems =>
      _myItems.where((item) => item.itemType == ItemType.lost).toList();

  List<ItemModel> get foundItems =>
      _myItems.where((item) => item.itemType == ItemType.found).toList();

  Future<void> fetchMyPosts(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _myItems = await _databaseService.getUserItems(userId).first;
      _hasLoaded = true;
    } catch (e) {
      _errorMessage = e.toString();
      _hasLoaded = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deletePost(String itemId, String? imageUrl) async {
    try {
      await _databaseService.deleteItem(itemId);
      if (imageUrl != null && imageUrl.isNotEmpty) {
        await _storageService.deleteImage(imageUrl);
      }
      _myItems.removeWhere((item) => item.itemId == itemId);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updatePostStatus(String itemId, ItemStatus status) async {
    try {
      await _databaseService.updateItemStatus(itemId, status);
      final index = _myItems.indexWhere((item) => item.itemId == itemId);
      if (index != -1) {
        _myItems[index] = _myItems[index].copyWith(status: status);
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  void clearErrors() {
    _errorMessage = null;
    notifyListeners();
  }
}
