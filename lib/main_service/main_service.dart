import 'dart:async';
import 'dart:collection';
import 'dart:developer';
import 'dart:io';
import 'dart:isolate';

import 'package:clean_desktop/logger/my_logger.dart';
import 'package:clean_desktop/models/changed_file.dart';
import 'package:clean_desktop/models/created_folder.dart';
import 'package:clean_desktop/system/system_settings.dart';
import 'package:clean_desktop/utils/dir_utils.dart';
import 'package:clean_desktop/utils/file_sorter.dart';
import 'package:clean_desktop/utils/file_utils.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:process_run/process_run.dart';

class MainService {
  static final MainService instance = MainService();

  bool get isRunning => SystemSettings.instance.running;

  late Isolate isolate;
  Function()? onChangeStatus;
  SendPort? sendPort;

  void setListener(Function() function) {
    onChangeStatus = function;
  }

  void changeCall() {
    onChangeStatus?.call();
  }

  Future<void> init() async {
    ReceivePort resivePort = ReceivePort();
    isolate = await Isolate.spawn<IsolateData>(
        _mainService,
        IsolateData(
          sendPort: resivePort.sendPort,
          token: RootIsolateToken.instance!,
        ));

    resivePort.listen((data) async {
      if (data is SendPort) {
        sendPort = data;
        logI('connected');
      }
      if (data is CreatedFolder) {
        SystemSettings.instance.addCreatedFolderHistory(data);
        changeCall();
      }
      if (data is String) {
        if (data.contains('service')) {
          switch (data.replaceAll('service_', '')) {
            case 'start':
              await start();
              break;
            case 'stop':
              await stop();
              break;
          }
          changeCall();
        } else {
          switch (data) {
            case 'work_path_update':
              sendPort
                  ?.send('data_workpath_${SystemSettings.instance.workPath}');
              break;
            case 'files_ignored_update':
              sendPort?.send(await getIgnoreSettings());
              break;
          }
        }
      }
    });
  }

  Future<IgnoreSettings> getIgnoreSettings() async {
    return Future.value(IgnoreSettings(
      filesIgnored: [],
      typesIgnored: [],
    ));
  }

  Future<void> start() async {
    SystemSettings.instance.setRunning(true);
  }

  Future<void> stop() async {
    SystemSettings.instance.setRunning(false);
  }

  void startService() async {
    sendPort!.send('start');
  }

  void stopService() {
    sendPort!.send('stop');
  }

  void manualStart() {
    sendPort!.send('manual_start');
  }

  void restartService() {
    stopService();
    startService();
  }

  void _mainService(IsolateData data) async {
    Completer<String>? actualWorkPath;
    Completer<IgnoreSettings>? ignoreSettings;
    var shell = Shell();
    logI('start');
    String workPath = '';
    void start() async {
      data.sendPort.send('service_start');
    }

    void stop() async {
      data.sendPort.send('service_stop');
    }

    Future<void> workPathUpdate() async {
      actualWorkPath = Completer();
      data.sendPort.send('work_path_update');
      workPath = await actualWorkPath!.future;
      logI('workPathSet [$workPath]');
      actualWorkPath = null;
    }

    Future<IgnoreSettings> getIgnoreSettings() async {
      ignoreSettings = Completer();
      data.sendPort.send('files_ignored_update');
      IgnoreSettings settings = await ignoreSettings!.future;
      ignoreSettings = null;
      return settings;
    }

    void manualStart() async {
      start();

      logI('manual_start');
      await workPathUpdate();
      if (workPath.isEmpty) {
        manualStart();
        return;
      }
      IgnoreSettings ignoreSettings = await getIgnoreSettings();
      Directory rootDirectory = Directory(workPath);
      FileSorter fileSorter =
          FileSorter(rootDirectory, settings: ignoreSettings);

      Map<String, List<FileSystemEntity>> sorted = await fileSorter.sort();

      DateFormat dateFormat = DateFormat('DD.MM.yyyy');
      DateTime createTime = DateTime.now();
      String dirName = dateFormat.format(createTime);
      if (sorted.isEmpty) {
        log('Files not found');
        return;
      }
      Directory dir = await createDir(rootDirectory.path, dirName, createNewIfExist: true);

      List<Directory> childrenDir =
          await createDirList(dir.path, sorted.keys.toList());

      List<ChangedFile> changedFiles = [];

      for (Directory directory in childrenDir) {
        List<FileSystemEntity> filesInDir = sorted[directory.name] ?? [];

        for (FileSystemEntity file in filesInDir) {
          log('file[${file.name}]');
          ChangedFile? changedFile =
              await safeMove(File(file.path), directory.path);

          if (changedFile != null) {
            changedFiles.add(changedFile);
          }
        }
      }

      data.sendPort.send(CreatedFolder(
          rootPath: workPath,
          creatingTime: DateTime.now().difference(createTime),
          createdDate: createTime,
          changedFiles: changedFiles,
          path: dir.path));
      // List<FileSystemEntity> allFiles = dir.listSync();
      // List<File> onlyFiles = [];
      // for (FileSystemEntity file in allFiles) {
      //   List<ProcessResult> results = await shell.run('attrib "${file.path}"');
      //   String result =
      //       results.first.outText.replaceFirst(file.path, '').trim();
      //   bool isVisible = !result.contains('H');

      //   if (!Directory(file.path).existsSync() && isVisible) {
      //     onlyFiles.add(File(file.path));
      //   }
      // }

      // List<File> finalListFiles = [];

      // for (File file in onlyFiles) {
      //   String type = file.uri.pathSegments.last.split('.').last;
      //   String path = file.uri.toFilePath();
      //   bool isTypeIgnored = false;
      //   bool isFileIgnored = false;
      //   for (String ignoreType in ignoreSettings.typesIgnored) {
      //     if (type == ignoreType) {
      //       isTypeIgnored = true;
      //       break;
      //     }
      //   }
      //   if (isTypeIgnored) continue;
      //   for (FileStatus ignoredFile in ignoreSettings.filesIgnored) {
      //     if (ignoredFile.status == 'not found') {
      //       continue;
      //     } else {
      //       if (ignoredFile.path == path) {
      //         isFileIgnored = true;
      //         break;
      //       }
      //     }
      //   }
      //   if (isFileIgnored) continue;
      //   finalListFiles.add(file);
      // }
      // Map<String, List<File>> sortedFromType = HashMap<String, List<File>>();

      // for (File file in finalListFiles) {
      //   String type = file.uri.pathSegments.last.split('.').last;
      //   sortedFromType[type] ??= [];
      //   sortedFromType[type]!.add(file);
      // }
      // DateFormat dateFormat = DateFormat('DD.MM.yyyy-test');
      // DateTime currentDate = DateTime.now();
      // dir = Directory('${dir.path}\\${dateFormat.format(currentDate)}');
      // if (!(await dir.exists())) {
      //   await dir.create();
      // }

      // String rootPath = dir.path;
      // List<ChangedFile> changedFiles = [];
      // for (String type in sortedFromType.keys) {
      //   Directory typeDir = Directory('$rootPath\\$type');
      //   if (!(await typeDir.exists())) {
      //     await typeDir.create();
      //   }
      //   for (File file in sortedFromType[type]!) {
      //     print('fileProcessing:[${file.uri.pathSegments.last}]');
      //     String originalMd5Hash =
      //         md5.convert(await file.readAsBytes()).toString();

      //     String fileName = file.uri.pathSegments.last;
      //     String newPath = '${typeDir.path}\\$fileName';
      //     File newFile = File(newPath);
      //     bool mdChecked = false;
      //     bool newFileExist = await newFile.exists();
      //     if (newFileExist) {
      //       String newMd5Hash =
      //           md5.convert(await newFile.readAsBytes()).toString();
      //       if (originalMd5Hash == newMd5Hash) {
      //         mdChecked = true;
      //       }
      //     }
      //     if (newFileExist && mdChecked) {
      //       file.deleteSync();
      //       continue;
      //     }
      //     if (newFileExist) {
      //       await file.copy(newPath);
      //     }
      //     ChangedFile? changedFile = await safeMove(file, newPath);
      //     if (changedFile != null) {
      //       changedFiles.add(changedFile);
      //     }
      //   }
      // }

      stop();
    }

    void restart() {}
    logI('isRunning[$isRunning]');
    final recvMsg = ReceivePort();
    recvMsg.listen((data) {
      logI('service: [$data]');
      if (data is IgnoreSettings) {
        ignoreSettings!.complete(data);
      }
      if (data is String) {
        if (data.contains('data')) {
          String dataType = data.split('_')[1];
          switch (dataType) {
            case 'workpath':
              actualWorkPath?.complete(data.split('_')[2]);
              break;
          }
        }
        switch (data) {
          case 'start':
            start();
            break;
          case 'stop':
            stop();
            break;
          case 'restart':
            restart();
            break;
          case 'manual_start':
            try {
              manualStart();
            } catch (e) {
              logE(e);
              stop();
            }
            break;
        }
      }
    });
    data.sendPort.send(recvMsg.sendPort);
    logI('stop');
  }
}

class IsolateData {
  final SendPort sendPort;
  final RootIsolateToken token;
  IsolateData({
    required this.sendPort,
    required this.token,
  });
}

class IgnoreSettings {
  List<FileStatus> filesIgnored;
  List<String> typesIgnored = ['lnk'];
  IgnoreSettings({required this.filesIgnored, List<String>? typesIgnored}) {
    this.typesIgnored.addAll((typesIgnored ?? [])
        .where((type) => !this.typesIgnored.contains(type))
        .toList());
  }

  @override
  String toString() {
    return 'IgnoreSettings{filesIgnored: ${filesIgnored.toString()}, typesIgnored: ${typesIgnored.toString()}}';
  }
}

class FileStatus {
  String path;
  String status;
  FileStatus({required this.path, required this.status});

  @override
  String toString() {
    return 'FileStatus{path: $path, status: $status}';
  }
}
