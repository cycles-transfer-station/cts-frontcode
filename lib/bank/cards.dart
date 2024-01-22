import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:ic_tools/tools.dart';
import 'package:ic_tools/common.dart' as ic_tools_common;
import 'package:ic_tools/candid.dart' show candid_text_hash, Blob;

import '../user.dart';
import '../config/state.dart';
import '../config/state_bind.dart';
import '../tools/tools.dart';


const double ct_list_item_body_font_size = 17;

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
        
        String? show_ctmemo_blob_as_text;
        if (cycles_transfer_in.cycles_transfer_memo.keys.first == candid_text_hash('Blob')) {
            Uint8List b = (cycles_transfer_in.cycles_transfer_memo.values.first as Blob).bytes;
            if (cycles_transfer_in.by_the_canister == ic_tools_common.SYSTEM_CANISTERS.cycles_mint.principal) { 
                if (utf8.decode(b.sublist(0,8)) == 'CMC-MINT') {
                    show_ctmemo_blob_as_text = 'CMC-MINT-' + bigint_of_the_be_bytes(Uint8List.fromList(b.sublist(8,16))).toString();
                }
            }            
        }
        
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
                        Container(
                            padding: EdgeInsets.fromLTRB(17,7,17,7),
                            width: double.infinity, 
                            child: SingleChildScrollView(
                                child: DefaultTextStyle.merge(
                                    style: TextStyle(fontFamily: 'CourierNew', fontSize: ct_list_item_body_font_size),
                                    child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                            SelectableText('cycles: ${cycles_transfer_in.cycles}'),
                                            SelectableText('memo: ${show_ctmemo_blob_as_text ?? cycles_transfer_in.cycles_transfer_memo}'),
                                            SelectableText('by: ${cycles_transfer_in.by_the_canister.text}'),
                                            SelectableText('timestamp: ${log_timestamp_format(DateTime.fromMillisecondsSinceEpoch(milliseconds_of_the_nanos(cycles_transfer_in.timestamp_nanos).toInt()))}'),
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
                        Container(
                            padding: EdgeInsets.fromLTRB(17,7,17,7),
                            width: double.infinity, 
                            child: SingleChildScrollView(
                                child: DefaultTextStyle.merge(
                                    style: TextStyle(fontFamily: 'CourierNew', fontSize: ct_list_item_body_font_size),
                                    child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                            SelectableText('for: ${cycles_transfer_out.for_the_canister.text}'),
                                            SelectableText('cycles-sent: ${cycles_transfer_out.cycles_sent}'),
                                            SelectableText('cycles-refunded: ${cycles_transfer_out.cycles_refunded != null ? cycles_transfer_out.cycles_refunded! : 'waiting for the callback'}'),
                                            SelectableText('memo: ${cycles_transfer_out.cycles_transfer_memo}'),
                                            SelectableText('status: ${cycles_transfer_out.cycles_refunded == null ? 'waiting for the callback' : cycles_transfer_out.opt_cycles_transfer_call_error == null ? 'complete' : 'error: ${cycles_transfer_out.opt_cycles_transfer_call_error!}'}'),
                                            SelectableText('timestamp: ${log_timestamp_format(DateTime.fromMillisecondsSinceEpoch(milliseconds_of_the_nanos(cycles_transfer_out.timestamp_nanos).toInt()))}'),
                                        ]                            
                                    )
                                ),
                            )
                        )
                    ]
                )
            )            
        );
    }
}


String log_timestamp_format(DateTime t) {
    DateTime now = DateTime.now();
    String s = '${t.hour}:${t.minute}:${t.second}';
    if ((now.year, now.month, now.day) != (t.year, t.month, t.day)) {
        s = s + ' ${t.month}/${t.day}/${t.year}';
    } 
    return s;
}


