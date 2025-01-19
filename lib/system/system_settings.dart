import 'dart:convert';

import 'package:clean_desktop/logger/my_logger.dart';
import 'package:clean_desktop/models/created_folder.dart';
import 'package:clean_desktop/storage/local_storage.dart';

class SystemSettings {
  static final SystemSettings instance = SystemSettings();
  final String _workPath = 'settings.workpath';
  final String _running = 'settings.running';
  final String _createdFolderHistory = 'settings.createdfolderhistory';

  String workPath = '';
  bool running = false;
  List<CreatedFolder> createdFolderHistory = [];

  CreatedFolder? get latestCreatedFolder => createdFolderHistory.lastOrNull;

  Future<void> init() async {
    workPath = LocalStorage.instance.getPrefs().getString(_workPath) ?? '';
    running = LocalStorage.instance.getPrefs().getBool(_running) ?? false;
    String history =
        LocalStorage.instance.getPrefs().getString(_createdFolderHistory) ?? '';
    List<String> historyList = history.split('|*|');
    List<CreatedFolder> list = [];
    for (String historyItem in historyList) {
      if (historyItem.isEmpty) {
        continue;
      }
      try {
        Map<String, dynamic> json = jsonDecode(historyItem);
        list.add(CreatedFolder.fromJson(json));
      } catch (e) {
        logE(e);
        clearHistory();
      }
    }
    createdFolderHistory = list;
  }

  bool get workPathIsSet => workPath.isNotEmpty;

  void setWorkPath(String value) {
    workPath = value;
    LocalStorage.instance.getPrefs().setString(_workPath, value);
  }

  Future<void> setRunning(bool value) async {
    running = value;
    await LocalStorage.instance.getPrefs().setBool(_running, value);
  }

  Future<void> deleteCreatedFolderHistory(CreatedFolder createFolder) async {
    createdFolderHistory.remove(createFolder);
    String history = createdFolderHistory
        .map((folder) => jsonEncode(folder.toJson()))
        .join('|*|');
    await LocalStorage.instance
        .getPrefs()
        .setString(_createdFolderHistory, history);
  }

  Future<void> addCreatedFolderHistory(CreatedFolder createFolder) async {
    createdFolderHistory.add(createFolder);
    String history = createdFolderHistory
        .map((folder) => jsonEncode(folder.toJson()))
        .join('|*|');
    await LocalStorage.instance
        .getPrefs()
        .setString(_createdFolderHistory, history);
  }

  Future<void> clearHistory() async {
    createdFolderHistory.clear();
    await LocalStorage.instance.getPrefs().setString(_createdFolderHistory, '');
  }
}
