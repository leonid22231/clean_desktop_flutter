import 'package:clean_desktop/logger/my_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static final LocalStorage instance = LocalStorage();
  late SharedPreferences _prefs;
  bool _isInit = false;

  Future<void> init() async {
    logI('init');
    try {
      _prefs = await SharedPreferences.getInstance();
      _isInit = true;
    } catch (e) {
      logE(e);
    }
  }

  Future<void> update() async{
    _isInit = false;
    await init();
  }

  SharedPreferences getPrefs() {
    if (!_isInit) {
      logE('LocalStorage is not initialized');
    }
    return _prefs;
  }
}
