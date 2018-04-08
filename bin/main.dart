import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:simplehaiku/simplehaiku.dart';

main(List<String> arguments) async {
  final filename = arguments.single;
  final file = new File(filename);
  Stream<List<int>> stream = file.openRead();
  final lines = stream.transform(UTF8.decoder)
      .transform(const LineSplitter());

  final writer = new SimpleHaiku();
  await writer.feed(lines);

  await writer.generate().take(10).forEach(print);
}
