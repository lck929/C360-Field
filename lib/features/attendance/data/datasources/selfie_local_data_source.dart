import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

abstract interface class SelfieLocalDataSource {
  Future<String> save(String sourcePath, String clientId);

  Future<String?> path(String name);

  Future<void> delete(String name);
}

class FileSelfieStore implements SelfieLocalDataSource {
  FileSelfieStore({required this.maxBytes, Future<Directory> Function()? baseDirectory})
      : _baseDirectory = baseDirectory ?? getApplicationDocumentsDirectory;

  final int maxBytes;
  final Future<Directory> Function() _baseDirectory;

  Future<File> _fileFor(String name) async {
    final dir = Directory('${(await _baseDirectory()).path}${Platform.pathSeparator}selfies');
    if (!await dir.exists()) await dir.create(recursive: true);
    return File('${dir.path}${Platform.pathSeparator}$name');
  }

  @override
  Future<String> save(String sourcePath, String clientId) async {
    final name = '$clientId.jpg';
    final target = await _fileFor(name);
    for (final quality in const [85, 70, 55, 40, 30]) {
      final output = await FlutterImageCompress.compressAndGetFile(
        sourcePath,
        target.path,
        minWidth: 720,
        minHeight: 960,
        quality: quality,
      );
      if (output == null) break;
      if (await target.length() <= maxBytes) {
        await _deleteQuietly(File(sourcePath));
        return name;
      }
    }
    await _deleteQuietly(target);
    throw const FileSystemException('Couldn’t prepare the photo');
  }

  @override
  Future<String?> path(String name) async {
    if (name.isEmpty) return null;
    final file = await _fileFor(name);
    return await file.exists() ? file.path : null;
  }

  @override
  Future<void> delete(String name) async {
    if (name.isNotEmpty) await _deleteQuietly(await _fileFor(name));
  }

  Future<void> _deleteQuietly(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}
