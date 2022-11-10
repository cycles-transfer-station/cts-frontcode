import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
    
import 'package:ic_tools/ic_tools.dart' show Principal;
import 'package:ic_tools/common.dart' show PrincipalIcpId, governance, IcpTokens;
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
    final BigInt timestamp_seconds;
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
    //print(icp_id);
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
        
        if (sponse_map['total'] as int == 0) {
            return icp_transfers;
        }
        
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
                        timestamp_seconds: BigInt.parse(block['created_at'].toString()),
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




final IcpTokens ICP_LEDGER_TRANSFER_FEE = IcpTokens.oftheDouble(0.0001);
final IcpTokens ICP_LEDGER_TRANSFER_FEE_TIMES_TWO = IcpTokens(e8s: ICP_LEDGER_TRANSFER_FEE.e8s*BigInt.from(2));




