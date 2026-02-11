import 'dart:io';
import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../supabase/supabase_config.dart';
import 'registration_repository.dart';

class SupabaseStorageService {
  Future<String> uploadRestaurantLogo(File file, {String? ownerId}) async {
    if (!SupabaseConfig.isConfigured) {
      throw RegistrationException(
        'supabase_not_configured',
        'Configurez Supabase avant l\'upload.',
      );
    }

    final client = Supabase.instance.client;
    final bucket = SupabaseConfig.logoBucket;
    final path = _buildStoragePath(file.path, ownerId: ownerId);
    final storage = client.storage.from(bucket);

    try {
      await storage.upload(
        path,
        file,
        fileOptions: const FileOptions(
          cacheControl: '3600',
          upsert: false,
        ),
      );

      if (SupabaseConfig.publicBucket) {
        return storage.getPublicUrl(path);
      }

      final signedUrl = await storage.createSignedUrl(path, 60 * 60 * 24);
      return signedUrl;
    } on StorageException catch (error) {
      throw RegistrationException('upload_failed', error.message);
    } catch (_) {
      throw RegistrationException('upload_failed', 'Upload du logo impossible.');
    }
  }

  String _buildStoragePath(String filePath, {String? ownerId}) {
    final ext = _extension(filePath);
    final random = Random().nextInt(999999).toString().padLeft(6, '0');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final owner = ownerId == null || ownerId.isEmpty ? 'owner' : ownerId;
    return 'logos/$owner/$timestamp-$random$ext';
  }

  String _extension(String path) {
    final index = path.lastIndexOf('.');
    if (index == -1) {
      return '.png';
    }
    return path.substring(index);
  }
}
