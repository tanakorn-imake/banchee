import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/services/family_service.dart';

class FamilyProvider extends ChangeNotifier {
  final FamilyService _service = FamilyService();

  // สถานะครอบครัว
  String? familyId;
  String? familyName;
  String? inviteCode;
  String? ownerId;

  // รายชื่อสมาชิก (โหลดมาพร้อมชื่อ)
  List<Map<String, dynamic>> members = [];

  bool isLoading = true;
  StreamSubscription? _userSubscription;
  StreamSubscription? _familySubscription;

  FamilyProvider() {
    _initListener();
  }

  // เริ่มฟังข้อมูล
  void _initListener() {
    // 1. ฟัง User ตัวเองก่อน ว่ามี family_id ไหม
    _userSubscription = _service.streamMyUserDoc().listen((userSnapshot) {
      if (!userSnapshot.exists) return;

      final userData = userSnapshot.data() as Map<String, dynamic>;
      final newFamilyId = userData['family_id'];

      if (newFamilyId != familyId) {
        familyId = newFamilyId;
        if (familyId != null) {
          // ถ้ามีบ้าน -> ไปฟังข้อมูลบ้านต่อ
          _listenToFamily(familyId!);
        } else {
          // ถ้าไม่มีบ้าน (โดนเตะ หรือออกเอง) -> ล้างข้อมูล
          _clearFamilyData();
        }
      } else if (familyId == null) {
        // ไม่มีบ้าน และค่าไม่เปลี่ยน
        isLoading = false;
        notifyListeners();
      }
    });
  }

  void _listenToFamily(String famId) {
    _familySubscription?.cancel();
    _familySubscription = _service.streamFamilyDoc(famId).listen((famSnapshot) async {
      if (!famSnapshot.exists) {
        _clearFamilyData(); // บ้านอาจจะโดนลบไปแล้ว
        return;
      }

      final data = famSnapshot.data() as Map<String, dynamic>;
      familyName = data['name'];
      inviteCode = data['invite_code'];
      ownerId = data['owner_id'];

      // อัปเดตรายชื่อสมาชิก (เอา ID ไปดึงชื่อมา)
      List<String> memberIds = List<String>.from(data['member_ids'] ?? []);
      members = await _service.getMembersProfile(memberIds);

      isLoading = false;
      notifyListeners();
    });
  }

  void _clearFamilyData() {
    familyId = null;
    familyName = null;
    inviteCode = null;
    ownerId = null;
    members = [];
    isLoading = false;
    notifyListeners();
  }

  // ================= Action Methods =================

  Future<void> createFamily(String name) async {
    try {
      await _service.createFamily(name);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> joinFamily(String code) async {
    try {
      await _service.joinFamily(code);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> leaveFamily() async {
    try {
      await _service.removeMember(); // ไม่ส่ง ID = ออกเอง
    } catch (e) {
      rethrow;
    }
  }

  Future<void> kickMember(String uid) async {
    try {
      await _service.removeMember(targetUid: uid);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteFamily() async {
    try {
      await _service.deleteFamily();
    } catch (e) {
      rethrow;
    }
  }

  bool get isOwner => ownerId == _service.currentUid;

  @override
  void dispose() {
    _userSubscription?.cancel();
    _familySubscription?.cancel();
    super.dispose();
  }
}