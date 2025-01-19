import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:clean_desktop/models/changed_file.dart';
import 'package:crypto/crypto.dart';
import 'package:convert/convert.dart';

Future<ChangedFile?> safeMove(File sourseFile, String path) async {
  String sMd5 = await sourseFile.md5Hash;

  String? changedPath = await _move(sourseFile, sMd5, path);
  if (changedPath == null) {
    return null;
  }
  return ChangedFile(
      name: sourseFile.uri.pathSegments.last,
      originalPath: sourseFile.path,
      changedPath: changedPath,
      md5Hash: sMd5);
}

Future<String?> _move(File sourseFile, String sMd5, path) async {
  Completer<String?> completer = Completer();

  int tryCount = 5;

  while (tryCount > 0) {
    File nFile = await sourseFile.copy('$path\\${sourseFile.name}');

    String nMd5 = await nFile.md5Hash;

    if (nMd5 != sMd5) {
      tryCount--;
      continue;
    }
    await sourseFile.delete();
    completer.complete(nFile.path);
    tryCount = -1;
  }

  if (tryCount == 0) {
    completer.complete(null);
  }
  return completer.future;
}

extension FileUtils on File {
  String get name {
    return uri.pathSegments.lastWhere((segment) => segment.isNotEmpty);
  }

  Future<String> get md5Hash async {
    final sw = Stopwatch()..start();
    log("START {{{");
    var output = AccumulatorSink<Digest>();

    final sink = md5.startChunkedConversion(output);

    final inputStream = openRead();
    int lenght = 0;
    await for (var chunk in inputStream) {
      sink.add(chunk);
      lenght += chunk.length;
    }
    sink.close();
    String hash = output.events.first.toString();
    log("${lenght ~/ (1024 * 1024)} mbytes hash[$hash]");
    log("}}} DONE IN ${sw.elapsedMilliseconds} ms.");
    sw.stop();
    return hash;
  }
}
