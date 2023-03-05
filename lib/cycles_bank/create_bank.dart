import 'package:flutter/material.dart';
import '../main.dart';
import '../config/state.dart';
import '../config/state_bind.dart';
import '../transfer_icp/scaffold_body.dart';
import '../transfer_icp/icp_ledger.dart';




class CreateBank extends StatelessWidget {
    CreateBank({super.key});
    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
        
        if ((state.user != null && state.user!.bank == null) == false) {
            return Text('CreateBank should only be created when the user is logged in and without a bank.');
        } 
        
        return Column(
            children: [
                Container(
                    padding: EdgeInsets.all(27),
                    child: Text(
                    /*
                    OutlineButton(
                        button_text:'HOW IT WORKS',
                        on_press_complete: () async {
                            await showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                    return AlertDialog(
                                        title: Text('What is a CYCLES-BANK?'),
                                        content: SingleChildScrollView(
                                            child: Text(
                    */
            """A CYCLES-BANK is a smart-contract living on the World-Computer-Blockchain that can hold CYCLES, transfer CYCLES, and receive CYCLES. 

            The CYCLES currency - different than other crypto-currencies - must be held by a smart-contract on the ICP-blockchain and cannot be held by a key-pair alone. This is why one needs a cycles-bank to hold or transfer the CYCLES currency.

            Creating a CYCLES-BANK creates a brand new personal cycles-bank for the user. A cycles-bank comes with a lifetime of 1-year, storage space of 10-MiB, and 2.0-CTSFuel. For each cycles-transfer, the world-computer-blockchain charges some fuel, in the cycles-bank that fuel is labeled as the CTSFuel. Once a cycles-bank is created, the user can lengthen the lifetime, grow the storage-space, and top-up the CTSFuel.

            """
                    /*
                                            )
                                        ),
                                        actions: <Widget>[
                                            TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: const Text('COOL'),
                                            ),
                                        ]
                                    );
                                }   
                            );
                        }
                    */
                    , style: TextStyle(fontSize: 17)
                    )
                ),
                SizedBox(
                    width: 3,
                    height: 7
                ),
                Container(
                    padding: EdgeInsets.fromLTRB(7,13,7,0),
                    child: Center(
                        child: Column(
                            children: [
                                Text('USER-CTS-ICP-ID: '),
                                SelectableText('${state.user!.user_icp_id}\n', style: TextStyle(fontSize: 14)),
                            ]
                        )
                    )
                ),
                IcpBalanceAndLoadIcpBalance(key: ValueKey('CyclesBankScaffoldBody PurchaseCyclesBank IcpBalanceAndLoadIcpBalance')),
                SizedBox(
                    width: 3,
                    height: 13
                ),
                Container(
                    width:  double.infinity,
                    padding: EdgeInsets.all(7),
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
                                    DataCell(Text('CYCLES-BANK COST XDR:')),
                                    DataCell(Text('${state.cts_fees.cycles_bank_cost_cycles.cycles/CYCLES_PER_XDR}-xdr')),
                                ]
                            ),
                            /*
                            DataRow(
                                cells: [
                                    DataCell(Text('CURRENT XDR-ICP RATE: ')),
                                    DataCell(Text('${state.xdr_icp_rate_with_a_timestamp!.xdr_icp_rate.xdr_permyriad_per_icp/BigInt.from(10000)}')),
                                ]
                            ),
                            DataRow(
                                cells: [
                                    DataCell(Text('ICP LEDGER FEES: ')),
                                    DataCell(Row(children: [Text('${ICP_LEDGER_TRANSFER_FEE_TIMES_TWO}-icp'), Tooltip(child: Icon(Icons.info_outline, size: 14.0), message: 'Creating a cycles-bank uses 2 ledger transfers. 1 transfer creates the cycles-bank and 1 transfer collects the CTS-fee.')])),
                                ]
                            ),
                            */
                            DataRow(
                                cells: [
                                    DataCell(Text('CYCLES-BANK COST ICP:')),
                                    DataCell(Row(children: [Text('${(cycles_to_icptokens(state.cts_fees.cycles_bank_cost_cycles, state.xdr_icp_rate_with_a_timestamp!.xdr_icp_rate) + ICP_LEDGER_TRANSFER_FEE_TIMES_TWO).round_decimal_places(1)}-icp'), Tooltip(child: Icon(Icons.info_outline, size: 14.0), message: 'The ICP cost is the cycles-bank cost XDR converted into ICP using the current ICP/XDR conversion-rate. This amount fluctuates based on the current ICP/XDR conversion-rate.')])),
                                ]
                            ),
                        ]
                    )                    
                ),
                SizedBox(
                    width: 3,
                    height: 37
                ),
                Container(
                    width: double.infinity,
                    height: 50,
                    constraints: BoxConstraints(maxWidth: 550),
                    padding: EdgeInsets.fromLTRB(11,0,11,0),
                    child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: blue),
                        child: Text('CREATE CYCLES-BANK', style: TextStyle(fontSize: 21)),
                        onPressed: () async {  
                            state.loading_text = 'creating cycles-bank ...';
                            state.is_loading = true;
                            MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                            try {
                                await state.user!.purchase_cycles_bank(opt_referral_user_id: null); //FOR THE DO! ferral
                            } catch(e) {
                                await showDialog(
                                    context: state.context,
                                    builder: (BuildContext context) {
                                        return AlertDialog(
                                            title: Text('create cycles-bank error:'),
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
                            state.loading_text = 'create cycles-bank success. \ncycles-bank id: ${state.user!.cycles_bank!.principal.text}\nloading cycles-bank metrics ...';
                            main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);
                            
                            Future success_dialog = showDialog(
                                context: state.context,
                                builder: (BuildContext context) {
                                    return AlertDialog(
                                        title: Text('create cycles-bank success:'),
                                        content: Text('cycles-bank id: ${state.user!.cycles_bank!.principal.text}'),
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
                                await state.user!.cycles_bank!.fresh_metrics();
                            } catch(e) {
                                await showDialog(
                                    context: state.context,
                                    builder: (BuildContext context) {
                                        return AlertDialog(
                                            title: Text('load cycles-bank metrics error:'),
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
                            
                            await success_dialog;
                            
                            state.is_loading = false;
                            main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);                                                                    
                                                         
                        }
                    ),
                ),
                SizedBox(
                    width: 3,
                    height: 27
                ),
            ]
        );
    }
}


