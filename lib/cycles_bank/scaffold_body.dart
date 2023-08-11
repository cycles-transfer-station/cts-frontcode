import 'dart:ui' as dart_ui;

import 'package:flutter/material.dart';
import 'package:ic_tools/tools.dart';
import 'package:ic_tools/common.dart' show Icrc1Ledger, Tokens;
import 'package:ic_tools/common.dart' as common;


import '../config/state.dart';
import '../config/state_bind.dart';
import 'forms.dart';
import 'cards.dart';
import 'cycles_bank.dart';
import 'configure.dart';
import 'create_bank.dart';
import '../main.dart';
import '../tools/widgets.dart';
import '../tools/ii_login.dart';
import '../tools/tools.dart';
import '../config/pages.dart';
import '../transfer_icp/icp_ledger.dart';
import '../transfer_icp/scaffold_body.dart';
import '../transfer_icp/cards.dart';


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
        
            column_children.add(CreateBank());
        
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
                                    quantums: state.user!.cycles_bank!.icrc1_balances_cache[state.user!.cycles_bank!.current_icrc1_ledger!]!,
                                    decimal_places: state.user!.cycles_bank!.current_icrc1_ledger!.decimals 
                                ), 
                                key: ValueKey('CyclesBankScaffoldBody Icrc1TokenBalance')
                            ),
                            SizedBox(
                                width: 3,
                                height: 7
                            ),
                        ]
                    )
                ),
                Container(
                    child: Padding(
                        padding: EdgeInsets.all(7),
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: blue),
                            child: Text('TRANSFER ${state.user!.cycles_bank!.current_icrc1_ledger == null ? 'CYCLES' : state.user!.cycles_bank!.current_icrc1_ledger!.symbol}'),
                            onPressed: () async {
                                showDialog<void>(
                                    barrierDismissible: true,
                                    context: context,
                                    builder: (BuildContext context) => AlertDialog(
                                        title: null,//Center(child: Text('')),
                                        content: Container(
                                            constraints: BoxConstraints(
                                                maxWidth: 700
                                            ),
                                            //width: double.infinity,
                                            //margin: EdgeInsets.all(11.0),
                                            //padding: const EdgeInsets.all(8.0),
                                            child: SingleChildScrollView(
                                                child: Column(
                                                    children: [
                                                        Container(
                                                            width: double.infinity,
                                                            padding: EdgeInsets.fromLTRB(7,11,7,11),
                                                            child: Center(
                                                                child: Text('TRANSFER-${state.user!.cycles_bank!.current_icrc1_ledger == null ? 'CYCLES' : state.user!.cycles_bank!.current_icrc1_ledger!.symbol}', style: TextStyle(fontSize:17))
                                                            ),
                                                        ),
                                                        SizedBox(
                                                            height: 11,
                                                            width: 3,
                                                        ),
                                                        if (state.user!.bank!.current_icrc1_ledger != null) ...[ 
                                                            BankIcrc1IdAndBalanceAndLoadBalanceAndFee(state.user!.bank!.current_icrc1_ledger!, key: ValueKey('BankTransferIcrc1FormState BankIcrc1IdAndBalanceAndLoadBalanceAndFee ${state.user!.bank!.current_icrc1_ledger!.symbol}')),
                                                            SizedBox(
                                                                width: 1,
                                                                height: 11
                                                            )
                                                        ],
                                                        if (state.user!.cycles_bank!.current_icrc1_ledger == null) 
                                                            CyclesBankTransferCyclesForm(key: ValueKey('CyclesBankScaffoldBody CyclesBankTransferCyclesForm ${state.current_url.string}'))
                                                        else if (state.user!.cycles_bank!.current_icrc1_ledger!.ledger.principal == common.SYSTEM_CANISTERS.ledger.principal)
                                                            BankTransferIcpForm(key: ValueKey('CyclesBankScaffoldBody BankTransferIcpForm'))
                                                        else BankTransferIcrc1Form(
                                                            key: ValueKey('CyclesBankScaffoldBody BankTransferIcrc1Form ${state.user!.cycles_bank!.current_icrc1_ledger!.ledger.principal.bytes}'),
                                                            icrc1_ledger: state.user!.cycles_bank!.current_icrc1_ledger!    
                                                        )
                                                    ]
                                                )
                                            )
                                        )
                                    )
                                );
                            }
                        )
                    ),
                    //Text('TRANSFER ${state.user!.cycles_bank!.current_icrc1_ledger == null ? 'CYCLES' : state.user!.cycles_bank!.current_icrc1_ledger!.symbol} Button'), 
                ),
                /*
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
                */
                SizedBox(width: 1, height: 11),
                Padding(
                    padding: EdgeInsets.fromLTRB(7,37,7,17),
                    child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: blue),
                        child: Text('LOAD TRANSFERS', style: TextStyle(fontSize:11)),
                        onPressed: () async {
                            state.loading_text = 'loading bank \$${state.user!.cycles_bank!.current_icrc1_ledger == null ? 'CYCLES' : state.user!.cycles_bank!.current_icrc1_ledger!.symbol} transfers ...';
                            state.is_loading = true;
                            MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                            try {
                                List<Future<void>> futures = [];
                                if (state.user!.cycles_bank!.current_icrc1_ledger == null) {
                                    futures.addAll([
                                        state.user!.cycles_bank!.fresh_cycles_transfers_in(),
                                        state.user!.cycles_bank!.fresh_cycles_transfers_out(),
                                    ]); 
                                } else {
                                    futures.add(state.user!.bank!.fresh_icrc1_transactions(state.user!.bank!.current_icrc1_ledger!));
                                }
                                await Future.wait(futures);
                            } catch(e) {
                                await showDialog(
                                    context: state.context,
                                    builder: (BuildContext context) {
                                        return AlertDialog(
                                            title: Text('Error when loading the bank ${state.user!.cycles_bank!.current_icrc1_ledger == null ? 'CYCLES' : state.user!.cycles_bank!.current_icrc1_ledger!.symbol} transfers:'),
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
                Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(11,0,0,0),
                    child: Text('${state.user!.cycles_bank!.current_icrc1_ledger == null ? 'CYCLES' : state.user!.cycles_bank!.current_icrc1_ledger!.symbol}-TRANSFERS', style: TextStyle(fontSize: 17)),
                ),                
                if (state.user!.cycles_bank!.current_icrc1_ledger != null) ...[
                    if (state.user!.cycles_bank!.current_icrc1_ledger!.ledger.principal == common.SYSTEM_CANISTERS.ledger.principal) IcpTransfersLogs(key: ValueKey('CyclesBankScaffoldBody IcpTransfersLogs'))
                    else BankTokenTransfersLog(key: ValueKey('BankScaffoldBody BankTokenTransfersLog ${state.user!.bank!.current_icrc1_ledger}'))
                ]
                else ...[
                    BankCyclesTransfersLog(key: ValueKey('BankScaffoldBody BankCyclesTransfersLog')),
                    /*
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
                    */
                ]
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
                        ScaffoldBodyHeader(Row(
                            mainAxisSize: MainAxisSize.max, 
                            children: [
                                Flexible(flex: 1,  fit: FlexFit.tight, child: Container(width: double.infinity, child: Text(''))),
                                Flexible(flex: 11, fit: FlexFit.tight, child: Center(
                                    child: Column(
                                        children: [
                                            Text('CYCLES-BANK', style: TextStyle(fontSize: 19)),
                                            if (state.user != null && state.user!.cycles_bank != null) ...[
                                                SelectableText('${state.user!.cycles_bank!.principal.text}', style: TextStyle(fontSize: 17)),
                                            ]
                                        ]
                                    )
                                )),
                                Flexible(flex:1, fit: FlexFit.tight, child:Container(
                                    width: double.infinity, 
                                    child: state.user != null && state.user!.bank != null ? Align(
                                        alignment: Alignment.topRight, 
                                        child: Container(
                                            padding: EdgeInsets.all(3),
                                            child: IconButton(
                                                icon: const Icon(Icons.settings_sharp, size: 17.0),
                                                tooltip: 'Settings', 
                                                onPressed: () async {
                                                    showDialog<void>(
                                                        barrierDismissible: false,
                                                        context: context,
                                                        builder: (BuildContext context) => Dialog(
                                                            child: Container(
                                                                constraints: BoxConstraints(maxWidth: 500),
                                                                //width: double.infinity,
                                                                margin: EdgeInsets.all(11.0),
                                                                padding: const EdgeInsets.all(8.0),
                                                                child: Center(child: ConfigureCyclesBank(key: ValueKey('ConfigureCyclesBank'))),
                                                            )
                                                        )
                                                    );
                                                    return;                        
                                                }
                                            )
                                        ) 
                                    ) : Text('')
                                )),
                            ]
                        )),
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


class BankTokenTransfersLog extends StatelessWidget {
    BankTokenTransfersLog({super.key});
    
    final ScrollController token_transfers_log_scroll_controller = ScrollController();
    
    Widget build(BuildContext context) {
        
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
    
        Icrc1Ledger ledger = state.user!.bank!.current_icrc1_ledger!;
        List<Icrc1Transaction> ts = state.user!.bank!.icrc1_transactions_cache[ledger]!;
    
        return LimitedBox(
            maxHeight: 500,
            child: Container(
                child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(dragDevices: ScrollConfiguration.of(context).dragDevices.toSet()..add(dart_ui.PointerDeviceKind.mouse), ),
                    child: Scrollbar(
                        controller: token_transfers_log_scroll_controller,
                        child: ListView.builder(
                            controller: token_transfers_log_scroll_controller,    
                            key: UniqueKey(), //ValueKey('cb cycles-transfers-out'),
                            scrollDirection: Axis.horizontal,
                            reverse: false,
                            shrinkWrap: false,
                            padding: EdgeInsets.all(11),
                            itemBuilder: (BuildContext context, int i) {
                                return Icrc1TransactionCard(ledger, ts[i]);
                            },
                            itemCount: ts.length,
                            addAutomaticKeepAlives: true,
                            addRepaintBoundaries: true,
                            addSemanticIndexes: true,
                            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
                            clipBehavior: Clip.hardEdge
                        )
                    )
                )
            )
        );    
    } 
}


class Icrc1TransactionCard extends StatelessWidget {
    Icrc1TransactionCard(this.ledger, this.t) : super(key: ValueKey('Icrc1TransactionCard ${t.block} ${ledger.symbol}'));
    Icrc1Ledger ledger; 
    Icrc1Transaction t;    

    Widget build(BuildContext context) {
        return Container(
            padding: EdgeInsets.all(11),
            constraints: BoxConstraints(maxWidth: 320),
            child: Card(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                        ListTile(
                            title: Text('${ledger.symbol}-TRANSFER-LOG'),
                            subtitle: Text('ID: ${t.block}'),
                        ),
                        Expanded(
                            child: Padding(
                                padding: EdgeInsets.fromLTRB(17,7,17,7),
                                child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                        Text('kind: ${t.icrc1_transaction_kind.name}'),
                                        Text('for: ${t.to}'),
                                        Text('by: ${t.from}'),
                                        Text('tokens: ${Tokens(quantums: t.tokens, decimal_places: ledger.decimals)}'),
                                        Text('memo: ${t.memo == null ? '' : bytesasahexstring(t.memo!)}'),
                                        Text('ledger-fee: ${t.fee == null ? 0 : Tokens(quantums: t.fee!, decimal_places: ledger.decimals)}'),
                                        Text('timestamp: ${seconds_of_the_nanos(t.timestamp_nanos)}'),
                                    ]
                                ),
                            )
                        )
                    ]
                )
            )
        );
        
    }
}



class IcpTransfersLogs extends StatelessWidget {
    IcpTransfersLogs({super.key});
    
    final ScrollController icp_transfers_log_scroll_controller = ScrollController();
    
    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
        
        return LimitedBox(
            maxHeight: 307,
            child: Container(
                child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(dragDevices: ScrollConfiguration.of(context).dragDevices.toSet()..add(dart_ui.PointerDeviceKind.mouse), ),
                    child: Scrollbar(
                        controller: icp_transfers_log_scroll_controller,
                        child: ListView.builder(
                            controller: icp_transfers_log_scroll_controller,
                            key: UniqueKey(),
                            scrollDirection: Axis.horizontal,
                            reverse: false,
                            shrinkWrap: false,
                            padding: EdgeInsets.all(11),
                            itemBuilder: (BuildContext context, int i) {
                                return IcpTransferListItem(state.user!.bank!.icp_transfers[i], state.user!.bank!.icp_id);
                            },
                            itemCount: state.user!.bank!.icp_transfers.length,
                            addAutomaticKeepAlives: true,
                        )
                    )
                )
            )
        );
    }
}


/*
class BankCyclesTransfersLog extends StatefulWidget {
    BankCyclesTransfersLog({super.key});
    State createState => BankCyclesTransfersLogState();
}
class BankCyclesTransfersLogState extends State<BankCyclesTransfersLog> {
    
    Widget build(BuildContext context) {
    
    } 
}
*/
class BankCyclesTransfersLog extends StatelessWidget {
    BankCyclesTransfersLog({super.key});
    
    final ScrollController token_transfers_log_scroll_controller = ScrollController();
    
    Widget build(BuildContext context) {
        
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
    
        List<CyclesTransfer> cycles_transfers = <CyclesTransfer>[
            ...state.user!.bank!.cycles_transfers_out,
            ...state.user!.bank!.cycles_transfers_in,
        ]
        ..sort((t1, t2)=>t1.id.compareTo(t2.id));
    
        return LimitedBox(
            maxHeight: 307,
            child: Container(
                child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(dragDevices: ScrollConfiguration.of(context).dragDevices.toSet()..add(dart_ui.PointerDeviceKind.mouse), ),
                    child: Scrollbar(
                        controller: token_transfers_log_scroll_controller,
                        child: ListView.builder(
                            controller: token_transfers_log_scroll_controller,    
                            key: UniqueKey(),
                            scrollDirection: Axis.horizontal,
                            reverse: false,
                            shrinkWrap: true,
                            padding: EdgeInsets.all(11),
                            itemBuilder: (BuildContext context, int i) {
                                CyclesTransfer t = cycles_transfers.elementAt(cycles_transfers.length -1 -i);
                                if (t is CyclesTransferOut) {
                                    return CyclesTransferOutListItem(t as CyclesTransferOut);
                                } else if (t is CyclesTransferIn) {
                                    return CyclesTransferInListItem(t as CyclesTransferIn);
                                }
                                return null;
                            },
                            itemCount: cycles_transfers.length,
                        )
                    )
                )
            )
        );    
    } 
}


