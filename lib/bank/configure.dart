import 'package:flutter/material.dart';

import '../main.dart';
import '../config/state.dart';
import '../config/state_bind.dart';
import '../tools/widgets.dart';
import '../user.dart';
import './forms.dart';




/*(state.user != null && state.user!.cycles_bank != null) */
class ConfigureCyclesBank extends StatelessWidget {
    ConfigureCyclesBank({super.key});
    
    final ScrollController main_listview_scroll_controller = ScrollController();  
    
    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
    
        return Center(
            child: Container(
                constraints: BoxConstraints(maxWidth: 900),
                child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                        ScaffoldBodyHeader(Center(child:Column(children: [
                            Text('SETTINGS', style: TextStyle(fontSize: 17)),
                            SizedBox(
                                height: 13,
                            ),
                            SelectableText('USER-ID: ${state.user!.principal.text}', style: TextStyle(fontSize: 14)),
                        ]))),
                        Expanded(
                            child: ListView(
                                controller: main_listview_scroll_controller,
                                padding: EdgeInsets.all(0),
                                addAutomaticKeepAlives: true,
                                children: [
                                    Column(
                                        children: [
                                            SizedBox(
                                                width: 2.0,
                                                height: 13.0
                                            ),/*
                                            Padding(
                                                padding: EdgeInsets.all(17),
                                                child: ElevatedButton(
                                                    style: ElevatedButton.styleFrom(backgroundColor: blue),
                                                    child: Text('LOAD METRICS'),
                                                    onPressed: () async {
                                                        state.loading_text = 'loading metrics ...';
                                                        state.is_loading = true;
                                                        MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                                                        try {
                                                            await state.user!.cycles_bank!.fresh_metrics();
                                                        } catch(e) {
                                                            await showDialog(
                                                                context: state.context,
                                                                builder: (BuildContext context) {
                                                                    return AlertDialog(
                                                                        title: Text('load metrics error:'),
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
                                                        return;                        
                                                    }
                                                )
                                            ),
                                            */
                                            Wrap(
                                                children: [
                                                    Center(
                                                        child: Container(
                                                            constraints: BoxConstraints(maxWidth: 450),
                                                            //width: double.infinity,
                                                            //alignment: Alignment.centerLeft,
                                                            //padding: EdgeInsets.fromLTRB(0,11,0,0),
                                                            child: Column(
                                                                children: [
                                                                    /*
                                                                    Center(
                                                                        child: DataTable(
                                                                            headingRowHeight: 0,
                                                                            showBottomBorder: true,
                                                                            columns: <DataColumn>[
                                                                                DataColumn(label: Text('')),
                                                                                DataColumn(label: Text('')),
                                                                            ],
                                                                            rows: <DataRow>[
                                                                                DataRow(
                                                                                    cells: <DataCell>[
                                                                                        DataCell(Text('membership creation: ')),
                                                                                        DataCell(SelectableText('${creation_timestamp}')),
                                                                                    ],
                                                                                ),
                                                                                DataRow(
                                                                                    cells: <DataCell>[
                                                                                        DataCell(Text('paid membership remaining: ')),
                                                                                        DataCell(SelectableText('${lifetime_remaining}')),
                                                                                    ],
                                                                                ),
                                                                                DataRow(
                                                                                    cells: <DataCell>[
                                                                                        DataCell(Text('\CYCLES: ')),
                                                                                        DataCell(SelectableText('${cycles_balance}')),
                                                                                    ]
                                                                                ),
                                                                                /*
                                                                                DataRow(
                                                                                    cells: <DataCell>[
                                                                                        DataCell(Text('ctsfuel: ')),
                                                                                        DataCell(SelectableText('${ctsfuel}')),
                                                                                    ]
                                                                                ),
                                                                                */
                                                                                DataRow(
                                                                                    cells: <DataCell>[
                                                                                        DataCell(Text('storage-usage: ')),
                                                                                        DataCell(SelectableText('${storage_usage}')),
                                                                                    ]
                                                                                ),
                                                                                DataRow(
                                                                                    cells: <DataCell>[
                                                                                        DataCell(Text('storage-size: ')),
                                                                                        DataCell(SelectableText('${storage_size}')),
                                                                                    ]
                                                                                )
                                                                            ]    
                                                                        )
                                                                    ),
                                                                    SizedBox(
                                                                        width: 3,
                                                                        height: 27
                                                                    ),
                                                                    */
                                                                ]
                                                            )
                                                        )
                                                    ),
                                                    Center(
                                                        child: Container(
                                                            constraints: BoxConstraints(maxWidth: 350),
                                                            child: Center(
                                                                child: Column(
                                                                    children: [
                                                                        // burn icp mint cycles,  
                                                                        Container(
                                                                            width: double.infinity,
                                                                            padding: EdgeInsets.all(17),
                                                                            child: MintCyclesButton(),                    
                                                                        ),
                                                                        // management_canister_deposit_cycles,  
                                                                        Container(
                                                                            width: double.infinity,
                                                                            padding: EdgeInsets.all(17),
                                                                            child: FilledButton.tonal(
                                                                                //style: ElevatedButton.styleFrom(backgroundColor: blue),
                                                                                child: Text('TOP-UP A CANISTER'),
                                                                                onPressed: () async {
                                                                                    await showDialog(
                                                                                        context: context,
                                                                                        builder: (BuildContext context) {
                                                                                            return AlertDialog(
                                                                                                title: Center(child: Text('MANAGEMENT CANISTER DEPOSIT CYCLES')),
                                                                                                content: Container(
                                                                                                    constraints: BoxConstraints(maxWidth: 500),
                                                                                                    child: SingleChildScrollView(
                                                                                                        child: ManagementCanisterDepositCyclesForm(key: ValueKey('CyclesBankScaffoldBody ManagementCanisterDepositCyclesForm'))
                                                                                                    )
                                                                                                ),
                                                                                                //actions: <Widget>[]
                                                                                            );
                                                                                        }   
                                                                                    );
                                                                                }
                                                                            )                     
                                                                        ),
                                                                    ]
                                                                )
                                                            )
                                                        )
                                                    )
                                                ]
                                            ),
                                        ] 
                                    )
                                ]
                            )
                        ),
                        Divider(
                            
                        ),
                        SizedBox(height: 11),
                        OutlineButton(
                            button_text: 'Done',
                            on_press_complete: () {
                                Navigator.pop(context);
                            }
                        ),
                    ]
                )
            )
        );        
    }
}


class MintCyclesButton extends StatelessWidget {
    Widget build(BuildContext context) {
        return FilledButton.tonal(
            //style: ElevatedButton.styleFrom(backgroundColor: blue),
            child: Text('MINT CYCLES'),
            onPressed: () async {
                await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                        return AlertDialog(
                            title: Center(child: Text('MINT CYCLES')),
                            content: Container(
                                child: SingleChildScrollView(
                                    child: BurnIcpMintCyclesForm(key: ValueKey('BurnIcpMintCyclesForm'))
                                )
                            ),
                        );
                    }   
                );
            }
        );
    }
}

