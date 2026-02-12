import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FamilyService {
  // ✅ Config Region ให้ตรงกับ Server
  FirebaseFunctions get _functions => FirebaseFunctions.instanceFor(region: 'asia-southeast1');
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  String? get currentUid => _auth.currentUser?.uid;

  // ==========================================
  // 1. Action: ยิงคำสั่ง (Cloud Functions)
  // ==========================================

  // สร้างครอบครัว
  Future<Map<String, dynamic>> createFamily(String name) async {
    final result = await _functions.httpsCallable('family_create').call({
      'familyName': name,
    });
    return Map<String, dynamic>.from(result.data);
  }

  // เข้าร่วมด้วย Code
  Future<void> joinFamily(String inviteCode) async {
    await _functions.httpsCallable('family_join').call({
      'inviteCode': inviteCode,
    });
  }

  // ลาออก หรือ เตะสมาชิก (ถ้าส่ง targetUid = เตะ, ไม่ส่ง = ออกเอง)
  Future<void> removeMember({String? targetUid}) async {
    await _functions.httpsCallable('family_removeMember').call({
      'targetUid': targetUid,
    });
  }

  // ยุบครอบครัว
  Future<void> deleteFamily() async {
    await _functions.httpsCallable('family_delete').call();
  }

  // ==========================================
  // 2. Data: ฟังข้อมูล (Firestore Streams)
  // ==========================================

  // ฟังการเปลี่ยนแปลงของ User ตัวเอง (เพื่อดูว่ามี family_id หรือยัง)
  Stream<DocumentSnapshot> streamMyUserDoc() {
    if (currentUid == null) return const Stream.empty();
    return _db.collection('users').doc(currentUid).snapshots();
  }

  // ฟังข้อมูลในบ้าน (เมื่อรู้ familyId แล้ว)
  Stream<DocumentSnapshot> streamFamilyDoc(String familyId) {
    return _db.collection('families').doc(familyId).snapshots();
  }

  // ดึงข้อมูลโปรไฟล์ของสมาชิกในบ้าน (เพื่อเอาชื่อมาโชว์)
  Future<List<Map<String, dynamic>>> getMembersProfile(List<String> memberIds) async {
    if (memberIds.isEmpty) return [];

    // ดึงข้อมูล User ทีละคน (ในเคสครอบครัวคนไม่เยอะ วิธีนี้ง่ายและชัวร์สุด)
    List<Map<String, dynamic>> members = [];
    for (String uid in memberIds) {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        members.add({
          'id': uid,
          'name': doc.data()?['display_name'] ?? 'Unknown',
          // สมมติว่ามี color หรือ avatar ก็ดึงมาได้
        });
      }
    }
    return members;
  }
}