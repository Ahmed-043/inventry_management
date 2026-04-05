import 'package:flutter/cupertino.dart';
import 'package:sqflite/sqflite.dart';

/// product only
Future<Map<int, int>> getRequiredStockOnlyProducts(
    Map<int, int> orderMap, Database db) async {
  final result = <int, int>{};

  for (final entry in orderMap.entries) {
    final id = entry.key;
    final requiredQty = entry.value;

    final stockData =
    await db.rawQuery('SELECT stock FROM products WHERE id = ?', [id]);
    final available = stockData.isNotEmpty ? stockData.first['stock'] as int : 0;
    final shortage = requiredQty - available;

    if (shortage > 0) result[id] = shortage;
  }

  return result;
}

/// components only
Future<Map<int, int>> getComponentStock(Map<int, int> orderMap, Database db) async {

  final Map<int, int> totalRequired = {};

  for (final entry in orderMap.entries) {
    final productId = entry.key;
    final qty = entry.value;

    final data = await db.rawQuery(
      'SELECT components FROM products WHERE id = ?',
      [productId],
    );
    if (data.isEmpty) continue;

    final components = (data.first['components'] ?? '').toString().trim();
    if (components.isEmpty) continue;

    final compList = components.split(',');
    final Map<int, int> compCount = {};

    for (final comp in compList) {
      final compId = int.tryParse(comp.trim());
      if (compId != null) {
        compCount[compId] = (compCount[compId] ?? 0) + 1;
      }
    }

    // ✅ direct components only
    for (final compEntry in compCount.entries) {
      totalRequired[compEntry.key] =
          (totalRequired[compEntry.key] ?? 0) + compEntry.value * qty;
    }
  }

  // Check shortages
  final Map<int, int> shortage = {};
  for (final entry in totalRequired.entries) {
    final data = await db.rawQuery(
      'SELECT stock FROM products WHERE id = ?',
      [entry.key],
    );
    if (data.isEmpty) continue;

    final stock = data.first['stock'] as int;
    final need = entry.value - stock;
    if (need > 0) shortage[entry.key] = need;
  }

  return shortage;
}

///product with components
Future<Map<int, int>> getRequiredStock(
    Map<int, int> orderMap, Database db) async {
  final Map<int, int> totalRequired = {};

  Future<void> expandProduct(int id, int qty) async {
    final data = await db.rawQuery(
        'SELECT stock, components FROM products WHERE id = ?', [id]);
    if (data.isEmpty) return;

    final components = (data.first['components'] ?? '').toString().trim();
    // Count this product itself too
    totalRequired[id] = (totalRequired[id] ?? 0) + qty;

    // If it has components, go deeper
    if (components.isNotEmpty) {
      final compList = components.split(',');
      final Map<int, int> compCount = {};
      for (final comp in compList) {
        final compId = int.tryParse(comp.trim());
        if (compId != null) {
          compCount[compId] = (compCount[compId] ?? 0) + 1;
        }
      }

      for (final entry in compCount.entries) {
        await expandProduct(entry.key, entry.value * qty);
      }
    }
  }

  for (final entry in orderMap.entries) {
    await expandProduct(entry.key, entry.value);
  }

  // Now check shortages for each collected product id
  final Map<int, int> shortage = {};
  for (final entry in totalRequired.entries) {
    final data =
    await db.rawQuery('SELECT stock FROM products WHERE id = ?', [entry.key]);
    if (data.isEmpty) continue;

    final stock = data.first['stock'] as int;
    final need = entry.value - stock;
    if (need > 0) shortage[entry.key] = need;
  }

  return shortage;
}

///--------

Future<void> updateAndDeductDirectComponentsOnly(
    Map<int, int> orderMap,
    Database db,
    ) async {
  print("DEDUCTING DIRECT COMPONENTS ONLY");

  // Step 1: Check shortages (must already be non-recursive)
  final shortages = await getComponentStock(orderMap, db);
  if (shortages.isNotEmpty) {
    debugPrint('⚠️ Not enough component stock: $shortages');
    return;
  }

  // Step 2: Collect ONLY direct components
  final Map<int, int> componentUsage = {};

  for (final entry in orderMap.entries) {
    final productId = entry.key;
    final productQty = entry.value;

    final data = await db.rawQuery(
      'SELECT components FROM products WHERE id = ?',
      [productId],
    );

    if (data.isEmpty) continue;

    final components = (data.first['components'] ?? '').toString().trim();
    if (components.isEmpty) continue;

    final compList = components.split(',');

    final Map<int, int> compCount = {};
    for (final comp in compList) {
      final compId = int.tryParse(comp.trim());
      if (compId != null) {
        compCount[compId] = (compCount[compId] ?? 0) + 1;
      }
    }

    for (final compEntry in compCount.entries) {
      final compId = compEntry.key;
      final totalQty = compEntry.value * productQty;
      componentUsage[compId] =
          (componentUsage[compId] ?? 0) + totalQty;
    }
  }

  // Step 3: Deduct direct component stock
  for (final entry in componentUsage.entries) {
    await db.rawUpdate(
      'UPDATE products SET stock = stock - ? WHERE id = ?',
      [entry.value, entry.key],
    );
  }

  // Step 4: Add finished product stock
  for (final entry in orderMap.entries) {
    await db.rawUpdate(
      'UPDATE products SET stock = stock + ? WHERE id = ?',
      [entry.value, entry.key],
    );
  }
}


/// checks then deduct components stock and then add main product stock
Future<void> updateAndDeductComponentsOnly(Map<int, int> orderMap, Database db) async {
  print("DEDUCTING");
  // Step 1: Check shortages using your existing function
  final shortages = await getComponentStock(orderMap, db);

  // If there are shortages, stop and print/log them
  if (shortages.isNotEmpty) {
    debugPrint('⚠️ Not enough component stock: $shortages');
    return; // or throw Exception('Insufficient component stock');
  }

  // Step 2: Build a map of all components needed
  final Map<int, int> componentUsage = {};

  Future<void> expandComponents(int id, int qty) async {
    final data = await db.rawQuery(
        'SELECT components FROM products WHERE id = ?', [id]);
    if (data.isEmpty) return;

    final components = (data.first['components'] ?? '').toString().trim();
    if (components.isEmpty) return;

    final compList = components.split(',');
    final Map<int, int> compCount = {};
    for (final comp in compList) {
      final compId = int.tryParse(comp.trim());
      if (compId != null) {
        compCount[compId] = (compCount[compId] ?? 0) + 1;
      }
    }

    for (final entry in compCount.entries) {
      final compId = entry.key;
      final totalQty = entry.value * qty;
      componentUsage[compId] = (componentUsage[compId] ?? 0) + totalQty;
      await expandComponents(compId, totalQty);
    }
  }

  for (final entry in orderMap.entries) {
    await expandComponents(entry.key, entry.value);
  }

  // Step 3: Deduct component stock and add to sold
  for (final entry in componentUsage.entries) {
    await db.rawUpdate(
      'UPDATE products SET stock = stock - ? WHERE id = ?',
      [entry.value, entry.key],
    );
  }

  // Step 4: Add finished quantity to main product
  for (final entry in orderMap.entries) {
    await db.rawUpdate(
      'UPDATE products SET stock = stock + ? WHERE id = ?',
      [entry.value, entry.key],
    );
  }
}


