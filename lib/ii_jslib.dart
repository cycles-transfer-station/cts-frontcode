@JS()
library ii_jslib;

import 'dart:typed_data';
import 'dart:js';
import 'package:js/js.dart';
import 'package:js/js_util.dart';






@JS()
@anonymous
class InternetIdentityAuthorize {
    external String get kind; 
    external Uint8List get sessionPublicKey;
    //external BigInt get maxTimeToLive;

    external factory InternetIdentityAuthorize({
        String kind, 
        Uint8List sessionPublicKey,
        //BigInt maxTimeToLive
    });
}



List<String> getKeysOfObject(JsObject object) => (context['Object'] as JsFunction).callMethod('keys', [object]);
