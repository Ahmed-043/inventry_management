import 'package:inventry_management/Database/retrieve_products.dart';
import 'package:inventry_management/Database/Reports_Data/inventory_movments.dart';
import 'package:sqflite/sqflite.dart';
import '../database.dart';

class StockSnapshotRow {
  final int productId;
  final String productName;
  final String? sku;
  final int lowStockLimit;
  final List<DayStockInfo> dailyStock;
  final double currentStock;

  StockSnapshotRow({
    required this.productId,
    required this.productName,
    this.sku,
    required this.lowStockLimit,
    required this.dailyStock,
    required this.currentStock,
  });
}

class DayStockInfo {
  final DateTime date;
  final double stockAtEnd;
  final double sold;
  final double purchased;
  final double adjustment;

  DayStockInfo({
    required this.date,
    required this.stockAtEnd,
    required this.sold,
    required this.purchased,
    required this.adjustment,
  });
}

/// Represents a product category
class Category {
  final int id;
  final String name;

  Category({
    required this.id,
    required this.name,
  });
}

Future<List<StockSnapshotRow>> getStockSnapshotMatrix(Database db, {DateTime? startDate, DateTime? endDate, String searchString = '', int? categoryId}) async {
  // 1. Get filtered active products
  String whereClause = 'active = 1';
  List<dynamic> whereArgs = [];

  if (categoryId != null) {
    whereClause += ' AND category = ?';
    whereArgs.add(categoryId);
  }

  if (searchString.isNotEmpty) {
    whereClause += ' AND name LIKE ?';
    whereArgs.add('%$searchString%');
  }

  final productRows = await db.query(
    'products',
    columns: ['id', 'name', 'sku', 'stock'],
    where: whereClause,
    whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
    orderBy: 'name ASC',
  );

  if (productRows.isEmpty) return [];

  final List<int> productIds = productRows.map((row) => row['id'] as int).toList();
  final String idPlaceholders = List.filled(productIds.length, '?').join(',');

  final start = startDate ?? DateTime.now().subtract(const Duration(days: 4));
  final end = endDate ?? DateTime.now();

  // Normalize dates
  final normalizedStart = DateTime(start.year, start.month, start.day);
  final normalizedEnd = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);

  final int daysCount = normalizedEnd.difference(normalizedStart).inDays + 1;
  final List<DateTime> days = List.generate(daysCount, (i) {
    return normalizedStart.add(Duration(days: i));
  });

  final startTs = normalizedStart.millisecondsSinceEpoch;
  final endTs = normalizedEnd.millisecondsSinceEpoch;

  // 2. Get the latest movement before the start date for these products to get starting stock
  // Efficient query to get the last stock_after for each product before the range
  final startingMovements = await db.rawQuery('''
    SELECT product_id, stock_after 
    FROM inventory_movements 
    WHERE id IN (
      SELECT MAX(id) 
      FROM inventory_movements 
      WHERE timestamp < ? AND product_id IN ($idPlaceholders)
      GROUP BY product_id
    )
  ''', [startTs, ...productIds]);

  Map<int, double> productStartingStock = {};
  for (var row in startingMovements) {
    productStartingStock[row['product_id'] as int] = (row['stock_after'] as num).toDouble();
  }

  // 3. Get all movements within the range for these products
  final movementsInRange = await db.query(
    'inventory_movements',
    where: 'timestamp BETWEEN ? AND ? AND product_id IN ($idPlaceholders)',
    whereArgs: [startTs, endTs, ...productIds],
    orderBy: 'timestamp ASC, id ASC',
  );

  // Group movements by product and then by day index
  Map<int, Map<int, List<Map<String, dynamic>>>> movementsByProductAndDay = {};

  for (var m in movementsInRange) {
    final pId = m['product_id'] as int;
    final ts = m['timestamp'] as int;
    final mDate = DateTime.fromMillisecondsSinceEpoch(ts);
    final normalizedMDate = DateTime(mDate.year, mDate.month, mDate.day);
    final dayIndex = normalizedMDate.difference(normalizedStart).inDays;

    if (dayIndex >= 0 && dayIndex < daysCount) {
      movementsByProductAndDay.putIfAbsent(pId, () => {});
      movementsByProductAndDay[pId]!.putIfAbsent(dayIndex, () => []);
      movementsByProductAndDay[pId]![dayIndex]!.add(m);
    }
  }

  List<StockSnapshotRow> matrix = [];

  for (final pRow in productRows) {
    final productId = pRow['id'] as int;
    final productName = pRow['name'] as String;
    final sku = pRow['sku'] as String?;
    final currentStock = (pRow['stock'] as num).toDouble();

    double rollingStock = productStartingStock[productId] ?? 0;
    List<DayStockInfo> dailyInfo = [];

    final productMovements = movementsByProductAndDay[productId] ?? {};

    for (int i = 0; i < daysCount; i++) {
      final dayMovements = productMovements[i] ?? [];
      
      double sold = 0;
      double purchased = 0;
      double adjustment = 0;

      if (dayMovements.isNotEmpty) {
        for (final m in dayMovements) {
          final type = m['movement_type'] as String;
          final change = (m['quantity_change'] as num).toDouble();
          
          if (type == 'Sale' || type == 'Sales Return') {
            sold += change.abs();
          } else if (type == 'Purchase' || type == 'Purchase Return') {
            purchased += change.abs();
          } else {
            adjustment += change;
          }
        }
        // Stock at end of day is the stock_after of the last movement of the day
        rollingStock = (dayMovements.last['stock_after'] as num).toDouble();
      }

      dailyInfo.add(DayStockInfo(
        date: days[i],
        stockAtEnd: rollingStock,
        sold: sold,
        purchased: purchased,
        adjustment: adjustment,
      ));
    }

    matrix.add(StockSnapshotRow(
      productId: productId,
      productName: productName,
      sku: sku,
      lowStockLimit: lowStockLimit,
      dailyStock: dailyInfo,
      currentStock: currentStock,
    ));
  }

  return matrix;
}

class ProductStockValue {
  final int productId;
  final double stock;
  final double basePrice;
  final double totalValue;

  ProductStockValue({
    required this.productId,
    required this.stock,
    required this.basePrice,
    required this.totalValue,
  });
}

Future<List<ProductStockValue>> getProductStockValues(Database db, {String searchString = ''}) async {
  // Fetch products (using page 0 to get the first set of products)
  final products = await getProductsPage(db, 0, productsPerPage ?? 10000, true,
      allProducts: true, search: searchString);

  // Map to ProductStockValue and calculate totalValue
  return products.map((product) {
    return ProductStockValue(
      productId: product.id,
      stock: product.stock.toDouble(),
      basePrice: product.totalPrice,
      totalValue: product.stock * product.totalPrice,
    );
  }).toList();
}

Future<List<InventoryMovement>> getProductMovementsForDate(
  Database db, {
  required int productId,
  required DateTime date,
}) async {
  final start = DateTime(date.year, date.month, date.day);
  final end = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

  final rows = await db.query(
    'inventory_movements',
    where: 'product_id = ? AND timestamp BETWEEN ? AND ?',
    whereArgs: [productId, start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
    orderBy: 'timestamp ASC, id ASC',
  );

  return rows.map((row) => InventoryMovement.fromMap(row)).toList();
}

