import 'dart:typed_data';
import 'dart:math';
import 'package:ic_tools/ic_tools.dart';
export 'package:ic_tools/tools.dart' show Chunks;



String etext(Object e) => e.toString().replaceFirst('Exception: ', '');


Principal principal_of_the_30_bytes(Iterable<int> b) {
    List<int> blist = b.toList();
    return Principal.bytes(Uint8List.fromList(blist.getRange(1, blist[0] + 1).toList()));
}

BigInt bigint_of_the_be_bytes(Iterable<int> bytes) {
    return BigInt.parse(bytes_as_the_bitstring(bytes), radix: 2);
}
BigInt Function(Iterable<int>) u128_of_the_be_bytes = bigint_of_the_be_bytes;

String bytes_as_the_bitstring(Iterable<int> bytes) {
    String bitstring = '';
    for (int byte in bytes) {
        String byte_bitstring = byte.toRadixString(2);
        while (byte_bitstring.length < 8) { byte_bitstring = '0' + byte_bitstring; }
        bitstring = bitstring + byte_bitstring;
    }
    return bitstring;
}




String principal_short(Principal p) {
    return p.text.substring(0,8) + '..' + p.text.substring(p.text.length - 5);
}
