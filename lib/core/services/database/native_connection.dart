import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

QueryExecutor openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'erp_local.db'));
    return NativeDatabase(file);
  });
}

Future<File> getDatabaseFile() async {
  final dbFolder = await getApplicationDocumentsDirectory();
  return File(p.join(dbFolder.path, 'erp_local.db'));
}

Future<Directory> getBackupsDirectory() async {
  final dbFolder = await getApplicationDocumentsDirectory();
  final backupDir = Directory(p.join(dbFolder.path, 'erp_backups'));
  if (!await backupDir.exists()) {
    await backupDir.create(recursive: true);
  }
  return backupDir;
}
