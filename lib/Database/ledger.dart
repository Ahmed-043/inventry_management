
import 'package:sqflite/sqflite.dart';

class LedgerHelper {
  /// Adds a ledger entry for a transaction.
  /// Handles both debit and credit entries.
  /// Ensures no duplicates for the same transaction_id and entry_type.
  static Future<void> syncTransactionToLedger(
    Transaction txn, {
    required int personId,
    required int transactionId,
    int? orderId,
    String source = '',
    required double targetAmount,
    required String entryType, // 'debit' or 'credit'
    required String remark,
  }) async {
    if (targetAmount.abs() < 0.01) return;

    // 1. Get existing sum for this transaction and type in the ledger
    // We always check the real transactionId to maintain sync integrity
    final sumResult = await txn.rawQuery(
      'SELECT SUM(amount) as total FROM ledger WHERE transaction_id = ? AND entry_type = ?',
      [transactionId, entryType],
    );
    double existingAmount = (sumResult.first['total'] as num?)?.toDouble() ?? 0.0;

    double amountToAdd = targetAmount.abs() - existingAmount;

    // Only add if there's a significant new amount
    if (amountToAdd < 0.01) return;

    // 2. Get the latest balance for this person
    final latestEntry = await txn.query(
      'ledger',
      columns: ['balance'],
      where: 'person_id = ?',
      whereArgs: [personId],
      orderBy: 'id DESC',
      limit: 1,
    );

    double previousBalance = 0;
    if (latestEntry.isNotEmpty) {
      previousBalance = (latestEntry.first['balance'] as num).toDouble();
    }

    // 3. New Balance Calculation:
    // new balance = previous balance + debit - credit
    double newBalance;
    if (entryType == 'debit') {
      newBalance = previousBalance + amountToAdd;
    } else {
      newBalance = previousBalance - amountToAdd;
    }

    // 4. Insert the ledger entry
    await txn.insert('ledger', {
      'person_id': personId,
      'transaction_id': transactionId,
      'order_id': orderId ?? 0,
      'source': source,
      'timestamp': DateTime.now().millisecondsSinceEpoch, // Record current time
      'entry_type': entryType,
      'amount': amountToAdd,
      'balance': 0, // No longer using this for view; balances calculated on the fly
      'remark': remark,
    });
  }

  /// Processes a payment transaction record and creates the appropriate ledger entries.
  /// Should be called after any insert or update to payment_transactions.
  static Future<void> processPaymentTransaction(
    Transaction txn,
    int transactionId, {
    String source = 'transaction', // Default source is transaction page
  }) async {
    final rows = await txn.query(
      'payment_transactions',
      where: 'id = ?',
      whereArgs: [transactionId],
      limit: 1,
    );

    if (rows.isEmpty) return;
    final trans = rows.first;

    final personId = trans['person_id'] as int;
    final orderId = trans['order_id'] as int?;
    final totalAmount = (trans['amount'] as num).toDouble();
    final paidAmount = (trans['paid_amount'] as num).toDouble();
    final String remark = trans['remark'] as String? ?? '';
    final String method = trans['payment_method'] as String? ?? 'Cash';
    final bool isFullPayment = paidAmount.abs() >= totalAmount.abs() && totalAmount != 0;
    final bool isOrder = source == 'order' || (orderId != null && orderId != 0);

    // Case 1: The transaction represents a debt (Sale/Purchase or Incoming/Outgoing)
    if (totalAmount != 0) {
      String typeStr = '';
      if (isOrder) {
        typeStr = totalAmount > 0 ? 'Sale' : 'Purchase';
      } else {
        typeStr = totalAmount > 0 ? 'Incoming' : 'Outgoing';
      }
      
      String orderStr = (orderId != null && orderId != 0) ? ' (#$orderId)' : '';

      // Construct a descriptive auto-remark if the user left it empty
      String autoRemark = '';
      if (isFullPayment) {
        autoRemark = '$typeStr$orderStr';
      } else if (paidAmount == 0) {
        autoRemark = 'Credit $typeStr$orderStr';
      } else {
        autoRemark = '$typeStr$orderStr';
      }

      final String finalRemark = remark.isEmpty ? autoRemark : remark;

      if (totalAmount > 0) {
        await syncTransactionToLedger(
          txn,
          personId: personId,
          transactionId: transactionId,
          orderId: orderId,
          source: source,
          targetAmount: totalAmount,
          entryType: 'debit',
          remark: finalRemark,
        );
      } else {
        await syncTransactionToLedger(
          txn,
          personId: personId,
          transactionId: transactionId,
          orderId: orderId,
          source: source,
          targetAmount: totalAmount.abs(),
          entryType: 'credit',
          remark: finalRemark,
        );
      }
    }

    // Case 2: The transaction represents a payment (Initial or Standalone)
    if (paidAmount != 0) {
      String payType = paidAmount > 0 ? 'Payment Received' : 'Payment Made';
      String methodStr = ' ($method)';
      String orderStr = (orderId != null && orderId != 0) ? ' for #$orderId' : '';

      // If user provided a remark, we append the payment details for clarity.
      String finalRemark = '';
      if (remark.isNotEmpty) {
        if (totalAmount != 0) {
          // It's a dual entry (Deal + Payment). Keep payment remark focused.
          finalRemark = 'Payment: $remark $methodStr';
        } else {
          // Just a payment entry.
          finalRemark = remark.contains(payType) ? remark : '$remark - $payType$methodStr';
        }
      } else {
        finalRemark = '$payType$methodStr$orderStr';
      }

      if (paidAmount > 0) {
        await syncTransactionToLedger(
          txn,
          personId: personId,
          transactionId: transactionId,
          orderId: orderId,
          source: source,
          targetAmount: paidAmount,
          entryType: 'credit',
          remark: finalRemark,
        );
      } else {
        await syncTransactionToLedger(
          txn,
          personId: personId,
          transactionId: transactionId,
          orderId: orderId,
          source: source,
          targetAmount: paidAmount.abs(),
          entryType: 'debit',
          remark: finalRemark,
        );
      }
    }
  }

  static Future<List<Map<String, dynamic>>> getLedgerEntries(
    Database db, {
    required int personId,
    int? startDate,
    int? endDate,
  }) async {
    final whereClauses = <String>['person_id = ?'];
    final whereArgs = <dynamic>[personId];

    if (startDate != null) {
      whereClauses.add('timestamp >= ?');
      whereArgs.add(startDate);
    }
    if (endDate != null) {
      whereClauses.add('timestamp <= ?');
      whereArgs.add(endDate);
    }

    return await db.query(
      'ledger',
      where: whereClauses.join(' AND '),
      whereArgs: whereArgs,
      orderBy: 'timestamp ASC, id ASC',
    );
  }

  /// Calculates the opening balance for a person before a specific timestamp.
  static Future<double> getOpeningBalance(
    Database db, {
    required int personId,
    required int timestamp,
  }) async {
    final result = await db.rawQuery(
      '''SELECT SUM(CASE WHEN entry_type = 'debit' THEN amount ELSE -amount END) as balance 
         FROM ledger 
         WHERE person_id = ? AND timestamp < ?''',
      [personId, timestamp],
    );
    return (result.first['balance'] as num?)?.toDouble() ?? 0.0;
  }
}
