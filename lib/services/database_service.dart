import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Create or update user profile
  Future<void> saveUserProfile({
    required String uid,
    required String email,
    String? displayName,
    String? photoUrl,
    String? role,
  }) async {
    try {
      await _db.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'displayName': displayName ?? '',
        'photoUrl': photoUrl ?? '',
        'role': role ?? 'DRIVER',
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print("Error saving user profile: $e");
      rethrow;
    }
  }

  // Get user profile data as a stream
  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserProfileStream(String uid) {
    return _db.collection('users').doc(uid).snapshots();
  }

  // Get user profile once
  Future<DocumentSnapshot<Map<String, dynamic>>> getUserProfile(String uid) async {
    try {
      return await _db.collection('users').doc(uid).get();
    } catch (e) {
      print("Error getting user profile: $e");
      rethrow;
    }
  }

  // Generic Create: Add item to a sub-collection (e.g. user notifications, items)
  Future<DocumentReference> addDocument({
    required String collectionPath,
    required Map<String, dynamic> data,
  }) async {
    try {
      data['createdAt'] = FieldValue.serverTimestamp();
      return await _db.collection(collectionPath).add(data);
    } catch (e) {
      print("Error adding document to $collectionPath: $e");
      rethrow;
    }
  }

  // Generic Update
  Future<void> updateDocument({
    required String collectionPath,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _db.collection(collectionPath).doc(docId).update(data);
    } catch (e) {
      print("Error updating document $docId in $collectionPath: $e");
      rethrow;
    }
  }

  // Generic Delete
  Future<void> deleteDocument({
    required String collectionPath,
    required String docId,
  }) async {
    try {
      await _db.collection(collectionPath).doc(docId).delete();
    } catch (e) {
      print("Error deleting document $docId in $collectionPath: $e");
      rethrow;
    }
  }

  // Generic Query Stream
  Stream<QuerySnapshot<Map<String, dynamic>>> getCollectionStream({
    required String collectionPath,
    Query<Map<String, dynamic>> Function(Query<Map<String, dynamic>> query)? queryBuilder,
  }) {
    Query<Map<String, dynamic>> query = _db.collection(collectionPath);
    if (queryBuilder != null) {
      query = queryBuilder(query);
    }
    return query.snapshots();
  }
}
