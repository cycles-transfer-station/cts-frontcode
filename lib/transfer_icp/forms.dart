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



class UserTransferIcpForm extends StatefulWidget {
    UserTransferIcpForm({super.key});
    @override 
    State createState() => UserTransferIcpFormState(); 
}
class UserTransferIcpFormState extends State<UserTransferIcpForm> {
    GlobalKey<FormState> form_key = GlobalKey<FormState>();
    
    late IcpTokens icp;
    late String to;
    late Nat64 memo;
    

    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
        
        const double datatable_text_fontsize = 13.0;
        
        return Form(
            key: form_key,
            child: Column(
                children: <Widget>[
                    Container(
                        width: double.infinity,
                        padding: EdgeInsets.fromLTRB(11,7,11,17),
                        child: DataTable(
                            headingRowHeight: 0,
                            showBottomBorder: true,
                            //dataRowHeight: 14,
                            dividerThickness: 0.0,
                            columns: <DataColumn>[
                                DataColumn(
                                    label: Expanded(
                                        child: Text(
                                            '',
                                        ),
                                    ),
                                ),
                                DataColumn(
                                    label: Expanded(
                                        child: Text(
                                            '',
                                        )
                                    )
                                )
                            ],
                            rows: [
                                DataRow(
                                    cells: [
                                        DataCell(Text('ICP TRANSFER FEE XDR: ', style: TextStyle(fontSize: datatable_text_fontsize))),
                                        DataCell(Text('${state.cts_fees.cts_transfer_icp_fee.cycles/CYCLES_PER_XDR}-xdr', style: TextStyle(fontSize: datatable_text_fontsize))),
                                    ]
                                ),
                                DataRow(
                                    cells: [
                                        DataCell(Text('CURRENT XDR-ICP RATE: ', style: TextStyle(fontSize: datatable_text_fontsize))),
                                        DataCell(Text('${state.xdr_icp_rate_with_a_timestamp!.xdr_icp_rate.xdr_permyriad_per_icp/BigInt.from(10000)}', style: TextStyle(fontSize: datatable_text_fontsize))),
                                    ]
                                ),
                                DataRow(
                                    cells: [
                                        DataCell(Text('ICP LEDGER FEES: ', style: TextStyle(fontSize: datatable_text_fontsize))),
                                        DataCell(Text('${ICP_LEDGER_TRANSFER_FEE_TIMES_TWO}-icp', style: TextStyle(fontSize: datatable_text_fontsize))),
                                    ]
                                ),
                                DataRow(
                                    cells: [
                                        DataCell(Text('ICP TRANSFER TOTAL COST: ', style: TextStyle(fontSize: datatable_text_fontsize))),
                                        DataCell(Text('${cycles_to_icptokens(state.cts_fees.cts_transfer_icp_fee, state.xdr_icp_rate_with_a_timestamp!.xdr_icp_rate) + ICP_LEDGER_TRANSFER_FEE_TIMES_TWO}-icp', style: TextStyle(fontSize: datatable_text_fontsize))),
                                    ]
                                ),
                            ]
                        )
                    ),
                    TextFormField(
                        decoration: InputDecoration(
                            labelText: 'for: ',
                        ),
                        onSaved: (String? value) { to = value!.trim().toLowerCase(); },
                        validator: icp_id_string_validator          
                    ),
                    TextFormField(
                        decoration: InputDecoration(
                            labelText: 'icp: '
                        ),
                        onSaved: (String? value) { icp = IcpTokens.oftheDoubleString(value!); },
                        validator: icp_validator
                    ),
                    TextFormField(
                        decoration: InputDecoration(
                            labelText: 'memo: '
                        ),
                        onSaved: (String? value) { memo = value == null || value == '' ? Nat64(BigInt.from(0)) : Nat64(BigInt.parse(value)); },
                        validator: (String? value) {
                            String error_string = 'Invalid memo. An icp memo is a number between 0 and 2^64 - 1';
                            try {
                                Nat64 n = Nat64(value == null || value == '' ? BigInt.from(0) : BigInt.parse(value, radix: 10));
                            } catch(e) {
                                return error_string;
                            }
                            return null;
                        }                        
                    ),
                    Padding(
                        padding: EdgeInsets.fromLTRB(7, 17, 7,7),
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: blue),
                            child: Text('TRANSFER ICP'),
                            onPressed: () async {
                                if (form_key.currentState!.validate()==true) {
                                    
                                    form_key.currentState!.save();
                                    
                                    TransferIcpQuest transfer_icp_quest = TransferIcpQuest(
                                        icp:icp,
                                        icp_fee: ICP_LEDGER_TRANSFER_FEE, 
                                        to:to,
                                        memo:memo,
                                    );
                                    
                                    state.loading_text = 'transferring icp ...';
                                    state.is_loading = true;
                                    MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                                    
                                    late TransferIcpSuccess transfer_icp_success;
                                    try {
                                        transfer_icp_success = await state.user!.transfer_icp(transfer_icp_quest);
                                    } catch(e) {
                                        await showDialog(
                                            context: state.context,
                                            builder: (BuildContext context) {
                                                return AlertDialog(
                                                    title: Text('Transfer Icp Error:'),
                                                    content: Text('${e}'),
                                                    actions: <Widget>[
                                                        TextButton(
                                                            onPressed: () => Navigator.pop(context),
                                                            child: const Text('OK'),
                                                        ),
                                                    ]
                                                );
                                            }   
                                        );                                    
                                        state.is_loading = false;
                                        main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);                                                                    
                                        return;
                                    }
                                    
                                    form_key.currentState!.reset();
                                    state.loading_text = 'Icp transfer is success. Block height: ${transfer_icp_success.block_height.value}\nloading icp balance and transfers list ...';
                                    main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);
                                    
                                    try {
                                        await Future.wait([
                                            state.user!.fresh_icp_balance(),
                                            state.user!.fresh_icp_transfers(),
                                        ]);
                                    } catch(e) {
                                        await showDialog(
                                            context: state.context,
                                            builder: (BuildContext context) {
                                                return AlertDialog(
                                                    title: Text('Error when loading the user icp balance and the transfers list:'),
                                                    content: Text('${e}'),
                                                    actions: <Widget>[
                                                        TextButton(
                                                            onPressed: () => Navigator.pop(context),
                                                            child: const Text('OK'),
                                                        ),
                                                    ]
                                                );
                                            }   
                                        );                                    
                                    }
                                
                                    await showDialog(
                                        context: state.context,
                                        builder: (BuildContext context) {
                                            return AlertDialog(
                                                title: Text('Icp Transfer Success:'),
                                                content: Text('transfer block height: ${transfer_icp_success.block_height.value}'),
                                                actions: <Widget>[
                                                    TextButton(
                                                        onPressed: () => Navigator.pop(context),
                                                        child: const Text('OK'),
                                                    ),
                                                ]
                                            );
                                        }   
                                    ); 
                                    
                                    state.is_loading = false;
                                    main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);
                                    
                                }
                            }
                        )
                    )
                ]
            )
        );
    }
}






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
        icpts = IcpTokens.oftheDoubleString(value);
    } catch(e) {
        return e_s;
    }
    if (icpts.e8s == BigInt.from(0)) {
        return e_s;
    }
    return null;           
};



