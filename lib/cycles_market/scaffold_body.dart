import 'dart:ui' as dart_ui;

import 'package:flutter/material.dart';

import 'package:ic_tools/tools.dart';
import 'package:ic_tools/common.dart';

import '../config/state.dart';
import '../config/state_bind.dart';
import 'forms.dart';
import 'cards.dart';
import 'cycles_market_data.dart';
import '../cycles_bank/cycles_bank.dart';
import '../main.dart';
import '../widgets.dart';
import '../config/pages.dart';
import '../config/urls.dart';


class CyclesMarketScaffoldBody extends StatelessWidget {
    CyclesMarketScaffoldBody({Key? key}) : super(key: key);
    static CyclesMarketScaffoldBody create({Key? key}) => CyclesMarketScaffoldBody(key: key);
    
    final ScrollController user_cycles_positions_scroll_controller = ScrollController();
    final ScrollController user_icp_positions_scroll_controller = ScrollController();    
    final ScrollController user_cycles_positions_purchases_scroll_controller = ScrollController();
    final ScrollController user_icp_positions_purchases_scroll_controller = ScrollController();    
    final ScrollController cycles_positions_scroll_controller = ScrollController();
    final ScrollController icp_positions_scroll_controller = ScrollController();    
    final ScrollController cycles_positions_purchases_scroll_controller = ScrollController();
    final ScrollController icp_positions_purchases_scroll_controller = ScrollController();    
    
    
    
    @override
    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
        
        
        List<Widget> column_children = [];
                
        column_children.add(
            SizedBox(
                height: 21
            )
        );
        
        if (state.user == null) {
            column_children.addAll([
                OutlineButton(
                    button_text: 'ii login',
                    on_press_complete: () async { await ii_login(context); }
                )       
            ]);
        } else if (state.user!.cycles_bank == null) {
            column_children.addAll([
                Container(
                    width: double.infinity,
                    height: 50,
                    constraints: BoxConstraints(maxWidth: 731),
                    padding: EdgeInsets.all(11),
                    child: OutlineButton(
                        button_text: 'PURCHASE CYCLES-BANK',
                        on_press_complete: () async {
                            state.current_url = CustomUrl('cycles_bank');
                            state.loading_text = 'loading ...';
                            state.is_loading = true;
                            MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                            state.is_loading = false;
                            main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);
                        }
                    )
                )
            ]);
        } else if (state.user != null && state.user!.cycles_bank != null) {
            column_children.addAll([
                Center(
                    child: Padding(
                        padding: EdgeInsets.all(17),
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: blue),
                            child: Text('LOAD CYCLES-MARKET DATA', style: TextStyle(fontSize:11)),
                            onPressed: () async {
                                state.loading_text = 'loading cycles-market data ...';
                                state.is_loading = true;
                                MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                                try {
                                    await Future.wait([
                                        state.cycles_market_data.load_data(),
                                        state.user!.cycles_bank!.fresh_metrics(),
                                        state.user!.cycles_bank!.load_cm_data()
                                    ]);
                                } catch(e) {
                                    await showDialog(
                                        context: state.context,
                                        builder: (BuildContext context) {
                                            return AlertDialog(
                                                title: Text('Error when loading the cycles-market data:'),
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
                ),
                Wrap(
                    children: [
                        Container(
                            constraints: BoxConstraints(maxWidth: 350, minWidth: 250),
                            child: Column(
                                children: [
                                    Container(
                                        padding: EdgeInsets.fromLTRB(17,5,17,5),
                                        child: Column(
                                            children: [
                                                Center(
                                                    child: SelectableText('CYCLES-BANK-ID: ', style: TextStyle(fontSize: 13)),
                                                ),
                                                SizedBox(
                                                    height: 27,
                                                    child: Center(
                                                        child: SelectableText('${state.user!.cycles_bank!.principal.text}', style: TextStyle(fontSize: 11)),
                                                    ),
                                                ),
                                                Container(
                                                    padding: EdgeInsets.fromLTRB(10,7,10,3),
                                                    child: Text('CYCLES: ${state.user!.cycles_bank!.metrics != null ? state.user!.cycles_bank!.metrics!.cycles_balance : 'unknown'}', style: TextStyle(fontSize:17)),                   
                                                )
                                            ]
                                        )
                                    )
                                ]
                            ) 
                        ),
                        Container(
                            constraints: BoxConstraints(maxWidth: 350, minWidth: 250),
                            child: Column(
                                children: [
                                    Container(
                                        padding: EdgeInsets.fromLTRB(17,5,17,5),
                                        child: Column(
                                            children: [
                                                Center(
                                                    child: SelectableText('CYCLES-BANK\'S CYCLES-MARKET ICP-ID: ', style: TextStyle(fontSize: 13)),
                                                ),
                                                SizedBox(
                                                    height: 27,
                                                    child: Center(
                                                        child: SelectableText('${state.user!.cycles_bank!.cm_icp_id}', style: TextStyle(fontSize: 11)),
                                                    ),
                                                ),
                                                Container(
                                                    padding: EdgeInsets.fromLTRB(10,7,10,3),
                                                    child: Text('ICP: ${state.user!.cycles_bank!.cm_icp_balance != null ? state.user!.cycles_bank!.cm_icp_balance! : 'unknown'}', style: TextStyle(fontSize:17)),                   
                                                )
                                            ]
                                        )
                                    ),
                                    /*
                                    Padding(
                                        padding: EdgeInsets.all(7),
                                        child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(backgroundColor: blue),
                                            child: Text('LOAD CM ICP BALANCE', style: TextStyle(fontSize:11)),
                                            onPressed: () async {
                                                state.loading_text = 'loading cycles-bank\'s cycles-market icp balance ...';
                                                state.is_loading = true;
                                                MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                                                try {
                                                    await state.user!.cycles_bank!.fresh_cm_icp_balance();
                                                } catch(e) {
                                                    await showDialog(
                                                        context: state.context,
                                                        builder: (BuildContext context) {
                                                            return AlertDialog(
                                                                title: Text('Error when loading the cycles-bank\'s cycles-market icp balance:'),
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
                                    */
                                    Padding(
                                        padding: EdgeInsets.all(7),
                                        child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(backgroundColor: blue),
                                            child: Text('WITHDRAW CM ICP BALANCE', style: TextStyle(fontSize:11)),
                                            onPressed: () async {
                                                await showDialog(
                                                    context: context,
                                                    builder: (BuildContext context) {
                                                        return AlertDialog(
                                                            title: Center(child: Text('Withdraw cycles-market icp-balance')),
                                                            content: Container(
                                                                padding: EdgeInsets.all(7),
                                                                child: CyclesBankCMTransferIcpForm(key: ValueKey('CyclesBankScaffoldBody CyclesBankCMTransferIcpForm'))
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
                    ]
                ),
                SizedBox(
                    width: 1,
                    height: 15
                ),
                Container(
                    padding: EdgeInsets.fromLTRB(10,17,10,17),
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
                                    DataCell(Text('CREATE POSITION FEE: ')),
                                    DataCell(Text('0.05-TCycles/XDR')),
                                ]
                            ),
                            DataRow(
                                cells: [
                                    DataCell(Text('PURCHASE POSITION FEE: ')),
                                    DataCell(Text('0.05-TCycles/XDR')),
                                ]
                            )                            

                            
                        ]
                    )
                ),
                SizedBox(
                    height: 17,
                    width: 1    
                ),
                Wrap(
                    children: [
                        Container(
                            constraints: BoxConstraints(maxWidth: 350, minWidth: 250),
                            child: CyclesBankCMCreateCyclesPositionForm(key: ValueKey('CyclesBankScoffoldBody CyclesBankCMCreateCyclesPositionForm')),
                        ),
                        Container(
                            constraints: BoxConstraints(maxWidth: 350, minWidth: 250),
                            child: CyclesBankCMCreateIcpPositionForm(key: ValueKey('CyclesBankScoffoldBody CyclesBankCMCreateIcpPositionForm')),
                        )
                    ]
                ),
                Padding(
                    padding: EdgeInsets.all(13),
                    child: Divider(
                        height: 13.0,   
                        thickness: 4.0,
                        indent: 17.0,
                        endIndent: 17.0,
                        //color: 
                    ),
                ),    
            ]);
            
        }    
        
        List<CyclesPosition> cycles_positions = state.cycles_market_data.cycles_positions.reversed.toList();
        List<IcpPosition> icp_positions = state.cycles_market_data.icp_positions.reversed.toList();
        List<CyclesPositionPurchase> cycles_positions_purchases = state.cycles_market_data.cycles_positions_purchases.reversed.toList();
        List<IcpPositionPurchase> icp_positions_purchases = state.cycles_market_data.icp_positions_purchases.reversed.toList();
        
        
        if (state.user != null && state.user!.cycles_bank != null) {
            cycles_positions = cycles_positions.where((CyclesPosition cp)=>cp.positor.text != state.user!.cycles_bank!.principal.text).toList();
            icp_positions = icp_positions.where((IcpPosition ip)=>ip.positor.text != state.user!.cycles_bank!.principal.text).toList();
        }        
        
        column_children.addAll([
            if (state.user == null || state.user!.cycles_bank == null) Padding(
                padding: EdgeInsets.all(7),
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: blue),
                    child: Text('LOAD CYCLES-MARKET DATA', style: TextStyle(fontSize:11)),
                    onPressed: () async {
                        state.loading_text = 'loading cycles-market data ...';
                        state.is_loading = true;
                        MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                        try {
                            await Future.wait([
                                state.cycles_market_data.load_data()
                            ]);
                        } catch(e) {
                            await showDialog(
                                context: state.context,
                                builder: (BuildContext context) {
                                    return AlertDialog(
                                        title: Text('Error when loading the cycles-market positions:'),
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
            if (cycles_positions.length > 0) Container(
                width: double.infinity,
                child: Text('CYCLES-POSITIONS', style: TextStyle(fontSize: 17)),
            ),
            if (cycles_positions.length > 0) LimitedBox(
                maxHeight: 407,
                child: Container(
                    constraints: BoxConstraints(),
                    padding: EdgeInsets.all(17),
                    child: ScrollConfiguration(
                        behavior: ScrollConfiguration.of(context).copyWith(dragDevices: ScrollConfiguration.of(context).dragDevices.toSet()..add(dart_ui.PointerDeviceKind.mouse), ),
                        child: Scrollbar(
                            controller: cycles_positions_scroll_controller,
                            child: ListView.builder(
                                controller: cycles_positions_scroll_controller,
                                key: ValueKey('cm cycles-positions'),
                                scrollDirection: Axis.horizontal,
                                reverse: false,
                                shrinkWrap: false,
                                padding: EdgeInsets.all(7),
                                itemBuilder: (BuildContext context, int i) {
                                    return CyclesPositionListItem(cycles_positions[i]);
                                },
                                itemCount: cycles_positions.length,
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
            if (icp_positions.length > 0) Container(
                width: double.infinity,
                child: Text('ICP-POSITIONS', style: TextStyle(fontSize: 17)),
            ),
            if (icp_positions.length > 0) LimitedBox(
                maxHeight: 407,
                child: Container(
                    constraints: BoxConstraints(),
                    padding: EdgeInsets.all(17),
                    child: ScrollConfiguration(
                        behavior: ScrollConfiguration.of(context).copyWith(dragDevices: ScrollConfiguration.of(context).dragDevices.toSet()..add(dart_ui.PointerDeviceKind.mouse), ),
                        child: Scrollbar(
                            controller: icp_positions_scroll_controller,
                            child: ListView.builder(
                                controller: icp_positions_scroll_controller,
                                key: ValueKey('cm icp-positions'),
                                scrollDirection: Axis.horizontal,
                                reverse: false,
                                shrinkWrap: false,
                                padding: EdgeInsets.all(7),
                                itemBuilder: (BuildContext context, int i) {
                                    return IcpPositionListItem(icp_positions[i]);
                                },
                                itemCount: icp_positions.length,
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
            if (cycles_positions_purchases.length > 0) Container(
                width: double.infinity,
                child: Text('CYCLES-POSITIONS-PURCHASES', style: TextStyle(fontSize: 17)),
            ),
            if (cycles_positions_purchases.length > 0) LimitedBox(
                maxHeight: 390,
                child: Container(
                    constraints: BoxConstraints(),
                    padding: EdgeInsets.all(17),
                    child: ScrollConfiguration(
                        behavior: ScrollConfiguration.of(context).copyWith(dragDevices: ScrollConfiguration.of(context).dragDevices.toSet()..add(dart_ui.PointerDeviceKind.mouse), ),
                        child: Scrollbar(
                            controller: cycles_positions_purchases_scroll_controller,
                            child: ListView.builder(
                                controller: cycles_positions_purchases_scroll_controller,
                                key: ValueKey('cm cycles-positions-purchases'),
                                scrollDirection: Axis.horizontal,
                                reverse: false,
                                shrinkWrap: false,
                                padding: EdgeInsets.all(7),
                                itemBuilder: (BuildContext context, int i) {
                                    return CyclesPositionPurchaseListItem(cycles_positions_purchases[i]);
                                },
                                itemCount: cycles_positions_purchases.length,
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
            if (icp_positions_purchases.length > 0) Container(
                width: double.infinity,
                child: Text('ICP-POSITIONS-PURCHASES', style: TextStyle(fontSize: 17)),
            ),
            if (icp_positions_purchases.length > 0) LimitedBox(
                maxHeight: 390,
                child: Container(
                    constraints: BoxConstraints(),
                    padding: EdgeInsets.all(17),
                    child: ScrollConfiguration(
                        behavior: ScrollConfiguration.of(context).copyWith(dragDevices: ScrollConfiguration.of(context).dragDevices.toSet()..add(dart_ui.PointerDeviceKind.mouse), ),
                        child: Scrollbar(
                            controller: icp_positions_purchases_scroll_controller,
                            child: ListView.builder(
                                controller: icp_positions_purchases_scroll_controller,
                                key: ValueKey('cm icp-positions-purchases'),
                                scrollDirection: Axis.horizontal,
                                reverse: false,
                                shrinkWrap: false,
                                padding: EdgeInsets.all(7),
                                itemBuilder: (BuildContext context, int i) {
                                    return IcpPositionPurchaseListItem(icp_positions_purchases[i]);
                                },
                                itemCount: icp_positions_purchases.length,
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
        ]);
        
            
        if (state.user != null && state.user!.cycles_bank != null) {    
            
            
            final bool Function(CyclesMarketDataPosition) is_position_by_the_user = (CyclesMarketDataPosition cmdp) {
                return aresamebytes(cmdp.positor.bytes, state.user!.cycles_bank!.principal.bytes);
            };
            
            Map<BigInt, CyclesPosition> current_user_cycles_positions = Map.fromIterable(
                state.cycles_market_data.cycles_positions.where(is_position_by_the_user).toList(),
                key: (cp) => cp.id,
                value: (cp) => cp
            );
        
            Map<BigInt, IcpPosition> current_user_icp_positions = Map.fromIterable(
                state.cycles_market_data.icp_positions.where(is_position_by_the_user).toList(),
                key: (ip) => ip.id,
                value: (ip) => ip
            );
                
            List<CMCyclesPosition> cycles_bank_cm_cycles_positions_logs = state.user!.cycles_bank!.cm_cycles_positions.toList()
                ..sort((CMCyclesPosition cm_cp1, CMCyclesPosition cm_cp2)=>cm_cp1.id.compareTo(cm_cp2.id))
                ..reversed;

            List<CMIcpPosition> cycles_bank_cm_icp_positions_logs = state.user!.cycles_bank!.cm_icp_positions.toList()
                ..sort((CMIcpPosition cm_ip1, CMIcpPosition cm_ip2)=>cm_ip1.id.compareTo(cm_ip2.id))
                ..reversed;
                
            Map<BigInt, List<CMMessageCyclesPositionPurchasePositorLog>> user_cycles_positions_ids_map_cm_message_cycles_position_purchase_positor_logs = {};
            
            Map<BigInt, List<CMMessageIcpPositionPurchasePositorLog>> user_icp_positions_ids_map_cm_message_icp_position_purchase_positor_logs = {};
            
            for (CMCyclesPosition cm_cycles_position in cycles_bank_cm_cycles_positions_logs) {
                user_cycles_positions_ids_map_cm_message_cycles_position_purchase_positor_logs[cm_cycles_position.id] = 
                    state.user!.cycles_bank!.cm_message_cycles_position_purchase_positor_logs
                        .where((CMMessageCyclesPositionPurchasePositorLog l) => cm_cycles_position.id == l.cm_message_cycles_position_purchase_positor_quest.cycles_position_id)
                        .toList()
                        ..sort((CMMessageCyclesPositionPurchasePositorLog l1, CMMessageCyclesPositionPurchasePositorLog l2) => l1.cm_message_cycles_position_purchase_positor_quest.purchase_id.compareTo(l2.cm_message_cycles_position_purchase_positor_quest.purchase_id));
            }

            for (CMIcpPosition cm_icp_position in cycles_bank_cm_icp_positions_logs) {
                user_icp_positions_ids_map_cm_message_icp_position_purchase_positor_logs[cm_icp_position.id] = 
                    state.user!.cycles_bank!.cm_message_icp_position_purchase_positor_logs
                        .where((CMMessageIcpPositionPurchasePositorLog l) => cm_icp_position.id == l.cm_message_icp_position_purchase_positor_quest.icp_position_id)
                        .toList()
                        ..sort((CMMessageIcpPositionPurchasePositorLog l1, CMMessageIcpPositionPurchasePositorLog l2) => l1.cm_message_icp_position_purchase_positor_quest.purchase_id.compareTo(l2.cm_message_icp_position_purchase_positor_quest.purchase_id));
            }
            
            
            if (cycles_bank_cm_cycles_positions_logs.length > 0) {
                column_children.addAll([
                    Container(
                        width: double.infinity,
                        child: Text('USER-CYCLES-POSITIONS', style: TextStyle(fontSize: 17)),
                    ),
                    LimitedBox(
                        maxHeight: 390,
                        child: Container(
                            constraints: BoxConstraints(),
                            padding: EdgeInsets.all(17),
                            child: ScrollConfiguration(
                                behavior: ScrollConfiguration.of(context).copyWith(dragDevices: ScrollConfiguration.of(context).dragDevices.toSet()..add(dart_ui.PointerDeviceKind.mouse), ),
                                child: Scrollbar(
                                    controller: user_cycles_positions_scroll_controller,
                                    child: ListView.builder(
                                        controller: user_cycles_positions_scroll_controller,
                                        key: ValueKey('cm user-cycles-positions'),
                                        scrollDirection: Axis.horizontal,
                                        reverse: false,
                                        shrinkWrap: false,
                                        padding: EdgeInsets.all(7),
                                        itemBuilder: (BuildContext context, int i) {
                                            CMCyclesPosition cm_cycles_position = cycles_bank_cm_cycles_positions_logs[i];
                                            List<CMMessageCyclesPositionPurchasePositorLog> purchases = user_cycles_positions_ids_map_cm_message_cycles_position_purchase_positor_logs[cm_cycles_position.id]!;  
                                            Cycles? current_position;
                                            if (current_user_cycles_positions[cm_cycles_position.id] is CyclesPosition) {
                                                current_position = (current_user_cycles_positions[cm_cycles_position.id] as CyclesPosition).cycles;
                                            }
                                            CMMessageVoidCyclesPositionPositorLog? cm_message_void_cycles_position_positor_log;
                                            Iterable<CMMessageVoidCyclesPositionPositorLog> cm_message_void_cycles_position_positor_logs_with_the_cm_cycles_position_id = 
                                                state.user!.cycles_bank!.cm_message_void_cycles_position_positor_logs
                                                    .where((CMMessageVoidCyclesPositionPositorLog l) => cm_cycles_position.id == l.cm_message_void_cycles_position_positor_quest.position_id);
                                            if (cm_message_void_cycles_position_positor_logs_with_the_cm_cycles_position_id.length > 0) {
                                                cm_message_void_cycles_position_positor_log = cm_message_void_cycles_position_positor_logs_with_the_cm_cycles_position_id.first;
                                            }
                                            return UserCyclesPositionListItem(
                                                cm_cycles_position: cm_cycles_position,
                                                purchases: purchases,
                                                current_position: current_position,             
                                                cm_message_void_cycles_position_positor_log: cm_message_void_cycles_position_positor_log,
                                            );
                                        },
                                        itemCount: cycles_bank_cm_cycles_positions_logs.length,
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
            }
            
            if (cycles_bank_cm_icp_positions_logs.length > 0) {
                column_children.addAll([
                    Container(
                        width: double.infinity,
                        child: Text('USER-ICP-POSITIONS', style: TextStyle(fontSize: 17)),
                    ),
                    LimitedBox(
                        maxHeight: 390,
                        child: Container(
                            constraints: BoxConstraints(),
                            padding: EdgeInsets.all(17),
                            child: ScrollConfiguration(
                                behavior: ScrollConfiguration.of(context).copyWith(dragDevices: ScrollConfiguration.of(context).dragDevices.toSet()..add(dart_ui.PointerDeviceKind.mouse), ),
                                child: Scrollbar(
                                    controller: user_icp_positions_scroll_controller,
                                    child: ListView.builder(
                                        controller: user_icp_positions_scroll_controller,
                                        key: ValueKey('cm user-icp-positions'),
                                        scrollDirection: Axis.horizontal,
                                        reverse: false,
                                        shrinkWrap: false,
                                        padding: EdgeInsets.all(7),
                                        itemBuilder: (BuildContext context, int i) {
                                            CMIcpPosition cm_icp_position = cycles_bank_cm_icp_positions_logs[i];
                                            List<CMMessageIcpPositionPurchasePositorLog> purchases = user_icp_positions_ids_map_cm_message_icp_position_purchase_positor_logs[cm_icp_position.id]!;  
                                            IcpTokens? current_position;
                                            if (current_user_icp_positions[cm_icp_position.id] is IcpPosition) {
                                                current_position = (current_user_icp_positions[cm_icp_position.id] as IcpPosition).icp;
                                            }
                                            CMMessageVoidIcpPositionPositorLog? cm_message_void_icp_position_positor_log;
                                            Iterable<CMMessageVoidIcpPositionPositorLog> cm_message_void_icp_position_positor_logs_with_the_cm_icp_position_id = 
                                                state.user!.cycles_bank!.cm_message_void_icp_position_positor_logs
                                                    .where((CMMessageVoidIcpPositionPositorLog l) => cm_icp_position.id == l.cm_message_void_icp_position_positor_quest.position_id);
                                            if (cm_message_void_icp_position_positor_logs_with_the_cm_icp_position_id.length > 0) {
                                                cm_message_void_icp_position_positor_log = cm_message_void_icp_position_positor_logs_with_the_cm_icp_position_id.first;
                                            }
                                            return UserIcpPositionListItem(
                                                cm_icp_position: cm_icp_position,
                                                purchases: purchases,
                                                current_position: current_position,             
                                                cm_message_void_icp_position_positor_log: cm_message_void_icp_position_positor_log,
                                            );
                                        },
                                        itemCount: cycles_bank_cm_icp_positions_logs.length,
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
            }
            
            if (state.user!.cycles_bank!.cm_cycles_positions_purchases.length > 0) {
                column_children.addAll([
                    Container(
                        width: double.infinity,
                        child: Text('USER-CYCLES-POSITIONS-PURCHASES', style: TextStyle(fontSize: 17)),
                    ),
                    LimitedBox(
                        maxHeight: 390,
                        child: Container(
                            constraints: BoxConstraints(),
                            padding: EdgeInsets.all(17),
                            child: ScrollConfiguration(
                                behavior: ScrollConfiguration.of(context).copyWith(dragDevices: ScrollConfiguration.of(context).dragDevices.toSet()..add(dart_ui.PointerDeviceKind.mouse), ),
                                child: Scrollbar(
                                    controller: user_cycles_positions_purchases_scroll_controller,
                                    child: ListView.builder(
                                        controller: user_cycles_positions_purchases_scroll_controller,
                                        key: ValueKey('cm user-cycles-positions-purchases'),
                                        scrollDirection: Axis.horizontal,
                                        reverse: false,
                                        shrinkWrap: false,
                                        padding: EdgeInsets.all(7),
                                        itemBuilder: (BuildContext context, int i) {
                                            CMCyclesPositionPurchase cm_cycles_position_purchase = state.user!.cycles_bank!.cm_cycles_positions_purchases[i];
                                            CMMessageCyclesPositionPurchasePurchaserLog? cm_message_cycles_position_purchase_purchaser_log;
                                            try {
                                                cm_message_cycles_position_purchase_purchaser_log = 
                                                    state.user!.cycles_bank!.cm_message_cycles_position_purchase_purchaser_logs
                                                    .where((CMMessageCyclesPositionPurchasePurchaserLog cm_message_cycles_position_purchase_purchaser_log)=>cm_message_cycles_position_purchase_purchaser_log.cm_message_cycles_position_purchase_purchaser_quest.purchase_id == cm_cycles_position_purchase.id).first;
                                            } catch(e) {
                                                
                                            }
                                            return UserCyclesPositionPurchaseListItem(
                                                cm_cycles_position_purchase: cm_cycles_position_purchase,
                                                cm_message_cycles_position_purchase_purchaser_log: cm_message_cycles_position_purchase_purchaser_log
                                            );
                                        },
                                        itemCount: state.user!.cycles_bank!.cm_cycles_positions_purchases.length,
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
            } 
            
            if (state.user!.cycles_bank!.cm_icp_positions_purchases.length > 0) {
                column_children.addAll([
                    Container(
                        width: double.infinity,
                        child: Text('USER-ICP-POSITIONS-PURCHASES', style: TextStyle(fontSize: 17)),
                    ),
                    LimitedBox(
                        maxHeight: 390,
                        child: Container(
                            constraints: BoxConstraints(),
                            padding: EdgeInsets.all(17),
                            child: ScrollConfiguration(
                                behavior: ScrollConfiguration.of(context).copyWith(dragDevices: ScrollConfiguration.of(context).dragDevices.toSet()..add(dart_ui.PointerDeviceKind.mouse), ),
                                child: Scrollbar(
                                    controller: user_icp_positions_purchases_scroll_controller,
                                    child: ListView.builder(
                                        controller: user_icp_positions_purchases_scroll_controller,
                                        key: ValueKey('cm user-icp-positions-purchases'),
                                        scrollDirection: Axis.horizontal,
                                        reverse: false,
                                        shrinkWrap: false,
                                        padding: EdgeInsets.all(7),
                                        itemBuilder: (BuildContext context, int i) {
                                            CMIcpPositionPurchase cm_icp_position_purchase = state.user!.cycles_bank!.cm_icp_positions_purchases[i];
                                            CMMessageIcpPositionPurchasePurchaserLog? cm_message_icp_position_purchase_purchaser_log;
                                            try {
                                                cm_message_icp_position_purchase_purchaser_log = 
                                                    state.user!.cycles_bank!.cm_message_icp_position_purchase_purchaser_logs
                                                    .where((CMMessageIcpPositionPurchasePurchaserLog cm_message_icp_position_purchase_purchaser_log)=>cm_message_icp_position_purchase_purchaser_log.cm_message_icp_position_purchase_purchaser_quest.purchase_id == cm_icp_position_purchase.id).first;
                                            } catch(e) {
                                                
                                            }
                                            return UserIcpPositionPurchaseListItem(
                                                cm_icp_position_purchase: cm_icp_position_purchase,
                                                cm_message_icp_position_purchase_purchaser_log: cm_message_icp_position_purchase_purchaser_log
                                            );
                                        },
                                        itemCount: state.user!.cycles_bank!.cm_icp_positions_purchases.length,
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
            }    
        }
        
        
        return Center(
            child: Container(
                constraints: BoxConstraints(maxWidth: 900),//731),
                child: Column(
                    children: [
                        ScaffoldBodyHeader('CYCLES-MARKET'),
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


