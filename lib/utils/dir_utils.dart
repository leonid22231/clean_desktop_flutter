import 'dart:io';

Future<Directory> createDir(String path, String name,
    {bool createNewIfExist = false}) async {
  int index = -1;
  Directory directory = Directory('$path\\$name');
  bool isExist = await directory.exists();
  if (isExist) {
    if (!createNewIfExist) {
      return directory;
    }

    index = int.tryParse(name.split('_').last) ?? 0;
    index++;
    name = '${name.split('_')[0]}_$index';
    return createDir(path, name, createNewIfExist: createNewIfExist);
  }
  await directory.create();
  return directory;
}

Future<List<Directory>> createDirList(
    String rootPath, List<String> names) async {
  List<Directory> list = [];
  for (String name in names) {
    Directory directory = await createDir(rootPath, name);
    list.add(directory);
  }
  return list;
}

extension DirectoryUtils on Directory {
  String get name {
    return uri.pathSegments.lastWhere((segment) => segment.isNotEmpty);
  }

  Future<bool> get isEmpty async {
    List<FileSystemEntity> files = await list().toList();
    for (FileSystemEntity file in files) {
      FileStat fileStat = await file.stat();
      if (fileStat.type == FileSystemEntityType.directory) {
        Directory directory = Directory(file.path);
        bool isEmpty = await directory.isEmpty;
        if (!isEmpty) {
          return false;
        }
      } else {
        return true;
      }
    }
    return true;
  }
}
