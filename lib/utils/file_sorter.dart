import 'dart:async';
import 'dart:io';

import 'package:clean_desktop/main_service/main_service.dart';
import 'package:process_run/process_run.dart';

class FileSorter {
  Directory rootDirectory;
  IgnoreSettings settings;
  FileSorter(this.rootDirectory, {required this.settings});

  Future<Map<String, List<FileSystemEntity>>> sort() async {
    List<FileSystemEntity> allFiles = await getAllFiles();

    List<FileSystemEntity> filteringFiles = filteringBySettings(allFiles);

    Map<String, List<FileSystemEntity>> map = {};

    for (FileSystemEntity file in filteringFiles) {
      String type = file.type;
      (map[type] ??= []).add(file);
    }

    return map;
  }

  List<FileSystemEntity> filteringBySettings(List<FileSystemEntity> list) {
    list.removeWhere((file) {
      String fileType = file.uri.pathSegments.last.split('.').last;
      String path = file.path;

      bool ignoreFileByPath = settings.filesIgnored.map((status) {
        return status.path;
      }).contains(path);

      bool ignoreFileByType = settings.typesIgnored.contains(fileType);

      return ignoreFileByPath || ignoreFileByType;
    });

    return list;
  }

  Future<List<FileSystemEntity>> getAllFiles(
      {bool ignoreFolders = true}) async {
    Shell shell = Shell();
    List<FileSystemEntity> list = await rootDirectory.list().toList();
    list.removeWhere((file) => fileIsHiden(shell, file: file));
    shell.kill();

    if (ignoreFolders) {
      list.removeWhere(
          (file) => file.statSync().type == FileSystemEntityType.directory);
    }

    return list;
  }

  bool fileIsHiden(Shell shell, {required FileSystemEntity file}) {
    List<ProcessResult> results = shell.runSync('attrib "${file.path}"');
    String result = results.first.outText.replaceFirst(file.path, '').trim();
    return result.contains('H');
  }
}

extension FileSystemEntityUtils on FileSystemEntity {
  String get type {
    return uri.pathSegments.last.split('.').last;
  }

  String get name {
    return uri.pathSegments.last;
  }
}
