@JS()
library ii_jslib;

import 'dart:typed_data';
//import 'dart:js';
import 'package:js/js.dart';
//import 'package:js/js_util.dart';




@JS()
@anonymous
class InternetIdentityAuthorize {
    external String get kind; 
    external Uint8List get sessionPublicKey;
    external int get maxTimeToLive; // js bigint. dart BigInt is not operating with js

    external factory InternetIdentityAuthorize({
        String kind, 
        Uint8List sessionPublicKey,
        int maxTimeToLive
    });
}










