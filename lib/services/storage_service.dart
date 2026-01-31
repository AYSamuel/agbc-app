// lib/services/storage_service.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;

/// Service for handling file storage operations including profile pictures.
/// Uses Supabase Storage for cloud storage with local image processing.
class StorageService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  /// Pick an image from camera or gallery
  ///
  /// [source] - ImageSource.camera or ImageSource.gallery
  /// Returns the picked file or null if cancelled
  Future<File?> pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image == null) return null;
      return File(image.path);
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  /// Crop an image to a square aspect ratio
  ///
  /// [imageFile] - The image file to crop
  /// [toolbarColor] - Optional toolbar color for the cropper UI
  /// Returns the cropped file or null if cancelled
  Future<File?> cropImage(File imageFile, {Color? toolbarColor}) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressQuality: 90,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Profile Picture',
            toolbarColor: toolbarColor ?? Colors.deepPurple,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            hideBottomControls: false,
          ),
          IOSUiSettings(
            title: 'Crop Profile Picture',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
            aspectRatioPickerButtonHidden: true,
          ),
        ],
      );
      if (croppedFile == null) return null;
      return File(croppedFile.path);
    } catch (e) {
      debugPrint('Error cropping image: $e');
      return null;
    }
  }

  /// Compress an image to reduce file size
  ///
  /// [file] - The image file to compress
  /// Returns the compressed file or null if failed
  Future<File?> compressImage(File file) async {
    try {
      final String targetPath = '${file.parent.path}/compressed_${path.basename(file.path)}';

      final XFile? result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 80,
        minWidth: 500,
        minHeight: 500,
        format: CompressFormat.jpeg,
      );

      if (result == null) return null;
      return File(result.path);
    } catch (e) {
      debugPrint('Error compressing image: $e');
      return null;
    }
  }

  /// Upload a profile picture to Supabase Storage
  ///
  /// [imageFile] - The image file to upload (should already be cropped)
  /// [userId] - The user's ID for the storage path
  /// Returns the public URL of the uploaded image or null if failed
  Future<String?> uploadProfilePicture({
    required File imageFile,
    required String userId,
  }) async {
    try {
      // 1. Compress the image
      final compressedFile = await compressImage(imageFile);
      if (compressedFile == null) {
        throw Exception('Failed to compress image');
      }

      // 2. Define storage path (using fixed name with upsert)
      final String storagePath = '$userId/profile.jpg';

      // 3. Read file as bytes for upload
      final bytes = await compressedFile.readAsBytes();

      // 4. Upload to Supabase Storage
      await _supabase.storage.from('avatars').uploadBinary(
        storagePath,
        bytes,
        fileOptions: const FileOptions(
          upsert: true,
          contentType: 'image/jpeg',
        ),
      );

      // 5. Get public URL with cache-busting timestamp
      final String publicUrl = _supabase.storage
          .from('avatars')
          .getPublicUrl(storagePath);
      final String urlWithTimestamp = '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';

      // 6. Update user profile in database
      await _supabase.from('users').update({
        'photo_url': urlWithTimestamp,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      // 7. Clean up temporary compressed file
      try {
        await compressedFile.delete();
      } catch (_) {
        // Ignore cleanup errors
      }

      debugPrint('Profile picture uploaded successfully: $urlWithTimestamp');
      return urlWithTimestamp;
    } catch (e) {
      debugPrint('Error uploading profile picture: $e');
      rethrow;
    }
  }

  /// Delete a user's profile picture
  ///
  /// [userId] - The user's ID
  Future<void> deleteProfilePicture(String userId) async {
    try {
      final String storagePath = '$userId/profile.jpg';

      // Delete from storage
      await _supabase.storage.from('avatars').remove([storagePath]);

      // Update user profile to remove photo URL
      await _supabase.from('users').update({
        'photo_url': null,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      debugPrint('Profile picture deleted successfully');
    } catch (e) {
      debugPrint('Error deleting profile picture: $e');
      rethrow;
    }
  }

  /// Complete flow to pick, crop, and upload a profile picture
  ///
  /// [source] - ImageSource.camera or ImageSource.gallery
  /// [userId] - The user's ID
  /// [toolbarColor] - Optional toolbar color for the cropper UI
  /// Returns the public URL of the uploaded image or null if cancelled/failed
  Future<String?> pickCropAndUploadProfilePicture({
    required ImageSource source,
    required String userId,
    Color? toolbarColor,
  }) async {
    // 1. Pick image
    final pickedFile = await pickImage(source);
    if (pickedFile == null) return null;

    // 2. Crop image
    final croppedFile = await cropImage(pickedFile, toolbarColor: toolbarColor);
    if (croppedFile == null) return null;

    // 3. Upload
    return await uploadProfilePicture(
      imageFile: croppedFile,
      userId: userId,
    );
  }
}
