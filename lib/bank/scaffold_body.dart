import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'package:ic_tools/tools.dart';
import 'package:ic_tools/common.dart' show Icrc1Ledger, Tokens;
import 'package:ic_tools/common.dart' as common;

import '../config/state.dart';
import '../config/state_bind.dart';
import '../config/urls.dart';
import 'forms.dart';
import 'cards.dart';
import 'configure.dart';
import '../main.dart';
import '../tools/widgets.dart';
import '../tools/ii_login.dart';
import '../tools/tools.dart';
import '../config/pages.dart';
import '../transfer_icp/icp_ledger.dart';
import '../transfer_icp/scaffold_body.dart';
import '../transfer_icp/cards.dart';
import '../cycles_market/scaffold_body.dart' show show_tokens_with_symbol, cycles_symbol;
import '../user.dart';

final GlobalKey transfer_cycles_form_container_key = GlobalKey();

class CyclesBankScaffoldBody extends StatelessWidget {
    CyclesBankScaffoldBody({Key? key}) : super(key: key);
    static CyclesBankScaffoldBody create({Key? key}) => CyclesBankScaffoldBody(key: key);
        
    final ScrollController cycles_transfers_out_scroll_controller = ScrollController();
    final ScrollController cycles_transfers_in_scroll_controller = ScrollController();    
    
    final ScrollController main_listview_scroll_controller = ScrollController();  
    
     final GlobalKey transfer_dialog_key = GlobalKey(); 
    
    @override
    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
        
        if (state.first_show_scaffold == false) {
            return Text(''); // is never shown to the user. it is for when the router is loading the first-state of tcs or bank or ledgers and want to put the pages into the navigator but not build the ui for the pages. 
        }
        
        late Widget body_widget;

        double scaffold_body_header_max_width = 900;
        
        if (state.user == null) {
            body_widget = Center(
                child: IILoginButton(key: ValueKey('cb-scaffold_body-ii-login-button')),
            );  
        } else {
            
            List<Widget> column_children = [];
            
            Future<void> Function() show_transfer_dialog = () async {
                showDialog<void>(
                    barrierDismissible: true,
                    context: context,
                    builder: (BuildContext context) => AlertDialog(
                        key: transfer_dialog_key,
                        title: Center(
                            child: Text('TRANSFER ${state.current_icrc1_ledger == CYCLES_BANK_LEDGER ? 'CYCLES' : state.current_icrc1_ledger.symbol}', /*style: TextStyle(fontSize:17)*/)
                        ),
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
                                        /*    
                                        SizedBox(
                                            height: 11,
                                            width: 3,
                                        ),*/
                                        BankIcrc1IdAndBalanceAndLoadBalanceAndFee(state.current_icrc1_ledger, key: ValueKey('BankTransferIcrc1FormState BankIcrc1IdAndBalanceAndLoadBalanceAndFee ${state.current_icrc1_ledger.symbol}')),
                                        SizedBox(
                                            width: 1,
                                            height: 11
                                        ),
                                        if (state.current_icrc1_ledger.ledger.principal == common.SYSTEM_CANISTERS.ledger.principal)
                                            BankTransferIcpForm(key: ValueKey('CyclesBankScaffoldBody BankTransferIcpForm'))
                                        else BankTransferIcrc1Form(
                                            key: ValueKey('CyclesBankScaffoldBody BankTransferIcrc1Form ${state.current_icrc1_ledger.ledger.principal.text}'),
                                            icrc1_ledger: state.current_icrc1_ledger    
                                        )
                                    ]
                                )
                            )
                        )
                    )
                );
            };

            column_children.addAll([
                SizedBox(height: 13),
                Container(
                    child: Container(margin: EdgeInsets.all(33), child: Column(
                        children: [
                            Container(
                                child: CyclesBankTokenSelector(),
                            ),
                            SizedBox(
                                width: 3,
                                height: 26
                            ),
                            DefaultTextStyle.merge(
                                style: TextStyle(fontSize: 27, fontFamily: 'CourierNewBold'),
                                child: Text(state.current_icrc1_ledger == CYCLES_BANK_LEDGER 
                                    ? Cycles(cycles: state.user!.icrc1_balances_cache[CYCLES_BANK_LEDGER]!).toString()
                                    : Tokens(
                                        quantums: state.user!.icrc1_balances_cache[state.current_icrc1_ledger]!,
                                        decimal_places: state.current_icrc1_ledger.decimals 
                                    ).toString()
                                )
                            ),
                            SizedBox(
                                width: 3,
                                height: 26
                            ),
                            Container(
                                padding: EdgeInsets.fromLTRB(7,0,7,7),
                                child: FilledButton.tonal(
                                    //style: ElevatedButton.styleFrom(backgroundColor: blue),
                                    child: Text('TRANSFER ${state.current_icrc1_ledger == CYCLES_BANK_LEDGER ? 'CYCLES' : state.current_icrc1_ledger.symbol}'),
                                    onPressed: () async {
                                        await show_transfer_dialog();
                                    }
                                )
                            ),
                            if (state.current_icrc1_ledger == CYCLES_BANK_LEDGER) ...[
                                SizedBox(
                                    width: 3,
                                    height: 10
                                ),
                                Container(
                                    padding: EdgeInsets.all(7),
                                    child: MintCyclesButton(),
                                ),
                            ],
                            SizedBox(
                                width: 3,
                                height: 10
                            ),
                            Container(
                                padding: EdgeInsets.all(7),
                                child: FilledButton.tonal(
                                    //style: ElevatedButton.styleFrom(backgroundColor: blue),
                                    child: Text('LOAD TRANSFERS'),
                                    onPressed: () async {
                                        state.loading_text = 'loading bank \$${state.current_icrc1_ledger == CYCLES_BANK_LEDGER ? 'CYCLES' : state.current_icrc1_ledger.symbol} transfers ...';
                                        state.is_loading = true;
                                        MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                                        try {
                                            await Future.wait([
                                                state.user!.fresh_icrc1_transactions([state.current_icrc1_ledger]),
                                                state.user!.fresh_icrc1_balances([state.current_icrc1_ledger]),
                                            ]);
                                        } catch(e) {
                                            await showDialog(
                                                context: state.context,
                                                builder: (BuildContext context) {
                                                    return AlertDialog(
                                                        title: Text('Error when loading the bank ${state.current_icrc1_ledger == CYCLES_BANK_LEDGER ? 'CYCLES' : state.current_icrc1_ledger.symbol} transfers:'),
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
                    ))
                ),
                Container(
                    constraints: BoxConstraints(
                        minWidth: scaffold_body_header_max_width,
                    ),
                    child: (state.current_icrc1_ledger == CYCLES_BANK_LEDGER)
                        ? BankCyclesTransfersLog(key: ValueKey('BankScaffoldBody BankCyclesTransfersLog'))
                        : (state.current_icrc1_ledger == common.Icrc1Ledgers.ICP)
                        ? IcpTransfersLogs(key: ValueKey('CyclesBankScaffoldBody IcpTransfersLogs'))
                        : BankTokenTransfersLog(key: ValueKey('BankScaffoldBody BankTokenTransfersLog ${state.current_icrc1_ledger.ledger.principal.text}'))
                ),
            ]);
            /*
            if (state.current_url.name == 'cycles_bank_pay') {
                if (ModalRoute.of(context)?.isCurrent == true) { // show if there are no open dialogs                    
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                        print('showing transfer dialog');
                        show_transfer_dialog();
                    });
                }
                /*
                WidgetsBinding.instance.addPostFrameCallback((_) {
                    RenderBox box = transfer_cycles_form_container_key.currentContext!.findRenderObject()! as RenderBox;
                    Offset offset = box.localToGlobal(Offset.zero);
                    double animationHeight = main_listview_scroll_controller.offset + offset.dy - MediaQuery.of(context).padding.top - 56.0/*scaffold appbar*/ - 77/*page header*/;
                    main_listview_scroll_controller.animateTo(animationHeight, duration: Duration(milliseconds: 500), curve: Curves.decelerate);
                });
                */
            }
            */
            
            body_widget = LayoutBuilder(builder: (context, constraints) {
                return SingleChildScrollView(
                    child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: column_children
                        ),
                    )
                );
            });
        }

        return Center(
            child: Container(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                        Container(
                            constraints: BoxConstraints(maxWidth: scaffold_body_header_max_width),
                            child: ScaffoldBodyHeader(Row(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                    Flexible(flex: 1,  fit: FlexFit.tight, child: Container(width: double.infinity, child: Text(''))),
                                    Flexible(flex: 11, fit: FlexFit.tight, child: Center(
                                        child: Column(
                                            children: [
                                                Text('CYCLES-BANK', style: TextStyle(fontSize: 19)),
                                                //if (state.user != null ) ...[
                                                //    SelectableText('${state.user!.principal.text}', style: TextStyle(fontSize: 17)),
                                                //]
                                            ]
                                        )
                                    )),
                                    Flexible(flex:1, fit: FlexFit.tight, child:Container(
                                        width: double.infinity,
                                        child: state.user != null ? Align(
                                            alignment: Alignment.centerRight,
                                            child: Container(
                                                child: IconButton(
                                                    icon: const Icon(Icons.settings_sharp, size: 19),
                                                    tooltip: 'Settings',
                                                    onPressed: () async {
                                                        showDialog<void>(
                                                            barrierDismissible: true,
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
                            )
                        )),
                        Expanded(
                            child: body_widget
                        )
                    ]
                )
            )
        );
    }
}





class CyclesBankTokenSelector extends StatefulWidget {
    CyclesBankTokenSelector({super.key});
    State<CyclesBankTokenSelector> createState() => CyclesBankTokenSelectorState();
}
class CyclesBankTokenSelectorState extends State<CyclesBankTokenSelector> {

    late TextEditingController text_controller;
    late FocusNode focus_node;

    late CustomState state; // need for the focus_node listener
    late MainStateBindScope<CustomState> main_state_bind_scope;

    void initState() {
        super.initState();
        text_controller = TextEditingController();
        focus_node = FocusNode(
            debugLabel: 'bank token selector',
            canRequestFocus: switch (defaultTargetPlatform) {
                TargetPlatform.android || TargetPlatform.iOS => false,
                _ => true,
            }
        );
        focus_node.addListener(focus_node_listener);
    }
    void dispose() {
        text_controller.dispose();
        focus_node.removeListener(focus_node_listener);
        focus_node.dispose();
        super.dispose();
    }

    void focus_node_listener() {
        // if go away from focus, set the text back to the current token symbol in case someone left something else in the text field.
        if (focus_node.hasPrimaryFocus == false) {
            print('setting token selector text back to the current token symbol');
            text_controller.text = state.current_icrc1_ledger == CYCLES_BANK_LEDGER ? 'CYCLES' : state.current_icrc1_ledger.symbol;
        }
    }

    Widget build(BuildContext context) {
        state = MainStateBind.get_state<CustomState>(context);
        main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);

        return DropdownMenu<Icrc1Ledger>(
            // remove the border
            inputDecorationTheme: InputDecorationTheme(
                outlineBorder: BorderSide.none,
                border: InputBorder.none,
            ),
            controller: text_controller,
            focusNode: focus_node,
            enableSearch: true,
            enableFilter: false, // we want the user to always be able to know that there are many tokens. the search already moves the highlighted selection so no need for this flag.
            textStyle: DefaultTextStyle.of(context).style.copyWith(fontFamily: 'CourierNewBold', fontSize: 22),
            dropdownMenuEntries: <DropdownMenuEntry<Icrc1Ledger>>[
                for (Icrc1Ledger icrc1_ledger in state.known_icrc1_ledgers)
                    DropdownMenuEntry<Icrc1Ledger>(
                        label: icrc1_ledger == CYCLES_BANK_LEDGER ? 'CYCLES' : icrc1_ledger.symbol,
                        value: icrc1_ledger,
                        style: ButtonStyle(textStyle: WidgetStatePropertyAll(TextStyle(fontFamily: 'CourierNewBold', fontSize: 22)))
                    ),
            ],
            initialSelection: state.current_icrc1_ledger,
            onSelected: (Icrc1Ledger? select_icrc1_ledger) {
                if (select_icrc1_ledger != null) {
                    if (select_icrc1_ledger != state.current_icrc1_ledger) {
                        change_url_into_cb(select_icrc1_ledger, context);
                    } else {
                        setState((){});
                    }
                }
            }
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


class ViewLedgerLogs extends StatelessWidget {

    final int itemCount;
    final Widget Function(BuildContext, int) itemBuilder;

    ViewLedgerLogs({
        super.key,
        required this.itemBuilder,
        required this.itemCount,
    });

    final ScrollController scroll_controller = ScrollController();

    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);

        return Container(
            constraints: BoxConstraints(
                maxHeight: 370, // 307?
            ),
            child: Container(
                child: ScrollConfigurationWithTheMouse(
                    Scrollbar(
                        controller: scroll_controller,
                        child: ListView.builder(
                            controller: scroll_controller,
                            key: UniqueKey(),
                            scrollDirection: Axis.horizontal,
                            reverse: false,
                            shrinkWrap: true,
                            padding: EdgeInsets.all(11),
                            itemBuilder: itemBuilder,
                            itemCount: itemCount,
                            addAutomaticKeepAlives: true,
                            addRepaintBoundaries: true,
                            addSemanticIndexes: true,
                            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
                            //clipBehavior: Clip.hardEdge
                        )
                    )
                )
            )
        );
    }
}


class BankTokenTransfersLog extends StatelessWidget {
    BankTokenTransfersLog({super.key});
    
    final ScrollController token_transfers_log_scroll_controller = ScrollController();
    
    Widget build(BuildContext context) {
        
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
    
        Icrc1Ledger ledger = state.current_icrc1_ledger;
        List<Icrc1Transaction> ts = state.user!.icrc1_transactions_cache[ledger]!;
    
        return ViewLedgerLogs(
            itemBuilder: (BuildContext context, int i) {
                return Icrc1TransactionCard(ledger, ts[i]);
            },
            itemCount: ts.length
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
            child: LedgerBlockLogCard(
                child: Column(
                    //mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                        ListTile(
                            title: Text('${ledger.symbol} TRANSFER'),
                            subtitle: Text('ID: ${t.block}'),
                        ),
                        Expanded(
                            child: Padding(
                                padding: EdgeInsets.fromLTRB(17,7,17,7),
                                child: DefaultTextStyle.merge(
                                    style: TextStyle(fontFamily: 'CourierNew', fontSize: ct_list_item_body_font_size),
                                    child: Column(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                            Text('operation: ${t.icrc1_transaction_kind.name}'),
                                            Text('tokens: ${Tokens(quantums: t.tokens, decimal_places: ledger.decimals)}'),
                                            if (t.from != null) Text('from: ${t.from}'),
                                            if (t.to != null) Text('to: ${t.to}'),
                                            if (t.memo != null && t.memo!.isNotEmpty) Row(children: [
                                                Text('memo: '),
                                                if (t.memo!.length <= 8) Text('${bytesasahexstring(t.memo!)}')
                                                else Tooltip(
                                                    message: bytesasahexstring(t.memo!),
                                                    child: Text('${bytesasahexstring(t.memo!.sublist(0, 8))}...')
                                                )
                                            ]),
                                            Text('fee: ${t.fee == null ? 0 : Tokens(quantums: t.fee!, decimal_places: ledger.decimals)}'),
                                            Text('timestamp: ${log_timestamp_format(DateTime.fromMillisecondsSinceEpoch(milliseconds_of_the_nanos(t.timestamp_nanos).toInt()))}'),
                                        ]
                                    ),
                                )
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
        
        return ViewLedgerLogs(
            itemBuilder: (BuildContext context, int i) {
                return IcpTransferListItem(state.user!.icp_transfers[i], state.user!.icp_id);
            },
            itemCount: state.user!.icp_transfers.length,
        );
    }
}


class BankCyclesTransfersLog extends StatelessWidget {
    BankCyclesTransfersLog({super.key});
    
    final ScrollController log_scroll_controller = ScrollController();
    
    Widget build(BuildContext context) {
        
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
    
        List<CyclesTransfer> cycles_transfers = state.user!.cycles_transfers;
    
        return ViewLedgerLogs(
            itemBuilder: (BuildContext context, int i) {
                CyclesTransfer t = cycles_transfers.elementAt(cycles_transfers.length -1 -i);
                return CyclesTransferListItem(t);
            },
            itemCount: cycles_transfers.length,
        );
    }
}


List<Future> generate_possible_cb_first_load_futures(Icrc1Ledger select_icrc1_ledger, CustomState state) {
    List<Future> wait_futures = [];
    if (state.user != null) {
        if (state.user!.first_load_icrc1ledgers_balances.containsKey(select_icrc1_ledger) == false) {
            state.user!.first_load_icrc1ledgers_balances[select_icrc1_ledger] = state.user!.fresh_icrc1_balances([select_icrc1_ledger]);
            wait_futures.add(state.user!.first_load_icrc1ledgers_balances[select_icrc1_ledger]!);
            //print('bank ${select_icrc1_ledger.symbol} balances first load');
        }
        if (state.user!.first_load_icrc1ledgers_transactions.containsKey(select_icrc1_ledger) == false) {
            state.user!.first_load_icrc1ledgers_transactions[select_icrc1_ledger] = state.user!.fresh_icrc1_transactions([select_icrc1_ledger]);
            wait_futures.add(state.user!.first_load_icrc1ledgers_transactions[select_icrc1_ledger]!);
            //print('bank ${select_icrc1_ledger.symbol} transactions first load');
        }
    }
    return wait_futures;
}


void change_url_into_cb(Icrc1Ledger select_icrc1_ledger, BuildContext context) {
    CustomState state = MainStateBind.get_state<CustomState>(context);
    MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
    
    List<Future> wait_futures = generate_possible_cb_first_load_futures(select_icrc1_ledger, state);
   
    Function d = () {
        state.current_icrc1_ledger = select_icrc1_ledger;
        state.current_url = CustomUrl('cycles_bank', variables: {'token_ledger_id': select_icrc1_ledger.ledger.principal.text});
        main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);                                                        
    };
    
    if (wait_futures.isNotEmpty) {
        state.loading_text = 'loading ${select_icrc1_ledger.symbol} balance and transactions ...';
        state.is_loading = true;
        state.show_loading_page_transition_completer = Completer();
        wait_futures.add(state.show_loading_page_transition_completer.future);
        main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);
        Future.wait(wait_futures).then((_x){
            state.is_loading = false;
            d();
        });
    } else {
        d();
    }
}
