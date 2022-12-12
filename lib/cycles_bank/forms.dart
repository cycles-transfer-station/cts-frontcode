import 'package:flutter/material.dart';

import 'package:ic_tools/ic_tools.dart';
import 'package:ic_tools/candid.dart' show Nat, Blob;
import 'package:ic_tools/candid.dart' as candid;
import 'package:ic_tools/common.dart';
import 'package:ic_tools/tools.dart';

import '../config/state.dart';
import '../config/state_bind.dart';
import '../config/pages.dart';
import '../transfer_icp/forms.dart';
import '../transfer_icp/scaffold_body.dart';
import '../main.dart';
import '../user.dart';
import './cycles_bank.dart';


enum CyclesTransferMemoType {
    Text,
    Nat,
    Blob
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
        return 'max 32 bytes for the now.';
    }
    return null;        
};




final String? Function(String?) tcycles_validator = (String? v) {
    if (v == null || v == '') {
        return 'Must be a number';
    }
    late Cycles cycles;
    try {
        cycles = Cycles.oftheTCyclesDoubleString(v);
    } catch(e) {
        return 'Must be a number > 0, max 12 decimal places';
    }
    if (cycles.cycles == BigInt.from(0)) {
        return 'Must be a number > 0';
    }
    return null;
};







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
        
        
        late String? Function(String?) cycles_transfer_memo_validator;
        switch (cycles_transfer_memo_type) {
            case CyclesTransferMemoType.Text: 
                cycles_transfer_memo_validator = cycles_transfer_memo_validator_text;
            break;
            case CyclesTransferMemoType.Nat: 
                cycles_transfer_memo_validator = cycles_transfer_memo_validator_nat;
            break;
            case CyclesTransferMemoType.Blob: 
                cycles_transfer_memo_validator = cycles_transfer_memo_validator_blob;
            break;
        }
        
        return Form(
            key: form_key,
            child: Column(
                children: <Widget>[
                    Container(
                        width: double.infinity,
                        padding: EdgeInsets.fromLTRB(7,11,7,11),
                        child: Center(
                            child: Text('TRANSFER-CYCLES', style: TextStyle(fontSize:17))
                        ),
                    ),
                    TextFormField(
                        decoration: InputDecoration(
                            labelText: 'For the cycles-bank: ',
                        ),
                        onSaved: (String? v) { for_the_canister = Principal(v!); },
                        validator: (String? v) {
                            if (v == null || v.trim() == '') {
                                return 'Write the text-principal-id of the cycles-bank that will cept the cycles';
                            }
                            late Principal p;
                            try {
                                p = Principal(v.trim());
                            } catch(e) {
                                return 'invalid cycles-bank-principal-id';
                            }
                            if (p.bytes.length == 0) {
                                return 'value must be the text-principal-id of the cycles-bank';
                            }
                            if (p.bytes.length >= 29) {
                                return 'Must be a cycles-bank princpal-id'; // Transfer cycles between canisters. Make sure that these cycles are for a canister-id.
                            }
                            return null;
                        }
                    ),
                    TextFormField(
                        decoration: InputDecoration(
                            labelText: 'TCycles: ',
                        ),
                        onSaved: (String? v) { cycles = Cycles.oftheTCyclesDoubleString(v!); },
                        validator: tcycles_validator
                    ),
                    DropdownButtonFormField<CyclesTransferMemoType>(
                        decoration: InputDecoration(
                            labelText: 'Cycles Transfer Memo: ',
                        ),
                        items: const [
                            DropdownMenuItem<CyclesTransferMemoType>(child: Text('Text'), value: CyclesTransferMemoType.Text ),
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
                        onSaved: (String? v) { 
                            switch (cycles_transfer_memo_type) {
                                case CyclesTransferMemoType.Text: 
                                    cycles_transfer_memo = CyclesTransferMemo.text(candid.Text(v ?? ''));
                                break;
                                case CyclesTransferMemoType.Nat: 
                                    cycles_transfer_memo = CyclesTransferMemo.nat(Nat(BigInt.parse((v == null || v.trim() == '') ? '0' : v, radix: 10)));
                                break;
                                case CyclesTransferMemoType.Blob: 
                                    cycles_transfer_memo = CyclesTransferMemo.blob(Blob((v == null || v.trim() == '') ? [] : hexstringasthebytes(v.trim().toLowerCase())));
                                break;
                            }
                        },
                        validator: cycles_transfer_memo_validator
                    ),
                    Padding(
                        padding: EdgeInsets.all(7),
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: blue),
                            child: Text('TRANSFER CYCLES'),
                            onPressed: () async {
                                if (form_key.currentState!.validate()==true) {
                                    form_key.currentState!.save();
                                    
                                    UserTransferCyclesQuest transfer_cycles_quest = UserTransferCyclesQuest(
                                        for_the_canister:for_the_canister,
                                        cycles:cycles, 
                                        cycles_transfer_memo:cycles_transfer_memo,
                                    );
                                    
                                    state.loading_text = 'transferring cycles ...';
                                    state.is_loading = true;
                                    MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                                    
                                    late BigInt cycles_transfer_out_id;
                                    try {
                                        cycles_transfer_out_id = await state.user!.cycles_bank!.transfer_cycles(transfer_cycles_quest);
                                    } catch(e) {
                                        print(e);
                                        await showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                                return AlertDialog(
                                                    title: Text('Transfer Cycles Error:'),
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
                                    
                                    state.loading_text = 'cycles transfer success. cycles_transfer_id: ${cycles_transfer_out_id}\nloading cycles balance and transfers list ...';
                                    main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);
                                
                                    await showDialog(
                                        context: state.context,
                                        builder: (BuildContext context) {
                                            return AlertDialog(
                                                title: Text('Cycles Transfer Success:'),
                                                content: Text('cycles_transfer_id: ${cycles_transfer_out_id}'),
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


class CTSFuelForTheCyclesBalanceForm extends StatefulWidget {
    CTSFuelForTheCyclesBalanceForm({super.key});
    State createState() => CTSFuelForTheCyclesBalanceFormState();
}
class CTSFuelForTheCyclesBalanceFormState extends State<CTSFuelForTheCyclesBalanceForm> {
    GlobalKey<FormState> form_key = GlobalKey<FormState>();
    
    late Cycles cycles_for_the_ctsfuel;
    
    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
        
        return Form(
            key: form_key,
            child: Wrap(
                children: [
                    TextFormField(
                        decoration: InputDecoration(
                            labelText: 'TCycles for the CTSFuel:',
                        ),
                        onSaved: (String? v) { cycles_for_the_ctsfuel = Cycles.oftheTCyclesDoubleString(v!); },
                        validator: tcycles_validator
                    ),    
                    Padding(
                        padding: EdgeInsets.all(7),
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: blue),
                            child: Text('TOPUP CTSFUEL'),
                            onPressed: () async {
                                if (form_key.currentState!.validate()==true) {
                                    form_key.currentState!.save();
                                    
                                    state.loading_text = 'ctsfuel topup ...';
                                    state.is_loading = true;
                                    MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                                    
                                    try {
                                        await state.user!.cycles_bank!.cycles_balance_for_the_ctsfuel(cycles_for_the_ctsfuel);
                                    } catch(e) {
                                        await showDialog(
                                            context: state.context,
                                            builder: (BuildContext context) {
                                                return AlertDialog(
                                                    title: Text('CTSFuel Topup Error:'),
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
                                
                                    await showDialog(
                                        context: state.context,
                                        builder: (BuildContext context) {
                                            return AlertDialog(
                                                title: Text('CTSFUEL TOPUP SUCCESS'),
                                                content: Text('CTSFUEL-BALANCE: ${state.user!.cycles_bank!.metrics!.ctsfuel_balance.cycles/Cycles.T_CYCLES_DIVIDABLE_BY}'),
                                                actions: <Widget>[
                                                    TextButton(
                                                        onPressed: () => Navigator.pop(context),
                                                        child: const Text('OK'),
                                                    ),
                                                ]
                                            );
                                        }
                                    );
                                    
                                    state.loading_text = 'ctsfuel topup success.\nloading ctsfuel balance ...';
                                    main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);
                                    
                                    try {
                                        await state.user!.cycles_bank!.fresh_metrics();
                                    } catch(e) {
                                        await showDialog(
                                            context: state.context,
                                            builder: (BuildContext context) {
                                                return AlertDialog(
                                                    title: Text('Error when loading the ctsfuel balance:'),
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





class GrowStorageSizeForm extends StatefulWidget {
    GrowStorageSizeForm({super.key});
    State createState() => GrowStorageSizeFormState();
}
class GrowStorageSizeFormState extends State<GrowStorageSizeForm> {
    GlobalKey<FormState> form_key = GlobalKey<FormState>();
    
    late BigInt new_storage_size_mib; //ChangeStorageSizeQuest
    
    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
        
        return Form(
            key: form_key,
            child: Wrap(
                children: [
                    TextFormField(
                        decoration: InputDecoration(
                            labelText: 'Set Storage Size MiB',
                        ),
                        onSaved: (String? v) { new_storage_size_mib = BigInt.parse(v!, radix: 10); },
                        validator: (String? v) {
                            String e_s = 'Must be a whole number';
                            if (v == null || v == '') {
                                return e_s;
                            }
                            try {
                                BigInt bi = BigInt.parse(v);
                            } catch(e) {
                                return e_s;
                            }
                            return null;
                        }
                    ),
                    Padding(
                        padding: EdgeInsets.all(7),
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: blue),
                            child: Text('GROW STORAGE'),
                            onPressed: () async {
                                if (form_key.currentState!.validate()==true) {
                                    form_key.currentState!.save();
                                    
                                    state.loading_text = 'growing storage ...';
                                    state.is_loading = true;
                                    MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                                    
                                    try {
                                        await state.user!.cycles_bank!.change_storage_size( 
                                            ChangeStorageSizeQuest(
                                                new_storage_size_mib: new_storage_size_mib
                                            )
                                        );
                                    } catch(e) {
                                        await showDialog(
                                            context: state.context,
                                            builder: (BuildContext context) {
                                                return AlertDialog(
                                                    title: Text('Grow Storage Error:'),
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
                                    state.user!.cycles_bank!.metrics!.storage_size_mib = new_storage_size_mib;
                                    
                                    await showDialog(
                                        context: state.context,
                                        builder: (BuildContext context) {
                                            return AlertDialog(
                                                title: Text('Grow Storage Success.'),
                                                content: Text('New cycles-bank storage-size Mib: ${state.user!.cycles_bank!.metrics!.storage_size_mib}'),
                                                actions: <Widget>[
                                                    TextButton(
                                                        onPressed: () => Navigator.pop(context),
                                                        child: const Text('OK'),
                                                    ),
                                                ]
                                            );
                                        }
                                    );
                                    
                                    state.loading_text = 'loading cycles-balance ...';
                                    MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                                    
                                    try {
                                        await state.user!.cycles_bank!.fresh_metrics();
                                    } catch(e) {
                                        await showDialog(
                                            context: state.context,
                                            builder: (BuildContext context) {
                                                return AlertDialog(
                                                    title: Text('Error loading cycles-balance'),
                                                    content: Text(e.toString()),
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
                            }
                        )
                    )
                ]
            ),
        );
    }
}




class LengthenLifetimeForm extends StatefulWidget {
    LengthenLifetimeForm({super.key});
    State createState() => LengthenLifetimeFormState();
}
class LengthenLifetimeFormState extends State<LengthenLifetimeForm> {
    GlobalKey<FormState> form_key = GlobalKey<FormState>();
    
    late BigInt set_lifetime_termination_timestamp_seconds;
    
    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
        
        return Form(
            key: form_key,
            child: Wrap(
                children: [
                    TextFormField(
                        decoration: InputDecoration(
                            labelText: 'Set Lifetime Termination Unix Timestamp Seconds',
                        ),
                        onSaved: (String? v) { set_lifetime_termination_timestamp_seconds = BigInt.parse(v!, radix: 10); },
                        validator: (String? v) {
                            String e_s = 'Must be a whole number';
                            if (v == null || v == '') {
                                return e_s;
                            }
                            late BigInt bi;
                            try {
                                bi = BigInt.parse(v);
                            } catch(e) {
                                return e_s;
                            }
                            if (bi < state.user!.cycles_bank!.metrics!.lifetime_termination_timestamp_seconds) {
                                return 'Must lengthen the lifetime';
                            } 
                            return null;
                        }
                    ),
                    Padding(
                        padding: EdgeInsets.all(7),
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: blue),
                            child: Text('SET LIFETIME'),
                            onPressed: () async {
                                if (form_key.currentState!.validate()==true) {
                                    form_key.currentState!.save();
                                    
                                    state.loading_text = 'lengthening cycles-bank lifetime ...';
                                    state.is_loading = true;
                                    MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                                    
                                    late BigInt new_lifetime_termination_timestamp_seconds;
                                    try {
                                        new_lifetime_termination_timestamp_seconds = await state.user!.cycles_bank!.lengthen_lifetime( 
                                            LengthenLifetimeQuest(
                                                set_lifetime_termination_timestamp_seconds: set_lifetime_termination_timestamp_seconds
                                            )
                                        );
                                    } catch(e) {
                                        await showDialog(
                                            context: state.context,
                                            builder: (BuildContext context) {
                                                return AlertDialog(
                                                    title: Text('Grow Storage Error:'),
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
                                    
                                    state.user!.cycles_bank!.metrics!.lifetime_termination_timestamp_seconds = new_lifetime_termination_timestamp_seconds;
                                    
                                    await showDialog(
                                        context: state.context,
                                        builder: (BuildContext context) {
                                            return AlertDialog(
                                                title: Text('Lengthen Lifetime Success.'),
                                                content: Text('New cycles-bank lifetime-termination-timestamp: ${state.user!.cycles_bank!.metrics!.lifetime_termination_timestamp_seconds}'),
                                                actions: <Widget>[
                                                    TextButton(
                                                        onPressed: () => Navigator.pop(context),
                                                        child: const Text('OK'),
                                                    ),
                                                ]
                                            );
                                        }
                                    );
                                    
                                    state.loading_text = 'loading cycles-balance ...';
                                    MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                                    
                                    try {
                                        await state.user!.cycles_bank!.fresh_metrics();
                                    } catch(e) {
                                        await showDialog(
                                            context: state.context,
                                            builder: (BuildContext context) {
                                                return AlertDialog(
                                                    title: Text('Error loading cycles-balance'),
                                                    content: Text(e.toString()),
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
                            }
                        )
                    )
                ]
            ),
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
    
    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
                
        return Form(
            key: form_key,
            child: Column(
                children: <Widget>[
                    Container(
                        padding: EdgeInsets.all(7),
                        child: Column(
                            children: [
                                Center(
                                    child: SelectableText('USER-CTS-ICP-ID:', style: TextStyle(fontSize: 13)),
                                ),
                                Center(
                                    child: SelectableText('${state.user!.user_icp_id}', style: TextStyle(fontSize: 11)),
                                ),
                                IcpBalanceAndLoadIcpBalance(key: ValueKey('CyclesBankScaffoldBody BurnIcpMintCyclesDialog IcpBalanceAndLoadIcpBalance'))
                            ]
                        )
                    ),
                    SizedBox(
                        width: 1,
                        height: 17
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
                                        )
                                    )
                                )
                            ],
                            rows: [
                                DataRow(
                                    cells: [
                                        DataCell(Text('BURN ICP MINT CYCLES FEE XDR: ')),
                                        DataCell(Text('${state.cts_fees.burn_icp_mint_cycles_fee.cycles/CYCLES_PER_XDR}-xdr')),
                                    ]
                                ),
                                DataRow(
                                    cells: [
                                        DataCell(Text('CURRENT NETWORK TCYCLES-ICP RATE: ', )),
                                        DataCell(Text('${state.xdr_icp_rate_with_a_timestamp!.xdr_icp_rate}')),
                                    ]
                                ),
                            ]
                        )
                    ),
                    SizedBox(
                        width: 1,
                        height: 17
                    ),
                    TextFormField(
                        decoration: InputDecoration(
                            labelText: 'burn icp: ',
                        ),
                        onSaved: (String? value) { burn_icp = IcpTokens.oftheDoubleString(value!); },
                        validator: icp_validator
                    ),
                    Padding(
                        padding: EdgeInsets.all(7),
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: blue),
                            child: Text('BURN ICP MINT CYCLES'),
                            onPressed: () async {
                                if (form_key.currentState!.validate()==true) {
                                    
                                    form_key.currentState!.save();
                                    
                                    state.loading_text = 'burning icp and minting cycles ...';
                                    state.is_loading = true;
                                    MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                                    
                                    late BurnIcpMintCyclesSuccess burn_icp_mint_cycles_success;
                                    try {
                                        burn_icp_mint_cycles_success = await state.user!.burn_icp_mint_cycles(burn_icp);
                                    } catch(e) {
                                        await showDialog(
                                            context: state.context,
                                            builder: (BuildContext context) {
                                                return AlertDialog(
                                                    title: Text('Burn Icp Mint Cycles Error:'),
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
                                    state.loading_text = 'Burn icp mint cycles is success. \ncycles-mint: ${burn_icp_mint_cycles_success.mint_cycles_for_the_user} \nloading icp balance, icp transfers, and cycles-bank cycles-balance ...';
                                    main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);
                                    
                                    try {
                                        await Future.wait([
                                            state.user!.fresh_icp_balance(),
                                            state.user!.fresh_icp_transfers(),
                                            state.user!.cycles_bank!.fresh_metrics(),
                                        ]);
                                    } catch(e) {
                                        await showDialog(
                                            context: state.context,
                                            builder: (BuildContext context) {
                                                return AlertDialog(
                                                    title: Text('Error when loading the icp balance, icp transfers, and cycles-bank cycles-balance:'),
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
                                
                                    state.is_loading = false;
                                    main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);
                                    
                                    await showDialog(
                                        context: state.context,
                                        builder: (BuildContext context) {
                                            return AlertDialog(
                                                title: Text('Burn Icp Mint Cycles Success:'),
                                                content: Text('cycles-mint: ${burn_icp_mint_cycles_success.mint_cycles_for_the_user}'),
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
                            }
                        )
                    )
                ]
            )
        );
    }
}


