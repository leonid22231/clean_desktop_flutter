import 'dart:io';

import 'package:clean_desktop/main_service/main_service.dart';
import 'package:clean_desktop/models/created_folder.dart';
import 'package:clean_desktop/storage/local_storage.dart';
import 'package:clean_desktop/system/system_settings.dart';
import 'package:clean_desktop/tray/system_tray.dart';
import 'package:clean_desktop/window_manager/my_window_manger.dart';
import 'package:filepicker_windows/filepicker_windows.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initAsync();
  runApp(const MyApp());
}

Future<void> initAsync() async {
  await SystemTrayController.instance.init();
  await MyWindowManger.instance.init();
  await LocalStorage.instance.init();
  await SystemSettings.instance.init();
  MainService.instance.init();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<CreatedFolder> history = [];

  @override
  void initState() {
    MainService.instance.setListener(onUpdate);
    history = SystemSettings.instance.createdFolderHistory;
    super.initState();
  }

  void onUpdate() {
    history = SystemSettings.instance.createdFolderHistory;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            DragToMoveArea(
              child: Container(
                color: Colors.red,
                height: 50,
                width: double.maxFinite,
              ),
            ),
            Expanded(
                child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    buildSpace(),
                    Container(
                      width: double.maxFinite,
                      color: Colors.purple.shade100,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          children: [
                            Flexible(
                                fit: FlexFit.tight,
                                child: Text(
                                    SystemSettings.instance.workPathIsSet
                                        ? SystemSettings.instance.workPath
                                        : 'Директория не установлена'
                                            .toUpperCase())),
                            Padding(
                              padding: const EdgeInsets.all(5),
                              child: InkWell(
                                onTap: () async {
                                  final file = DirectoryPicker()
                                    ..title = 'Select a directory';

                                  final result = file.getDirectory();
                                  if (result != null) {
                                    SystemSettings.instance
                                        .setWorkPath(result.path);
                                    setState(() {});
                                  }
                                },
                                child: Ink(
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    color: Colors.pinkAccent.shade200,
                                    child: Center(
                                      child: Text(
                                        'Установить'.toUpperCase(),
                                        style: const TextStyle(
                                            color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                    buildSpace(),
                    buildButton(
                        text: 'Запуск',
                        color: Colors.pinkAccent.shade200,
                        onClick: () {}),
                    buildSpace(),
                    buildTitle(text: 'Статус'),
                    buildSpace(),
                    Text(
                      MainService.instance.isRunning ? 'Запущен' : 'Остановлен',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: MainService.instance.isRunning
                              ? Colors.green
                              : Colors.red),
                    ),
                    buildButton(
                        text: MainService.instance.isRunning ? 'Стоп' : 'Старт',
                        color: Colors.pinkAccent.shade200,
                        onClick: () async {
                          if (MainService.instance.isRunning) {
                            MainService.instance.stopService();
                          } else {
                            MainService.instance.startService();
                          }
                        }),
                    buildSpace(),
                    buildButton(
                        text: 'manual',
                        color: Colors.tealAccent.shade200,
                        onClick: () async {
                          MainService.instance.manualStart();
                        }),
                    buildSpace(),
                    buildTitle(text: 'История: Количество: ${history.length}'),
                    ListView.separated(
                      primary: false,
                      shrinkWrap: true,
                      itemCount: history.length,
                      itemBuilder: (comtext, index) {
                        return buildHistoryItem(history[index], index);
                      },
                      separatorBuilder: (context, index) {
                        return const Divider();
                      },
                    ),
                    buildSpace(),
                  ],
                ),
              ),
            ))
          ],
        ),
      ),
    );
  }

  Widget buildHistoryItem(CreatedFolder folder, int index) {
    CreatedFolder currentFolder = folder;

    return Container(
      decoration: BoxDecoration(
          border: Border.all(width: 2, color: Colors.blueAccent.shade700),
          borderRadius: BorderRadius.circular(20),
          color: Colors.amberAccent.shade200),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '${index + 1}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            Row(
              children: [
                SvgPicture.asset('assets/icons/folder.svg'),
                const SizedBox(
                  width: 10,
                ),
                Text(folder.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 20))
              ],
            ),
            Row(
              children: [
                buildActionButton(() async {}, onLongPress: () {
                  SystemSettings.instance
                      .deleteCreatedFolderHistory(currentFolder);
                  setState(() {});
                }, SvgPicture.asset('assets/icons/delete.svg')),
                const SizedBox(
                  width: 10,
                ),
                buildActionButton(
                    () {}, SvgPicture.asset('assets/icons/recover.svg')),
                const SizedBox(
                  width: 10,
                ),
                Column(
                  children: [
                    Text('Файлов'.toUpperCase()),
                    Text('${folder.changedFiles.length}'),
                  ],
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget buildActionButton(Function() onClick, Widget icon,
      {Function()? onLongPress}) {
    return Material(
      borderRadius: BorderRadius.circular(1000),
      child: InkWell(
        onLongPress: onLongPress,
        onTap: onClick,
        borderRadius: BorderRadius.circular(1000),
        child: Ink(
          // decoration: BoxDecoration(
          //   color: Colors.white,
          //   //borderRadius: BorderRadius.circular(1000),
          // ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: icon,
            ),
          ),
        ),
      ),
    );
  }

  Widget buildButton({
    required String text,
    required Color color,
    required Function() onClick,
  }) {
    return Material(
      child: InkWell(
        onTap: onClick,
        child: Ink(
          child: Container(
            padding: const EdgeInsets.all(5),
            color: color,
            child: Center(
              child: Text(
                text.toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildSpace() {
    return const SizedBox(
      height: 50,
    );
  }

  Widget buildTitle({required String text}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(text.toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
