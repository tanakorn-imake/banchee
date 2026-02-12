// lib/data/services/database_helper.dart

import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/transaction_model.dart';
import '../models/recurring_bill_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  static const String _dbName = 'banchee.db';
  // ✅ อัปเกรดเป็น Version 5 เพื่อรองรับคอลัมน์ recipientName (ชื่อผู้รับโอน)
  static const int _dbVersion = 5;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(_dbName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  // สร้าง Database สำหรับผู้ใช้ใหม่ (Version 5 Structure)
  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const textNullable = 'TEXT';
    const boolType = 'INTEGER NOT NULL';
    const doubleType = 'REAL NOT NULL';
    const intType = 'INTEGER NOT NULL';

    // 1. Transactions Table
    await db.execute('''
    CREATE TABLE transactions (
      id $idType,
      amount $doubleType,
      date $textType,
      category $textType,
      note $textType,
      receiptPath $textNullable,
      tag $textNullable,
      creatorId $textNullable,
      payerName $textType,
      recipientName $textNullable, 
      deviceId $textType,
      isSplitBill $boolType,
      splitWith $textType,
      isSynced $boolType,
      isDeleted $boolType,
      lastUpdated $textType
    )
    ''');

    // 2. Recurring Table
    await db.execute('''
    CREATE TABLE recurring_bills (
      id $idType,
      title $textType,
      amount $doubleType,
      dayOfMonth $intType,
      isPaid $boolType
    )
    ''');

    // 3. Categories Table
    await db.execute('''
    CREATE TABLE categories (
      id $idType,
      name $textType,
      iconCode $intType,
      colorValue $intType
    )
    ''');

    // 4. Tags Table
    await db.execute('''
    CREATE TABLE tags (
      id $idType,
      name $textType
    )
    ''');
  }

  // ระบบอัปเกรดฐานข้อมูลแบบ Step-by-Step
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print("🔄 Upgrading DB from $oldVersion to $newVersion");

    if (oldVersion < 2) {
      await db.execute('CREATE TABLE IF NOT EXISTS tags (id TEXT PRIMARY KEY, name TEXT NOT NULL)');
      try { await db.execute('ALTER TABLE transactions ADD COLUMN tag TEXT'); } catch (e) { print(e); }
    }
    if (oldVersion < 3) {
      try { await db.execute('ALTER TABLE transactions ADD COLUMN creatorId TEXT'); } catch (e) { print(e); }
    }
    if (oldVersion < 4) {
      try { await db.execute('ALTER TABLE transactions ADD COLUMN isDeleted INTEGER DEFAULT 0'); } catch (e) { print(e); }
      try { await db.execute('ALTER TABLE transactions ADD COLUMN isSynced INTEGER DEFAULT 0'); } catch (e) { print(e); }
      try { await db.execute('ALTER TABLE transactions ADD COLUMN lastUpdated TEXT'); } catch (e) { print(e); }
    }
    // ✅ V4 -> V5: เพิ่มคอลัมน์ recipientName สำหรับจดจำผู้รับโอน
    if (oldVersion < 5) {
      try {
        await db.execute('ALTER TABLE transactions ADD COLUMN recipientName TEXT');
        print("✅ Added recipientName column successfully");
      } catch (e) {
        print("Add recipientName error: $e");
      }
    }
  }

  // ====================================================
  // 💰 SMART MAPPING (FIXED)
  // ====================================================

  // ค้นหาหมวดหมู่และแท็กล่าสุดจากชื่อผู้รับ
  Future<Map<String, String?>> getLastMappingByRecipient(String name) async {
    final db = await instance.database;
    final result = await db.query(
      'transactions',
      columns: ['category', 'tag'],
      where: 'recipientName = ? AND isDeleted = 0',
      whereArgs: [name], // ✅ แก้ไข: ใส่ whereArgs ให้ถูกต้อง
      orderBy: 'date DESC',
      limit: 1,
    );

    if (result.isNotEmpty) {
      return {
        'category': result.first['category'] as String?,
        'tag': result.first['tag'] as String?,
      };
    }
    return {'category': null, 'tag': null};
  }

  // ====================================================
  // 💰 TRANSACTIONS CRUD
  // ====================================================

  Future<void> createTransaction(TransactionModel txn) async {
    final db = await instance.database;
    await db.insert('transactions', txn.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<TransactionModel?> readTransaction(String id) async {
    final db = await instance.database;
    final maps = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return TransactionModel.fromMap(maps.first);
    }
    return null;
  }

  Future<List<TransactionModel>> getAllTransactions() async {
    final db = await instance.database;
    final result = await db.query('transactions', where: 'isDeleted = 0', orderBy: 'date DESC');
    return result.map((json) => TransactionModel.fromMap(json)).toList();
  }

  Future<List<TransactionModel>> getTransactionsByMonth(int month, int year) async {
    final db = await instance.database;
    String monthStr = month.toString().padLeft(2, '0');
    String target = '$year-$monthStr-';
    final result = await db.query(
      'transactions',
      where: 'isDeleted = 0 AND date LIKE ?',
      whereArgs: ['$target%'],
      orderBy: 'date DESC',
    );
    return result.map((json) => TransactionModel.fromMap(json)).toList();
  }

  Future<List<TransactionModel>> getTransactionsByYear(int year) async {
    final db = await instance.database;
    String target = '$year-';
    final result = await db.query(
      'transactions',
      where: 'isDeleted = 0 AND date LIKE ?',
      whereArgs: ['$target%'],
      orderBy: 'date DESC',
    );
    return result.map((json) => TransactionModel.fromMap(json)).toList();
  }

  Future<List<TransactionModel>> getAllSplitTransactions() async {
    final db = await instance.database;
    final result = await db.query(
      'transactions',
      where: 'isDeleted = 0 AND isSplitBill = 1',
      orderBy: 'date DESC',
    );
    return result.map((json) => TransactionModel.fromMap(json)).toList();
  }

  Future<int> updateTransaction(TransactionModel txn) async {
    final db = await instance.database;
    final map = txn.toMap();
    map['lastUpdated'] = DateTime.now().toIso8601String();
    map['isSynced'] = 0;
    return db.update('transactions', map, where: 'id = ?', whereArgs: [txn.id]);
  }

  Future<int> deleteTransaction(String id) async {
    final db = await instance.database;
    return db.update(
      'transactions',
      {
        'isDeleted': 1,
        'isSynced': 0,
        'lastUpdated': DateTime.now().toIso8601String()
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ====================================================
  // 🔄 SYNC HELPERS
  // ====================================================

  Future<List<TransactionModel>> getUnsyncedTransactions() async {
    final db = await instance.database;
    final result = await db.query('transactions', where: 'isSynced = 0');
    return result.map((json) => TransactionModel.fromMap(json)).toList();
  }

  Future<void> markAsSynced(String id) async {
    final db = await instance.database;
    await db.update('transactions', {'isSynced': 1}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> saveTransactionFromCloud(TransactionModel txn) async {
    final db = await instance.database;
    final existing = await db.query('transactions', where: 'id = ?', whereArgs: [txn.id]);

    if (existing.isNotEmpty) {
      final localTxn = TransactionModel.fromMap(existing.first);
      if (localTxn.isSynced == false && localTxn.lastUpdated.isAfter(txn.lastUpdated)) {
        return;
      }
    }
    await db.insert('transactions', txn.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ====================================================
  // 🔁 RECURRING BILLS CRUD
  // ====================================================

  Future<void> createRecurringBill(RecurringBillModel bill) async {
    final db = await instance.database;
    await db.insert('recurring_bills', bill.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<RecurringBillModel>> getAllRecurringBills() async {
    final db = await instance.database;
    final result = await db.query('recurring_bills', orderBy: 'dayOfMonth ASC');
    return result.map((json) => RecurringBillModel.fromMap(json)).toList();
  }

  Future<int> updateRecurringBill(RecurringBillModel bill) async {
    final db = await instance.database;
    return db.update('recurring_bills', bill.toMap(), where: 'id = ?', whereArgs: [bill.id]);
  }

  Future<int> deleteRecurringBill(String id) async {
    final db = await instance.database;
    return db.delete('recurring_bills', where: 'id = ?', whereArgs: [id]);
  }

  // ====================================================
  // 📂 CATEGORIES & TAGS CRUD
  // ====================================================

  Future<List<Map<String, dynamic>>> getCustomCategories() async {
    final db = await instance.database;
    return await db.query('categories');
  }

  Future<void> addCustomCategory(String id, String name, int iconCode, int colorValue) async {
    final db = await instance.database;
    await db.insert('categories', {
      'id': id,
      'name': name,
      'iconCode': iconCode,
      'colorValue': colorValue
    });
  }

  Future<void> deleteCustomCategory(String id) async {
    final db = await instance.database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<String>> getAllTags() async {
    final db = await instance.database;
    final result = await db.query('tags', orderBy: 'name ASC');
    return result.map((json) => json['name'] as String).toList();
  }

  Future<void> addTag(String name) async {
    final db = await instance.database;
    await db.insert('tags', {'id': name, 'name': name}, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> deleteTag(String name) async {
    final db = await instance.database;
    await db.delete('tags', where: 'id = ?', whereArgs: [name]);
  }
}