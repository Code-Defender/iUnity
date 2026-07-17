import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload file (useful for Android/iOS local file uploads)
  Future<String> uploadFile({
    required String path,
    required File file,
    SettableMetadata? metadata,
  }) async {
    try {
      Reference ref = _storage.ref().child(path);
      UploadTask uploadTask = ref.putFile(file, metadata);
      
      // Monitor upload task if needed
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("Error uploading file to path $path: $e");
      rethrow;
    }
  }

  // Upload raw bytes (useful for Web file uploads or platform-independent bytes)
  Future<String> uploadBytes({
    required String path,
    required Uint8List bytes,
    SettableMetadata? metadata,
  }) async {
    try {
      Reference ref = _storage.ref().child(path);
      UploadTask uploadTask = ref.putData(bytes, metadata);
      
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("Error uploading bytes to path $path: $e");
      rethrow;
    }
  }

  // Delete file from Firebase Storage
  Future<void> deleteFile({required String path}) async {
    try {
      Reference ref = _storage.ref().child(path);
      await ref.delete();
    } catch (e) {
      print("Error deleting file at path $path: $e");
      rethrow;
    }
  }

  // Get download URL of an existing file
  Future<String> getDownloadUrl({required String path}) async {
    try {
      Reference ref = _storage.ref().child(path);
      return await ref.getDownloadURL();
    } catch (e) {
      print("Error getting download URL for path $path: $e");
      rethrow;
    }
  }
}
