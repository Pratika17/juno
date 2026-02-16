import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  // Upload Item Image
  Future<String> uploadItemImage(File image, String itemId) async {
    try {
      File compressedImage = await _compressImage(image);
      String fileName = '${_uuid.v4()}.jpg';
      Reference ref = _storage.ref().child('items/$itemId/$fileName');

      UploadTask uploadTask = ref.putFile(compressedImage);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload item image: $e');
    }
  }

  // Upload Profile Image
  Future<String> uploadProfileImage(File image, String userId) async {
    try {
      File compressedImage = await _compressImage(image);
      String fileName = '${_uuid.v4()}.jpg';
      Reference ref = _storage.ref().child('users/$userId/$fileName');

      UploadTask uploadTask = ref.putFile(compressedImage);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload profile image: $e');
    }
  }

  // Delete Image
  Future<void> deleteImage(String imageUrl) async {
    try {
      Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete image: $e');
    }
  }

  // Compress Image
  Future<File> _compressImage(File file) async {
    try {
      final filePath = file.absolute.path;
      final lastIndex = filePath.lastIndexOf(RegExp(r'.jp'));
      final splitted = filePath.substring(0, (lastIndex));
      final outPath = "${splitted}_out${filePath.substring(lastIndex)}";

      // Basic implementation logic.
      // Note: flutter_image_compress might need temporary path handling properly.
      // For simplicity, we create a new file in same directory with _out suffix.
      // In production, consider using path_provider to get temporary directory.

      var result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        outPath,
        quality: 70,
        minWidth: 1024,
        minHeight: 1024,
      );

      if (result == null) {
        return file; // Return original if compression fails
      }

      // Convert XFile to File
      return File(result.path);
    } catch (e) {
      // print("Image compression failed: $e");
      return file; // Return original if compression fails
    }
  }
}
