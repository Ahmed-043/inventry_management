import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';

import '../Home_Page/Dashboard_Panel/info_chip.dart';
import 'database.dart';

class SalesData {
  final String label;
  final double total;
  SalesData(this.label, this.total);
}


String formatLargeNumber(num value) {
  final n = value.abs();
  if (n >= 1e12) return '${(n / 1e12).toStringAsFixed(2)}T';
  if (n >= 1e9) return '${(n / 1e9).toStringAsFixed(2)}B';
  if (n >= 1e6) return '${(n / 1e6).toStringAsFixed(2)}M';
  if (n >= 1e3) return '${(n / 1e3).toStringAsFixed(2)}K';
  return n.toStringAsFixed(0);
}

Future<List<ChipData>> loadDashboardChipData(
  Database db,
  int startTimestamp,
  int endTimestamp, {
  String msg = 'from selected period',
}) async {
  int i(Object? o) => (o as num?)?.toInt() ?? 0;
  double d(Object? o) => (o as num?)?.toDouble() ?? 0.0;

  final r = (await db.rawQuery(
    '''
    SELECT
      (SELECT COUNT(*) FROM orders WHERE order_type='sell' AND order_status!='Canceled') AS salesAll,
      (SELECT COUNT(*) FROM orders WHERE order_type='sell' AND order_status!='Canceled' AND order_timestamp BETWEEN ? AND ?) AS salesPeriod,
      (SELECT COUNT(*) FROM orders WHERE order_type='buy' AND order_status!='Canceled') AS purchaseAll,
      (SELECT COUNT(*) FROM orders WHERE order_type='buy' AND order_status!='Canceled' AND order_timestamp BETWEEN ? AND ?) AS purchasePeriod,

      (SELECT SUM(amount) FROM payment_transactions WHERE amount>0) AS incomeAll,
      (SELECT SUM(amount) FROM payment_transactions WHERE amount>0 AND timestamp BETWEEN ? AND ?) AS incomePeriod,
      (SELECT SUM(amount) FROM payment_transactions WHERE amount<0) AS outAll,
      (SELECT SUM(amount) FROM payment_transactions WHERE amount<0 AND timestamp BETWEEN ? AND ?) AS outPeriod,

      (SELECT COUNT(*) FROM orders WHERE order_status IN ('Pending','Overdue')) AS pendingOrdersAll,
      (SELECT COUNT(*) FROM orders WHERE order_status IN ('Pending','Overdue') AND order_timestamp BETWEEN ? AND ?) AS pendingOrdersPeriod,
      (SELECT COUNT(*) FROM payment_transactions WHERE payment_status IN ('Pending','Overdue')) AS pendingTxnAll,
      (SELECT COUNT(*) FROM payment_transactions WHERE payment_status IN ('Pending','Overdue') AND timestamp BETWEEN ? AND ?) AS pendingTxnPeriod,

      (SELECT COUNT(*) FROM products WHERE stock < ? AND stock > 0) AS lowStock,
      (SELECT COUNT(*) FROM products WHERE stock = 0) AS OutOfStock,
      (SELECT COUNT(*) FROM products) AS allStock,
      (SELECT COUNT(*) FROM products WHERE stock >= ? ) AS inStock

  ''',
    [
      startTimestamp,
      endTimestamp,
      startTimestamp,
      endTimestamp,
      startTimestamp,
      endTimestamp,
      startTimestamp,
      endTimestamp,
      startTimestamp,
      endTimestamp,
      startTimestamp,
      endTimestamp,
      lowStockLimit,
      lowStockLimit,
    ],
  )).first;

  final salesAll = i(r['salesAll']);
  final salesPeriod = i(r['salesPeriod']);
  final purchaseAll = i(r['purchaseAll']);
  final purchasePeriod = i(r['purchasePeriod']);

  final incomeAll = d(r['incomeAll']);
  final incomePeriod = d(r['incomePeriod']);
  final outAll = d(r['outAll']);
  final outPeriod = d(r['outPeriod']);

  final pendingOrdersAll = i(r['pendingOrdersAll']);
  final pendingOrdersPeriod = i(r['pendingOrdersPeriod']);
  final pendingTxnAll = i(r['pendingTxnAll']);
  final pendingTxnPeriod = i(r['pendingTxnPeriod']);

  final lowStock = i(r['lowStock']);
  final outOfStock = i(r['OutOfStock']);
  final inStock = i(r['inStock']);
  final allStock = i(r['allStock']);

  return [
    ChipData(
      title: 'Total Income',
      prefix: 'Rs. ',
      value: incomeAll.abs(),
      trend: incomePeriod.abs(),
      trendText: '${formatLargeNumber(incomePeriod.abs())} $msg',
    ),
    ChipData(
      title: 'Total Purchase',
      prefix: 'Rs. ',
      value: outAll.abs(),
      trend: outPeriod.abs(),
      trendText: '${formatLargeNumber(outPeriod.abs())} $msg',
    ),
    ChipData(
      title: 'Total Sales',
      prefix: 'Orders: ',
      value: salesAll.toDouble(),
      trend: salesPeriod.toDouble(),
      trendText: '${formatLargeNumber(salesPeriod)} $msg',
    ),
    ChipData(
      title: 'Total Purchase',
      prefix: 'Orders: ',
      value: purchaseAll.toDouble(),
      trend: purchasePeriod.toDouble(),
      trendText: '${formatLargeNumber(purchasePeriod)} $msg',
    ),
    ChipData(
      title: 'Pending',
      prefix: 'Orders: ',
      value: pendingOrdersAll.toDouble(),
      trend: pendingOrdersPeriod.toDouble(),
      trendText: '${formatLargeNumber(pendingOrdersPeriod)} $msg',
    ),
    ChipData(
      title: 'Pending',
      prefix: 'Payments: ',
      value: pendingTxnAll.toDouble(),
      trend: pendingTxnPeriod.toDouble(),
      trendText: '${formatLargeNumber(pendingTxnPeriod)} $msg',
    ),
    ChipData(
      title: 'Low Stock',
      prefix: 'Items: ',
      value: lowStock.toDouble(),
      trend: inStock.toDouble(),
      trendText: '$inStock Items in Good Stock',
    ),
    ChipData(
      title: 'Out of Stock',
      prefix: 'Items: ',
      value: outOfStock.toDouble(),
      trend: allStock.toDouble(),
      trendText: '$allStock Total Items',
    ),
  ];
}


/// Monthly Sale , Purchases
Future<List<SalesData>> getMonthlySales({
  required Database db,
  required int startTimestamp,
  required int endTimestamp,
  final bool sales = true,
}) async {
  DateTime start = DateTime.fromMillisecondsSinceEpoch(startTimestamp);
  DateTime end = DateTime.fromMillisecondsSinceEpoch(endTimestamp);
  start = DateTime(start.year, start.month);
  end = DateTime(end.year, end.month + 1).subtract(const Duration(milliseconds: 1));

  int totalMonths = (end.year - start.year) * 12 + (end.month - start.month) + 1;

  // Fetch totals per month
  final rows = await db.rawQuery('''
  SELECT strftime('%Y-%m', datetime(order_timestamp / 1000, 'unixepoch')) AS ym,
         SUM(total_amount) AS total
  FROM orders
  WHERE order_status != 'Canceled'
    AND order_type = ?
    AND order_timestamp BETWEEN ? AND ?
  GROUP BY ym
''', [
    sales ? 'sell' : 'buy',
    start.millisecondsSinceEpoch,
    end.millisecondsSinceEpoch,
  ]);


  Map<String, double> dbData = {
    for (var row in rows)
      row['ym'] as String:
      ((row['total'] as num?)?.toDouble().abs() ?? 0.0)
  };


  List<SalesData> result = [];

  for (int i = 0; i < totalMonths; i++) {
    final year = start.year + (start.month - 1 + i) ~/ 12;
    final month = (start.month - 1 + i) % 12 + 1;
    final key = '$year-${month.toString().padLeft(2, '0')}';
    final total = (dbData[key] ?? 0.0).abs();

    String label = DateFormat('MMM').format(DateTime(year, month));

    // Add year tag at the first month of the range and at every January
    if (i == 0 || month == 1) {
      label += '\n$year';
    }

    result.add(SalesData(label, total));
  }
//print(result[0].label);
  return result;
}

/// Daily Sale , Purchase
Future<List<SalesData>> getDailyPayments({
  required Database db,
  required int startTimestamp,
  required int endTimestamp,
  required bool positiveOnly,
}) async {
  DateTime start = DateTime.fromMillisecondsSinceEpoch(startTimestamp);
  DateTime end = DateTime.fromMillisecondsSinceEpoch(endTimestamp);

  start = DateTime(start.year, start.month, start.day);
  end = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);

  int totalDays = end.difference(start).inDays + 1;

  final rows = await db.rawQuery('''
    SELECT strftime('%Y-%m-%d', datetime(timestamp / 1000, 'unixepoch')) AS yd,
           SUM(ABS(amount)) AS total
    FROM payment_transactions
    WHERE payment_status = 'Paid'
      AND timestamp BETWEEN ? AND ?
      AND amount ${positiveOnly ? '>= 0' : '< 0'}
    GROUP BY yd
  ''', [
    start.millisecondsSinceEpoch,
    end.millisecondsSinceEpoch,
  ]);

  Map<String, double> dbData = {
    for (var row in rows)
      row['yd'] as String: ((row['total'] as num?)?.toDouble() ?? 0.0)
  };

  List<SalesData> result = [];

  for (int i = 0; i < totalDays; i++) {
    final date = start.add(Duration(days: i));
    final key = DateFormat('yyyy-MM-dd').format(date);
    final total = dbData[key] ?? 0.0;

    final label = DateFormat('MMM\ndd').format(date);

    result.add(SalesData(label, total.abs()));
  }

  return result;
}



/// Monthly Income, Expenses
Future<List<SalesData>> getMonthlyPayments({
  required Database db,
  required int startTimestamp,
  required int endTimestamp,
  required bool positiveOnly, // true = +values only, false = -values only
}) async {
  DateTime start = DateTime.fromMillisecondsSinceEpoch(startTimestamp);
  DateTime end = DateTime.fromMillisecondsSinceEpoch(endTimestamp);
  start = DateTime(start.year, start.month);
  end = DateTime(end.year, end.month + 1).subtract(const Duration(milliseconds: 1));

  int totalMonths = (end.year - start.year) * 12 + (end.month - start.month) + 1;

  // Fetch totals per month based on flag
  final rows = await db.rawQuery('''
    SELECT strftime('%Y-%m', datetime(timestamp / 1000, 'unixepoch')) AS ym,
           SUM(ABS(amount)) AS total
    FROM payment_transactions
    WHERE payment_status = 'Paid'
      AND timestamp BETWEEN ? AND ?
      AND amount ${positiveOnly ? '>= 0' : '< 0'}
    GROUP BY ym
  ''', [
    start.millisecondsSinceEpoch,
    end.millisecondsSinceEpoch,
  ]);

  Map<String, double> dbData = {
    for (var row in rows)
      row['ym'] as String: ((row['total'] as num?)?.toDouble() ?? 0.0)
  };

  List<SalesData> result = [];

  for (int i = 0; i < totalMonths; i++) {
    final year = start.year + (start.month - 1 + i) ~/ 12;
    final month = (start.month - 1 + i) % 12 + 1;
    final key = '$year-${month.toString().padLeft(2, '0')}';
    final total = dbData[key] ?? 0.0;

    String label = DateFormat('MMM').format(DateTime(year, month));
    if (i == 0 || month == 1) {
      label += '\n$year';
    }

    result.add(SalesData(label, total.abs()));
  }

  return result;
}


/// Transaction Info Values
Future<List<SalesData>> getPaymentStatusSalesData(
    Database db,
    {bool positiveAmounts = true,}
    ) async {
  final signCondition = positiveAmounts ? '> 0' : '< 0';

  final result = await db.rawQuery('''
    SELECT payment_status, COUNT(*) AS total
    FROM payment_transactions
    WHERE amount $signCondition
    GROUP BY payment_status
  ''');

  double paid = 0, pending = 0, overdue = 0;

  for (final row in result) {
    final status = row['payment_status'] as String;
    final count = (row['total'] as int).toDouble();

    if (status == 'Paid') paid = count;
    if (status == 'Pending') pending = count;
    if (status == 'Overdue') overdue = count;
  }

  return [
    SalesData('Paid', paid),
    SalesData('Pending', pending),
    SalesData('Overdue', overdue),
  ];
}

/// Orders Info Values
Future<List<SalesData>> getOrderStatusSalesData(
    Database db, {
      required bool sale, // true = 'sell', false = 'buy'
    }) async {
  final orderType = sale ? 'sell' : 'buy';

  final result = await db.rawQuery('''
    SELECT order_status, COUNT(*) AS total
    FROM orders
    WHERE order_type = ?
    GROUP BY order_status
  ''', [orderType]);

  double completed = 0, pending = 0,canceled = 0;

  for (final row in result) {
    final status = row['order_status'] as String;
    final count = (row['total'] as int).toDouble();

    if (status == 'Completed') completed = count;
    if (status == 'Pending') pending = count;
    if (status == 'Canceled') canceled = count;
  }

  return [
    SalesData('Completed', completed),
    SalesData('Pending', pending),
    SalesData('Canceled', canceled),
  ];
}


Future<List<SalesData>> getTop10MostSold(Database db) async {
  final result = await db.rawQuery('''
    SELECT name, sold
    FROM products
    WHERE sold > 0
    ORDER BY sold DESC
    LIMIT 10
  ''');

  return result.map((row) {
    final name = (row['name'] as String)
        .trim()
        .split(RegExp(r'\s+'))
        .take(3)
        .join(' ');
    return SalesData(name, (row['sold'] as num).toDouble());
  }).toList();
}

Future<double> getTotalUnpaidAmount(Database db) async {
  final result = await db.rawQuery(
      '''
    SELECT SUM(amount - paid_amount) AS total
    FROM payment_transactions
    WHERE payment_status != 'Paid'
    '''
  );

  final value = result.first['total'];
  return (value as num?)?.toDouble() ?? 0.0;
}

