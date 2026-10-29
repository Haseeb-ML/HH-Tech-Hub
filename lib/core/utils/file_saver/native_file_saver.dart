import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

Future<String> saveAndLaunchFile(List<int> bytes, String fileName) async {
  Directory? downloadsDir;
  if (Platform.isAndroid || Platform.isIOS) {
    try {
      downloadsDir = await getExternalStorageDirectory();
    } catch (_) {}
  }
  downloadsDir ??= await getDownloadsDirectory();
  downloadsDir ??= await getApplicationDocumentsDirectory();
  var filePath = p.join(downloadsDir.path, fileName);
  var file = File(filePath);

  try {
    await file.writeAsBytes(bytes, flush: true);
    return filePath;
  } catch (e) {
    if (e is FileSystemException ||
        e.toString().contains('errno = 32') ||
        e.toString().contains('being used by another process')) {
      final ext = p.extension(fileName);
      final nameWithoutExt = p.basenameWithoutExtension(fileName);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueFileName = '${nameWithoutExt}_$timestamp$ext';
      filePath = p.join(downloadsDir.path, uniqueFileName);
      file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);
      return filePath;
    }
    rethrow;
  }
}
