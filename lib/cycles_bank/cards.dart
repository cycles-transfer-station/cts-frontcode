import 'package:flutter/material.dart';

import 'package:ic_tools/tools.dart';

import 'cycles_bank.dart';
import '../config/state.dart';
import '../config/state_bind.dart';



class CyclesTransferInListItem extends StatelessWidget {
    final CyclesTransferIn cycles_transfer_in;
    CyclesTransferInListItem(CyclesTransferIn cycles_transfer_in): cycles_transfer_in = cycles_transfer_in, super(key: ValueKey('CyclesTransferInListItem: ${cycles_transfer_in.id}'));
    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
                
        /*bool is_mint = 
            cycles_transfer_in.cycles_transfer_memo.containsKey('Blob') 
            && bytesasahexstring((cycles_transfer_in.cycles_transfer_memo['Blob'] as Blob).bytes) == '4354532d4255524e2d4943502d4d494e542d4359434c4553' 
            && cycles_transfer_in.by_the_canister.text == cts.principal.text;
        */
        
        return Container(
            padding: EdgeInsets.all(11),
            constraints: BoxConstraints(maxWidth: 350),
            child: Card(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                        ListTile(
                            title: Text('CYCLES TRANSFER IN'),
                            subtitle: Text('ID: ${cycles_transfer_in.id}'),
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
                                            SelectableText('cycles: ${cycles_transfer_in.cycles}'),
                                            SelectableText('cycles-transfer-memo: ${cycles_transfer_in.cycles_transfer_memo}'),
                                            SelectableText('by: ${cycles_transfer_in.by_the_canister.text}'),
                                            SelectableText('timestamp: ${seconds_of_the_nanos(cycles_transfer_in.timestamp_nanos)}'),
                                        ]
                                    ),
                                )
                            )
                        )
                    ]
                )
            )            
        );
    }
}

class CyclesTransferOutListItem extends StatelessWidget {
    final CyclesTransferOut cycles_transfer_out;
    CyclesTransferOutListItem(CyclesTransferOut cycles_transfer_out): cycles_transfer_out = cycles_transfer_out, super(key: ValueKey('CyclesTransferOutListItem: ${cycles_transfer_out.id}'));
    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
                
        return Container(
            constraints: BoxConstraints(maxWidth: 350),
            padding: EdgeInsets.all(11),
            child: Card(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                        ListTile(
                            title: Text('CYCLES TRANSFER OUT'),
                            subtitle: Text('ID: ${cycles_transfer_out.id}'),
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
                                            SelectableText('for: ${cycles_transfer_out.for_the_canister.text}'),
                                            SelectableText('cycles_sent: ${cycles_transfer_out.cycles_sent}'),
                                            SelectableText('cycles_refunded: ${cycles_transfer_out.cycles_refunded != null ? cycles_transfer_out.cycles_refunded! : 'waiting for the callback'}'),
                                            SelectableText('cycles-transfer-memo: ${cycles_transfer_out.cycles_transfer_memo}'),
                                            SelectableText('transfer-call-status: ${cycles_transfer_out.cycles_refunded == null ? 'waiting for the callback' : cycles_transfer_out.opt_cycles_transfer_call_error == null ? 'complete' : 'error: ${cycles_transfer_out.opt_cycles_transfer_call_error!}'}'),
                                            SelectableText('cycles_transferrer_fee: ${cycles_transfer_out.fee_paid}'),
                                            SelectableText('timestamp: ${seconds_of_the_nanos(cycles_transfer_out.timestamp_nanos)}'),
                                        ]                            
                                    ),
                                )
                            )
                        )
                    ]
                )
            )            
        );
    }
}


