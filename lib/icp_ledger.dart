import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
    
import 'package:ic_tools/ic_tools.dart' show Principal;
import 'package:ic_tools/common.dart' show PrincipalIcpId, governance;
import 'package:ic_tools/candid.dart' show Record, CandidType, Nat64;
import 'package:ic_tools/tools.dart';

    
void print_map(Map map) {
    JsonEncoder encoder = new JsonEncoder.withIndent('  ');
    String prettyprint = encoder.convert(map);
    print(prettyprint);
}

main() async {
    var l = await get_icp_transfers('88d962bcb90c03675918f4a2609648e092274df657c6a9444308549aa541819d', already_have: 12420);
    print(l.length);
    //print(l);
}




//'https://ledger-api.internetcomputer.org/accounts/7de45dcb25c6e9e765d8fb51087b581f93d6d1c5ad3675da3cdddfbb3249c165/transactions?limit=100&offset=0&max_block_index=4423786&transfer_type='

class IcpTransfer {
    final String block_height;
    final String parent_hash;
    final String block_hash;
    final String transaction_hash;
    final String from_account_identifier;
    final String to_account_identifier;
    final String transfer_type;
    final IcpTokens amount;
    final IcpTokens fee;
    final String memo;
    final int timestamp_seconds;
    IcpTransfer._({
        required this.block_height,
        required this.parent_hash,
        required this.block_hash,
        required this.transaction_hash,
        required this.from_account_identifier,
        required this.to_account_identifier,
        required this.transfer_type,
        required this.amount,
        required this.fee,
        required this.memo,
        required this.timestamp_seconds
    });

    String toString() {
        return 
'''

block_height: ${this.block_height}
by: ${this.from_account_identifier}
for: ${this.to_account_identifier}
icp: ${this.amount}
fee: ${this.fee}
memo: ${this.memo}
timestamp: ${this.timestamp_seconds}

''';
    }

}




Future<List<IcpTransfer>> get_icp_transfers(String icp_id, {int already_have = 0}) async {
    print(icp_id);
    List<IcpTransfer> icp_transfers = [];
    try {
        
        Uri first_url = Uri(
            scheme: 'https',
            host: 'ledger-api.internetcomputer.org',
            path: '/accounts/' + icp_id + '/transactions',
            queryParameters: {'limit': '1'});                     // 'max_block_index': '', 'offset': '0'});
        http.Response response = await http.get(first_url);
        Map sponse_map = jsonDecode(utf8.decode(response.bodyBytes)) as Map;
        //print_map('first_url: $sponse_map');
        
        final int get_transfers_count = (sponse_map['total'] as int) - already_have;
        final String max_block_index = ((sponse_map['blocks']! as List)[0] as Map)['block_height'] as String;
        
        final int limit = 100;
        for (int c=0; c < (get_transfers_count/limit).toDouble().ceil(); c+=1) {
            Uri go = first_url.replace(
                queryParameters: {'limit': limit.toString(),'max_block_index': max_block_index, 'offset': (c*limit).toString()}
            );
            http.Response response = await http.get(go);
            Map sponse_map = jsonDecode(utf8.decode(response.bodyBytes)) as Map;
            //print_map('go: $c \n$sponse_map');
            for (Map block in (sponse_map['blocks']! as List).cast<Map>()) {
                if (icp_transfers.length == get_transfers_count) {
                    break;
                }
                icp_transfers.add(
                    IcpTransfer._(
                        block_height: block['block_height'] as String,
                        parent_hash: block['parent_hash'] as String,
                        block_hash: block['block_hash'] as String,
                        transaction_hash: block['transaction_hash'] as String,
                        from_account_identifier: block['from_account_identifier'] as String, 
                        to_account_identifier: block['to_account_identifier'] as String,
                        transfer_type: block['transfer_type'] as String,
                        amount: IcpTokens(e8s: BigInt.parse(block['amount'] as String)),
                        fee: IcpTokens(e8s: BigInt.parse(block['fee'] as String)),
                        memo: block['memo'] as String,
                        timestamp_seconds: block['created_at'] as int,
                    )
                );
            }
        }
        if (get_transfers_count != icp_transfers.length) {
            throw Exception('count error');
        }
        return icp_transfers;
    
    } catch(e) {
        print(e);
        throw Exception('Error connecting to the transaction-logs.');
    }
    
}



class IcpTokens extends Record {
    final BigInt e8s;
    IcpTokens({required this.e8s}) { 
        super['e8s'] = Nat64(this.e8s);
    }
    String toString() {
        String s = this.e8s.toRadixString(10);
        while (s.length < IcpTokens.DECIMAL_PLACES + 1) { s = '0$s'; }
        int split_i = s.length - IcpTokens.DECIMAL_PLACES;
        s = '${s.substring(0, split_i)}.${s.substring(split_i)}';
        while (s[s.length - 1] == '0' && s.length > 3/*minimum '0.0'*/) { s = s.substring(0, s.length - 1); }
        return s;   
    }
    static IcpTokens oftheRecord(CandidType icptokensrecord) {
        Nat64 e8s_nat64 = (icptokensrecord as Record)['e8s'] as Nat64; 
        return IcpTokens(
            e8s: e8s_nat64.value
        );
    }
    static IcpTokens oftheDouble(double icp) {
        if (check_double_decimal_point_places(icp) > IcpTokens.DECIMAL_PLACES) {
            throw Exception('max ${IcpTokens.DECIMAL_PLACES} decimal places for the icp');
        }
        return IcpTokens(
            e8s: BigInt.parse((icp * IcpTokens.DIVIDABLE_BY.toDouble()).toString().split('.')[0])
        );
    }
    static int DECIMAL_PLACES = 8;    
    static BigInt DIVIDABLE_BY = BigInt.from(pow(10, IcpTokens.DECIMAL_PLACES));
    
    IcpTokens operator + (IcpTokens t) {
        return IcpTokens(e8s: this.e8s + t.e8s);
    }    
    IcpTokens operator - (IcpTokens t) {
        return IcpTokens(e8s: this.e8s - t.e8s);
    } 
    IcpTokens operator * (IcpTokens t) {
        return IcpTokens(e8s: this.e8s * t.e8s);
    } 
    IcpTokens operator ~/ (IcpTokens t) {
        return IcpTokens(e8s: this.e8s ~/ t.e8s);
    } 
    bool operator > (IcpTokens t) {
        return this.e8s > t.e8s;
    } 
    bool operator < (IcpTokens t) {
        return this.e8s < t.e8s;
    } 
    bool operator >= (IcpTokens t) {
        return this.e8s >= t.e8s;
    } 
    bool operator <= (IcpTokens t) {
        return this.e8s <= t.e8s;
    } 
    

}

final IcpTokens ICP_LEDGER_TRANSFER_FEE = IcpTokens.oftheDouble(0.0001);
