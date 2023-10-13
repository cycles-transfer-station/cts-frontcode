import 'dart:typed_data';
import 'dart:math';
import 'package:ic_tools/ic_tools.dart';




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



extension Chunks<T extends List> on T {
    List<T> chunks(int chunk_size) {
        var b_len = this.length;
        List<T> chunks = [];
        for(int i = 0; i < b_len; i += chunk_size) {    
            chunks.add(this.sublist(i,min(i+chunk_size, b_len)) as T);
        }
        return chunks;
    }
} 
