import 'dart:typed_data';
import 'dart:io' as io;

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';

class SupabaseService {
  final client = Supabase.instance.client;

  Future<String> uploadFile(PlatformFile pickedFile, String path, String bucket) async {
    Uint8List? bytes = pickedFile.bytes;

    if (bytes == null && pickedFile.path != null) {
      final file = io.File(pickedFile.path!);
      bytes = await file.readAsBytes();
    }

    if (bytes == null) throw Exception("Impossible de lire le fichier sélectionné");

    await client.storage.from(bucket).uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(upsert: true),
    );

    return client.storage.from(bucket).getPublicUrl(path);
  }
}
