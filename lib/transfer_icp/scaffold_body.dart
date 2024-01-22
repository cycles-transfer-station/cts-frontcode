import 'dart:ui' as dart_ui;

import 'package:flutter/material.dart';
import 'package:ic_tools/tools.dart';
import 'package:ic_tools/common.dart';

import '../config/state.dart';
import '../config/state_bind.dart';
import 'icp_ledger.dart';
import 'forms.dart';
import 'cards.dart';
import '../main.dart';
import '../tools/widgets.dart';
import '../tools/ii_login.dart';
import '../config/pages.dart';

/*
class TransferIcpScaffoldBody extends StatelessWidget {
    TransferIcpScaffoldBody({Key? key}) : super(key: key);
    static TransferIcpScaffoldBody create({Key? key}) => TransferIcpScaffoldBody(key: key);
    
    final ScrollController scroll_controller = ScrollController();
    
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


        if (state.user != null) {
            column_children.addAll([
                Wrap(
                    children: [
                        Container(
                            constraints: BoxConstraints(
                                maxWidth: 350,
                                minWidth: 250
                            ),
                            padding: EdgeInsets.all(17),
                            child: Column(
                                children: [
                                    Center(
                                        child: SelectableText('USER-CTS-ICP-ID:', style: TextStyle(fontSize: 13)),
                                    ),
                                    Center(
                                        child: SelectableText('${state.user!.icp_id}', style: TextStyle(fontSize: 11)),
                                    ),
                                    IcpBalanceAndLoadIcpBalance(key: ValueKey('TransferIcpScaffoldBody IcpBalanceAndLoadIcpBalance'))
                                ]
                            )
                        ),
                        Container(
                            constraints: BoxConstraints(
                                maxWidth: 350,
                                minWidth: 250
                            ),
                            padding: EdgeInsets.all(17),
                            child: Column(
                                children: [
                                    UserTransferIcpForm(key: ValueKey('TransferIcpScaffoldBody UserTransferIcpForm'))  /*Text('')*/
                                ]
                            )
                        )
                    ]
                )
            ]);
                
            column_children.addAll([
                SizedBox(
                    width: 1,
                    height: 40
                ),
                Padding(
                    padding: EdgeInsets.all(7),
                    child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: blue),
                        child: Text('LOAD TRANSFERS', style: TextStyle(fontSize:11)),
                        onPressed: () async {
                            state.loading_text = 'loading user icp transfers ...';
                            state.is_loading = true;
                            MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                            try {
                                await state.user!.fresh_icrc1_transactions([Icrc1Ledgers.ICP]);
                            } catch(e) {
                                await showDialog(
                                    context: state.context,
                                    builder: (BuildContext context) {
                                        return AlertDialog(
                                            title: Text('Error when loading the user icp transfers:'),
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
                LimitedBox(
                    maxHeight: 307,
                    child: Container(
                        constraints: BoxConstraints(),
                        //padding: EdgeInsets.all(17),
                        child: ScrollConfiguration(
                            behavior: ScrollConfiguration.of(context).copyWith(dragDevices: ScrollConfiguration.of(context).dragDevices.toSet()..add(dart_ui.PointerDeviceKind.mouse), ),
                            child: Scrollbar(
                                controller: scroll_controller,
                                child: ListView.builder(
                                    controller: scroll_controller,
                                    key: UniqueKey(), //ValueKey('transfer-icp icp-transfers-list-items'),
                                    scrollDirection: Axis.horizontal,
                                    reverse: false,
                                    shrinkWrap: false,
                                    padding: EdgeInsets.all(11),
                                    itemBuilder: (BuildContext context, int i) {
                                        return IcpTransferListItem(state.user!.icp_transfers[i], state.user!.icp_id);
                                    },
                                    itemCount: state.user!.icp_transfers.length,
                                    addAutomaticKeepAlives: false,
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
            
        } else /*if (state.user == null)*/ {
            
            column_children.addAll([
                Text('Log in for the icp-transfers.'),
                Container(
                    padding: EdgeInsets.all(11),
                    child: Center(child: OutlineButton(
                        button_text: 'ii login',
                        on_press_complete: () async { await ii_login(context); }
                    )) 
                )
            ]);
            
        }        
        
        
        return Center(
            child: Container(
                constraints: BoxConstraints(maxWidth: 900),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                        ScaffoldBodyHeader(Text('TRANSFER-ICP', style: TextStyle(fontSize: 19))),
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
                        )
                    ]
                )
            )
        );
    }
}

*/
class IcpBalanceAndLoadIcpBalance extends StatelessWidget {
    IcpBalanceAndLoadIcpBalance({super.key});
    
    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);

        
        return Padding(
            padding: EdgeInsets.fromLTRB(13.0, 13, 13,13),
            child: Column(
                children: [
                    //Text('ICP-BALANCE: ${state.user!.icp_balance != null ? state.user!.icp_balance!.icp : 'unknown'}', style: TextStyle(fontSize:17)),
                    //Text('timestamp: ${state.user!.icp_balance != null ? seconds_of_the_nanos(state.user!.icp_balance!.timestamp_nanos) : 'unknown'}', style: TextStyle(fontSize:9)),
                    Padding(
                        padding: EdgeInsets.fromLTRB(7,13,7,7),
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: blue),
                            child: Text('LOAD ICP BALANCE', style: TextStyle(fontSize:11)),
                            onPressed: () async {
                                state.loading_text = 'load user icp balance ...';
                                state.is_loading = true;
                                MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                                try {
                                    //await state.user!.fresh_icp_balance();
                                } catch(e) {
                                    await showDialog(
                                        context: state.context,
                                        builder: (BuildContext context) {
                                            return AlertDialog(
                                                title: Text('Error when checking the user icp balance:'),
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
                ]
            )
        );
    }
}


