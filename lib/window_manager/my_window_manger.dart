import 'package:clean_desktop/logger/my_logger.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class MyWindowManger {
  static final MyWindowManger instance = MyWindowManger();
  bool _isInit = false;
  Future<void> init() async {
    logI('init');
    if (_isInit) {
      return;
    }
    try {
      await windowManager.ensureInitialized();
      await initWindowOptions();
      _isInit = true;
    } catch (e) {
      logE(e);
    }
  }

  Future<void> switchVisible() async {
    bool isVisible = await windowManager.isVisible();

    if (!isVisible) {
      await show();
    } else {
      await hide();
    }
  }

  Future<bool> isVisible() async {
    bool isVisible = await windowManager.isVisible();
    return isVisible;
  }

  Future<void> show() async {
    if (!_isInit) {
      return;
    }
    await windowManager.show();
    await windowManager.focus();
  }

  Future<void> hide() async {
    if (!_isInit) {
      return;
    }
    await windowManager.hide();
  }

  Future<void> close() async {
    if (!_isInit) {
      return;
    }
    await windowManager.close();
  }

  Future<void> initWindowOptions() async {
    WindowOptions windowOptions = const WindowOptions(
      size: Size(769, 600),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {});
  }
}
