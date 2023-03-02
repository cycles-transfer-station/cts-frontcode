import 'dart:ui' as dart_ui;

import 'package:flutter/material.dart';
import 'package:ic_tools/tools.dart';
import 'package:ic_tools/common.dart' show Icrc1Ledger, Tokens;

import '../config/state.dart';
import '../config/state_bind.dart';
import 'forms.dart';
import 'cards.dart';
import 'cycles_bank.dart';
import 'configure.dart';
import '../main.dart';
import '../tools/widgets.dart';
import '../tools/ii_login.dart';
import '../config/pages.dart';
import '../transfer_icp/icp_ledger.dart';
import '../transfer_icp/scaffold_body.dart';

final GlobalKey transfer_cycles_form_container_key = GlobalKey();

class CyclesBankScaffoldBody extends StatelessWidget {
    CyclesBankScaffoldBody({Key? key}) : super(key: key);
    static CyclesBankScaffoldBody create({Key? key}) => CyclesBankScaffoldBody(key: key);
    
    final ScrollController cycles_transfers_out_scroll_controller = ScrollController();
    final ScrollController cycles_transfers_in_scroll_controller = ScrollController();    
    
    final ScrollController main_listview_scroll_controller = ScrollController();  
    
    
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
                Container(
                    padding: EdgeInsets.all(11),
                    child: Center(child: OutlineButton(
                        button_text: 'ii login',
                        on_press_complete: () async { await ii_login(context); }
                    ))
                )
            ]);
        
        } else if (state.user!.cycles_bank == null) {
        
            column_children.addAll([
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
            ]);
        
        } else /* if (state.user != null && state.user!.cycles_bank != null) */{
            
            String cycles_balance = 'unknown';
            if (state.user!.cycles_bank!.metrics != null) {
                CyclesBankMetrics metrics = state.user!.cycles_bank!.metrics!;
                cycles_balance = '${metrics.cycles_balance}';
            }

            
            List<CyclesTransferOut> cycles_transfers_out_reversed = state.user!.cycles_bank!.cycles_transfers_out.reversed.toList();
            List<CyclesTransferIn> cycles_transfers_in_reversed = state.user!.cycles_bank!.cycles_transfers_in.reversed.toList();
            
            //List<CyclesTransfer> cycles_transfers = [];
            
            column_children.addAll([
                /*
                Container(
                    padding: EdgeInsets.fromLTRB(11,0,11,0),
                    child: Center(
                        child: Column(
                            children: [
                                Text('CYCLES-BANK-ID: '),
                                SelectableText('${state.user!.cycles_bank!.principal.text}', style: TextStyle(fontSize: 20)),
                            ]
                        )
                    )
                ),
                */
                SizedBox(
                    width: 3,
                    height: 17
                ),
                Container(
                    child: DropdownButton<Icrc1Ledger?>(
                        //decoration: InputDecoration(
                        //    labelText: 'Token'//state.user!.cycles_bank!.current_icrc1_ledger.symbol,
                        //),
                        underline: Container(
                            height: 0,
                            color: Colors.deepPurpleAccent,
                        ),
                        isExpanded: false,
                        items: [
                            DropdownMenuItem<Icrc1Ledger?>(
                                child: Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Text('CYCLES', style: TextStyle(fontSize: 22)), 
                                ),
                                value: null
                            ),  
                            for (Icrc1Ledger icrc1_ledger in state.user!.cycles_bank!.known_icrc1_ledgers)                 
                                DropdownMenuItem<Icrc1Ledger?>(
                                    child: Padding(
                                        padding: EdgeInsets.all(8),
                                        child: Text(icrc1_ledger.symbol, style: TextStyle(fontSize: 22)), 
                                    ),
                                    value: icrc1_ledger
                                ),
                        ],
                        value: state.user!.cycles_bank!.current_icrc1_ledger,
                        onChanged: (Icrc1Ledger? select_icrc1_ledger) { 
                            //if (select_icrc1_ledger is Icrc1Ledger) { 
                                state.user!.cycles_bank!.current_icrc1_ledger = select_icrc1_ledger;
                                MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                            //}
                        }
                    )
                ),
                Container(
                    width: double.infinity,
                    child: Column(
                        children: [
                            SizedBox(
                                width: 3,
                                height: 17
                            ),
                            if (state.user!.cycles_bank!.current_icrc1_ledger == null) Container(
                                padding: EdgeInsets.fromLTRB(7,10,7,27),
                                child: SelectableText('CYCLES: ${cycles_balance}', style: TextStyle(fontSize: 27)),
                            ) else TokenBalance(
                                symbol: state.user!.cycles_bank!.current_icrc1_ledger!.symbol, 
                                tokens: Tokens(
                                    token_quantums: state.user!.cycles_bank!.icrc1_balances_cache[state.user!.cycles_bank!.current_icrc1_ledger!]!,
                                    decimal_places: state.user!.cycles_bank!.current_icrc1_ledger!.decimals 
                                ), 
                                key: ValueKey('CyclesBankScaffoldBody Icrc1TokenBalance')
                            ),
                            SizedBox(
                                width: 3,
                                height: 17
                            ),
                        ]
                    )
                ),
                Container(
                    key: transfer_cycles_form_container_key,
                    padding: EdgeInsets.fromLTRB(13,17,13,17),
                    child: state.user!.cycles_bank!.current_icrc1_ledger == null ? CyclesBankTransferCyclesForm(
                        key: ValueKey('CyclesBankScaffoldBody CyclesBankTransferCyclesForm ${state.current_url.string}')
                    ) : 
                    BankTransferIcrc1Form(
                        key: ValueKey('CyclesBankScaffoldBody BankTransferIcrc1Form ${state.user!.cycles_bank!.current_icrc1_ledger!.ledger.principal.bytes}'),
                        icrc1_ledger: state.user!.cycles_bank!.current_icrc1_ledger!    
                    )
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
                                    key: UniqueKey(), //ValueKey('cb cycles-transfers-out'),
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
                                    key: UniqueKey(), //ValueKey('cb cycles-transfers-in'),
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
                    )
                )
            ]);
            if (state.current_url.name == 'cycles_bank_pay') {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                    RenderBox box = transfer_cycles_form_container_key.currentContext!.findRenderObject()! as RenderBox;
                    Offset offset = box.localToGlobal(Offset.zero);
                    double animationHeight = main_listview_scroll_controller.offset + offset.dy - MediaQuery.of(context).padding.top - 56.0/*scaffold appbar*/ - 77/*page header*/;
                    main_listview_scroll_controller.animateTo(animationHeight, duration: Duration(milliseconds: 500), curve: Curves.decelerate);
                });
            }
        }
        
        return Center(
            child: Container(
                constraints: BoxConstraints(maxWidth: 900),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                        ScaffoldBodyHeader(Center(child:Column(children: [
                            Text('CYCLES-BANK', style: TextStyle(fontSize: 19)),
                            if (state.user != null && state.user!.cycles_bank != null) ...[
                                SelectableText('${state.user!.cycles_bank!.principal.text}', style: TextStyle(fontSize: 20)),
                                Container(
                                    padding: EdgeInsets.all(17),
                                    child: IconButton(
                                        icon: const Icon(Icons.settings_sharp, size: 30.0),
                                        tooltip: 'settings', 
                                        onPressed: () async {
                                            showDialog<void>(
                                                barrierDismissible: false,
                                                context: context,
                                                builder: (BuildContext context) => Dialog(
                                                    child: Container(
                                                        constraints: BoxConstraints(maxWidth: 700),
                                                        width: double.infinity,
                                                        margin: EdgeInsets.all(11.0),
                                                        padding: const EdgeInsets.all(8.0),
                                                        child: ConfigureCyclesBank(key: ValueKey('ConfigureCyclesBank')),
                                                    )
                                                )
                                            );
                                            return;                        
                                        }
                                    )
                                ),
                            ],
                        ]))),
                        Expanded(
                            child: ListView(
                                controller: main_listview_scroll_controller,
                                padding: EdgeInsets.all(0),
                                children: [
                                    Column(
                                        children: column_children 
                                    )
                                ],
                                addAutomaticKeepAlives: true
                            )
                        )
                    ]
                )
            )
        );
    }
}



class TokenBalance extends StatelessWidget {
    final String symbol;
    final Tokens tokens;
    TokenBalance({required this.symbol, required this.tokens, super.key});
    Widget build(BuildContext context) {
        return Container(
            padding: EdgeInsets.all(11),
            child: SelectableText('${this.symbol}: ${this.tokens}', style: TextStyle(fontSize: 27))
        );
    }
}
