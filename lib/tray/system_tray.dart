import 'dart:developer';
import 'dart:io';

import 'package:clean_desktop/logger/my_logger.dart';
import 'package:clean_desktop/window_manager/my_window_manger.dart';
import 'package:flutter/widgets.dart';
import 'package:system_tray/system_tray.dart';

class SystemTrayController {
  static final SystemTrayController instance = SystemTrayController();

  bool _isInit = false;

  late AppWindow _window;
  late SystemTray _systemTray;

  final List<MenuItemLabel> _menuIsVisible = [
    MenuItemLabel(
        label: 'Hide', onClicked: (menuItem) => MyWindowManger.instance.hide()),
    MenuItemLabel(
        label: 'Close Program',
        onClicked: (menuItem) => MyWindowManger.instance.close()),
  ];

  final List<MenuItemLabel> _menuIsNotVisible = [
    MenuItemLabel(
        label: 'Show', onClicked: (menuItem) => MyWindowManger.instance.show()),
    MenuItemLabel(
        label: 'Close Program',
        onClicked: (menuItem) => MyWindowManger.instance.close()),
  ];

  Future<void> init() async {
    logI('init');
    if (_isInit) {
      return;
    }
    try {
      await initSystemTray();
      _isInit = true;
    } catch (e) {
      logE(e);
    }
  }

  Future<void> setMenu({required List<MenuItemLabel> menuList}) async {
    final Menu menu = Menu();

    await menu.buildFrom(menuList);

    await _systemTray.setContextMenu(menu);
  }

  Future<void> show() async {
    await _systemTray.popUpContextMenu();
  }

  Future<void> initSystemTray() async {
    String path =
        Platform.isWindows ? 'assets/app_icon.ico' : 'assets/app_icon.png';

    _window = AppWindow();
    _systemTray = SystemTray();

    await _systemTray.initSystemTray(
      title: "system tray",
      iconPath: path,
    );

    _systemTray.registerSystemTrayEventHandler((eventName) async {
      log("eventName: $eventName");
      if (eventName == kSystemTrayEventClick) {
        MyWindowManger.instance.switchVisible();
      } else if (eventName == kSystemTrayEventRightClick) {
        bool isVisible = await MyWindowManger.instance.isVisible();
        
        if (isVisible) {
          await setMenu(menuList: _menuIsVisible);
          await show();
        }else{
          await setMenu(menuList: _menuIsNotVisible);
          await show();
        }
      }
    });
  }
}
