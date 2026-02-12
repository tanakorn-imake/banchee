// lib/data/services/sync_service.dart

import 'package:cloud_functions/cloud_functions.dart';
import '../models/transaction_model.dart';
import 'database_helper.dart';

class SyncService {
  // เรียกใช้ Cloud Functions โซนเอเชีย (ตามที่ตั้งค่าใน Firebase)
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'asia-southeast1');
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // ==========================================
  // ⬆️ PUSH: ส่งข้อมูลขึ้น (Manual)
  // ==========================================
  Future<Map<String, dynamic>> pushTransactions() async {
    try {
      // 1. ดึงรายการที่ยังไม่ได้ Sync จากเครื่องเรา
      final unsyncedTxns = await _dbHelper.getUnsyncedTransactions();

      if (unsyncedTxns.isEmpty) {
        return {'success': true, 'count': 0, 'message': 'ไม่มีรายการใหม่ให้ส่ง'};
      }

      // 2. แปลงข้อมูลโดยใช้ Model Helper (ปลอดภัยกว่าเขียนเอง)
      List<Map<String, dynamic>> payload = unsyncedTxns
          .map((txn) => txn.toCloudJson())
          .toList();

      // 3. ยิง API 'sync_push'
      final callable = _functions.httpsCallable('sync_push');
      await callable.call({
        'transactions': payload,
      });

      // 4. Mark ว่า Sync แล้ว
      for (var txn in unsyncedTxns) {
        await _dbHelper.markAsSynced(txn.id);
      }

      print("✅ Push Success: ${unsyncedTxns.length} items");
      return {'success': true, 'count': unsyncedTxns.length};

    } catch (e) {
      print("❌ Sync Push Error: $e");
      return {'success': false, 'message': e.toString()};
    }
  }

  // ==========================================
  // ⬇️ PULL: ดึงข้อมูลลง (Auto)
  // ==========================================
  Future<Map<String, dynamic>> pullTransactions() async {
    try {
      // 1. ยิง API 'sync_pull'
      final callable = _functions.httpsCallable('sync_pull');
      final result = await callable.call();

      // รับข้อมูลกลับมา
      final data = result.data as Map<dynamic, dynamic>;
      final List<dynamic> transactions = data['transactions'] ?? [];

      if (transactions.isEmpty) {
        print("✅ Pull Success: No new items");
        return {'success': true, 'count': 0, 'message': 'ไม่มีรายการใหม่'};
      }

      int saveCount = 0;

      // 2. วนลูปบันทึกลงเครื่อง
      for (var json in transactions) {
        try {
          // แปลง JSON จาก Server กลับเป็น TransactionModel ด้วย Helper
          final txn = TransactionModel.fromCloudJson(Map<String, dynamic>.from(json));

          if (txn.isDeleted) {
            // ถ้าเป็นคำสั่งลบ
            await _dbHelper.deleteTransaction(txn.id);
          } else {
            // บันทึก หรือ อัปเดต (Upsert)
            await _dbHelper.saveTransactionFromCloud(txn);
          }
          saveCount++;

        } catch (e) {
          print("⚠️ Error parsing transaction: $e");
          // ข้ามรายการที่พัง ไปทำรายการถัดไป
        }
      }

      print("✅ Pull Success: Saved $saveCount items");
      return {'success': true, 'count': saveCount};

    } catch (e) {
      print("❌ Sync Pull Error: $e");
      return {'success': false, 'message': e.toString()};
    }
  }
}