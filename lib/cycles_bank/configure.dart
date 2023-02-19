import 'package:flutter/material.dart';

import '../main.dart';
import '../config/state.dart';
import '../config/state_bind.dart';
import '../tools/widgets.dart';
import './cycles_bank.dart';
import './forms.dart';




/*(state.user != null && state.user!.cycles_bank != null) */
class ConfigureCyclesBank extends StatelessWidget {
    ConfigureCyclesBank({super.key});
    
    final ScrollController main_listview_scroll_controller = ScrollController();  
    
    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);

        String cycles_balance = 'unknown';
        String creation_timestamp = 'unknown';
        String lifetime_remaining = 'unknown';
        String ctsfuel = 'unknown';
        String storage_usage = 'unknown';
        String storage_size = 'unknown';
        
        if (state.user!.cycles_bank!.metrics != null) {
            CyclesBankMetrics metrics = state.user!.cycles_bank!.metrics!;
            cycles_balance = '${metrics.cycles_balance}';
            DateTime creation_datetime = DateTime.fromMillisecondsSinceEpoch((metrics.user_canister_creation_timestamp_nanos/BigInt.from(Duration.microsecondsPerSecond)).toInt());
            creation_timestamp = '${creation_datetime.year}-${creation_datetime.month}-${creation_datetime.day}\n${creation_datetime.hour}:${creation_datetime.minute}';
            lifetime_remaining = '${DateTime.fromMillisecondsSinceEpoch((metrics.lifetime_termination_timestamp_seconds*BigInt.from(Duration.millisecondsPerSecond)).toInt()).difference(DateTime.now()).inDays}-days';
            ctsfuel = '${(metrics.ctsfuel_balance.cycles/Cycles.T_CYCLES_DIVIDABLE_BY).toStringAsFixed(5)}';
            storage_usage = '${(metrics.storage_usage / BigInt.from(1024*1024)).toStringAsFixed(1)}-MiB';
            storage_size = '${metrics.storage_size_mib}-MiB';
        }

        return Center(
            child: Container(
                constraints: BoxConstraints(maxWidth: 900),
                child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                        ScaffoldBodyHeader(Icon(Icons.settings_sharp, size: 50.0)),
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
                                            ),
                                            Container(
                                                padding: EdgeInsets.fromLTRB(11,0,11,17),
                                                child: Center(
                                                    child: Column(
                                                        children: [
                                                            Text('CYCLES-BANK-ID: '),
                                                            SelectableText('${state.user!.cycles_bank!.principal.text}', style: TextStyle(fontSize: 20)),
                                                        ]
                                                    )
                                                )
                                            ),
                                            Padding(
                                                padding: EdgeInsets.all(17),
                                                child: ElevatedButton(
                                                    style: ElevatedButton.styleFrom(backgroundColor: blue),
                                                    child: Text('LOAD METRICS'),
                                                    onPressed: () async {
                                                        state.loading_text = 'loading cycles-bank metrics ...';
                                                        state.is_loading = true;
                                                        MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                                                        try {
                                                            await state.user!.cycles_bank!.fresh_metrics();
                                                        } catch(e) {
                                                            await showDialog(
                                                                context: state.context,
                                                                builder: (BuildContext context) {
                                                                    return AlertDialog(
                                                                        title: Text('cycles-bank load metrics error:'),
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
                                            Wrap(
                                                children: [
                                                    Center(
                                                        child: Container(
                                                            constraints: BoxConstraints(maxWidth: 450),
                                                            //width: double.infinity,
                                                            //alignment: Alignment.centerLeft,
                                                            padding: EdgeInsets.fromLTRB(0,11,0,0),
                                                            child: Column(
                                                                children: [
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
                                                                                        DataCell(Text('creation-timestamp: ')),
                                                                                        DataCell(SelectableText('${creation_timestamp}')),
                                                                                    ],
                                                                                ),
                                                                                DataRow(
                                                                                    cells: <DataCell>[
                                                                                        DataCell(Text('lifetime-remaining: ')),
                                                                                        DataCell(SelectableText('${lifetime_remaining}')),
                                                                                    ],
                                                                                ),
                                                                                DataRow(
                                                                                    cells: <DataCell>[
                                                                                        DataCell(Text('ctsfuel: ')),
                                                                                        DataCell(SelectableText('${ctsfuel}')),
                                                                                    ]
                                                                                ),
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
                                                                    // burn icp mint cycles,  
                                                                    SizedBox(
                                                                        width: 3,
                                                                        height: 10
                                                                    ),
                                                                    Container(
                                                                        width: double.infinity,
                                                                        padding: EdgeInsets.all(17),
                                                                        child: ElevatedButton(
                                                                            style: ElevatedButton.styleFrom(backgroundColor: blue),
                                                                            child: Text('BURN ICP MINT CYCLES'),
                                                                            onPressed: () async {
                                                                                await showDialog(
                                                                                    context: context,
                                                                                    builder: (BuildContext context) {
                                                                                        return AlertDialog(
                                                                                            title: Center(child: Text('BURN-ICP MINT-CYCLES')),
                                                                                            content: Container(
                                                                                                padding: EdgeInsets.all(0),
                                                                                                child: SingleChildScrollView(
                                                                                                    child: BurnIcpMintCyclesForm(key: ValueKey('CyclesBankScaffoldBody BurnIcpMintCyclesForm'))
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
                                                    ),
                                                    Center(
                                                        child: Container(
                                                            constraints: BoxConstraints(maxWidth: 350),
                                                            //width: double.infinity,
                                                            //alignment: Alignment.centerLeft,
                                                            //margin: EdgeInsets.fromLTRB(13,7,13,7),
                                                            child: Center(
                                                                child: Column(
                                                                    children: [
                                                                        CTSFuelForTheCyclesBalanceForm(key: ValueKey('CyclesBankScaffoldBody CTSFuelForTheCyclesBalanceForm')),
                                                                        SizedBox(
                                                                            height: 20, 
                                                                            width: 1
                                                                        ),
                                                                        GrowStorageSizeForm(key: ValueKey('CyclesBankScaffoldBody GrowStorageSizeForm')),
                                                                        SizedBox(
                                                                            height: 20, 
                                                                            width: 1
                                                                        ),
                                                                        LengthenLifetimeForm(key: ValueKey('CyclesBankScaffoldBody LengthenLifetimeForm')),
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
                        Divider(),
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
