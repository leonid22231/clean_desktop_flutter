import 'package:logger/logger.dart';

var logger = Logger();

logI(dynamic message) {
  logger.i(message);
}

logE(dynamic message) {
  logger.e(message);
}
