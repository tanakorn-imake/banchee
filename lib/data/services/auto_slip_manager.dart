// lib/data/services/auto_slip_manager.dart

import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../models/transaction_model.dart';
import 'database_helper.dart';

class SlipCandidate {
  final AssetEntity asset;
  final String bankName;

  SlipCandidate({required this.asset, required this.bankName});
}

class AutoSlipManager {
  static const String _prefLastCheckKey = "last_slip_auto_scan_time";

  // Mapping ชื่ออัลบั้มรูปภาพ -> ชื่อธนาคาร
  static const Map<String, String> _bankMapping = {
    "K PLUS": "KBank",
    "SCB EASY": "SCB",
    "Krungthai NEXT": "KTB",
    "BualuangM": "BBL",
    "KMA": "Krungsri",
    "ttb touch": "TTB",
    "MyMo": "GSB",
  };

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// ค้นหารูปภาพสลิปใหม่ๆ จากอัลบั้มธนาคาร
  Future<List<SlipCandidate>> scanForNewSlips() async {
    // ขอ Permission เข้าถึงรูปภาพ
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (!ps.isAuth && ps != PermissionState.limited) return [];

    final prefs = await SharedPreferences.getInstance();
    // เช็คครั้งล่าสุดเมื่อไหร่ (ถ้าไม่มีให้ย้อนหลัง 14 วัน)
    int lastCheckTime = prefs.getInt(_prefLastCheckKey) ??
        DateTime.now().subtract(const Duration(days: 14)).millisecondsSinceEpoch;

    DateTime checkSince = DateTime.fromMillisecondsSinceEpoch(lastCheckTime);
    // DateTime checkSince = DateTime(2025, 1, 1); // บรรทัดนี้สำหรับ Debug เท่านั้น

    List<SlipCandidate> foundSlips = [];

    // ดึงอัลบั้มทั้งหมด
    final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(type: RequestType.image);

    for (var album in albums) {
      // ถ้าชื่ออัลบั้มตรงกับ App ธนาคารที่เรา Map ไว้
      if (_bankMapping.containsKey(album.name)) {
        // ดึงรูป 50รูปล่าสุดมาเช็ค (เพื่อความเร็ว)
        final List<AssetEntity> photos = await album.getAssetListRange(start: 0, end: 50);
        for (var photo in photos) {
          // ถ้าเป็นรูปใหม่กว่าเวลาที่เช็คครั้งล่าสุด
          if (photo.createDateTime.isAfter(checkSince)) {
            foundSlips.add(SlipCandidate(asset: photo, bankName: _bankMapping[album.name]!));
          }
        }
      }
    }

    // เรียงตามเวลาเก่าไปใหม่
    foundSlips.sort((a, b) => a.asset.createDateTime.compareTo(b.asset.createDateTime));
    return foundSlips;
  }

  /// ประมวลผลสลิปด้วย ML Kit OCR และบันทึกลง Database
  Future<int> processAndSaveSlips(List<SlipCandidate> slips, {Function(int current, int total)? onProgress}) async {
    if (slips.isEmpty) return 0;

    final prefs = await SharedPreferences.getInstance();
    final String deviceId = prefs.getString('device_id') ?? 'unknown_device';
    final String payerName = prefs.getString('user_name') ?? 'Me';

    int savedCount = 0;
    int current = 0;

    // เตรียมตัวอ่านข้อความ OCR
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      for (var slip in slips) {
        current++;
        if (onProgress != null) onProgress(current, slips.length);

        try {
          final File? file = await slip.asset.file;
          if (file != null) {

            // เช็คว่าไฟล์นี้เคย import ไปแล้วหรือยัง (ดูจากวันที่สร้างรูป)
            if (await _isDuplicate(file.path, slip.asset.createDateTime)) {
              continue;
            }

            debugPrint("📌 [Process ML Kit] Reading Slip (${slip.bankName})");

            final inputImage = InputImage.fromFilePath(file.path);
            final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

            String rawText = recognizedText.text;

            // --- Log เพื่อ Debug ---
            // debugPrint("📝 [RAW TEXT] ${rawText.substring(0, min(100, rawText.length))}...");

            // 1. ดึงยอดเงิน (ใช้ Logic หาเลขทศนิยม 2 ตำแหน่งที่มากที่สุด)
            double? amount = _extractAmount(rawText);

            // 2. ดึงชื่อผู้รับ (ถ้าทำได้)
            String? recipient = _extractRecipient(rawText);

            // 3. ใช้วันที่ของรูปภาพเป็นวันที่ทำรายการ
            DateTime txDate = slip.asset.createDateTime;

            debugPrint("💰 Extracted Amount: $amount, Recipient: $recipient");

            if (amount != null) {
              String category = "รายจ่าย";
              String? tag;

              // 4. Smart Mapping: ถ้ามีชื่อผู้รับ ให้ไปดูประวัติว่าเคยลงเป็นหมวดอะไร
              if (recipient != null && recipient.isNotEmpty) {
                final history = await _dbHelper.getLastMappingByRecipient(recipient);
                if (history['category'] != null) {
                  category = history['category']!;
                  tag = history['tag'];
                }
              }

              // ✅ สร้าง TransactionModel (พร้อมแก้ปัญหา ReadOnly)
              final newTxn = TransactionModel(
                id: const Uuid().v4(),
                amount: amount,
                date: txDate,
                category: category,
                note: recipient != null ? "โอนไปยัง $recipient" : "Auto-scan (${slip.bankName})",
                recipientName: recipient, // เก็บชื่อผู้รับไว้ใช้ครั้งหน้า
                receiptPath: file.path,
                tag: tag,

                // ✅✅✅ สำคัญ: ใส่ creatorId เป็น deviceId ของเรา เพื่อให้แก้ไขได้
                creatorId: deviceId,
                payerName: payerName,
                deviceId: deviceId,

                isSplitBill: false,
                isSynced: false,
                isDeleted: false,
              );

              await _dbHelper.createTransaction(newTxn);
              savedCount++;
            }
          }
        } catch (e) {
          debugPrint("❌ Error processing slip: $e");
          continue;
        }
      }
    } finally {
      textRecognizer.close();
    }

    // อัปเดตเวลาเช็คล่าสุด
    await prefs.setInt(_prefLastCheckKey, DateTime.now().millisecondsSinceEpoch);
    return savedCount;
  }

  // ---------------------------------------------------------------------------
  // 💰 Logic ดึงยอดเงิน
  // ---------------------------------------------------------------------------
  double? _extractAmount(String text) {
    // Pattern: จับตัวเลขที่มีทศนิยม 2 ตำแหน่งเท่านั้น (เช่น 100.00, 1,250.50)
    final RegExp moneyRegex = RegExp(r'(\d{1,3}(?:,\d{3})*|\d+)\.(\d{2})');

    Iterable<RegExpMatch> matches = moneyRegex.allMatches(text);
    List<double> candidates = [];

    for (var match in matches) {
      String rawNum = match.group(0)!;
      // ลบลูกน้ำออก
      String cleanNum = rawNum.replaceAll(',', '');
      double? val = double.tryParse(cleanNum);

      // กรอง 0.00 ทิ้ง
      if (val != null && val > 0.00) {
        candidates.add(val);
      }
    }

    if (candidates.isEmpty) return null;

    // เรียงค่าจากน้อยไปมาก
    candidates.sort();

    // ✅ เลือกค่าที่มากที่สุด (สมมติฐาน: ยอดโอนมักจะมากกว่าค่าธรรมเนียม)
    return candidates.last;
  }

  // ---------------------------------------------------------------------------
  // 👤 Logic ดึงชื่อผู้รับ (พอสังเขป)
  // ---------------------------------------------------------------------------
  String? _extractRecipient(String text) {
    // หมายเหตุ: ML Kit Latin อ่านภาษาไทยไม่ค่อยออก ถ้าจะให้อ่านชื่อไทยแม่นๆ
    // อาจต้องใช้ Google Cloud Vision API แทน

    // ลองหาบรรทัดที่มีคำว่า "To", "Mr.", "Ms.", "Mrs." หรือชื่อภาษาอังกฤษ
    final lines = text.split('\n');
    for (int i = 0; i < lines.length; i++) {
      String line = lines[i].trim();

      // ตัวอย่าง Logic ง่ายๆ หาชื่อภาษาอังกฤษหลังคำว่า To
      if (line.toLowerCase().startsWith('to') || line.toLowerCase().startsWith('to:')) {
        String possibleName = line.replaceAll(RegExp(r'(?i)to:?'), '').trim();
        if (_isValidName(possibleName)) return _cleanName(possibleName);

        // หรือถ้าชื่ออยู่อีกบรรทัด
        if (i + 1 < lines.length && _isValidName(lines[i+1])) {
          return _cleanName(lines[i+1]);
        }
      }
    }
    return null;
  }

  bool _isValidName(String text) {
    if (text.length < 3) return false;
    // ต้องไม่มีตัวเลขเยอะเกินไป (กันว่าเป็นเลขบัญชี)
    int digitCount = text.replaceAll(RegExp(r'[^0-9]'), '').length;
    if (digitCount > 3) return false;
    return true;
  }

  String _cleanName(String name) {
    return name.replaceAll(RegExp(r'[0-9xX\*\-]'), '') // ลบเลขและอักขระแปลกๆ
        .replaceAll(RegExp(r'\s+'), ' ') // ลบช่องว่างซ้ำ
        .trim();
  }

  // เช็คว่ารูปนี้เคยบันทึกไปแล้วหรือยัง โดยดูจากเวลาที่รูปถูกสร้าง (แม่นยำกว่าชื่อไฟล์)
  Future<bool> _isDuplicate(String filePath, DateTime date) async {
    final db = await _dbHelper.database;
    final String dateStr = date.toIso8601String();

    // Query ดูว่ามีรายการไหนที่มีวันที่ตรงกันเป๊ะๆ ไหม
    final List<Map<String, dynamic>> res = await db.query(
      'transactions',
      columns: ['id'],
      where: 'date = ? AND isDeleted = 0',
      whereArgs: [dateStr],
      limit: 1,
    );
    return res.isNotEmpty;
  }
}