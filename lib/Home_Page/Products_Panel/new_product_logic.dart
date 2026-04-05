import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:inventry_management/Database/database.dart';
import 'package:inventry_management/Database/retrieve_products.dart';

import '../../Database/category.dart';



class InputNewProductController extends ChangeNotifier {
  // Controllers
  final name = TextEditingController();
  final price = TextEditingController();
  final stock = TextEditingController();
  final weight = TextEditingController();
  final sku = TextEditingController();
  final desc = TextEditingController();
  final categoryController = TextEditingController();

  // State
  bool isLoading = false;
  Uint8List? image;
  Map<int, int> compQuantities = {};
  List<Product> compProducts = [];
  List<DBCategory> categories = [];
  int? selectedCategoryId;
  bool showAddCategoryIcon = false;
  final Map<int, bool> blinkMap = {};

  InputNewProductController() {
    categoryController.addListener(_onCategoryTextChanged);
  }

  @override
  void dispose() {
    [name, price, stock, weight, desc, sku, categoryController].forEach((c) => c.dispose());
    super.dispose();
  }

  // Load categories from database
  Future<void> loadCategories() async {
    final result = await currentDB!.query('categories', orderBy: 'sequence ASC, name ASC');
    categories = result.map((row) => DBCategory.fromMap(row)).toList();
    notifyListeners();
  }

  // Handle category text change
  void _onCategoryTextChanged() {
    final text = categoryController.text.trim();
    final exists = categories.any((c) => c.name.toLowerCase() == text.toLowerCase());
    final hasSelectedMatch = selectedCategoryId != null &&
        categories.any((c) => c.id == selectedCategoryId && c.name == text);

    showAddCategoryIcon = text.isNotEmpty && !exists && !hasSelectedMatch;
    if (!hasSelectedMatch) selectedCategoryId = null;
    notifyListeners();
  }

  // Add new category
  Future<String?> addNewCategory(String categoryName) async {
    try {
      final maxSeq = await currentDB!.rawQuery('SELECT MAX(sequence) as maxSeq FROM categories');
      final nextSequence = ((maxSeq.first['maxSeq'] as int?) ?? 0) + 1;

      final id = await currentDB!.insert('categories', {
        'name': categoryName,
        'sequence': nextSequence,
      });

      await loadCategories();
      selectedCategoryId = id;
      showAddCategoryIcon = false;
      notifyListeners();

      return 'Category "$categoryName" created!';
    } catch (e) {
      return 'Failed to create category: $e';
    }
  }

  // Select category
  void selectCategory(int? categoryId) {
    selectedCategoryId = categoryId;
    if (categoryId != null) {
      final cat = categories.firstWhere((c) => c.id == categoryId);
      categoryController.text = cat.name;
      showAddCategoryIcon = false;
    }
    notifyListeners();
  }

  // Update image
  void updateImage(Uint8List? newImage) {
    image = newImage;
    notifyListeners();
  }

  // Sync component quantities
  void syncComponentQuantities() {
    compQuantities.removeWhere((id, _) => !compProducts.any((p) => p.id == id));
    for (var p in compProducts) {
      compQuantities.putIfAbsent(p.id, () => 1);
    }
    notifyListeners();
  }

  // Update component quantity
  void updateComponentQuantity(int productId, int quantity) {
    compQuantities[productId] = quantity;
    notifyListeners();
  }

  // Remove component
  void removeComponent(int index) {
    final productId = compProducts[index].id;
    compQuantities.remove(productId);
    compProducts.removeAt(index);
    notifyListeners();
  }

  // Calculate totals
  Map<String, double> calculateTotals() {
    double totalPrice = double.tryParse(price.text) ?? 0;
    double totalWeight = double.tryParse(weight.text) ?? 0;

    for (var p in compProducts) {
      final qty = compQuantities[p.id] ?? 1;
      totalPrice += p.totalPrice * qty;
      totalWeight += p.weight * qty;
    }

    return {"price": totalPrice, "weight": totalWeight};
  }

  // Round to two decimals
  double _roundToTwoDecimals(double value) {
    return (value * 100).roundToDouble() / 100;
  }

  // Build components string
  String _buildComponentsString() => compQuantities.entries
      .where((e) => e.value > 0)
      .expand((e) => List.filled(e.value, e.key.toString()))
      .join(',');

  // Validate and save product
  Future<String?> saveProduct() async {
    isLoading = true;
    notifyListeners();

    // Validation
    if (name.text.isEmpty) {
      isLoading = false;
      notifyListeners();
      return "The product name cannot be empty!";
    }

    final qty = int.tryParse(stock.text);
    if (qty != null && qty > 9007199254740991) {
      isLoading = false;
      notifyListeners();
      return "Quantity is too large!";
    }

    final wt = double.tryParse(weight.text);
    if (wt != null && wt > 9007199254740991) {
      isLoading = false;
      notifyListeners();
      return "Weight is too large!";
    }

    // Insert product
    final success = await insertProduct(
      db: currentDB!,
      name: name.text,
      basePrice: _roundToTwoDecimals(double.tryParse(price.text) ?? 0.0),
      stock: int.tryParse(stock.text) ?? 0,
      weight: _roundToTwoDecimals(double.tryParse(weight.text) ?? 0.0),
      sku: sku.text.isEmpty ? null : sku.text,
      description: desc.text,
      image: image,
      components: _buildComponentsString(),
      category: selectedCategoryId ?? 0,
    );

    isLoading = false;
    notifyListeners();

    if (!success) {
      return "The given SKU already exists!";
    }

    return null; // Success
  }

  // Set blink state
  void setBlinkState(int index, bool state) {
    blinkMap[index] = state;
    notifyListeners();
  }
}