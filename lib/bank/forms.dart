import 'dart:typed_data';
import 'dart:convert';
import 'dart:html' show window;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:ic_tools/ic_tools.dart';
import 'package:ic_tools/candid.dart' show Nat, Int, Blob, Record, Option, Nat64, Nat8, Vector;
import 'package:ic_tools/candid.dart' as candid;
import 'package:ic_tools/common.dart';
import 'package:ic_tools/common.dart' as common;
import 'package:ic_tools/tools.dart';

import '../config/state.dart';
import '../config/state_bind.dart';
import '../config/pages.dart';
import '../config/urls.dart';
import '../transfer_icp/forms.dart';
import '../transfer_icp/scaffold_body.dart';
import '../transfer_icp/icp_ledger.dart';
import '../main.dart';
import '../user.dart';
import '../tools/tools.dart';



enum CyclesTransferMemoType {
    Text,
    Nat,
    Blob,
    Int
}

final String? Function(String?) cycles_transfer_memo_validator_text = (String? value) {
    return null;
};
final String? Function(String?) cycles_transfer_memo_validator_nat = (String? value) {
    if (value == null || value == '') {
        return 'Must be a number';
    }
    try {
        Nat nat = Nat(BigInt.parse(value, radix: 10));
    } catch(e) {
        return 'Must be a number >= 0 and without decimal places';
    }
    return null;
};
final String? Function(String?) cycles_transfer_memo_validator_int = (String? value) {
    if (value == null || value == '') {
        return 'Must be a number';
    }
    try {
        Int int_ = Int(BigInt.parse(value, radix: 10));
    } catch(e) {
        return 'Must be a number and without decimal places';
    }
    return null;
};
final String? Function(String?) cycles_transfer_memo_validator_blob = (String? value) {
    if (value == null || value == '') {
        return null;
    }
    for (String char in value.trim().toLowerCase().split('')) {
        if (lower_case_hex_chars.contains(char) == false && number_chars.contains(char) == false) {
            return 'Blob is in the hex format. hex format characters are 0-9 a-f.';
        }
    }
    if (value.trim().length > 64) {
        return 'max 32 bytes.';
    }
    return null;        
};

final Map<CyclesTransferMemoType, String? Function(String?)> cycles_transfer_memo_validators_map = {
    CyclesTransferMemoType.Nat: cycles_transfer_memo_validator_nat,
    CyclesTransferMemoType.Text: cycles_transfer_memo_validator_text,
    CyclesTransferMemoType.Blob: cycles_transfer_memo_validator_blob,
    CyclesTransferMemoType.Int: cycles_transfer_memo_validator_int,
};


final String? Function(String?) tcycles_validator = (String? v) {
    if (v == null || v == '') {
        return 'Must be a number';
    }
    late Cycles cycles;
    try {
        cycles = Cycles.oftheTCyclesDoubleString(v.trim());
    } catch(e) {
        return 'Must be a number > 0, max 12 decimal places';
    }
    if (cycles.cycles == BigInt.from(0)) {
        return 'Must be a number > 0';
    }
    return null;
};


final String? Function(String?) cycles_bank_principal_validator = (String? v) {
    if (v == null || v.trim() == '') {
        return 'Write the text-principal-id of a cycles-bank';
    }
    late Principal p;
    try {
        p = Principal.text(v.trim());
    } catch(e) {
        return 'invalid cycles-bank-principal-id';
    }
    if (p.bytes.length == 0) {
        return 'value must be the text-principal-id of a cycles-bank';
    }
    if (p.bytes.length >= 29) {
        return 'Must be a cycles-bank princpal-id'; // Transfer cycles between canisters. Make sure that these cycles are for a canister-id.
    }
    return null;
};


/*

class CyclesBankTransferCyclesForm extends StatefulWidget {
    CyclesBankTransferCyclesForm({super.key});
    State createState() => CyclesBankTransferCyclesFormState();
}
class CyclesBankTransferCyclesFormState extends State<CyclesBankTransferCyclesForm> {
    GlobalKey<FormState> form_key = GlobalKey<FormState>();
    
    late Principal for_the_canister;
    late Cycles cycles;
    late CyclesTransferMemo cycles_transfer_memo;
    
    CyclesTransferMemoType cycles_transfer_memo_type = CyclesTransferMemoType.Text;
    
    
    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
        
        
        String? for_the_cycles_bank_initial_value;
        String? tcycles_initial_value;
        String? memo_initial_value;
        
        if (state.current_url.name == 'cycles_bank_pay') {
            if (
                cycles_bank_principal_validator(state.current_url.variables['for_the_cycles_bank']) == null
                && tcycles_validator(state.current_url.variables['Tcycles']) == null
                && CyclesTransferMemoType.values.map((mt)=>mt.name).toList().contains(state.current_url.variables['memo_type'])
                && cycles_transfer_memo_validators_map[CyclesTransferMemoType.values.byName(state.current_url.variables['memo_type']!)]!(state.current_url.variables['memo']) == null
            ) {
                for_the_cycles_bank_initial_value = state.current_url.variables['for_the_cycles_bank'];
                tcycles_initial_value = state.current_url.variables['Tcycles'];
                cycles_transfer_memo_type = CyclesTransferMemoType.values.byName(state.current_url.variables['memo_type']!);
                memo_initial_value = state.current_url.variables['memo'];                            
            } else {
                print('pre-fill payment data is invalid');
                WidgetsBinding.instance.addPostFrameCallback((_) {
                    state.current_url = CustomUrl('cycles_bank');
                    main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);
                    Future(()async{
                        await Future.delayed(Duration(milliseconds: 500));
                        showDialog(
                            context: state.context,
                            builder: (BuildContext context) {
                                return AlertDialog(
                                    title: Text("Alert"),
                                    content: Text('The pre-fill payment data is invalid.'),
                                    actions: [
                                        TextButton(
                                            child: Text("OK"),
                                            onPressed:  () {
                                                Navigator.of(context).pop();
                                            },
                                        )
                                    ],
                                );
                            }
                        );
                    });
                });
            }
        }
                
        
        return Form(
            key: form_key,
            child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                    /*
                    Container(
                        width: double.infinity,
                        padding: EdgeInsets.fromLTRB(7,11,7,11),
                        child: Center(
                            child: Text('TRANSFER-CYCLES', style: TextStyle(fontSize:17))
                        ),
                    ),
                    */
                    TextFormField(
                        decoration: InputDecoration(
                            labelText: 'For the cycles-bank: ',
                        ),
                        initialValue: for_the_cycles_bank_initial_value,
                        onSaved: (String? v) { for_the_canister = Principal.text(v!.trim()); },
                        validator: cycles_bank_principal_validator
                    ),
                    TextFormField(
                        decoration: InputDecoration(
                            labelText: 'TCYCLES: ',
                        ),
                        initialValue: tcycles_initial_value,
                        onSaved: (String? v) { cycles = Cycles.oftheTCyclesDoubleString(v!.trim()); },
                        validator: tcycles_validator
                    ),
                    DropdownButtonFormField<CyclesTransferMemoType>(
                        decoration: InputDecoration(
                            labelText: 'Cycles Transfer Memo: ',
                        ),
                        items: const [
                            DropdownMenuItem<CyclesTransferMemoType>(child: Text('Text'), value: CyclesTransferMemoType.Text ),
                            DropdownMenuItem<CyclesTransferMemoType>(child: Text('Int'), value: CyclesTransferMemoType.Int ),
                            DropdownMenuItem<CyclesTransferMemoType>(child: Text('Nat'), value: CyclesTransferMemoType.Nat ),
                            DropdownMenuItem<CyclesTransferMemoType>(child: Text('Blob'), value: CyclesTransferMemoType.Blob ),                            
                        ],
                        value: cycles_transfer_memo_type,
                        onChanged: (CyclesTransferMemoType? select_cycles_transfer_memo_type) { 
                            if (select_cycles_transfer_memo_type is CyclesTransferMemoType) { 
                                setState(() {
                                    this.cycles_transfer_memo_type = select_cycles_transfer_memo_type; 
                                });
                            }
                        }
                    ),
                    TextFormField(
                        initialValue: memo_initial_value,
                        onSaved: (String? v) { 
                            switch (cycles_transfer_memo_type) {
                                case CyclesTransferMemoType.Text: 
                                    cycles_transfer_memo = CyclesTransferMemo.text(candid.Text(v ?? ''));
                                break;
                                case CyclesTransferMemoType.Int: 
                                    cycles_transfer_memo = CyclesTransferMemo.int_(Int(BigInt.parse((v == null || v.trim() == '') ? '0' : v, radix: 10)));
                                break;
                                case CyclesTransferMemoType.Nat: 
                                    cycles_transfer_memo = CyclesTransferMemo.nat(Nat(BigInt.parse((v == null || v.trim() == '') ? '0' : v, radix: 10)));
                                break;
                                case CyclesTransferMemoType.Blob: 
                                    cycles_transfer_memo = CyclesTransferMemo.blob(Blob((v == null || v.trim() == '') ? [] : hexstringasthebytes(v.trim().toLowerCase())));
                                break;
                            }
                        },
                        validator: cycles_transfer_memo_validators_map[cycles_transfer_memo_type]!
                    ),
                    Padding(
                        padding: EdgeInsets.all(7),
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: blue),
                            child: Text('TRANSFER CYCLES'),
                            onPressed: () async {
                                if (form_key.currentState!.validate()==true) {
                                    
                                    form_key.currentState!.save();
                                    /*
                                    bool _continue = false;
                                    await showDialog(
                                        context: state.context,
                                        builder: (BuildContext context) {
                                            Widget cancelButton = TextButton(
                                                child: Text("Cancel"),
                                                onPressed:  () {
                                                    Navigator.of(context).pop();
                                                },
                                            );
                                            Widget continueButton = TextButton(
                                                child: Text("Continue"),
                                                onPressed:  () {
                                                    _continue = true;
                                                    Navigator.of(context).pop();
                                                },
                                            );
                                            return AlertDialog(
                                                title: Text("Confirm"),
                                                content: Text(
"""Cycles transfers are sent using the cycles-transfer-specification.
For a temporary safegaurd, cycles-transfers are routed through a safe-transferrer with a fee: 0.02-xdr and cycles-transfers sent to external (not made by the CYCLES-TRANSFER-STATION) cycles-banks (or canister-smart-contracts) will not see the cycles-bank-id as the transferrer. (Soon when the smart-contract safe-upgrades feature is complete, there will be no fee, and transfers to external smart-contracts will see the correct cycles-bank-id as the transferrer.)
"""                                             
                                                ),
                                                actions: [
                                                    cancelButton,
                                                    continueButton,
                                                ],
                                            );
                                        }
                                    );     
                                    if (_continue == false) {
                                        return;
                                    }
                                    */
                                
                                    UserTransferCyclesQuest transfer_cycles_quest = UserTransferCyclesQuest(
                                        for_the_canister:for_the_canister,
                                        cycles:cycles, 
                                        cycles_transfer_memo:cycles_transfer_memo,
                                    );
                                    
                                    state.loading_text = 'transferring cycles ...';
                                    state.is_loading = true;
                                    //MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                                    main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);
                                    
                                    late TransferCyclesSponse transfer_cycles_sponse;
                                    try {
                                        transfer_cycles_sponse = await state.user!.cycles_bank!.transfer_cycles(transfer_cycles_quest);
                                    } catch(e) {
                                        print(e);
                                        await showDialog(
                                            context: state.context,
                                            builder: (BuildContext context) {
                                                return AlertDialog(
                                                    title: Text('Transfer Cycles Error:'),
                                                    content: Text('${etext(e)}'),
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
                                    state.loading_text = 
"""cycles-transfer-id: ${transfer_cycles_sponse.cycles_transfer_id}
cycles-sent: ${transfer_cycles_quest.cycles}
cycles-refunded: ${transfer_cycles_sponse.cycles_refund}
transfer-call-response: ${transfer_cycles_sponse.opt_cycles_transfer_call_error == null ? 'success' : transfer_cycles_sponse.opt_cycles_transfer_call_error!.toString()}  

loading cycles balance and transfers list ...""";
                                    main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);
                                
                                    Future success_dialog = showDialog(
                                        context: state.context,
                                        builder: (BuildContext context) {
                                            return AlertDialog(
                                                title: Text('Transfer sent:'),
                                                content: Text(state.loading_text),
                                                actions: <Widget>[
                                                    TextButton(
                                                        onPressed: () => Navigator.pop(context),
                                                        child: const Text('OK'),
                                                    ),
                                                ]
                                            );
                                        }   
                                    );
                                
                                    try {
                                        await Future.wait([
                                            state.user!.cycles_bank!.fresh_metrics(),
                                            state.user!.cycles_bank!.fresh_cycles_transfers_out()
                                        ]);
                                    } catch(e) {
                                        await showDialog(
                                            context: state.context,
                                            builder: (BuildContext context) {
                                                return AlertDialog(
                                                    title: Text('Error when loading the cycles balance and the transfers list:'),
                                                    content: Text('${etext(e)}'),
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
                                    
                                    await success_dialog;
                                    
                                    state.is_loading = false;
                                    
                                    if (state.current_url.name == 'cycles_bank_pay') {
                                        state.current_url = CustomUrl('cycles_bank');
                                    } 
                                    
                                    main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);
                                    
                                    Future.delayed(Duration(milliseconds: 20), () async { Navigator.pop(state.context); });
                                }
                            }
                        )
                    )
                ]
            )
        );  
    }
}
*/




class Icrc1TokenBalanceAndLoadIcrc1TokenBalance extends StatelessWidget {
    final Icrc1Ledger icrc1_ledger;
    Icrc1TokenBalanceAndLoadIcrc1TokenBalance(this.icrc1_ledger, {super.key});
    
    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);

        
        return Padding(
            padding: EdgeInsets.fromLTRB(13.0, 13, 13,13),
            child: Column(
                children: [
                    Text('${this.icrc1_ledger == CYCLES_BANK_LEDGER ? 'CYCLES' : this.icrc1_ledger.symbol}-BALANCE: ${state.user!.icrc1_balances_cache[this.icrc1_ledger] == null ? 'unknown' : this.icrc1_ledger == CYCLES_BANK_LEDGER ? Cycles(cycles: state.user!.icrc1_balances_cache[this.icrc1_ledger]!) : Tokens(quantums: state.user!.icrc1_balances_cache[this.icrc1_ledger]!, decimal_places: this.icrc1_ledger.decimals)}', style: TextStyle(fontSize:17)),
                    //Text('timestamp: ${state.user!.icp_balance != null ? seconds_of_the_nanos(state.user!.icp_balance!.timestamp_nanos) : 'unknown'}', style: TextStyle(fontSize:9)),
                    Padding(
                        padding: EdgeInsets.fromLTRB(7,13,7,7),
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: blue),
                            child: Text('LOAD BALANCE', style: TextStyle(fontSize:11)),
                            onPressed: () async {
                                state.loading_text = 'load bank ${this.icrc1_ledger.symbol} balance ...';
                                state.is_loading = true;
                                MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                                try {
                                    await state.user!.fresh_icrc1_balances([this.icrc1_ledger]);
                                } catch(e) {
                                    await showDialog(
                                        context: state.context,
                                        builder: (BuildContext context) {
                                            return AlertDialog(
                                                title: Text('Error when checking the bank ${this.icrc1_ledger.symbol} balance:'),
                                                content: Text('${etext(e)}'),
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
                                state.is_loading = false;
                                main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);
                            }
                        )
                    ),   
                ]
            )
        );
    }
}



class BankIcrc1IdAndBalanceAndLoadBalanceAndFee extends StatelessWidget {
    final Icrc1Ledger icrc1_ledger;
    final bool show_transfer_fee;
    BankIcrc1IdAndBalanceAndLoadBalanceAndFee(this.icrc1_ledger, {super.key, this.show_transfer_fee = true});
    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
        String bank_icrc1_account_id = this.icrc1_ledger.ledger.principal == common.SYSTEM_CANISTERS.ledger.principal ? state.user!.icp_id : state.user!.principal.text;
        return Column(
            children: [
                Container(
                    padding: EdgeInsets.all(7),
                    child: Column(
                        children: [
                            Center(
                                child: SelectableText('BANK-${icrc1_ledger == CYCLES_BANK_LEDGER ? 'CYCLES' : icrc1_ledger.symbol}-ID:', style: TextStyle(fontSize: 13)),
                            ),
                            Center(
                                child: SelectableText('${bank_icrc1_account_id}', style: TextStyle(fontSize: 11)),
                            ),
                            SizedBox(
                                height: 11,
                                width: 3,
                            ),
                            Icrc1TokenBalanceAndLoadIcrc1TokenBalance(this.icrc1_ledger, key: ValueKey('CyclesBankScaffoldBody BankTransferIcrc1Tokens Icrc1TokenBalanceAndLoadIcrc1TokenBalance'))
                        ]
                    )
                ),
                if (this.show_transfer_fee) ...[
                    SizedBox(
                        width: 1,
                        height: 11
                    ),
                    Container(
                        width: double.infinity,
                        child: Text('ledger-transfer-fee: ${Tokens(quantums: this.icrc1_ledger.fee, decimal_places: this.icrc1_ledger.decimals)}', style: TextStyle(fontSize: 13))
                    ),
                ],
                /*
                Container(
                    width: double.infinity,
                    child: DataTable(
                        headingRowHeight: 0,
                        showBottomBorder: true,
                        columns: <DataColumn>[
                            DataColumn(label: Text('')),
                            DataColumn(label: Text('')),
                        ],
                        rows: [
                            DataRow(
                                cells: [
                                    DataCell(Text('ledger-transfer-fee:', )),
                                    DataCell(Text('${Tokens(quantums: this.icrc1_ledger.fee, decimal_places: this.icrc1_ledger.decimals)}-${this.icrc1_ledger.symbol}')),
                                ]
                            ),
                        ]
                    )
                ),
                */
            ]
        );  
    }
}



class BankTransferIcrc1Form extends StatefulWidget {
    final Icrc1Ledger icrc1_ledger;
    BankTransferIcrc1Form({super.key, required this.icrc1_ledger});
    State createState() => BankTransferIcrc1FormState();
}
class BankTransferIcrc1FormState extends State<BankTransferIcrc1Form> {
    GlobalKey<FormState> form_key = GlobalKey<FormState>();
    
    late Icrc1Account for_the_icrc1_id;
    late Tokens tokens;
    late Uint8List memo;    
    
    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
                
        return Form(
            key: form_key,
            child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                    TextFormField(
                        decoration: InputDecoration(
                            labelText: 'For: ',
                        ),
                        onSaved: (String? v) { for_the_icrc1_id = Icrc1Account.of_the_id(v!.trim()); },
                        validator: (String? v) {
                            if (v == null || v.trim() == '') {
                                return 'Type the account-id';
                            }
                            late Icrc1Account icrc_id;
                            try {
                                icrc_id = Icrc1Account.of_the_id(v);
                            } catch(e) {
                                return 'Must be a valid ICRC ID.';
                            }
                            return null;
                        }
                    ),
                    TextFormField(
                        decoration: InputDecoration(
                            labelText: 'Tokens: ',
                        ),
                        onSaved: (String? v) { tokens = Tokens.of_the_double_string(v!, decimal_places: widget.icrc1_ledger.decimals); },
                        validator: tokens_validator(token_decimal_places: widget.icrc1_ledger.decimals)
                    ),
                    TextFormField(
                        decoration: InputDecoration(
                            labelText: 'Memo: ',
                        ),
                        onSaved: (String? v) { 
                            if (v == null || v.trim() == '') {
                                memo = Uint8List(0);
                                return;
                            } else {
                                memo = hexstringasthebytes(v);
                            }
                        },
                        validator: (String? value) {
                            if (value == null || value.trim().length == 0) {
                                return null;
                            }
                            for (String char in value.trim().toLowerCase().split('')) {
                                if (lower_case_hex_chars.contains(char) == false && number_chars.contains(char) == false) {
                                    return 'An Icrc1 transfer memo is in the hex format. hex format characters are 0-9 a-f.';
                                }
                            }
                            if (value.trim().length > 64) {
                                return 'Max 32-bytes (64 hex characters)';
                            }
                            if (value.trim().length % 2 != 0) {
                                return 'Must be even amount of hexidecimal characters';
                            }
                            return null;                            
                        }
                    ),
                    Padding(
                        padding: EdgeInsets.all(7),
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: blue),
                            child: Text('TRANSFER ${widget.icrc1_ledger == CYCLES_BANK_LEDGER ? 'CYCLES' : widget.icrc1_ledger.symbol}'),
                            onPressed: () async {
                                if (form_key.currentState!.validate()==true) {
                                    
                                    form_key.currentState!.save();
                                    
                                    bool _continue = false;
                                    
                                    await showDialog(
                                        context: state.context,
                                        builder: (BuildContext context) {
                                            Widget cancelButton = TextButton(
                                                child: Text("Cancel"),
                                                onPressed:  () {
                                                    Navigator.of(context).pop();
                                                },
                                            );
                                            Widget continueButton = TextButton(
                                                child: Text("Continue"),
                                                onPressed:  () {
                                                    _continue = true;
                                                    Navigator.of(context).pop();
                                                },
                                            );
                                            return AlertDialog(
                                                title: Text("Confirm"),
                                                content: Text(
(widget.icrc1_ledger.ledger.principal == CYCLES_BANK_LEDGER.ledger.principal
&& for_the_icrc1_id.owner.bytes.length < 29 
? 'Looks like you are trying to send CYCLES to a canister. This form transfers CYCLES to an account at the CTS. If you are looking to topup a canister with CYCLES or deposit CYCLES onto a canister, use the MANAGEMENT-CANISTER-DEPOSIT-CYCLES form in the BANK settings by clicking the gears icon on the BANK page. If you are looking to send CYCLES to an account at the CTS, then continue with this form.\n\n'  
: '') + 'Transfer ${tokens}-${widget.icrc1_ledger.symbol} to ${for_the_icrc1_id}?'                                             
                                                ),
                                                actions: [
                                                    cancelButton,
                                                    continueButton,
                                                ],
                                            );
                                        }
                                    );     
                                    if (_continue == false) {
                                        return;
                                    }
                                
                                    Uint8List icrc1_transfer_arg_raw = candid.c_forwards([
                                        Record.of_the_map({
                                            //'from_subaccount' : opt Subaccount;
                                            'to' : for_the_icrc1_id,
                                            'amount' : tokens,
                                            'fee' : Option<Nat>(value: widget.icrc1_ledger.fee_tokens),
                                            'memo' : Option<Vector<Nat8>>(value: memo != null ? Blob(memo) : null, value_type: Blob.type_mode()),
                                        })
                                    ]);
                                
                                    state.loading_text = 'transferring ${tokens}-${widget.icrc1_ledger.symbol} to ${for_the_icrc1_id} ...';
                                    state.is_loading = true;
                                    //MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                                    main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);
                                    
                                    late BigInt transfer_block_i;
                                    try {
                                        transfer_block_i = await state.user!.transfer_icrc1(widget.icrc1_ledger, icrc1_transfer_arg_raw);
                                    } catch(e,s) {
                                        print(e);
                                        print(s);
                                        await showDialog(
                                            context: state.context,
                                            builder: (BuildContext context) {
                                                return AlertDialog(
                                                    title: Text('Transfer error:'),
                                                    content: Text('${etext(e)}'),
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
                                    state.loading_text = 'transfer sent. transfer block: ${transfer_block_i}\nloading current balance ...'; // and loading transfer-logs
                                    main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);
                                
                                    Future success_dialog = showDialog(
                                        context: state.context,
                                        builder: (BuildContext context) {
                                            return AlertDialog(
                                                title: Text('Transfer Success:'),
                                                content: Text('Block: ${transfer_block_i}'),
                                                actions: <Widget>[
                                                    TextButton(
                                                        onPressed: () => Navigator.pop(context),
                                                        child: const Text('OK'),
                                                    ),
                                                ]
                                            );
                                        }   
                                    );
                                
                                    try {
                                        await Future.wait([
                                            state.user!.fresh_icrc1_balances([widget.icrc1_ledger]),
                                            state.user!.fresh_icrc1_transactions([widget.icrc1_ledger]),
                                        ]);
                                    } catch(e) {
                                        await showDialog(
                                            context: state.context,
                                            builder: (BuildContext context) {
                                                return AlertDialog(
                                                    title: Text('Error when loading ${widget.icrc1_ledger.symbol} balance:'),
                                                    content: Text('${etext(e)}'),
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
                                    
                                    await success_dialog;
                                    
                                    state.is_loading = false;
                                                                        
                                    main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);
                                    
                                    Future.delayed(Duration(milliseconds: 20), () async { Navigator.pop(state.context); });
                                    
                                }
                            }
                        )
                    )
                ]
            )
        );  
    }
}



String? Function(String?) tokens_validator({required int token_decimal_places}) {
    return 
        (String? v) {
            if (v == null || v == '') {
                return 'Must be a number';
            }
            late Tokens t;
            try {
                t = Tokens.of_the_double_string(v, decimal_places: token_decimal_places);
            } catch(e) {
                return 'Must be a number > 0, max ${token_decimal_places} decimal places';
            }
            if (t.quantums == BigInt.from(0)) {
                return 'Must be a number > 0';
            }
            return null;
        };
}

String? Function(String?) cycles_per_token_rate_validator({required int token_decimal_places}) {
    return tokens_validator(token_decimal_places: Cycles.T_CYCLES_DECIMAL_PLACES - token_decimal_places);
}




class BankTransferIcpForm extends StatefulWidget {
    BankTransferIcpForm({super.key});
    @override 
    State createState() => BankTransferIcpFormState(); 
}
class BankTransferIcpFormState extends State<BankTransferIcpForm> {
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
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                    /*
                    Container(
                        width: double.infinity,
                        padding: EdgeInsets.fromLTRB(11,7,11,17),
                        child: DataTable(
                            headingRowHeight: 0,
                            showBottomBorder: true,
                            //dataRowHeight: 14,
                            dividerThickness: 0.0,
                            columns: <DataColumn>[
                                DataColumn(label: Text('')),
                                DataColumn(label: Text(''))
                            ],
                            rows: [
                                DataRow(cells: [
                                    DataCell(Text('LEDGER-FEE: ', style: TextStyle(fontSize: datatable_text_fontsize))),
                                    DataCell(Text('${ICP_LEDGER_TRANSFER_FEE}-icp', style: TextStyle(fontSize: datatable_text_fontsize))),
                                ]),
                            ]
                        )
                    ),
                    */
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
                        onSaved: (String? value) { icp = IcpTokens.of_the_double_string(value!); },
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
                                    
                                    Uint8List transfer_icp_quest = candid.c_forwards([
                                        Record.of_the_map({
                                            'memo': memo,
                                            'amount': icp,
                                            'fee': ICP_LEDGER_TRANSFER_FEE,
                                            'from_subaccount': Option<Blob>(value: null, value_type: Blob.type_mode()),
                                            'to': Blob(hexstringasthebytes(to)),
                                        })
                                    ]);
                                    
                                    state.loading_text = 'transferring icp ...';
                                    state.is_loading = true;
                                    MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                                    
                                    late BigInt block;
                                    try {
                                        block = await state.user!.transfer_icp(transfer_icp_quest);
                                    } catch(e) {
                                        await showDialog(
                                            context: state.context,
                                            builder: (BuildContext context) {
                                                return AlertDialog(
                                                    title: Text('Transfer Icp Error:'),
                                                    content: Text('${etext(e)}'),
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
                                    state.loading_text = 'Icp transfer success. Block height: ${block}\nloading icp balance and transfers list ...';
                                    main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);
                                    
                                    Future success_dialog = showDialog(
                                        context: state.context,
                                        builder: (BuildContext context) {
                                            return AlertDialog(
                                                title: Text('Icp Transfer Success:'),
                                                content: Text('transfer block height: ${block}'),
                                                actions: <Widget>[
                                                    TextButton(
                                                        onPressed: () => Navigator.pop(context),
                                                        child: const Text('OK'),
                                                    ),
                                                ]
                                            );
                                        }   
                                    ); 
                                    
                                    try {
                                        await Future.wait([
                                            state.user!.fresh_icrc1_balances([Icrc1Ledgers.ICP]),
                                            state.user!.fresh_icrc1_transactions([Icrc1Ledgers.ICP]),
                                        ]);
                                    } catch(e) {
                                        await showDialog(
                                            context: state.context,
                                            builder: (BuildContext context) {
                                                return AlertDialog(
                                                    title: Text('Error when loading the icp balance and the transfers list:'),
                                                    content: Text('${etext(e)}'),
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
                                
                                    await success_dialog;
                                    
                                    state.is_loading = false;
                                    main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);   
                                
                                    Future.delayed(Duration(milliseconds: 20), () async { Navigator.pop(state.context); });
                                }
                            }
                        )
                    )
                ]
            )
        );
    }
}



class BurnIcpMintCyclesForm extends StatefulWidget {
    BurnIcpMintCyclesForm({super.key});
    State createState() => BurnIcpMintCyclesFormState();
}
class BurnIcpMintCyclesFormState extends State<BurnIcpMintCyclesForm> {
    GlobalKey<FormState> form_key = GlobalKey<FormState>();
    
    late IcpTokens burn_icp;
    
    late Future<BurnIcpMintCyclesSuccess> burn_icp_mint_cycles_future;
    late Future<void> fresh_data_after_burn_icp_mint_cycles_future;
        
    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
                
        return Form(
            key: form_key,
            child: Column(
                children: <Widget>[
                    Container(
                        padding: EdgeInsets.all(0),
                        child: BankIcrc1IdAndBalanceAndLoadBalanceAndFee(Icrc1Ledgers.ICP, show_transfer_fee: false, key: ValueKey('BurnIcpMintCyclesForm BankIcrc1IdAndBalanceAndLoadBalanceAndFee')),
                    ),
                    if (state.user!.bank_user_subaccount_icp_balance > BigInt.zero) ...[
                        Container(
                            width: double.infinity,
                            child: Tooltip(
                                message: 'These funds will be used first.',
                                child: Text(/*'BANK-MINT-CYCLES-ICP-*/'ESCROW-BALANCE: ${IcpTokens(e8s: state.user!.bank_user_subaccount_icp_balance)}', style: TextStyle(fontSize: 15))
                            )
                        ),
                        SizedBox(
                            width: 1,
                            height: 7
                        ),
                    ],
                    SizedBox(
                        width: 1,
                        height: 11
                    ),
                    Container(
                        width: double.infinity,
                        child: DataTable(
                            headingRowHeight: 0,
                            showBottomBorder: true,
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
                                        ),
                                    ),
                                ),
                            ],
                            rows: [
                                DataRow(
                                    cells: [
                                        DataCell(Text('CYCLES PER ICP RATE:', )),
                                        DataCell(Text('${state.cmc_cycles_per_icp_rate}')),
                                    ]
                                ),
                            ]
                        )
                    ),
                    SizedBox(
                        width: 1,
                        height: 17
                    ),
                    Container(
                        width: double.infinity,
                        child: Text('ICP-ledger-fees: ${IcpTokens(e8s: ICP_LEDGER_TRANSFER_FEE.e8s*BigInt.from(2))}', style: TextStyle(fontSize: 13))
                    ),
                    Container(
                        width: double.infinity,
                        child: Text('CYCLES-fee: ${Cycles(cycles: CYCLES_BANK_LEDGER.fee)}', style: TextStyle(fontSize: 13))
                    ),
                    SizedBox(
                        width: 1,
                        height: 17
                    ),
                    TextFormField(
                        key: ValueKey('BurnIcpMintCycles TextFormField burn-icp'),
                        decoration: InputDecoration(
                            labelText: 'Burn ICP: ',
                        ),
                        onSaved: (String? value) { burn_icp = IcpTokens.of_the_double_string(value!.trim()); },
                        validator: (String? v) {
                            String? icp_validator_result = icp_validator(v);
                            if (icp_validator_result != null) {
                                return icp_validator_result;
                            }
                            IcpTokens quest_burn_icp = IcpTokens.of_the_double_string(v!);
                            Cycles max_mint_cycles = Cycles.oftheTCyclesDoubleString('40000');
                            IcpTokens max_burn_icp = IcpTokens(e8s: cycles_transform_tokens(max_mint_cycles, state.cmc_cycles_per_icp_rate));
                            IcpTokens min_burn_icp = IcpTokens(e8s: BigInt.from(10000000));
                            if (quest_burn_icp.e8s > max_burn_icp.e8s) {
                                return 'Max burn icp at once: ${max_burn_icp}';
                            } 
                            if (quest_burn_icp.e8s < min_burn_icp.e8s) {
                                return 'Minimum burn icp: ${min_burn_icp}';
                            }
                            return null;
                        }
                    ),
                    Padding(
                        padding: EdgeInsets.all(7),
                        child: ElevatedButton(
                            key: ValueKey('BurnIcpMintCyclesForm MINT CYCLES GO BUTTON'),
                            style: ElevatedButton.styleFrom(backgroundColor: blue),
                            child: Text('MINT CYCLES'),
                            onPressed: () async {
                                if (form_key.currentState!.validate()==true) {
                                    
                                    form_key.currentState!.save();
                                    
                                    state.loading_text = 'burning icp and minting cycles ...';
                                    state.is_loading = true;
                                    MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                                    
                                    late BurnIcpMintCyclesSuccess burn_icp_mint_cycles_success;
                                    try {
                                        this.burn_icp_mint_cycles_future = state.user!.burn_icp_mint_cycles(burn_icp.e8s);
                                        burn_icp_mint_cycles_success = await this.burn_icp_mint_cycles_future;
                                    } catch(e, s) {
                                        print(e);
                                        print(s);
                                        Future sd = showDialog(
                                            context: state.context,
                                            builder: (BuildContext context) {
                                                return AlertDialog(
                                                    title: Text('Mint Cycles Error:'),
                                                    content: Text('${etext(e)}'),
                                                    actions: <Widget>[
                                                        TextButton(
                                                            onPressed: () => Navigator.pop(context),
                                                            child: const Text('OK'),
                                                        ),
                                                    ]
                                                );
                                            }   
                                        );          
                                        try {
                                            // might have transferred to the bank-user-subaccount
                                            await Future.wait([
                                                state.user!.fresh_bank_user_subaccount_icp_balance(),
                                                state.user!.fresh_icrc1_balances([Icrc1Ledgers.ICP]),
                                                state.user!.fresh_icrc1_transactions([Icrc1Ledgers.ICP]),
                                            ]);
                                        } catch(e) {
                                            window.alert('Error loading icp balances and/or transactions: \n${etext(e)}');
                                        }
                                        await sd;
                                        state.is_loading = false;
                                        main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);                                                                    
                                        return;
                                    }
                                    
                                    form_key.currentState!.reset();
                                    state.loading_text = 'Mint cycles success. \ncycles-mint: ${burn_icp_mint_cycles_success.mint_cycles} \nloading icp-balance, icp-transfers, cycles-balance, and cycles-transfers ...';
                                    main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);
                                    
                                    Future success_dialog = showDialog(
                                        context: state.context,
                                        builder: (BuildContext context) {
                                            return AlertDialog(
                                                title: Text('Mint Cycles Success:'),
                                                content: Text('cycles-mint: ${burn_icp_mint_cycles_success.mint_cycles}', key: ValueKey('mint-cycles-success-dialog-cycles-mint-mount-text-line')),
                                                actions: <Widget>[
                                                    TextButton(
                                                        onPressed: () => Navigator.pop(context),
                                                        child: const Text('OK'),
                                                    ),
                                                ]
                                            );
                                        }   
                                    );
                                    
                                    try {
                                        this.fresh_data_after_burn_icp_mint_cycles_future = Future.wait([
                                            state.user!.fresh_icrc1_balances([Icrc1Ledgers.ICP, CYCLES_BANK_LEDGER]),
                                            state.user!.fresh_icrc1_transactions([Icrc1Ledgers.ICP, CYCLES_BANK_LEDGER]),
                                            state.user!.fresh_bank_user_subaccount_icp_balance(),
                                        ]);
                                        await this.fresh_data_after_burn_icp_mint_cycles_future;
                                    } catch(e) {
                                        await showDialog(
                                            context: state.context,
                                            builder: (BuildContext context) {
                                                return AlertDialog(
                                                    title: Text('Error when loading the icp balance, icp transfers, cycles-balance, and cycles-transfers:'),
                                                    content: Text('${etext(e)}'),
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
                                    
                                    await success_dialog;
                                
                                    state.is_loading = false;
                                    main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);
                                    
                                    Future.delayed(Duration(milliseconds: 20), () async { Navigator.pop(state.context); });
                                }
                            }
                        )
                    )
                ]
            )
        );
    }
}


class ManagementCanisterDepositCyclesForm extends StatefulWidget {
    ManagementCanisterDepositCyclesForm({super.key});
    State createState() => ManagementCanisterDepositCyclesFormState();
}
class ManagementCanisterDepositCyclesFormState extends State<ManagementCanisterDepositCyclesForm> {
    GlobalKey<FormState> form_key = GlobalKey<FormState>();
    
    late Principal canister_id;    
    late Cycles cycles;
        
    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
                
        return Form(
            key: form_key,
            child: Column(
                children: <Widget>[
                    Container(
                        child: Text(
                            'Warning: This form deposits CYCLES onto a canister, topping up the canister with CYCLES. If you are looking to transfer CYCLES to an account at the CTS, use the TRANSFER-CYCLES form on the main BANK page when selecting the CYCLES token.', 
                            style: TextStyle(fontSize: 13, fontFamily: 'ChakraPetch')
                        )
                    ),
                    SizedBox(
                        width: 1,
                        height: 11
                    ),
                    Container(
                        child: Text('Cycles balance: ${Cycles(cycles: state.user!.icrc1_balances_cache[CYCLES_BANK_LEDGER]!)}'),
                    ),
                    TextFormField(
                        key: ValueKey('ManagementCanisterDepositCyclesForm TextFormField canister_id'),
                        decoration: InputDecoration(
                            labelText: 'For the canister: ',
                        ),
                        onSaved: (String? value) { canister_id = Principal.text(value!.trim()); },
                        validator: (String? v) {
                            try {
                                Principal p = Principal.text(v.nullmap((vs)=>vs.trim()) ?? '');
                                if (p.bytes.length >= 29) {
                                    return 'Must be a canister princpal-id';
                                }
                            } catch(e) {
                                return 'Must be a valid principal.';
                            }
                        }
                    ),
                    TextFormField(
                        decoration: InputDecoration(
                            labelText: 'TCYCLES: ',
                        ),
                        onSaved: (String? v) { cycles = Cycles.oftheTCyclesDoubleString(v!.trim()); },
                        validator: tcycles_validator
                    ),
                    Text('Fee: ${Cycles(cycles: CYCLES_BANK_LEDGER.fee)}', style: TextStyle(fontSize: 11)),
                    Padding(
                        padding: EdgeInsets.all(7),
                        child: ElevatedButton(
                            key: ValueKey('ManagementCanisterDepositCyclesForm DEPOSIT CYCLES GO BUTTON'),
                            style: ElevatedButton.styleFrom(backgroundColor: blue),
                            child: Text('DEPOSIT CYCLES'),
                            onPressed: () async {
                                if (form_key.currentState!.validate()==true) {
                                    
                                    form_key.currentState!.save();
                                    
                                    state.loading_text = 'calling managment canister deposit_cycles ...';
                                    state.is_loading = true;
                                    MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                                    
                                    late BigInt cycles_transfer_out_id;
                                    try {
                                        cycles_transfer_out_id = await state.user!.management_canister_deposit_cycles(
                                            CyclesOutQuest(
                                                fee: CYCLES_BANK_LEDGER.fee,
                                                cycles: cycles,
                                                for_canister: canister_id,
                                            )
                                        );
                                    } catch(e) {
                                        await showDialog(
                                            context: state.context,
                                            builder: (BuildContext context) {
                                                return AlertDialog(
                                                    title: Text('Management Canister Deposit Cycles Error:'),
                                                    content: Text('${etext(e)}'),
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
                                    state.loading_text = 'Deposit cycles success. ${cycles} cycles deposited onto the canister: ${canister_id}\nloading cycles-balance and cycles-transfers ...';
                                    main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);
                                    
                                    Future success_dialog = showDialog(
                                        context: state.context,
                                        builder: (BuildContext context) {
                                            return AlertDialog(
                                                title: Text('Deposit Cycles Success:'),
                                                content: Text('${cycles} cycles deposited onto the canister: ${canister_id}'),
                                                actions: <Widget>[
                                                    TextButton(
                                                        onPressed: () => Navigator.pop(context),
                                                        child: const Text('OK'),
                                                    ),
                                                ]
                                            );
                                        }   
                                    );
                                    
                                    try {
                                        await Future.wait([
                                            state.user!.fresh_icrc1_balances([CYCLES_BANK_LEDGER]),
                                            state.user!.fresh_icrc1_transactions([CYCLES_BANK_LEDGER]),
                                        ]);
                                    } catch(e) {
                                        await showDialog(
                                            context: state.context,
                                            builder: (BuildContext context) {
                                                return AlertDialog(
                                                    title: Text('Error when loading the cycles-balance and cycles-transfers:'),
                                                    content: Text('${etext(e)}'),
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
                                    
                                    await success_dialog;
                                
                                    state.is_loading = false;
                                    main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);
                                    
                                    Future.delayed(Duration(milliseconds: 20), () async { Navigator.pop(state.context); });
                                }
                            }
                        )
                    )
                ]
            )
        );
    }
}
