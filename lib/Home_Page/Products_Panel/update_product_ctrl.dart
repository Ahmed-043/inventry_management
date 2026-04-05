import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:inventry_management/Database/database.dart';
import 'package:inventry_management/Database/retrieve_products.dart';
import 'package:inventry_management/Database/update_product.dart';
import 'package:inventry_management/Database/delete.dart';

import '../../Database/category.dart';

class UpdateProductController extends ChangeNotifier {
  final Product product;

  // Controllers
  late final TextEditingController name;
  late final TextEditingController price;
  late final TextEditingController stock;
  late final TextEditingController weight;
  late final TextEditingController desc;
  final categoryController = TextEditingController();

  // State
  bool isLoading = false;
  Uint8List? image;
  List<Product> compProducts = [];
  Map<int, int> compQuantities = {};
  List<DBCategory> categories = [];
  int? selectedCategoryId;

  UpdateProductController(this.product) {
    name = TextEditingController(text: product.name);
    price = TextEditingController(text: product.basePrice.toStringAsFixed(2));
    stock = TextEditingController(text: product.stock.toString());
    weight = TextEditingController(text: product.weight.toStringAsFixed(2));
    desc = TextEditingController(text: product.description ?? '');

    image = product.imageData;
    selectedCategoryId = product.category == 0 ? null : product.category;

    // IMPORTANT: This triggers the UI to check "showAddCategoryIcon" on every keystroke
    categoryController.addListener(() {
      notifyListeners();
    });

    _loadComponents();
    _loadCategories();
  }
  @override
  void dispose() {
    [name, price, stock, weight, desc, categoryController].forEach((c) => c.dispose());
    super.dispose();
  }

  // Load categories from database
  Future<void> _loadCategories() async {
    final result = await currentDB!.query('categories', orderBy: 'sequence ASC, name ASC');
    categories = result.map((row) => DBCategory.fromMap(row)).toList();

    // Set initial category text
    if (selectedCategoryId != null) {
      final cat = categories.where((c) => c.id == selectedCategoryId).firstOrNull;
      if (cat != null) {
        categoryController.text = cat.name;
      }
    }

    notifyListeners();
  }

  // Load components
  Future<void> _loadComponents() async {
    compProducts = await getImmediateComponentsFromDB(currentDB!, product.id);

    product.components
        .split(',')
        .map((e) => int.tryParse(e.trim()))
        .whereType<int>()
        .forEach((id) => compQuantities[id] = (compQuantities[id] ?? 0) + 1);

    notifyListeners();
  }

  // Select category
  void selectCategory(int? categoryId) {
    selectedCategoryId = categoryId;
    if (categoryId != null) {
      final cat = categories.firstWhere((c) => c.id == categoryId);
      categoryController.text = cat.name;
    }
    notifyListeners();
  }

  // Update image
  void updateImage(Uint8List? newImage) {
    image = newImage;
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

  // Validate and update product
// Inside UpdateProductController...

  Future<String?> updateProductData() async {
    isLoading = true;
    notifyListeners();

    // --- ADD THIS CHECK HERE ---
    // If the user cleared the text, force the category to 0 (Null)
    if (categoryController.text.trim().isEmpty) {
      selectedCategoryId = 0;
    }
    // ---------------------------

    // Validation
    if (name.text.isEmpty) {
      isLoading = false;
      notifyListeners();
      return "The product name cannot be empty!";
    }

    // ... (keep your existing Stock/Weight validation code) ...

    // Update product in DB
    await updateProduct(
      db: currentDB!,
      id: product.id,
      name: name.text,
      price: _roundToTwoDecimals(double.tryParse(price.text) ?? 0.0),
      stock: int.tryParse(stock.text) ?? 0,
      weight: _roundToTwoDecimals(double.tryParse(weight.text) ?? 0.0),
      description: desc.text,
      image: image,
      category: selectedCategoryId ?? 0, // This will now be 0 if text was empty
    );

    isLoading = false;
    notifyListeners();
    return null;
  }

  // Check if product can be safely deleted
  Future<bool> canDelete() async {
    return await safeDelete(currentDB!, product.id);
  }

  // Get parent products
  Future<String> getParentProducts() async {
    return await getDirectParentNames(currentDB!, product.id);
  }

  // Delete product
  Future<void> deleteProductData() async {
    await deleteProduct(currentDB!, product.id);
  }

  // Getter: Show icon only if text doesn't match an existing category exactly
  bool get showAddCategoryIcon {
    final text = categoryController.text.trim().toLowerCase();
    if (text.isEmpty) return false;
    // Hide icon if the typed text perfectly matches an existing category name
    return !categories.any((c) => c.name.toLowerCase() == text);
  }

  // Function: Add new category to DB and refresh list
  Future<String?> addNewCategory(String name) async {
    try {
      // 1. Get the current max sequence to put the new one at the end
      final result = await currentDB!.rawQuery('SELECT MAX(sequence) as maxSeq FROM categories');
      int nextSeq = (result.first['maxSeq'] as int? ?? 0) + 1;

      // 2. Insert into database
      final id = await currentDB!.insert('categories', {
        'name': name,
        'sequence': nextSeq,
      });

      // 3. Update local state
      final newCategory = DBCategory(id: id, name: name, sequence: nextSeq);
      categories.add(newCategory);
      categories.sort((a, b) => (a.sequence ?? 0).compareTo(b.sequence ?? 0));

      // 4. Auto-select the newly created category
      selectedCategoryId = id;
      categoryController.text = name;

      notifyListeners();
      return "Category '$name' added successfully!";
    } catch (e) {
      return "Error adding category: $e";
    }
  }
}