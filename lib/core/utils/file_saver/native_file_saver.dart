import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

Future<String> saveAndLaunchFile(List<int> bytes, String fileName) async {
  final downloadsDir =
      await getDownloadsDirectory() ??
      await getApplicationDocumentsDirectory();
  final filePath = p.join(downloadsDir.path, fileName);
  final file = File(filePath);
  await file.writeAsBytes(bytes);
  return filePath;
}
