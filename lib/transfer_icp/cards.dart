import 'package:flutter/material.dart';

import 'icp_ledger.dart';
import '../config/state.dart';
import '../config/state_bind.dart';
import '../config/state.dart';
import '../cycles_bank/cards.dart';

class IcpTransferListItem extends StatelessWidget {
    late final IcpTransfer icp_transfer;
    late final String self_icp_id;
    IcpTransferListItem(IcpTransfer icp_transfer_, String self_icp_id_): icp_transfer = icp_transfer_, self_icp_id = self_icp_id_, super(key: ValueKey('IcpTransferListItem: ${icp_transfer_.block_height}, self_icp_id: ${self_icp_id_}'));
    
    Widget build(BuildContext context) {        
        
        bool is_cts_transfer_icp_fee = icp_transfer.memo == '4851594152738179398' && icp_transfer.from_account_identifier == self_icp_id && icp_transfer.to_account_identifier == cts_main_icp_id;

        bool is_out = icp_transfer.from_account_identifier == self_icp_id;
        bool is_in = icp_transfer.to_account_identifier == self_icp_id;
        
        late String listtile_title;
        if (is_cts_transfer_icp_fee) {
            listtile_title = 'CTS TRANSFER-ICP FEE';
        } else {
            listtile_title = 'ICP-TRANSFER' + (is_out ? ' OUT' : '') + (is_in ? ' IN' : '');
        }
        
        return Container(
            padding: EdgeInsets.all(11),            
            constraints: BoxConstraints(maxWidth: 300),
            child: Card(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                        ListTile(
                            title: Text(listtile_title),
                            subtitle: Text('BLOCK-HEIGHT: ${icp_transfer.block_height}'),
                        ),
                        Expanded(
                            child: Container(
                                padding: EdgeInsets.fromLTRB(17,7,17,7),
                                width: double.infinity, 
                                child: SingleChildScrollView(
                                    child: Column(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                            SelectableText((is_out ? 'for: ${icp_transfer.to_account_identifier} ' : '') + (is_in ? '${is_out ? '\n' : ''}by: ${icp_transfer.from_account_identifier}' : '')),
                                            SelectableText('icp: ${icp_transfer.amount}'),
                                            SelectableText('memo: ${icp_transfer.memo}'),
                                            SelectableText('icp-ledger-fee: ${icp_transfer.fee}'),
                                            SelectableText('timestamp: ${log_timestamp_format(DateTime.fromMillisecondsSinceEpoch(icp_transfer.timestamp_seconds.toInt() * 1000))}'),
                                        ]
                                    )
                                )
                            )
                        )
                    ]
                )
            )
        );
    }
}


