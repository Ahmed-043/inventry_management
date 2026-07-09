
import 'package:flutter/cupertino.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

import 'Reports_Data/inventory_movments.dart';


class Product {
  final int id;
  final String name;
  final String? description;
  final String? sku;
  double basePrice;
  final int stock;
  final int sold;
  double weight; // in kg
  final String components;
  final Uint8List? imageData;
  final String? imageType;
  final int? category;
  // ✅ New fields
  double totalPrice;
  double totalWeight;
  bool active;

  Product({
    required this.id,
    required this.name,
    this.description,
    this.sku,
    required this.basePrice,
    required this.stock,
    required this.sold,
    required this.weight,
    required this.components,
    this.imageData,
    this.imageType,
    this.totalPrice = 0.0,
    this.totalWeight = 0.0,
    this.category,
    this.active = true,
  });

  factory Product.fromMap(Map<String, Object?> map) {
    return Product(
      id: map['id'] as int,
      name: map['name'] as String,
      description: map['description'] as String?,
      sku: map['sku'] as String?,
      basePrice: (map['base_price'] as num).toDouble(),
      stock: map['stock'] as int,
      sold: map['sold'] as int,
      weight: (map['weight'] as num).toDouble(),
      components: map['components'] as String,
      imageData: map['image'] as Uint8List?,
      category: map['category'] as int?,
      active: map['active'] == 1 || map['active'] == true,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'sku': sku,
      'base_price': basePrice,
      'stock': stock,
      'sold': sold,
      'weight': weight,
      'components': components,
      'image': imageData,
      'category': category,
      'active': active,
    };
  }
}

Future<List<Product>> getProductsPage(
    Database db,
    int page,
    int pageSize,
    bool withoutImage, {
      String? search,
      List<int>? IDS,
      int lowerLimit = 0,
      int? upperLimit,
      int sortMode = 0,         // 0–10 product sorting
      int categorySortMode = 0, // 0=no sort, 1=sequence ASC, 2=sequence DESC
      bool active = true,
      bool allProducts = false,
    }) async
{
  final offset = page * pageSize;

  String whereClause = '';
  List<dynamic> whereArgs = [];

  // ---------------- SEARCH ----------------
  if (search != null && search.trim().isNotEmpty) {
    final normalizedSearch =
    search.replaceAll(RegExp(r'[\s-]'), '').toLowerCase();

    whereClause += '''
      (LOWER(REPLACE(REPLACE(name, ' ', ''), '-', '')) LIKE ? OR
       LOWER(REPLACE(REPLACE(sku, ' ', ''), '-', '')) LIKE ? OR
       LOWER(REPLACE(REPLACE(description, ' ', ''), '-', '')) LIKE ?)
    ''';

    whereArgs.addAll([
      '%$normalizedSearch%',
      '%$normalizedSearch%',
      '%$normalizedSearch%',
    ]);
  }
  // ---------------- Active products FILTER ----------------

    whereClause += '${whereClause.isEmpty ? '' : ' AND '}active = ${active ? '1' : '0'}';


  // ---------------- STOCK FILTER ----------------
  if (upperLimit != null) {
    whereClause +=
    '${whereClause.isEmpty ? '' : ' AND '}stock BETWEEN ? AND ?';
    whereArgs.addAll([lowerLimit, upperLimit]);
  } else {
    whereClause += '${whereClause.isEmpty ? '' : ' AND '}stock >= ?';
    whereArgs.add(lowerLimit);
  }

  // ---------------- IDS FILTER ----------------
  if (IDS != null && IDS.isNotEmpty) {
    final placeholders = List.filled(IDS.length, '?').join(',');
    whereClause +=
        (whereClause.isEmpty ? '' : ' AND ') + 'id IN ($placeholders)';
    whereArgs.addAll(IDS);
  }

  // ---------------- ORDER BY ----------------
  List<String> orderParts = [];

  // 1️⃣ Category sorting (group categorized first)
  if (categorySortMode != 0) {
    // categorized first, uncategorized last
    orderParts.add('(category IS NULL OR category = 0) ASC');

    orderParts.add('''
      (SELECT sequence
       FROM categories
       WHERE categories.id = products.category)
      ${categorySortMode == 1 ? 'ASC' : 'DESC'}
    ''');
  }

  // 2️⃣ Product sorting
  String productSort;
  switch (sortMode) {
    case 1:
      productSort = 'base_price ASC';
      break;
    case 2:
      productSort = 'base_price DESC';
      break;
    case 3:
      productSort = 'stock ASC';
      break;
    case 4:
      productSort = 'stock DESC';
      break;
    case 5:
      productSort = 'weight ASC';
      break;
    case 6:
      productSort = 'weight DESC';
      break;
    case 7:
      productSort = 'name ASC';
      break;
    case 8:
      productSort = 'name DESC';
      break;
    case 9:
      productSort = 'id ASC';
      break;
    case 10:
      productSort = 'id DESC';
      break;
    default:
      productSort = 'id DESC';
  }

  orderParts.add(productSort);

  final orderBy = orderParts.join(', ');

  // ---------------- QUERY ----------------
  final result = await db.query(
    'products',
    columns: withoutImage
        ? [
      'id',
      'name',
      'description',
      'sku',
      'base_price',
      'stock',
      'sold',
      'weight',
      'components',
      'category',
    ]
        : null,
    where: whereClause.isEmpty ? null : whereClause,
    whereArgs: whereArgs.isEmpty ? null : whereArgs,
    limit: allProducts ? null : pageSize,
    offset: allProducts ? null : offset,
    orderBy: orderBy,
  );

  final products = result.map((row) => Product.fromMap(row)).toList();

  // ---------------- POST PROCESSING ----------------
  final productBasics = await getTotal(db);

  for (var product in products) {
    final totals =
    calculateComponentTotalsForOne(product.components, productBasics);

    product.totalPrice =
        product.basePrice + (totals['totalPrice'] ?? 0.0);

    product.totalWeight =
        product.weight + (totals['totalWeight'] ?? 0.0);
  }

  return products;
}



Future<Product?> getProductById(Database db, int id, {bool withoutImage = true}) async {
  final result = await db.query(
    'products',
    columns: (withoutImage)
        ? ['id', 'name', 'description', 'sku', 'base_price', 'stock', 'sold', 'weight', 'components']
        : null, // null = all columns, including image
    where: 'id = ?',
    whereArgs: [id],
    limit: 1,
  );

  if (result.isEmpty) return null;

  final product = Product.fromMap(result.first);

  // Fetch basics once to calculate totals
  final productBasics = await getTotal(db);

  final totals = calculateComponentTotalsForOne(product.components, productBasics);
  product.totalPrice = product.basePrice + (totals['totalPrice'] ?? 0.0);
  product.totalWeight = product.weight + (totals['totalWeight'] ?? 0.0);

  return product;
}

Future<List<Product>> getProductsByIds(
     List<int> ids,Database db, {bool withoutImage = true}) async {
  if (ids.isEmpty) return [];

  final result = await db.query(
    'products',
    columns: (withoutImage)
        ? ['id', 'name', 'description', 'sku', 'base_price', 'stock', 'sold', 'weight', 'components']
        : null,
    where: 'id IN (${List.filled(ids.length, '?').join(', ')})',
    whereArgs: ids,
  );

  if (result.isEmpty) return [];

  final productBasics = await getTotal(db);

  return result.map((row) {
    final product = Product.fromMap(row);
    final totals =
    calculateComponentTotalsForOne(product.components, productBasics);
    product.totalPrice = product.basePrice + (totals['totalPrice'] ?? 0.0);
    product.totalWeight = product.weight + (totals['totalWeight'] ?? 0.0);
    return product;
  }).toList();
}

Future<Map<String, int>> getStockSummary(int lowLimit, Database db) async {
  final all = await db.rawQuery('SELECT stock, active FROM products');

  int getStock(Map<String, dynamic> p) =>
      (p['stock'] is int) ? p['stock'] as int : int.tryParse(p['stock'].toString()) ?? 0;

  bool isActive(Map<String, dynamic> p) {
    final a = p['active'];
    if (a is int) return a == 1;
    if (a is bool) return a;
    return true; // Default to active if null or missing
  }

  int total = all.length;
  int inStock = all.where((p) => isActive(p) && getStock(p) > lowLimit).length;
  int lowStock = all.where((p) => isActive(p) && getStock(p) > 0 && getStock(p) <= lowLimit).length;
  int outOfStock = all.where((p) => isActive(p) && getStock(p) == 0).length;
  int inactive = all.where((p) => !isActive(p)).length;

  return {
    'all': total,
    'inStock': inStock,
    'lowStock': lowStock,
    'outOfStock': outOfStock,
    'inactive': inactive,
  };
}


class ProductBasic {
  final int id;
  final String? name;
  final String? sku;
  final double? weight;
  final double? price;
  final Uint8List? image;
  final String? components;
  ProductBasic({required this.id, this.name, this.sku, this.weight,this.price,this.image,this.components});

  factory ProductBasic.fromMap(Map<String, dynamic> map) {
    return ProductBasic(
      id: map['id'] as int,
      name: map['name'] as String?,
      sku: map['sku'] as String?,
      weight: map['weight'] as double,
      price: map['base_price'] as double,
      image: map['image'] as Uint8List?,
      components:(map['components'] as String?) ?? '',
    );
  }
}

Future<List<Product>> getProductIds(Database db) async {
  final rows = await db.query(
    'products',
    columns: ['id', 'name', 'sku','weight','base_price','image'],
    orderBy: 'id ASC',
  );

  return rows.map((row) => Product.fromMap(row)).toList();
}

Future<List<ProductBasic>> getTotal(Database db) async {
  final rows = await db.query(
    'products',
    columns: ['id', 'weight','base_price','components'],
    orderBy: 'id ASC',
  );

  return rows.map((row) => ProductBasic.fromMap(row)).toList();
}


Map<String, double> calculateComponentTotalsForOne(
    String? components,
    List<ProductBasic> productBasics,
    ) {
  double totalPrice = 0;
  double totalWeight = 0;

  if (components == null || components.isEmpty) {
    return {'totalPrice': 0, 'totalWeight': 0};
  }

  bool addComponents(String comps, Set<int> path) {
    final ids = comps.split(',').map((e) => int.tryParse(e.trim())).whereType<int>();
    for (final id in ids) {
      if (path.contains(id)) {
        debugPrint('Overflow error with product ID: $id');
        return false; // actual circular reference
      }

      final comp = productBasics.firstWhere(
            (p) => p.id == id,
        orElse: () => ProductBasic(id: -1, price: 0, weight: 0, components: ''),
      );

      if (comp.id != -1) {
        totalPrice += comp.price ?? 0;
        totalWeight += comp.weight ?? 0;

        if (comp.components != null && comp.components!.isNotEmpty) {
          final newPath = {...path, id}; // create path copy for this branch
          if (!addComponents(comp.components!, newPath)) return false;
        }
      }
    }
    return true;
  }

  final ok = addComponents(components, {});
  if (!ok) return {'totalPrice': 0, 'totalWeight': 0};

  return {'totalPrice': totalPrice, 'totalWeight': totalWeight};
}

Future<bool> insertProduct({
  required Database db,
  required String name,
  required double basePrice,
  String? description,
  String? sku,
  int stock = 0,
  int sold = 0,
  double weight = 0.0,
  Uint8List? image,
  String components = '',
  int category = 0,
  bool active = true,
}) async {
  int id = 0;

  try {
    await db.transaction((txn) async {
      id = await txn.insert(
        'products',
        {
          'name': name,
          'description': description,
          'sku': sku,
          'base_price': basePrice,
          'stock': stock,
          'sold': sold,
          'weight': weight,
          'components': components,
          'image': image,
          'category': category,
          'active': active ? 1 : 0,
        },
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    });
    if(id > 0) {
      final movement = InventoryMovement(
        productId: id,
        movementType: 'Stock Adjustment',
        quantityChange: 0,
        stockBefore: stock,
        stockAfter: stock,
        unitCost: basePrice,
        unitPrice: basePrice.round(),
        totalValue: (stock * basePrice).round(),
        timestamp: DateTime.now().millisecondsSinceEpoch,
        remark: 'New Product',
      );

      await db.insert('inventory_movements', movement.toMap());
    }
    return true;
  } catch (e) {
    if (e is DatabaseException) {
      debugPrint("DB error: ${e.result}");
    } else {
      debugPrint("Error: $e");
    }
    return false;
  }
}

img.Image? decodeImageBytes(Uint8List bytes) {
  return img.decodeImage(bytes);
}