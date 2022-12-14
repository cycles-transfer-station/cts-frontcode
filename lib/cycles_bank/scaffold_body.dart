import 'dart:ui' as dart_ui;

import 'package:flutter/material.dart';

import 'package:ic_tools/tools.dart';

import '../config/state.dart';
import '../config/state_bind.dart';
import 'forms.dart';
import 'cards.dart';
import 'cycles_bank.dart';
import '../main.dart';
import '../widgets.dart';
import '../config/pages.dart';
import '../transfer_icp/icp_ledger.dart';
import '../transfer_icp/scaffold_body.dart';


class CyclesBankScaffoldBody extends StatelessWidget {
    CyclesBankScaffoldBody({Key? key}) : super(key: key);
    static CyclesBankScaffoldBody create({Key? key}) => CyclesBankScaffoldBody(key: key);
    
    final ScrollController cycles_transfers_out_scroll_controller = ScrollController();
    final ScrollController cycles_transfers_in_scroll_controller = ScrollController();    
    
    
    @override
    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
        
        
        List<Widget> column_children = [];
        
        column_children.add(
            Padding(
                padding: EdgeInsets.fromLTRB(17,17,17,17)
            )
        );

        
        if (state.user == null) {
            
            column_children.addAll([
                Text('Log in for the cycles-bank.'),
                Center(child: OutlineButton(
                    button_text: 'ii login',
                    on_press_complete: () async { await ii_login(context); }
                )) 
            ]);
        
        } else if (state.user!.cycles_bank == null) {
        
            column_children.addAll([
                Padding(
                    padding: EdgeInsets.fromLTRB(13,13,13,13),
                    child: OutlineButton(
                        button_text:'HOW IT WORKS',
                        on_press_complete: () async {
                            await showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                    return AlertDialog(
                                        title: Text('What is a CYCLES-BANK?'),
                                        content: SingleChildScrollView(
                                            child: Text(
''' 
A CYCLES-BANK is a bank for the native stable-currency: CYCLES on the world-computer. \n\nThe CYCLES currency - different than other crypto-currencies - must be held by a smart-contract on the ICP-blockchain and cannot be held by a key-pair alone. A CYCLES-BANK is a smart-contract living on the Internet-Computer-Blockchain that holds CYCLES, transfers CYCLES, and takes in-coming CYCLES-transfers. 

'''
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
                    )
                ),
                SizedBox(
                    width: 3,
                    height: 27
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
                Container(
                    width:  double.infinity,
                    padding: EdgeInsets.all(7),
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
                                    DataCell(Text('CYCLES-BANK COST XDR: ')),
                                    DataCell(Text('${state.cts_fees.cycles_bank_cost_cycles.cycles/CYCLES_PER_XDR}-xdr')),
                                ]
                            ),
                            DataRow(
                                cells: [
                                    DataCell(Text('CURRENT XDR-ICP RATE: ')),
                                    DataCell(Text('${state.xdr_icp_rate_with_a_timestamp!.xdr_icp_rate.xdr_permyriad_per_icp/BigInt.from(10000)}')),
                                ]
                            ),
                            DataRow(
                                cells: [
                                    DataCell(Text('ICP LEDGER FEES: ')),
                                    DataCell(Row(children: [Text('${ICP_LEDGER_TRANSFER_FEE_TIMES_TWO}-icp'), Tooltip(child: Icon(Icons.info_outline, size: 14.0), message: 'A cycles-bank-purchase uses 2 ledger transfers. 1 transfer creates the cycles-bank and 1 transfer collects the CTS-fee.')])),
                                ]
                            ),
                            DataRow(
                                cells: [
                                    DataCell(Text('CYCLES-BANK TOTAL COST ICP: ')),
                                    DataCell(Text('${cycles_to_icptokens(state.cts_fees.cycles_bank_cost_cycles, state.xdr_icp_rate_with_a_timestamp!.xdr_icp_rate) + ICP_LEDGER_TRANSFER_FEE_TIMES_TWO}-icp')),
                                ]
                            ),
                        ]
                    )                    
                ),
                SizedBox(
                    width: 3,
                    height: 37
                ),
                //this is where the purchase-cycles-bank button was once                    
                Container(
                    width: double.infinity,
                    height: 50,
                    constraints: BoxConstraints(maxWidth: 550),
                    padding: EdgeInsets.fromLTRB(11,0,11,17),
                    child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: blue),
                        child: Text('PURCHASE CYCLES-BANK', style: TextStyle(fontSize: 21)),
                        onPressed: () async {  
                            state.loading_text = 'purchasing cycles-bank ...';
                            state.is_loading = true;
                            MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                            try {
                                await state.user!.purchase_cycles_bank(opt_referral_user_id: null/*FOR THE DO!*/);
                            } catch(e) {
                                await showDialog(
                                    context: state.context,
                                    builder: (BuildContext context) {
                                        return AlertDialog(
                                            title: Text('Purchase cycles-bank error:'),
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
                            state.loading_text = 'cycles-bank purchase success. \ncycles-bank id: ${state.user!.cycles_bank!.principal.text}\nloading cycles-bank metrics ...';
                            main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);
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
                            state.is_loading = false;
                            main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);                                                                    
                            await showDialog(
                                context: state.context,
                                builder: (BuildContext context) {
                                    return AlertDialog(
                                        title: Text('cycles-bank purchase success:'),
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
                        }
                    ),
                )
            ]);
        
        } else /* if (state.user != null && state.user!.cycles_bank != null) */{
            
            String cycles_balance = 'unknown';
            String creation_timestamp = 'unknown';
            String lifetime_termination = 'unknown';
            String ctsfuel = 'unknown';
            String storage_usage = 'unknown';
            String storage_size = 'unknown';
            
            if (state.user!.cycles_bank!.metrics != null) {
                CyclesBankMetrics metrics = state.user!.cycles_bank!.metrics!;
                cycles_balance = '${metrics.cycles_balance}';
                creation_timestamp = '${seconds_of_the_nanos(metrics.user_canister_creation_timestamp_nanos)}';
                lifetime_termination = '${metrics.lifetime_termination_timestamp_seconds}';
                ctsfuel = '${(metrics.ctsfuel_balance.cycles/Cycles.T_CYCLES_DIVIDABLE_BY).toStringAsFixed(5)}';
                storage_usage = '${(metrics.storage_usage / BigInt.from(1024*1024)).toStringAsFixed(5)}-MiB';
                storage_size = '${metrics.storage_size_mib}-MiB';
            }
            
            List<CyclesTransferOut> cycles_transfers_out_reversed = state.user!.cycles_bank!.cycles_transfers_out.reversed.toList();
            List<CyclesTransferIn> cycles_transfers_in_reversed = state.user!.cycles_bank!.cycles_transfers_in.reversed.toList();
            
            column_children.addAll([
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
                Container(
                    width: double.infinity,
                    child: Column(
                        children: [
                            Container(
                                padding: EdgeInsets.fromLTRB(7,10,7,27),
                                child: SelectableText('CYCLES: ${cycles_balance}', style: TextStyle(fontSize: 19)),
                            )
                        ]
                    )
                ),
                Wrap(
                    children: [
                        Container(
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
                                                DataColumn(
                                                  label: Expanded(
                                                    child: Text(
                                                      '',
                                                      //style: TextStyle(fontStyle: FontStyle.italic),
                                                    ),
                                                  ),
                                                ),
                                                DataColumn(
                                                  label: Expanded(
                                                    child: Text(
                                                      '',
                                                      //style: TextStyle(fontStyle: FontStyle.italic),
                                                    ),
                                                  ),
                                                ),
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
                                                        DataCell(Text('lifetime-termination: ')),
                                                        DataCell(SelectableText('${lifetime_termination}')),
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
                                                                child: BurnIcpMintCyclesForm(key: ValueKey('CyclesBankScaffoldBody BurnIcpMintCyclesForm'))
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
                        ),
                        Container(
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
                    ]
                ),               
                Container(
                    padding: EdgeInsets.fromLTRB(13,17,13,17),
                    child: CyclesBankTransferCyclesForm(key: ValueKey('CyclesBankScaffoldBody CyclesBankTransferCyclesForm')),
                ),
                Padding(
                    padding: EdgeInsets.fromLTRB(7,37,7,17),
                    child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: blue),
                        child: Text('LOAD TRANSFERS', style: TextStyle(fontSize:11)),
                        onPressed: () async {
                            state.loading_text = 'loading cycles-bank cycles transfers ...';
                            state.is_loading = true;
                            MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                            try {
                                await Future.wait([
                                    state.user!.cycles_bank!.fresh_cycles_transfers_in(),
                                    state.user!.cycles_bank!.fresh_cycles_transfers_out(),
                                ]);
                            } catch(e) {
                                await showDialog(
                                    context: state.context,
                                    builder: (BuildContext context) {
                                        return AlertDialog(
                                            title: Text('Error when loading the cycles-bank cycles transfers:'),
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
                    )
                ),
                Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(11,0,0,0),
                    child: Text('CYCLES-TRANSFERS-OUT', style: TextStyle(fontSize: 17)),
                ),
                LimitedBox(
                    maxHeight: 337,
                    child: Container(
                        constraints: BoxConstraints(),
                        //padding: EdgeInsets.all(17),
                        child: ScrollConfiguration(
                            behavior: ScrollConfiguration.of(context).copyWith(dragDevices: ScrollConfiguration.of(context).dragDevices.toSet()..add(dart_ui.PointerDeviceKind.mouse), ),
                            child: Scrollbar(
                                controller: cycles_transfers_out_scroll_controller,
                                child: ListView.builder(
                                    controller: cycles_transfers_out_scroll_controller,    
                                    key: ValueKey('cb cycles-transfers-out'),
                                    scrollDirection: Axis.horizontal,
                                    reverse: false,
                                    shrinkWrap: false,
                                    padding: EdgeInsets.all(11),
                                    itemBuilder: (BuildContext context, int i) {
                                        return CyclesTransferOutListItem(cycles_transfers_out_reversed[i]);
                                    },
                                    itemCount: cycles_transfers_out_reversed.length,
                                    addAutomaticKeepAlives: true,
                                    addRepaintBoundaries: true,
                                    addSemanticIndexes: true,
                                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
                                    clipBehavior: Clip.hardEdge
                                )
                            )
                        )
                    )
                ),
                Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(11,0,0,0),
                    child: Text('CYCLES-TRANSFERS-IN', style: TextStyle(fontSize: 17)),
                ),
                LimitedBox(
                    maxHeight: 307,
                    child: Container(
                        constraints: BoxConstraints(),
                        //padding: EdgeInsets.all(17),
                        child: ScrollConfiguration(
                            behavior: ScrollConfiguration.of(context).copyWith(dragDevices: ScrollConfiguration.of(context).dragDevices.toSet()..add(dart_ui.PointerDeviceKind.mouse), ),
                            child: Scrollbar(
                                controller: cycles_transfers_in_scroll_controller,
                                child: ListView.builder(
                                    controller: cycles_transfers_in_scroll_controller,
                                    key: ValueKey('cb cycles-transfers-in'),
                                    scrollDirection: Axis.horizontal,
                                    reverse: false,
                                    shrinkWrap: false,
                                    padding: EdgeInsets.all(11),
                                    itemBuilder: (BuildContext context, int i) {
                                        return CyclesTransferInListItem(cycles_transfers_in_reversed[i]);
                                    },
                                    itemCount: cycles_transfers_in_reversed.length,
                                    addAutomaticKeepAlives: true,
                                    addRepaintBoundaries: true,
                                    addSemanticIndexes: true,
                                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
                                    clipBehavior: Clip.hardEdge
                                )
                            )   
                        )
                    ),
                )
            ]);   
        }
    
        return Center(
            child: Container(
                constraints: BoxConstraints(maxWidth: 900),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                        ScaffoldBodyHeader('CYCLES-BANK'),
                        Expanded(
                            child: ListView(
                                padding: EdgeInsets.all(0),
                                children: [
                                    Column(
                                        children: column_children 
                                    )
                                ],
                                addAutomaticKeepAlives: true
                            )
                        ),
                        if (state.user != null && state.user!.cycles_bank == null) Container(
                            width: double.infinity,
                            height: 50,
                            constraints: BoxConstraints(maxWidth: 550),
                            padding: EdgeInsets.fromLTRB(11,0,11,17),
                            child: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: blue),
                                child: Text('PURCHASE CYCLES-BANK', style: TextStyle(fontSize: 21)),
                                onPressed: () async {  
                                    state.loading_text = 'purchasing cycles-bank ...';
                                    state.is_loading = true;
                                    MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                                    try {
                                        await state.user!.purchase_cycles_bank(opt_referral_user_id: null/*FOR THE DO!*/);
                                    } catch(e) {
                                        await showDialog(
                                            context: state.context,
                                            builder: (BuildContext context) {
                                                return AlertDialog(
                                                    title: Text('Purchase cycles-bank error:'),
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
                                    state.loading_text = 'cycles-bank purchase success. \ncycles-bank id: ${state.user!.cycles_bank!.principal.text}\nloading cycles-bank metrics ...';
                                    main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);
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
                                    state.is_loading = false;
                                    main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);                                                                    
                                    await showDialog(
                                        context: state.context,
                                        builder: (BuildContext context) {
                                            return AlertDialog(
                                                title: Text('cycles-bank purchase success:'),
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
                                }
                            ),
                        )
                    ]
                )
            )
        );
    }
}

