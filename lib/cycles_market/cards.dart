import 'package:flutter/material.dart';

import 'package:ic_tools/common.dart';
import 'package:ic_tools/tools.dart';

import 'cycles_market_data.dart';
import '../cycles_bank/cycles_bank.dart';
import '../config/state.dart';
import '../config/state_bind.dart';
import './forms.dart';
import '../main.dart';
import '../widgets.dart';


class CyclesPositionListItem extends StatelessWidget {
    final CyclesPosition cycles_position;
    CyclesPositionListItem(CyclesPosition cycles_position): cycles_position = cycles_position, super(key: ValueKey('CyclesPositionListItem: ${cycles_position.id}'));
    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);

        return Container(
            padding: EdgeInsets.all(11),
            constraints: BoxConstraints(maxWidth: 320),
            child: Card( 
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                        ListTile(
                            title: Text('CYCLES POSITION'),
                            subtitle: Text('ID: ${cycles_position.id}'),
                        ),
                        Expanded(
                            child: Padding(
                                padding: EdgeInsets.fromLTRB(17,7,17,7),
                                child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                        Text('cycles: ${cycles_position.cycles}'),
                                        Text('minimum-purchase: ${cycles_position.minimum_purchase}'),
                                        Text('xdr-icp-rate: ${cycles_position.xdr_permyriad_per_icp_rate}'),
                                        Text('positor: ${cycles_position.positor.text}'),
                                        Text('timestamp: ${seconds_of_the_nanos(cycles_position.timestamp_nanos)}'),
                                    ]
                                ),
                            )
                        ),
                        Padding(
                            padding: EdgeInsets.all(11),
                            child: PurchaseCyclesPositionForm(cycles_position, key: ValueKey('PurchaseCyclesPositionForm ${cycles_position.id}')),
                        )
                    ]
                )
            )
        );
    }
}


class IcpPositionListItem extends StatelessWidget {
    final IcpPosition icp_position;
    IcpPositionListItem(IcpPosition icp_position): icp_position = icp_position, super(key: ValueKey('IcpPositionListItem: ${icp_position.id}'));
    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
        
        return Container(
            padding: EdgeInsets.all(11),
            constraints: BoxConstraints(maxWidth: 320),
            child: Card(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                        ListTile(
                            title: Text('ICP POSITION'),
                            subtitle: Text('ID: ${icp_position.id}'),
                        ),
                        Expanded(
                            child: Padding(
                                padding: EdgeInsets.fromLTRB(17,7,17,7),
                                child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                        Text('icp: ${icp_position.icp}'),
                                        Text('minimum-purchase: ${icp_position.minimum_purchase}'),
                                        Text('xdr-icp-rate: ${icp_position.xdr_permyriad_per_icp_rate}'),
                                        Text('positor: ${icp_position.positor.text}'),
                                        Text('timestamp: ${seconds_of_the_nanos(icp_position.timestamp_nanos)}'),
                                    ]
                                )
                            )
                        ),
                        Padding(
                            padding: EdgeInsets.all(11),
                            child: PurchaseIcpPositionForm(icp_position, key: ValueKey('PurchaseIcpPositionForm ${icp_position.id}')),
                        )
                    ]
                )
            )
        );
    }
}





class CyclesPositionPurchaseListItem extends StatelessWidget {
    final CyclesPositionPurchase cycles_position_purchase;
    CyclesPositionPurchaseListItem(CyclesPositionPurchase cycles_position_purchase): cycles_position_purchase = cycles_position_purchase, super(key: ValueKey('CyclesPositionPurchaseListItem: ${cycles_position_purchase.id}'));
    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);

        return Container(
            padding: EdgeInsets.all(11),
            constraints: BoxConstraints(maxWidth: 320),
            child: Card(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                        ListTile(
                            title: Text('CYCLES POSITION PURCHASE'),
                            subtitle: Text('ID: ${cycles_position_purchase.id}'),
                        ),
                        Expanded(
                            child: Padding(
                                padding: EdgeInsets.fromLTRB(17,7,17,7),
                                child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                        Text('cycles-purchase: ${cycles_position_purchase.cycles}'),
                                        Text('icp-payment: ${cycles_to_icptokens(cycles_position_purchase.cycles, cycles_position_purchase.cycles_position_xdr_permyriad_per_icp_rate)}'),
                                        Text('xdr-icp-rate: ${cycles_position_purchase.cycles_position_xdr_permyriad_per_icp_rate}'),
                                        Text('purchaser: ${cycles_position_purchase.purchaser.text}'),
                                        Text('positor: ${cycles_position_purchase.cycles_position_positor.text}'),
                                        Text('cycles-position-id: ${cycles_position_purchase.cycles_position_id}'),
                                        Text('timestamp: ${seconds_of_the_nanos(cycles_position_purchase.timestamp_nanos)}'),
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



class IcpPositionPurchaseListItem extends StatelessWidget {
    final IcpPositionPurchase icp_position_purchase;
    IcpPositionPurchaseListItem(IcpPositionPurchase icp_position_purchase): icp_position_purchase = icp_position_purchase, super(key: ValueKey('IcpPositionPurchaseListItem: ${icp_position_purchase.id}'));
    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);

        return Container(
            padding: EdgeInsets.all(11),
            constraints: BoxConstraints(maxWidth: 320),
            child: Card(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                        ListTile(
                            title: Text('ICP POSITION PURCHASE'),
                            subtitle: Text('ID: ${icp_position_purchase.id}'),
                        ),
                        Expanded(
                            child: Padding(
                                padding: EdgeInsets.fromLTRB(17,7,17,7),
                                child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                        Text('icp-purchase: ${icp_position_purchase.icp}'),
                                        Text('cycles-payment: ${icptokens_to_cycles(icp_position_purchase.icp, icp_position_purchase.icp_position_xdr_permyriad_per_icp_rate)}'),
                                        Text('xdr-icp-rate: ${icp_position_purchase.icp_position_xdr_permyriad_per_icp_rate}'),
                                        Text('purchaser: ${icp_position_purchase.purchaser.text}'),
                                        Text('positor: ${icp_position_purchase.icp_position_positor.text}'),
                                        Text('icp-position-id: ${icp_position_purchase.icp_position_id}'),
                                        Text('timestamp: ${seconds_of_the_nanos(icp_position_purchase.timestamp_nanos)}'),
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




class UserCyclesPositionListItem extends StatelessWidget {
    final CMCyclesPosition cm_cycles_position;
    final List<CMMessageCyclesPositionPurchasePositorLog> purchases;
    final Cycles? current_position; // null means the position is void/not-active
    final CMMessageVoidCyclesPositionPositorLog? cm_message_void_cycles_position_positor_log; // null means it is either on the market, or complete.
    
    UserCyclesPositionListItem({
        required CMCyclesPosition cm_cycles_position,
        required this.purchases,
        required this.current_position,
        required this.cm_message_void_cycles_position_positor_log
    }): cm_cycles_position = cm_cycles_position, super(key: ValueKey('UserCyclesPositionListItem: ${cm_cycles_position.id}'));
    
    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
        
        return Container(
            padding: EdgeInsets.all(11),
            constraints: BoxConstraints(maxWidth: 320),
            child: Card(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                        ListTile(
                            title: Text('USER CYCLES POSITION'),
                            subtitle: Text('ID: ${cm_cycles_position.id}'),
                        ),
                        Expanded(
                            child: Padding(
                                padding: EdgeInsets.fromLTRB(17,7,17,7),
                                child: SingleChildScrollView(
                                    child: Column(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        children: [
                                            Container(
                                                width: double.infinity,
                                                child: Column(
                                                    mainAxisAlignment: MainAxisAlignment.start,
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                        Text('original posit: ${cm_cycles_position.cycles}'),
                                                        Text('minimum-purchase: ${cm_cycles_position.minimum_purchase}'),
                                                        Text('xdr-icp-rate: ${cm_cycles_position.xdr_permyriad_per_icp_rate}'),
                                                        Text('create_position_fee: ${cm_cycles_position.create_position_fee}'),
                                                        Text('timestamp: ${seconds_of_the_nanos(cm_cycles_position.timestamp_nanos)}'),
                                                        if (current_position != null) ...[
                                                            Text('on-the-market: true'),
                                                            Text('current-position: ${this.current_position!}'),    
                                                        ]
                                                        else Text('on-the-market: false'),
                                                        if (this.cm_message_void_cycles_position_positor_log != null) ...[
                                                            Text('void-cycles: ${this.cm_message_void_cycles_position_positor_log!.void_cycles}'),
                                                            Text('void-timestamp: ${seconds_of_the_nanos(this.cm_message_void_cycles_position_positor_log!.cm_message_void_cycles_position_positor_quest.timestamp_nanos)}'),
                                                        ]
                                                    ]
                                                )
                                            ),
                                            SizedBox(
                                                width: 1,
                                                height: 10,
                                            ),
                                            Container(
                                                child: Column(
                                                    children: purchases.map((CMMessageCyclesPositionPurchasePositorLog purchase){
                                                        return Container(
                                                            padding: EdgeInsets.all(0),
                                                            child: Card(
                                                                child: Column(
                                                                    mainAxisSize: MainAxisSize.min,
                                                                    children: <Widget>[
                                                                        ListTile(
                                                                            title: Text('PURCHASE'),
                                                                            subtitle: Text('ID: ${purchase.cm_message_cycles_position_purchase_positor_quest.purchase_id}'),
                                                                        ),
                                                                        Container(
                                                                            constraints: BoxConstraints(
                                                                                maxWidth: double.infinity,
                                                                            ),
                                                                            child: Padding(
                                                                                padding: EdgeInsets.fromLTRB(17,7,17,7),
                                                                                child: Column(
                                                                                    mainAxisAlignment: MainAxisAlignment.start,
                                                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                                                    children: [
                                                                                        Text('cycles-purchase: ${purchase.cm_message_cycles_position_purchase_positor_quest.cycles_purchase}'),
                                                                                        Text('icp-payment: ${purchase.cm_message_cycles_position_purchase_positor_quest.icp_payment}'),
                                                                                        Text('purchaser: ${purchase.cm_message_cycles_position_purchase_positor_quest.purchaser.text}'),
                                                                                        Text('timestamp: ${seconds_of_the_nanos(purchase.cm_message_cycles_position_purchase_positor_quest.purchase_timestamp_nanos)}'),
                                                                                    ]
                                                                                )
                                                                            )
                                                                        )
                                                                    ]
                                                                )
                                                            )
                                                        );
                                                    }).toList() 
                                                )
                                            )
                                        ]
                                    )
                                )
                            )
                        ),
                        if (this.cm_message_void_cycles_position_positor_log == null && current_position != null) Container(
                            padding: EdgeInsets.all(17),
                            width: double.infinity,
                            child: OutlineButton(
                                button_text: 'VOID POSITION',
                                on_press_complete: () async {
                                    
                                    bool _continue = false;
                                    
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
                                                content: Text("Confirm to void the cycles-position id: ${this.cm_cycles_position.id}, with the cycles: ${this.current_position!}"),
                                                actions: [
                                                    cancelButton,
                                                    continueButton,
                                                ],
                                            );
                                        }
                                    );     
                                    if (_continue == false) {
                                        return;
                                    }
                                    
                                    state.loading_text = 'void-position: ${this.cm_cycles_position.id} ...';
                                    state.is_loading = true;
                                    MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                                    
                                    try {
                                        await state.user!.cycles_bank!.cm_void_position(this.cm_cycles_position.id);
                                    } catch(e) {
                                        await showDialog(
                                            context: state.context,
                                            builder: (BuildContext context) {
                                                return AlertDialog(
                                                    title: Text('Void Position:'),
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
                                                                        
                                    Future show_success_dialog = showDialog(
                                        context: state.context,
                                        builder: (BuildContext context) {
                                            return AlertDialog(
                                                title: Text('void-position success'),
                                                content: Text('cycles-position: ${this.cm_cycles_position.id} is now void.'),
                                                actions: <Widget>[
                                                    TextButton(
                                                        onPressed: () => Navigator.pop(context),
                                                        child: const Text('OK'),
                                                    ),
                                                ]
                                            );
                                        }
                                    );
                                    
                                    state.loading_text = 'loading cycles-bank-cycles-balance and cycles-position updates ...';
                                    MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                                    
                                    try {
                                        await Future(()async{
                                            await Future.delayed(Duration(seconds: 3));
                                            await state.user!.cycles_bank!.fresh_metrics();
                                            await Future.wait([
                                                state.user!.cycles_bank!.fresh_cm_cycles_positions(),
                                                state.user!.cycles_bank!.fresh_cm_message_cycles_position_purchase_positor_logs(),
                                                state.user!.cycles_bank!.fresh_cm_message_void_cycles_position_positor_logs(),
                                            ]);
                                        });
                                    } catch(e) {
                                        await showDialog(
                                            context: state.context,
                                            builder: (BuildContext context) {
                                                return AlertDialog(
                                                    title: Text('Error loading cycles-bank-cycles-balance and cycles-position updates:'),
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
                                    
                                    await show_success_dialog;
                                    
                                    state.is_loading = false;
                                    main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);
                                    
                                }
                            )
                        )
                    ]
                )
            )
        );
    }
}



class UserIcpPositionListItem extends StatelessWidget {
    final CMIcpPosition cm_icp_position;
    final List<CMMessageIcpPositionPurchasePositorLog> purchases;
    final IcpTokens? current_position; // null means the position is void/not-active
    final CMMessageVoidIcpPositionPositorLog? cm_message_void_icp_position_positor_log; // null means it is either on the market, or complete.
    
    UserIcpPositionListItem({
        required CMIcpPosition cm_icp_position,
        required this.purchases,
        required this.current_position,
        required this.cm_message_void_icp_position_positor_log
    }): cm_icp_position = cm_icp_position, super(key: ValueKey('UserIcpPositionListItem: ${cm_icp_position.id}'));
    
    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
    
        
        return Container(
            padding: EdgeInsets.all(11),
            constraints: BoxConstraints(maxWidth: 320),
            child: Card(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                        ListTile(
                            title: Text('USER ICP POSITION'),
                            subtitle: Text('ID: ${cm_icp_position.id}'),
                        ),
                        Expanded(
                            child: Padding(
                                padding: EdgeInsets.fromLTRB(17,7,17,7),
                                child: SingleChildScrollView(
                                    child: Column(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        children: [
                                            Container(
                                                width: double.infinity,
                                                child: Column(
                                                    mainAxisAlignment: MainAxisAlignment.start,
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                        Text('original posit: ${cm_icp_position.icp}'),
                                                        Text('minimum-purchase: ${cm_icp_position.minimum_purchase}'),
                                                        Text('xdr-icp-rate: ${cm_icp_position.xdr_permyriad_per_icp_rate}'),
                                                        Text('create_position_fee: ${cm_icp_position.create_position_fee}'),
                                                        Text('timestamp: ${seconds_of_the_nanos(cm_icp_position.timestamp_nanos)}'),
                                                        if (current_position != null) ...[
                                                            Text('on-the-market: true'),
                                                            Text('current-position: ${this.current_position!}'),    
                                                        ]
                                                        else Text('on-the-market: false'),
                                                        if (this.cm_message_void_icp_position_positor_log != null) ...[
                                                            Text('void-icp: ${this.cm_message_void_icp_position_positor_log!.cm_message_void_icp_position_positor_quest.void_icp}'),
                                                            Text('void-timestamp: ${seconds_of_the_nanos(this.cm_message_void_icp_position_positor_log!.cm_message_void_icp_position_positor_quest.timestamp_nanos)}'),
                                                        ]
                                                    ]
                                                )
                                            ),
                                            SizedBox(
                                                width: 1,
                                                height: 10,
                                            ),
                                            Container(
                                                child: Column(
                                                    children: purchases.map((CMMessageIcpPositionPurchasePositorLog purchase){    
                                                        return Container(
                                                            padding: EdgeInsets.all(0),
                                                            child: Card(
                                                                child: Column(
                                                                    mainAxisSize: MainAxisSize.min,
                                                                    children: <Widget>[
                                                                        ListTile(
                                                                            title: Text('PURCHASE'),
                                                                            subtitle: Text('ID: ${purchase.cm_message_icp_position_purchase_positor_quest.purchase_id}'),
                                                                        ),
                                                                        Container(
                                                                            constraints: BoxConstraints(
                                                                                maxWidth: double.infinity,
                                                                            ),
                                                                            child: Padding(
                                                                                padding: EdgeInsets.fromLTRB(17,7,17,7),
                                                                                child: Column(
                                                                                    mainAxisAlignment: MainAxisAlignment.start,
                                                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                                                    children: [
                                                                                        Text('icp-purchase: ${purchase.cm_message_icp_position_purchase_positor_quest.icp_purchase}'),
                                                                                        Text('cycles-payment: ${purchase.cycles_payment}'),
                                                                                        Text('purchaser: ${purchase.cm_message_icp_position_purchase_positor_quest.purchaser.text}'),
                                                                                        Text('timestamp: ${seconds_of_the_nanos(purchase.cm_message_icp_position_purchase_positor_quest.purchase_timestamp_nanos)}'),
                                                                                    ]
                                                                                )
                                                                            )
                                                                        )
                                                                    ]
                                                                )
                                                            )
                                                        );
                                                    }).toList()
                                                ) 
                                            ),
                                        ]
                                    )
                                )
                            )
                        ),
                        SizedBox(
                            width: 1,
                            height: 10,
                        ),
                        if (this.cm_message_void_icp_position_positor_log == null && current_position != null) Container(
                            padding: EdgeInsets.all(17),
                            width: double.infinity,
                            child: OutlineButton(
                                button_text: 'VOID POSITION',
                                on_press_complete: () async {
                                    
                                    bool _continue = false;
                                    
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
                                                content: Text("Confirm to void the icp-position id: ${this.cm_icp_position.id}, with the icp: ${this.current_position!}"),
                                                actions: [
                                                    cancelButton,
                                                    continueButton,
                                                ],
                                            );
                                        }
                                    );     
                                    if (_continue == false) {
                                        return;
                                    }
                                    
                                    state.loading_text = 'void-position: ${this.cm_icp_position.id} ...';
                                    state.is_loading = true;
                                    MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                                    
                                    try {
                                        await state.user!.cycles_bank!.cm_void_position(this.cm_icp_position.id);
                                    } catch(e) {
                                        await showDialog(
                                            context: state.context,
                                            builder: (BuildContext context) {
                                                return AlertDialog(
                                                    title: Text('Void Position:'),
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
                                                                        
                                    Future show_success_dialog = showDialog(
                                        context: state.context,
                                        builder: (BuildContext context) {
                                            return AlertDialog(
                                                title: Text('void-position success'),
                                                content: Text('icp-position: ${this.cm_icp_position.id} is now void.'),
                                                actions: <Widget>[
                                                    TextButton(
                                                        onPressed: () => Navigator.pop(context),
                                                        child: const Text('OK'),
                                                    ),
                                                ]
                                            );
                                        }
                                    );
                                    
                                    state.loading_text = 'loading cycles-market-icp-balance and icp-position updates ...';
                                    MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                                    
                                    try {
                                        await Future(()async{
                                            await Future.delayed(Duration(seconds: 3));
                                            await Future.wait([
                                                state.user!.cycles_bank!.fresh_cm_icp_balance(),
                                                state.user!.cycles_bank!.fresh_metrics(),
                                            ]);
                                            await Future.wait([
                                                state.user!.cycles_bank!.fresh_cm_icp_positions(),
                                                state.user!.cycles_bank!.fresh_cm_message_icp_position_purchase_positor_logs(),
                                                state.user!.cycles_bank!.fresh_cm_message_void_icp_position_positor_logs(),
                                            ]);
                                        });
                                    } catch(e) {
                                        await showDialog(
                                            context: state.context,
                                            builder: (BuildContext context) {
                                                return AlertDialog(
                                                    title: Text('Error loading cycles-market-icp-balance and icp-position updates:'),
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
                                    
                                    await show_success_dialog;
                                    
                                    state.is_loading = false;
                                    main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);
                                    
                                }
                            )
                        )
                    ]
                )
            )
        );
    }
}

class UserCyclesPositionPurchaseListItem extends StatelessWidget {
    final CMCyclesPositionPurchase cm_cycles_position_purchase;
    final CMMessageCyclesPositionPurchasePurchaserLog? cm_message_cycles_position_purchase_purchaser_log; 
    UserCyclesPositionPurchaseListItem({
        required CMCyclesPositionPurchase cm_cycles_position_purchase,
        required this.cm_message_cycles_position_purchase_purchaser_log
    }) : cm_cycles_position_purchase = cm_cycles_position_purchase, super(key: ValueKey('UserCyclesPositionPurchaseListItem ${cm_cycles_position_purchase.id}'));
    
    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
                
        return Container(
            padding: EdgeInsets.all(11),
            constraints: BoxConstraints(maxWidth: 320),
            child: Card(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                        ListTile(
                            title: Text('USER CYCLES POSITION PURCHASE'),
                            subtitle: Text('PURCHASE ID: ${cm_cycles_position_purchase.id}'),
                        ),
                        Expanded(
                            child: SingleChildScrollView(
                                child: Padding(
                                    padding: EdgeInsets.fromLTRB(17,7,17,7),
                                    child: Column(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                            Text('cycles-purchase: ${cm_cycles_position_purchase.cycles}'),
                                            Text('icp-payment: ${cycles_to_icptokens(cm_cycles_position_purchase.cycles, cm_cycles_position_purchase.cycles_position_xdr_permyriad_per_icp_rate)}'),
                                            Text('xdr-icp-rate: ${cm_cycles_position_purchase.cycles_position_xdr_permyriad_per_icp_rate}'),
                                            Text('cycles-position-positor: ${cm_cycles_position_purchase.cycles_position_positor.text}'),
                                            Text('cycles-position-id: ${cm_cycles_position_purchase.cycles_position_id}'),
                                            Text('purchase-position-fee: ${cm_cycles_position_purchase.purchase_position_fee}'),
                                            Text('timestamp: ${seconds_of_the_nanos(cm_cycles_position_purchase.timestamp_nanos)}'),
                                            Text('payout-status: ${cm_message_cycles_position_purchase_purchaser_log == null ? 'pending' : 'complete'}'),
                                        ]
                                    )
                                )
                            )
                        ),
                        
                    ]
                )
            )
        );
    }
    
}

class UserIcpPositionPurchaseListItem extends StatelessWidget {
    final CMIcpPositionPurchase cm_icp_position_purchase;
    final CMMessageIcpPositionPurchasePurchaserLog? cm_message_icp_position_purchase_purchaser_log; 
    UserIcpPositionPurchaseListItem({
        required CMIcpPositionPurchase cm_icp_position_purchase,
        required this.cm_message_icp_position_purchase_purchaser_log
    }) : cm_icp_position_purchase = cm_icp_position_purchase, super(key: ValueKey('UserIcpPositionPurchaseListItem ${cm_icp_position_purchase.id}'));
    
    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
                
        return Container(
            padding: EdgeInsets.all(11),
            constraints: BoxConstraints(maxWidth: 320),
            child: Card(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                        ListTile(
                            title: Text('USER ICP POSITION PURCHASE'),
                            subtitle: Text('PURCHASE ID: ${cm_icp_position_purchase.id}'),
                        ),
                        Expanded(
                            child: SingleChildScrollView(
                                child: Padding(
                                    padding: EdgeInsets.fromLTRB(17,7,17,7),
                                    child: Column(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                            Text('icp-purchase: ${cm_icp_position_purchase.icp}'),
                                            Text('cycles-payment: ${icptokens_to_cycles(cm_icp_position_purchase.icp, cm_icp_position_purchase.icp_position_xdr_permyriad_per_icp_rate)}'),
                                            Text('xdr-icp-rate: ${cm_icp_position_purchase.icp_position_xdr_permyriad_per_icp_rate}'),
                                            Text('icp-position-positor: ${cm_icp_position_purchase.icp_position_positor.text}'),
                                            Text('icp-position-id: ${cm_icp_position_purchase.icp_position_id}'),
                                            Text('purchase-position-fee: ${cm_icp_position_purchase.purchase_position_fee}'),
                                            Text('timestamp: ${seconds_of_the_nanos(cm_icp_position_purchase.timestamp_nanos)}'),
                                            Text('payout-status: ${cm_message_icp_position_purchase_purchaser_log == null ? 'pending' : 'complete'}')
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





/*

class CMCyclesPositionListItem extends StatelessWidget {
    final CMCyclesPosition cm_cycles_position;
    CMCyclesPositionListItem(CMCyclesPosition _cm_cycles_position): cm_cycles_position = _cm_cycles_position, super(key: ValueKey('CMCyclesPositionListItem: ${_cm_cycles_position.id}'));
    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
                
        return Container(
            padding: EdgeInsets.all(11),
            child: Card(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                        ListTile(
                            title: Text('MARKET CYCLES POSITION'),
                            subtitle: Text('ID: ${cm_cycles_position.id}'),
                        ),
                        Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Text('cycles: ${cm_cycles_position.cycles.cycles}'),
                                Text('minimum-purchase: ${cm_cycles_position.minimum_purchase.cycles}'),
                                Text('xdr/Tcycles per icp rate: ${cm_cycles_position.xdr_permyriad_per_icp_rate}'),
                                Text('market create position fee: ${cm_cycles_position.create_position_fee}'),
                                Text('timestamp: ${seconds_of_the_nanos(cm_cycles_position.timestamp_nanos)}'),
                            ]                            
                        ),
                    ]
                )
            )            
        );
    }
}


class CMIcpPositionListItem extends StatelessWidget {
    final CMIcpPosition cm_icp_position;
    CMIcpPositionListItem(CMIcpPosition _cm_icp_position): cm_icp_position = _cm_icp_position, super(key: ValueKey('CMIcpPositionListItem: ${_cm_icp_position.id}'));
    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
                
        return Container(
            padding: EdgeInsets.all(11),
            child: Card(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                        ListTile(
                            title: Text('MARKET ICP POSITION'),
                            subtitle: Text('ID: ${cm_icp_position.id}'),
                        ),
                        Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Text('icp: ${cm_icp_position.icp}'),
                                Text('minimum-purchase: ${cm_icp_position.minimum_purchase}'),
                                Text('xdr/Tcycles per icp rate: ${cm_icp_position.xdr_permyriad_per_icp_rate}'),
                                Text('market create position fee: ${cm_icp_position.create_position_fee}'),
                                Text('timestamp: ${seconds_of_the_nanos(cm_icp_position.timestamp_nanos)}'),
                            ]
                        ),
                    ]
                )
            )            
        );
    }
}



class CMCyclesPositionPurchaseListItem extends StatelessWidget {
    final CMCyclesPositionPurchase cm_cycles_position_purchase;
    CMCyclesPositionPurchaseListItem(CMCyclesPositionPurchase _cm_cycles_position_purchase): cm_cycles_position_purchase = _cm_cycles_position_purchase, super(key: ValueKey('CMCyclesPositionPurchaseListItem: ${_cm_cycles_position_purchase.id}'));
    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
        
        return Container(
            padding: EdgeInsets.all(11),
            child: Card(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                        ListTile(
                            title: Text('MARKET CYCLES POSITION PURCHASE'),
                            subtitle: Text('ID: ${cm_cycles_position_purchase.id}'),
                        ),
                        Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Text('cycles-position id: ${cm_cycles_position_purchase.cycles_position_id}'),
                                Text('cycles purchase: ${cm_cycles_position_purchase.cycles}'),
                                Text('xdr/Tcycles per icp purchase rate: ${cm_cycles_position_purchase.cycles_position_xdr_permyriad_per_icp_rate}'),
                                Text('icp payment: ${cycles_to_icptokens(cm_cycles_position_purchase.cycles, cm_cycles_position_purchase.cycles_position_xdr_permyriad_per_icp_rate)}'),
                                Text('market purchase position fee: ${cm_cycles_position_purchase.purchase_position_fee}'),
                                Text('timestamp: ${seconds_of_the_nanos(cm_cycles_position_purchase.timestamp_nanos)}'),
                            ]
                        ),
                    ]
                )
            )            
        );
    }
}


class CMIcpPositionPurchaseListItem extends StatelessWidget {
    final CMIcpPositionPurchase cm_icp_position_purchase;
    CMIcpPositionPurchaseListItem(CMIcpPositionPurchase _cm_icp_position_purchase): cm_icp_position_purchase = _cm_icp_position_purchase, super(key: ValueKey('CMIcpPositionPurchaseListItem: ${_cm_icp_position_purchase.id}'));
    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
        
        return Container(
            padding: EdgeInsets.all(11),
            child: Card(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                        ListTile(
                            title: Text('MARKET ICP POSITION PURCHASE'),
                            subtitle: Text('ID: ${cm_icp_position_purchase.id}'),
                        ),
                        Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Text('icp-position id: ${cm_icp_position_purchase.icp_position_id}'),
                                Text('icp purchase: ${cm_icp_position_purchase.icp}'),
                                Text('xdr/Tcycles per icp purchase rate: ${cm_icp_position_purchase.icp_position_xdr_permyriad_per_icp_rate}'),
                                Text('cycles payment: ${icptokens_to_cycles(cm_icp_position_purchase.icp, cm_icp_position_purchase.icp_position_xdr_permyriad_per_icp_rate)}'),
                                Text('market purchase position fee: ${cm_icp_position_purchase.purchase_position_fee}'),
                                Text('timestamp: ${seconds_of_the_nanos(cm_icp_position_purchase.timestamp_nanos)}'),
                            ]
                        ),
                    ]
                )
            )            
        );
    }
}



class CMIcpTransferOutListItem extends StatelessWidget {
    final CMIcpTransferOut cm_icp_transfer_out;
    CMIcpTransferOutListItem(CMIcpTransferOut cm_icp_transfer_out): cm_icp_transfer_out = cm_icp_transfer_out, super(key: ValueKey('CMIcpTransferOutListItem: ${cm_icp_transfer_out.block_height}'));
    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
        
        return Container(
            padding: EdgeInsets.all(11),
            child: Card(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                        ListTile(
                            title: Text('CYCLES-MARKET ICP BALANCE WITHDRAWAL'),
                            subtitle: Text('BLOCK: ${cm_icp_transfer_out.block_height}'),
                        ),
                        Column( // datatable?
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Text('icp withdrawal: ${cm_icp_transfer_out.icp}'),
                                Text('for: ${cm_icp_transfer_out.to}'),
                                Text('icp ledger fee: ${cm_icp_transfer_out.icp_fee}'),
                                Text('cycles-market icp-withdraw-fee: ${cm_icp_transfer_out.transfer_icp_balance_fee}'),
                                Text('timestamp: ${seconds_of_the_nanos(cm_icp_transfer_out.timestamp_nanos)}'),
                            ]
                        ),
                    ]
                )
            )            
        );
    }
}


*/

