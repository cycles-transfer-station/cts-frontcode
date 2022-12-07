import 'package:flutter/material.dart';

import 'package:ic_tools/common.dart';

import '../config/state.dart';
import '../config/state_bind.dart';
import '../transfer_icp/icp_ledger.dart';
import '../transfer_icp/forms.dart';
import '../cycles_bank/cycles_bank.dart';
import '../cycles_bank/forms.dart';
import '../main.dart';
import './cycles_market_data.dart';



class CyclesBankCMTransferIcpForm extends StatefulWidget {
    CyclesBankCMTransferIcpForm({super.key});
    State<CyclesBankCMTransferIcpForm> createState() => CyclesBankCMTransferIcpFormState();
}
class CyclesBankCMTransferIcpFormState extends State<CyclesBankCMTransferIcpForm> {
    GlobalKey<FormState> form_key = GlobalKey<FormState>();
    
    late IcpTokens withdraw_icp;
    late String to;
    IcpTokens icp_fee = ICP_LEDGER_TRANSFER_FEE;
    
    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
                
        return Form(
            key: form_key,
            child: Column(
                children: <Widget>[               
                    Container(
                        width: double.infinity,
                        padding: EdgeInsets.fromLTRB(7,11,7,11),
                        child: Center(
                            child: Text('WITHDRAW ICP')
                        ),
                    ),
                    Container(
                        width: double.infinity,
                        padding: EdgeInsets.fromLTRB(7,11,7,11),
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
                                        DataCell(Text('WITHDRAW ICP FEE: ')),
                                        DataCell(Text('0.05-TCycles/XDR')),
                                    ]
                                ),
                                DataRow(
                                    cells: [
                                        DataCell(Text('ICP LEDGER TRANSFER FEE: ')),
                                        DataCell(Text('${ICP_LEDGER_TRANSFER_FEE}-icp')),
                                    ]
                                )
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
                        onSaved: (String? value) { withdraw_icp = IcpTokens.oftheDoubleString(value!); },
                        validator: icp_validator
                    ),
                    Container(
                        width: double.infinity,
                        height: 70.0,
                        padding: EdgeInsets.all(17),
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: blue),
                            child: Text('WITHDRAW ICP'),
                            onPressed: () async {
                                if (form_key.currentState!.validate()==true) {
                                    
                                    form_key.currentState!.save();
                                    
                                    CyclesMarketTransferIcpBalanceQuest cm_transfer_icp_balance_quest = CyclesMarketTransferIcpBalanceQuest(
                                        icp: withdraw_icp,
                                        icp_fee: icp_fee, 
                                        to: to,
                                    );
                                    
                                    state.loading_text = 'withdraw icp ...';
                                    state.is_loading = true;
                                    MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                                    
                                    late BigInt withdraw_icp_block_height;
                                    try {
                                        withdraw_icp_block_height = await state.user!.cycles_bank!.cm_transfer_icp_balance(cm_transfer_icp_balance_quest);
                                    } catch(e) {
                                        await showDialog(
                                            context: state.context,
                                            builder: (BuildContext context) {
                                                return AlertDialog(
                                                    title: Text('Cycles-Market Withdraw Icp Error:'),
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
                                    state.loading_text = 'Withdraw ICP success. \nblock height: ${withdraw_icp_block_height}\nloading cycles-market icp-balance and icp-transfers';
                                    main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);
                                    
                                    try {
                                        await Future.wait([
                                            state.user!.cycles_bank!.fresh_metrics(),                                        
                                            state.user!.cycles_bank!.fresh_cm_icp_balance(),
                                            state.user!.cycles_bank!.fresh_cm_icp_transfers(),
                                            state.user!.cycles_bank!.fresh_cm_icp_transfers_out(),
                                        ]);
                                    } catch(e) {
                                        await showDialog(
                                            context: state.context,
                                            builder: (BuildContext context) {
                                                return AlertDialog(
                                                    title: Text('Error when loading the cycles-market icp-balance and icp-transfers:'),
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
                                                title: Text('Cycles-Market Withdraw Icp Success:'),
                                                content: Text('transfer block height: ${withdraw_icp_block_height}'),
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




final String? Function(String?) xdr_icp_rate_validator = (String? v) {
    String e_s = 'Must be a number with a max ${XDRICPRate.DECIMAL_PLACES} decimal places';
    if (v == null || v.trim() == '') {
        return e_s;
    }
    try {
        XDRICPRate tr = XDRICPRate.oftheDoubleString(v.trim()); 
    } catch(e) {
        return e_s;    
    }
    return null;
};





class CyclesBankCMCreateCyclesPositionForm extends StatefulWidget {
    CyclesBankCMCreateCyclesPositionForm({super.key});
    State createState() => CyclesBankCMCreateCyclesPositionFormState();
}
class CyclesBankCMCreateCyclesPositionFormState extends State<CyclesBankCMCreateCyclesPositionForm> {
    GlobalKey<FormState> form_key = GlobalKey<FormState>();
    
    late Cycles cycles_for_the_position;
    late Cycles minimum_purchase;
    late XDRICPRate xdr_icp_rate;
    
    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
                
        return Form(
            key: form_key,
            child: Column(
                children: <Widget>[               
                    Container(
                        width: double.infinity,
                        child: Center(
                            child: Text('CREATE CYCLES-POSITION')
                        ),
                    ),
                    TextFormField(
                        decoration: InputDecoration(
                            labelText: 'Tcycles for the position: ',
                        ),
                        onSaved: (String? v) { cycles_for_the_position = Cycles.oftheTCyclesDoubleString(v!); },
                        validator: tcycles_validator
                    ),
                    TextFormField(
                        decoration: InputDecoration(
                            labelText: 'Tcycles minimum purchase: '
                        ),
                        onSaved: (String? v) { minimum_purchase = Cycles.oftheTCyclesDoubleString(v!); },
                        validator: tcycles_validator
                    ),
                    TextFormField(
                        decoration: InputDecoration(
                            labelText: 'TCycles per ICP rate: '
                        ),
                        onSaved: (String? value) { xdr_icp_rate = XDRICPRate.oftheDoubleString(value!.trim()); },
                        validator: xdr_icp_rate_validator
                    ),
                    Padding(
                        padding: EdgeInsets.all(7),
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: blue),
                            child: Text('CREATE CYCLES-POSITION'),
                            onPressed: () async {
                                if (form_key.currentState!.validate()==true) {
                                    
                                    form_key.currentState!.save();
                                    
                                    if (minimum_purchase.cycles > cycles_for_the_position.cycles) {
                                        await showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                                return AlertDialog(
                                                    title: Text(""),
                                                    content: Text("The minimum-purchase of the position must be equal or less than the position."),
                                                    actions: [
                                                        TextButton(
                                                            child: Text("Ok"),
                                                            onPressed:  () {
                                                                Navigator.of(context).pop();
                                                            },
                                                        )
                                                    ],
                                                );
                                            }
                                        );  
                                        return;
                                    }
                                    
                                    
                                    bool _continue = false;
                                    
                                    BigInt cycles_modulo_xdr_permyriad_per_icp = cycles_for_the_position.cycles % xdr_icp_rate.xdr_permyriad_per_icp;
                                    BigInt minimum_purchase_modulo_xdr_permyriad_per_icp = minimum_purchase.cycles % xdr_icp_rate.xdr_permyriad_per_icp;
                                    
                                    if (cycles_modulo_xdr_permyriad_per_icp != BigInt.from(0) || minimum_purchase_modulo_xdr_permyriad_per_icp != BigInt.from(0)) { 
                                        
                                        Cycles new_cycles = Cycles(cycles: cycles_for_the_position.cycles - cycles_modulo_xdr_permyriad_per_icp); 
                                        Cycles new_minimum_purchase = Cycles(cycles: minimum_purchase.cycles - minimum_purchase_modulo_xdr_permyriad_per_icp);
                                        
                                        if (new_cycles.cycles == BigInt.from(0)) {
                                            new_cycles = Cycles(cycles: xdr_icp_rate.xdr_permyriad_per_icp);
                                        }
                                        if (new_minimum_purchase.cycles == BigInt.from(0)) {
                                            new_minimum_purchase = Cycles(cycles: xdr_icp_rate.xdr_permyriad_per_icp);
                                        }
                                        
                                        await showDialog(
                                            context: context,
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
                                                    content: Text("The cycles and minimum-purchase of the position must be a multiple of the position\'s-TCycles-per-icp-rate*10000. \nContinue with the following values for the cycles and for the minimum-purchase of the position?\ncycles: ${cycles_for_the_position} -> ${new_cycles}\nminimum_purchase: ${minimum_purchase} -> ${new_minimum_purchase}"),
                                                    actions: [
                                                        cancelButton,
                                                        continueButton,
                                                    ],
                                                );
                                            }
                                        );     
                                        if (_continue == true) {
                                            cycles_for_the_position = new_cycles;
                                            minimum_purchase = new_minimum_purchase;
                                        } else {
                                            return;
                                        }
                                    }
                                    
                                    CreateCyclesPositionQuest cm_create_cycles_position_quest = CreateCyclesPositionQuest(
                                        cycles: cycles_for_the_position,
                                        minimum_purchase: minimum_purchase,
                                        xdr_icp_rate: xdr_icp_rate
                                    );
                                    
                                    state.loading_text = 'create cycles-position ...';
                                    state.is_loading = true;
                                    MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                                    
                                    late CreateCyclesPositionSuccess create_cycles_position_success;
                                    try {
                                        create_cycles_position_success = await state.user!.cycles_bank!.cm_create_cycles_position(cm_create_cycles_position_quest);
                                    } catch(e) {
                                        await showDialog(
                                            context: state.context,
                                            builder: (BuildContext context) {
                                                return AlertDialog(
                                                    title: Text('cycles-market create cycles-position error:'),
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
                                    state.loading_text = 'create cycles-position success. \ncycles-position ID: ${create_cycles_position_success.position_id}\nloading cycles-market cycles-positions and cycles-bank cycles-balance ...';
                                    main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);
                                    
                                    try {
                                        await Future.wait([
                                            state.cycles_market_data.fresh_cycles_positions(),
                                            state.user!.cycles_bank!.fresh_metrics(),
                                            state.user!.cycles_bank!.fresh_cm_cycles_positions(),
                                        ]);
                                    } catch(e) {
                                        await showDialog(
                                            context: state.context,
                                            builder: (BuildContext context) {
                                                return AlertDialog(
                                                    title: Text('Error when loading the cycles-market cycles-positions and cycles-bank cycles-balance'),
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
                                                title: Text('Cycles-Market Create CYCLES-POSITION Success:'),
                                                content: Text('cycles-position ID: ${create_cycles_position_success.position_id}'),
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


class CyclesBankCMCreateIcpPositionForm extends StatefulWidget {
    CyclesBankCMCreateIcpPositionForm({super.key});
    State<CyclesBankCMCreateIcpPositionForm> createState() => CyclesBankCMCreateIcpPositionFormState();
}
class CyclesBankCMCreateIcpPositionFormState extends State<CyclesBankCMCreateIcpPositionForm> {
    GlobalKey<FormState> form_key = GlobalKey<FormState>();
    
    late IcpTokens icp_for_the_position; 
    late IcpTokens minimum_purchase;
    late XDRICPRate xdr_icp_rate;
    
    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
                
        return Form(
            key: form_key,
            child: Column(
                children: <Widget>[               
                    Container(
                        width: double.infinity,
                        child: Center(
                            child: Text('CREATE ICP-POSITION')
                        ),
                    ),
                    TextFormField(
                        decoration: InputDecoration(
                            labelText: 'icp for the position: ',
                        ),
                        onSaved: (String? value) { icp_for_the_position = IcpTokens.oftheDoubleString(value!); },
                        validator: icp_validator
                    ),
                    TextFormField(
                        decoration: InputDecoration(
                            labelText: 'minimum purchase: '
                        ),
                        onSaved: (String? value) { minimum_purchase = IcpTokens.oftheDoubleString(value!); },
                        validator: icp_validator
                    ),
                    TextFormField(
                        decoration: InputDecoration(
                            labelText: 'TCycles per ICP rate: '
                        ),
                        onSaved: (String? value) { xdr_icp_rate = XDRICPRate.oftheDoubleString(value!.trim()); },
                        validator: xdr_icp_rate_validator
                    ),
                    Padding(
                        padding: EdgeInsets.all(7),
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: blue),
                            child: Text('CREATE ICP-POSITION'),
                            onPressed: () async {
                                if (form_key.currentState!.validate()==true) {
                                    
                                    form_key.currentState!.save();
                                    
                                    if (minimum_purchase > icp_for_the_position) {
                                        await showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                                return AlertDialog(
                                                    title: Text(""),
                                                    content: Text("The minimum-purchase of the position must be equal or less than the position."),
                                                    actions: [
                                                        TextButton(
                                                            child: Text("Ok"),
                                                            onPressed:  () {
                                                                Navigator.of(context).pop();
                                                            },
                                                        )
                                                    ],
                                                );
                                            }
                                        );  
                                        return;
                                    }
                                    /*
                                    await this.fresh_cm_icp_balance();
                                    if (this.cm_icp_balance! < q.icp + q.icp ~/ q.minimum_purchase * ICP_LEDGER_TRANSFER_FEE) {
                                        throw Exception('The cycles-bank\'s cycles-market-icp-balance is too low. The icp-balance must be enough to cover the icp-position + icp-position ~/ icp-position-minimum_purchase * ICP_LEDGER_TRANSFER_FEE[${ICP_LEDGER_TRANSFER_FEE}]\nicp-balance: ${this.cm_icp_balance!}\n');
                                    }
                                    */
                                    
                                    CreateIcpPositionQuest cm_create_icp_position_quest = CreateIcpPositionQuest(
                                        icp: icp_for_the_position,
                                        minimum_purchase: minimum_purchase,
                                        xdr_icp_rate: xdr_icp_rate
                                    );
                                    
                                    state.loading_text = 'create icp-position ...';
                                    state.is_loading = true;
                                    MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                                    
                                    late CreateIcpPositionSuccess create_icp_position_success;
                                    try {
                                        create_icp_position_success = await state.user!.cycles_bank!.cm_create_icp_position(cm_create_icp_position_quest);
                                    } catch(e) {
                                        await showDialog(
                                            context: state.context,
                                            builder: (BuildContext context) {
                                                return AlertDialog(
                                                    title: Text('cycles-market create icp-position error:'),
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
                                    state.loading_text = 'create icp-position success. \icp-position ID: ${create_icp_position_success.position_id}\nloading cycles-market icp-positions, icp-balance, and cycles-balance ...';
                                    main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);
                                    
                                    try {
                                        await Future.wait([
                                            state.cycles_market_data.fresh_icp_positions(),
                                            state.user!.cycles_bank!.fresh_metrics(),
                                            state.user!.cycles_bank!.fresh_cm_icp_balance(),
                                            state.user!.cycles_bank!.fresh_cm_icp_positions(),
                                        ]);
                                    } catch(e) {
                                        await showDialog(
                                            context: state.context,
                                            builder: (BuildContext context) {
                                                return AlertDialog(
                                                    title: Text('Error when loading the cycles-market icp-positions, icp-balance, and cycles-balance.'),
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
                                                title: Text('Cycles-Market Create ICP-POSITION Success:'),
                                                content: Text('icp-position ID: ${create_icp_position_success.position_id}'),
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







class PurchaseCyclesPositionForm extends StatefulWidget {
    final CyclesPosition cycles_position;
    PurchaseCyclesPositionForm(this.cycles_position, {super.key});
    State<PurchaseCyclesPositionForm> createState() => PurchaseCyclesPositionFormState();
}
class PurchaseCyclesPositionFormState extends State<PurchaseCyclesPositionForm> {
    GlobalKey<FormState> form_key = GlobalKey<FormState>();
    
    late Cycles purchase_cycles;
    
    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);

        return Form(
            key: form_key,
            child: Column(
                children: <Widget>[
                    TextFormField(
                        decoration: InputDecoration(
                            labelText: 'Tcycles purchase:',
                        ),
                        onSaved: (String? v) { purchase_cycles = Cycles.oftheTCyclesDoubleString(v!); },
                        validator: tcycles_validator
                    ),
                    Padding(
                        padding: EdgeInsets.all(7),
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: blue),
                            child: Text('PURCHASE'),
                            onPressed: () async {
                                if (form_key.currentState!.validate()==true) {
                                    
                                    form_key.currentState!.save();
                                    
                                    if (this.widget.cycles_position.minimum_purchase > purchase_cycles) {
                                        await showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                                return AlertDialog(
                                                    title: Text(""),
                                                    content: Text("The minimum-purchase of this cycles-position is ${this.widget.cycles_position.minimum_purchase}"),
                                                    actions: [
                                                        TextButton(
                                                            child: Text("Ok"),
                                                            onPressed:  () {
                                                                Navigator.of(context).pop();
                                                            },
                                                        )
                                                    ],
                                                );
                                            }
                                        );  
                                        return;
                                    }
                                    if (this.widget.cycles_position.cycles < purchase_cycles) {
                                        await showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                                return AlertDialog(
                                                    title: Text(""),
                                                    content: Text("This cycles-position: ${this.widget.cycles_position.id} has ${this.widget.cycles_position.cycles} cycles in the position."),
                                                    actions: [
                                                        TextButton(
                                                            child: Text("Ok"),
                                                            onPressed:  () {
                                                                Navigator.of(context).pop();
                                                            },
                                                        )
                                                    ],
                                                );
                                            }
                                        );  
                                        return;
                                    }
                                    /*
                                    await fresh_cm_icp_balance();
                                    IcpTokens cycles_position_purchase_cycles_icp_cost = cycles_to_icptokens(purchase_cycles, cycles_position.xdr_permyriad_per_icp_rate); 
                                    if (this.cm_icp_balance! < cycles_position_purchase_cycles_icp_cost + ICP_LEDGER_TRANSFER_FEE) {
                                        throw Exception('The cycles-bank\'s cycles-market-icp-balance is too low for the purchase. \ncycles-bank\'s cycles-market-icp-balance: ${this.cm_icp_balance!}\npurchase_cycles: ${purchase_cycles}\nicp-cost of these cycles in this cycles-position: ${cycles_position_purchase_cycles_icp_cost}, icp-ledger-transfer-fee: ${ICP_LEDGER_TRANSFER_FEE}');
                                    }
                                    */
                                    
                                    bool _continue = false;
                                    
                                    BigInt purchase_cycles_modulo_xdr_permyriad_per_icp = purchase_cycles.cycles % this.widget.cycles_position.xdr_permyriad_per_icp_rate.xdr_permyriad_per_icp;
                                    
                                    if (purchase_cycles_modulo_xdr_permyriad_per_icp != BigInt.from(0)) { 
                                        
                                        Cycles new_purchase_cycles = Cycles(cycles: purchase_cycles.cycles - purchase_cycles_modulo_xdr_permyriad_per_icp);
                                        
                                        if (new_purchase_cycles.cycles == BigInt.from(0)) {
                                            new_purchase_cycles = Cycles(cycles: this.widget.cycles_position.xdr_permyriad_per_icp_rate.xdr_permyriad_per_icp);
                                        }
                                        
                                        await showDialog(
                                            context: context,
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
                                                    content: Text("The cycles-purchase must be a multiple of the position\'s-TCycles-per-icp-rate*10000. \nContinue with the following new value for the cycles-purchase?\npurchase-cycles: ${purchase_cycles} -> ${new_purchase_cycles}"),
                                                    actions: [
                                                        cancelButton,
                                                        continueButton,
                                                    ],
                                                );
                                            }
                                        );     
                                        if (_continue == true) {
                                            purchase_cycles = new_purchase_cycles;
                                        } else {
                                            return;
                                        }
                                    }
                                    
                                    
                                    state.loading_text = 'purchasing ${purchase_cycles}-cycles ...';
                                    state.is_loading = true;
                                    MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                                    
                                    late PurchaseCyclesPositionSuccess purchase_cycles_position_success;
                                    try {
                                        purchase_cycles_position_success = await state.user!.cycles_bank!.cm_purchase_cycles_position(
                                            this.widget.cycles_position, 
                                            purchase_cycles
                                        );
                                    } catch(e) {
                                        await showDialog(
                                            context: state.context,
                                            builder: (BuildContext context) {
                                                return AlertDialog(
                                                    title: Text('Purchase Cycles:'),
                                                    content: Text('$e'),
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
                                                title: Text('Purchase Cycles Success'),
                                                content: Text('${purchase_cycles}-cycles. purchase-id: ${purchase_cycles_position_success.purchase_id}.'),
                                                actions: <Widget>[
                                                    TextButton(
                                                        onPressed: () => Navigator.pop(context),
                                                        child: const Text('OK'),
                                                    ),
                                                ]
                                            );
                                        }
                                    );
                                    
                                    state.loading_text = 'loading cycles-balance and cycles-market-icp-balance ...';
                                    MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                                    
                                    try {
                                        await Future.wait([
                                            state.user!.cycles_bank!.fresh_metrics(),
                                            state.user!.cycles_bank!.fresh_cm_icp_balance()
                                        ]);
                                    } catch(e) {
                                        await showDialog(
                                            context: state.context,
                                            builder: (BuildContext context) {
                                                return AlertDialog(
                                                    title: Text('Error loading cycles-bank balance:'),
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
            )   
        );
    }
}




class PurchaseIcpPositionForm extends StatefulWidget {
    final IcpPosition icp_position;
    PurchaseIcpPositionForm(this.icp_position, {super.key});
    State<PurchaseIcpPositionForm> createState() => PurchaseIcpPositionFormState();
}
class PurchaseIcpPositionFormState extends State<PurchaseIcpPositionForm> {
    GlobalKey<FormState> form_key = GlobalKey<FormState>();
    
    late IcpTokens purchase_icp;
    
    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);

        return Form(
            key: form_key,
            child: Column(
                children: <Widget>[
                    TextFormField(
                        decoration: InputDecoration(
                            labelText: 'purchase icp:',
                        ),
                        onSaved: (String? value) { purchase_icp = IcpTokens.oftheDoubleString(value!); },
                        validator: icp_validator
                    ),
                    Padding(
                        padding: EdgeInsets.all(7),
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: blue),
                            child: Text('PURCHASE'),
                            onPressed: () async {
                                if (form_key.currentState!.validate()==true) {
                                    
                                    form_key.currentState!.save();
                                    
                                    if (this.widget.icp_position.minimum_purchase > purchase_icp) {
                                        await showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                                return AlertDialog(
                                                    title: Text(""),
                                                    content: Text("The minimum-purchase of this icp-position is ${this.widget.icp_position.minimum_purchase}"),
                                                    actions: [
                                                        TextButton(
                                                            child: Text("Ok"),
                                                            onPressed:  () {
                                                                Navigator.of(context).pop();
                                                            },
                                                        )
                                                    ],
                                                );
                                            }
                                        );  
                                        return;
                                    }
                                    if (this.widget.icp_position.icp < purchase_icp) {
                                        await showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                                return AlertDialog(
                                                    title: Text(""),
                                                    content: Text("This icp-position: ${this.widget.icp_position.id} has ${this.widget.icp_position.icp} icp for the sale."),
                                                    actions: [
                                                        TextButton(
                                                            child: Text("Ok"),
                                                            onPressed:  () {
                                                                Navigator.of(context).pop();
                                                            },
                                                        )
                                                    ],
                                                );
                                            }
                                        );  
                                        return;
                                    }    
                                    // the cycles-bank checks that the cycles-bank's-cycles_balance is good for this purchase
                                    
                                    state.loading_text = 'purchasing ${purchase_icp}-icp ...';
                                    state.is_loading = true;
                                    MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                                    
                                    late PurchaseIcpPositionSuccess purchase_icp_position_success;
                                    try {
                                        purchase_icp_position_success = await state.user!.cycles_bank!.cm_purchase_icp_position(
                                            this.widget.icp_position, 
                                            purchase_icp
                                        );
                                    } catch(e) {
                                        await showDialog(
                                            context: state.context,
                                            builder: (BuildContext context) {
                                                return AlertDialog(
                                                    title: Text('Purchase Icp:'),
                                                    content: Text('$e'),
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
                                                title: Text('Purchase Icp Success'),
                                                content: Text('${purchase_icp}-icp. purchase-id: ${purchase_icp_position_success.purchase_id}.'),
                                                actions: <Widget>[
                                                    TextButton(
                                                        onPressed: () => Navigator.pop(context),
                                                        child: const Text('OK'),
                                                    ),
                                                ]
                                            );
                                        }
                                    );
                                    
                                    state.loading_text = 'loading cycles-market-icp-balance and cycles-balance ...';
                                    MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                                    
                                    try {
                                        await Future.wait([
                                            state.user!.cycles_bank!.fresh_metrics(),
                                            state.user!.cycles_bank!.fresh_cm_icp_balance()
                                        ]);
                                    } catch(e) {
                                        await showDialog(
                                            context: state.context,
                                            builder: (BuildContext context) {
                                                return AlertDialog(
                                                    title: Text('Error loading cycles-bank balance:'),
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
            )   
        );
    }
}







