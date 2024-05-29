import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:ic_tools/ic_tools.dart';
import 'package:ic_tools/tools.dart';

Future<void> main() async {
    
    Map<String, Uint8List> files_hash = {};
    
    Directory build_web_dir = Directory(Directory.current.absolute.path + '/build/web'); 
    
    await for (FileSystemEntity fse in build_web_dir.list(recursive: true, followLinks: false)) {
        if (fse is File) {            
            
            String filename = fse.path.replaceFirst(build_web_dir.path, ''); 
            
            if (filename == '/index.html') {
                filename = '/';
            }
                
            List<int> file_bytes_gzip = gzip.encode(await fse.readAsBytes());
            
            files_hash[filename] = Uint8List.fromList(file_bytes_gzip);
        }
    }
    
    print('batch_hash: ${bytesasahexstring(ic_data_hash(files_hash))}');
}