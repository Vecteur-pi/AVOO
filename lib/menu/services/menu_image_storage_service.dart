import 'dart:io';
import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../supabase/supabase_config.dart';

class MenuImageStorageService {
  Future<String> uploadMenuImage(File file, {String? restaurantId}) async {
    if (!SupabaseConfig.isConfigured) {
      throw Exception('Configurez Supabase avant l\'upload de l\'image.');
    }

    final client = Supabase.instance.client;
    final bucket = SupabaseConfig.menuImagesBucket;
    final path = _buildStoragePath(file.path, restaurantId: restaurantId);
    final storage = client.storage.from(bucket);

    try {
      await storage.upload(
        path,
        file,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );

      if (SupabaseConfig.publicBucket) {
        return storage.getPublicUrl(path);
      }

      return storage.createSignedUrl(path, 60 * 60 * 24);
    } on StorageException catch (error) {
      throw Exception(error.message);
    } catch (_) {
      throw Exception('Upload de l\'image impossible.');
    }
  }

  String _buildStoragePath(String filePath, {String? restaurantId}) {
    final ext = _extension(filePath);
    final random = Random().nextInt(999999).toString().padLeft(6, '0');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final restaurant = (restaurantId == null || restaurantId.isEmpty)
        ? 'restaurant'
        : restaurantId.replaceAll('/', '_');

    return 'menu-items/$restaurant/$timestamp-$random$ext';
  }

  String _extension(String path) {
    final index = path.lastIndexOf('.');
    if (index == -1) {
      return '.png';
    }
    return path.substring(index);
  }
}
