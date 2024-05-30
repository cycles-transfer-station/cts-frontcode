import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:ic_tools/ic_tools.dart';
import 'package:ic_tools/tools.dart';

Future<void> main() async {
	// when want to update the service worker, change the value in the .service_worker_version file.
	String service_worker_version = await File('.service_worker_version').readAsString();
	File file = File('build/web/flutter_bootstrap.js');
	String s = await file.readAsString();
	s = s.replaceFirst(RegExp(r'(?<=serviceWorkerVersion: ").+(?=")'), service_worker_version);
	await file.writeAsString(s);
}