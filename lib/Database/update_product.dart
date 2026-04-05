import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:inventry_management/Database/retrieve_products.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> updateProduct({
  required Database db,
  required int id,
  required String name,
  required double price,
  required int stock,
  required double weight,
  required String description,
  required int category,
  Uint8List? image,
}) async {
  try {
    await db.update(
      'products',
      {
        'name': name,
        'base_price': price,
        'stock': stock,
        'weight': weight,
        'description': description,
        'image': image,
        'category': category,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    debugPrint("Product with id=$id updated successfully");
  } catch (e) {
    debugPrint("Update error: $e");
  }
}

Future<List<Product>> getImmediateComponentsFromDB(
    Database db, int productId) async {
  // 1️⃣ Get the main product's components string
  final productQuery = await db.query(
    'products',
    columns: ['components'],
    where: 'id = ?',
    whereArgs: [productId],
    limit: 1,
  );

  if (productQuery.isEmpty) return [];

  final componentsStr = productQuery.first['components'] as String?;
  if (componentsStr == null || componentsStr.trim().isEmpty) return [];

  // 2️⃣ Parse immediate component IDs
  final ids = componentsStr
      .split(',')
      .map((e) => int.tryParse(e.trim()))
      .whereType<int>()
      .toList();

  if (ids.isEmpty) return [];

  // 3️⃣ Fetch all products to calculate hierarchical totals
  final allRows = await db.query(
    'products',
    columns: ['id', 'name', 'base_price', 'weight', 'components', 'description', 'sku', 'stock', 'sold', 'image'],
  );

  final allProducts = allRows.map((e) => ProductBasic.fromMap(e)).toList();

  // 4️⃣ Fetch immediate component products and calculate totals
  final placeholders = List.filled(ids.length, '?').join(',');
  final componentQuery = await db.query(
    'products',
    where: 'id IN ($placeholders)',
    whereArgs: ids,
  );


  List<Product> components = [];
  for (final compMap in componentQuery) {
    final p = Product.fromMap(compMap);

    // calculate hierarchical totals using your ProductBasic list
    final totals = calculateComponentTotalsForOne(p.components, allProducts);
    p.totalPrice = (p.basePrice) + totals['totalPrice']!;
    p.totalWeight = (p.weight) + totals['totalWeight']!;

    components.add(p);
  }

  return components;
}

Future<bool> safeDelete(Database db, int productId) async {
  final result = await db.rawQuery(
    '''
    SELECT 1
    FROM products
    WHERE components IS NOT NULL
      AND components != ''
      AND (
        components = ?
        OR components LIKE ?
        OR components LIKE ?
        OR components LIKE ?
      )
    LIMIT 1
    ''',
    [
      productId.toString(),          // exact match
      '$productId,%',                // at start
      '%,$productId',                // at end
      '%,$productId,%',              // in middle
    ],
  );

  return result.isEmpty; // true = safe to delete
}

Future<String> getDirectParentNames(Database db, int productId) async {
  final rows = await db.rawQuery(
    '''
    SELECT name
    FROM products
    WHERE components IS NOT NULL
      AND components != ''
      AND (
        components = ?
        OR components LIKE ?
        OR components LIKE ?
        OR components LIKE ?
      )
    ''',
    [
      productId.toString(),
      '$productId,%',
      '%,$productId',
      '%,$productId,%',
    ],
  );

  if (rows.isEmpty) return '';

  return rows
      .map((e) => e['name'] as String)
      .join(', ');
}


