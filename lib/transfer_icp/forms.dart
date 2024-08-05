import 'package:flutter/material.dart';

import 'package:ic_tools/candid.dart' show Nat64;
import 'package:ic_tools/common.dart';
import 'package:ic_tools/tools.dart';

import 'package:archive/archive.dart'; // crc32

import '../config/state.dart';
import '../config/state_bind.dart';
import '../config/pages.dart';
import '../transfer_icp/icp_ledger.dart';
import '../main.dart';
import '../user.dart';




final String? Function(String?) icp_id_string_validator = (String? value) {
    if (value == null || value.trim().length != 64) {
        return 'Icp ids are 64 characters long';
    }
    for (String char in value.trim().toLowerCase().split('')) {
        if (lower_case_hex_chars.contains(char) == false && number_chars.contains(char) == false) {
            return 'Icp ids are in the hex format. hex format characters are 0-9 a-f.';
        }
    }
    List<int> b = hexstringasthebytes(value.trim().toLowerCase());
    Crc32 crc32_checksum_compute = Crc32()..add(b.sublist(4));
    if (aresamebytes(crc32_checksum_compute.close(), b.sublist(0,4)) == false) {
        return 'The checksum does not match, invalid icp-id.';
    } 
    return null;                            
};
 

final String? Function(String?) icp_validator = (String? value) {
    String e_s = 'Number > 0 with a max ${IcpTokens.DECIMAL_PLACES} decimal point places';
    if (value == null || value.trim() == '') {
        return e_s;
    }
    late IcpTokens icpts;
    try {
        icpts = IcpTokens.of_the_double_string(value);
    } catch(e) {
        return e_s;
    }
    if (icpts.e8s == BigInt.from(0)) {
        return e_s;
    }
    return null;           
};



