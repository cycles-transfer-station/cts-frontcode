import 'dart:typed_data';
import 'dart:html';
import 'dart:js' as js;
import 'dart:js_util';
import 'dart:convert';
import 'dart:ui' as dart_ui;

import 'package:flutter/material.dart';

import 'package:ic_tools/ic_tools.dart';
import 'package:ic_tools/candid.dart' show c_backwards, PrincipalReference, Nat64, Nat, Blob;
import 'package:ic_tools/candid.dart' as candid;
import 'package:ic_tools/tools.dart';
import 'package:ic_tools/common.dart' show IcpTokens;
import 'package:ic_tools/common.dart' as common;
import 'package:ic_tools/common_web.dart';

import 'package:archive/archive.dart'; // crc32
import 'package:tuple/tuple.dart';

import 'main.dart';
import 'ii_jslib.dart';
import 'urls.dart';
import 'state.dart';
import 'state_bind.dart';
import 'widgets.dart';
import 'user.dart';
import 'icp_ledger.dart';
import 'cycles_bank.dart';
import 'cycles_market.dart';
import 'indexdb.dart';




// most state can be held in the MainState and can re-build with MainStateBind.set_state.tifyListeners so the page widgets can be StatelessWidget s


const List<String> lower_case_hex_chars = ['a','b','c','d','e','f'];
const List<String> number_chars = ['0','1','2','3','4','5','6','7','8','9'];





class LoadingPage extends Page {
    
    LoadingPage({LocalKey? key}) : super(key: key);
    
    Route createRoute(BuildContext context) {
        return PageRouteBuilder(
            settings: this,
            // do a cool fade in and fade out 
            pageBuilder: (context, animation, animation2) {
                final tween = Tween(begin: 0.0, end: 1.0);
                final curve_tween = CurveTween(curve: Curves.easeOutSine);
                
                return FadeTransition(
                    opacity: animation.drive(tween).drive(curve_tween),
                    child: Loading()
                );
            }
        );
    }
}





// urls pages


class VoidPage {
    static create({LocalKey? key}) => MaterialPage(key: key, child: VoidPageWidget());
}
class VoidPageWidget extends StatelessWidget {
    Widget build(BuildContext context) {
        return Loading('page not found');
    }
}



class WelcomePage extends Page {
    WelcomePage({LocalKey? key}) : super(key: key);
    static WelcomePage create({LocalKey? key}) => WelcomePage(key: key);

    Route createRoute(BuildContext context) {
        return PageRouteBuilder(
            settings: this,
            pageBuilder: (context, animation, animation2) {
                final tween = Tween(begin: 0.0, end: 1.0);
                final curve_tween = CurveTween(curve: Curves.easeOutSine);
                return FadeTransition(
                    opacity: animation.drive(tween).drive(curve_tween),
                    child: WelcomePageWidget(key: ValueKey('WelcomePageWidget'))
                );
            }
        );
    }
}
class WelcomePageWidget extends StatefulWidget {
    const WelcomePageWidget({super.key});
    State createState() => WelcomePageWidgetState();
}
class WelcomePageWidgetState extends State<WelcomePageWidget> {

    GlobalKey<ScaffoldState> scaffold_key = GlobalKey<ScaffoldState>();
    
    
    @override
    Widget build(BuildContext context) {
    
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
        
        
        return /*SelectionArea(
            child: */Scaffold(
                    key: scaffold_key,
                    appBar: AppBar(
                        title: Center(child: const Text(':CYCLES-TRANSFER-STATION.')),
                        automaticallyImplyLeading: false,
                    ),
                    drawer: Drawer(
                        child: Column(
                            children: [
                                DrawerHeader(
                                    child: state.user==null ? Center(child: OutlineButton(button_text: 'ii login', on_press_complete: () async { await ii_login(context); })) : SelectableText('USER ID: ${state.user!.principal.text}')
                                ),
                                Expanded(
                                    child: ListView(
                                        padding: EdgeInsets.zero,
                                        children: [
                                            ListTile(
                                                title: const Text('HOME'),
                                                onTap: () {
                                                    state.current_url = CustomUrl('welcome');
                                                    MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                                                    Navigator.pop(context);
                                                    
                                                },
                                            ),
                                            ListTile(
                                                title: const Text('TRANSFER-ICP'),
                                                onTap: () {
                                                    state.current_url = CustomUrl('transfer_icp');
                                                    MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                                                    Navigator.pop(context);
                                                },
                                            ),
                                            ListTile(
                                                title: const Text('CYCLES-BANK'),
                                                onTap: () {
                                                    state.current_url = CustomUrl('cycles_bank');
                                                    MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                                                    Navigator.pop(context);
                                                },
                                            ),
                                            ListTile(
                                                title: const Text('CYCLES-MARKET'),
                                                onTap: () {
                                                    state.current_url = CustomUrl('cycles_market');
                                                    MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                                                    Navigator.pop(context);
                                                },
                                            ),
                                            AboutListTile(
                                                applicationVersion: '0.1.0',
                                            ),
                                        ]
                                    )
                                ),
                                Container(
                                    child: Align(
                                        alignment: FractionalOffset.bottomCenter,
                                        child: Column(
                                            children: <Widget>[
                                                Divider(),
                                                if (state.user != null) Container(
                                                    padding: EdgeInsets.all(17),
                                                    child: OutlineButton(
                                                        button_text: 'LOG-OUT',
                                                        on_press_complete: () {
                                                            state.user = null;
                                                            IndexDB.delete_database('cts');
                                                            MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);            
                                                            Navigator.pop(context);
                                                        }
                                                    )
                                                )
                                                else/*if (state.user == null)*/ SizedBox(height: 20) 
                                            ]
                                        )
                                    )
                                ),
                            ]
                        )
                    ),
                    body: state.current_url.main_page_scaffold_body(), 
                    bottomNavigationBar: BottomAppBar(
                        //color: Colors.blue,
                        child: IconTheme(
                            data: IconThemeData(color: Theme.of(context).colorScheme.onPrimary),
                            child: Row(
                                children: <Widget>[
                                    IconButton(
                                        tooltip: 'Navigation',
                                        icon: const Icon(Icons.menu),
                                        onPressed: () {
                                            scaffold_key.currentState!.openDrawer();
                                        },
                                    ),
                                    /*
                                    if (true) const Spacer(),
                                    IconButton(
                                        tooltip: 'Search',
                                        icon: const Icon(Icons.search),
                                        onPressed: () {},
                                    ),
                                    IconButton(
                                        tooltip: 'Favorite',
                                        icon: const Icon(Icons.favorite),
                                        onPressed: () {},
                                    ),
                                    */
                                ]
                            ) 
                        )       
                    )
                
            )
        /*)*/;
    }
}






class WelcomeScaffoldBody extends StatelessWidget {
    WelcomeScaffoldBody({super.key});
    static WelcomeScaffoldBody create({Key? key}) => WelcomeScaffoldBody(key: key);
    @override
    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
        state.context = context;
        
        
        List<Widget> column_children = [
            Padding(
                padding: EdgeInsets.fromLTRB(17.0, 34.0, 17.0, 17.0),
                child: Container(
                    child: Text('Purchase, transfer, and trade the native stable-currency on the world-computer: CYCLES.', style: TextStyle(fontSize: 19))
                )
            ),
            Padding(
                padding: EdgeInsets.fromLTRB(0, 0, 0, 37.0),
                child: Divider(
                    height: 13.0,   
                    thickness: 4.0,
                    indent: 34.0,
                    endIndent: 34.0,
                    //color: 
                ),
            )
        
        ];
        
        
        if (state.user == null) {
            if (window.location.hostname!.contains('bayhi-') || window.location.hostname!.contains('localhost') || window.location.hostname!.contains('127.0.0.1')) {
                column_children.add(
                    OutlineButton(
                        button_text: 'test user login',
                        on_press_complete: () async {
                            /*test*/
                            state.is_loading = true;
                            state.loading_text = 'loading test';
                            MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                            
                            
                            SubtleCryptoECDSAP256Caller test_caller = await SubtleCryptoECDSAP256Caller.new_keys(); 
                            
                            state.user = User(
                                state: state,
                                caller: test_caller,
                                legations: [],
                            );
                            
                            await state.save_state_in_the_browser_storage();
                            
                            try {
                                await state.loadfirststate();
                            } catch(e) {
                                await showDialog(
                                    context: state.context,
                                    builder: (BuildContext context) {
                                        return AlertDialog(
                                            title: Text('Error:'),
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
                                state.loading_text = 'Error: ${e}';
                                main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);    
                                return;
                            }
                            
                            state.is_loading = false;
                            main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);
                        }
                    )
                );
            }
            
            column_children.add(   
                Center(child: OutlineButton(
                    button_text: 'ii login',
                    on_press_complete: () async { await ii_login(context); }
                ))
            );
        }
        
        else /*if (state.user != null)*/ {
            
            column_children.addAll(
                [
                    Padding(
                        padding: EdgeInsets.fromLTRB(17.0, 17.0, 17.0, 17.0), //EdgeInsets.all(17.0),
                        child: Container(
                            child: SelectableText('USER ID: ${state.user!.principal.text}')
                        )
                    ),
                ]
            );

        }
        
        column_children.add(
            SingleChildScrollView(
                child: Text("""""")
            )
        );
        
        return Column(                
            children: column_children,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center
        );
    
    }

}

class TransferIcpScaffoldBody extends StatelessWidget {
    TransferIcpScaffoldBody({Key? key}) : super(key: key);
    static TransferIcpScaffoldBody create({Key? key}) => TransferIcpScaffoldBody(key: key);
    
    final ScrollController scroll_controller = ScrollController();
    
    @override
    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
        state.context = context;
        
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
                                        child: SelectableText('USER-ICP-ID:', style: TextStyle(fontSize: 13)),
                                    ),
                                    Center(
                                        child: SelectableText('${state.user!.user_icp_id}', style: TextStyle(fontSize: 11)),
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
            
            if (state.user!.cycles_bank != null) {
                column_children.addAll([
                    // burn icp mint cycles,  
                    SizedBox(
                        width: 1,
                        height: 40
                    ),
                    Padding(
                        padding: EdgeInsets.all(17),
                        child: BurnIcpMintCyclesForm(key: ValueKey('TransferIcpScaffoldBody BurnIcpMintCyclesForm'))
                    )
                ]);
            }
    
    
            List<IcpTransfer> icp_transfers_reversed = state.user!.icp_transfers.reversed.toList();
            
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
                                await state.user!.fresh_icp_transfers();
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
                        padding: EdgeInsets.all(17),
                        child: ScrollConfiguration(
                            behavior: ScrollConfiguration.of(context).copyWith(dragDevices: ScrollConfiguration.of(context).dragDevices.toSet()..add(dart_ui.PointerDeviceKind.mouse), ),
                            child: Scrollbar(
                                controller: scroll_controller,
                                child: ListView.builder(
                                    controller: scroll_controller,
                                    key: ValueKey('transfer-icp icp-transfers-list-items'),
                                    scrollDirection: Axis.horizontal,
                                    reverse: false,
                                    shrinkWrap: false,
                                    padding: EdgeInsets.all(11),
                                    itemBuilder: (BuildContext context, int i) {
                                        return IcpTransferListItem(icp_transfers_reversed[i]);
                                    },
                                    itemCount: icp_transfers_reversed.length,
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
            
        } else /*if (state.user == null)*/ {
            
            column_children.addAll([
                Text('Log in for the icp-wallet.'),
                Center(child: OutlineButton(
                    button_text: 'ii login',
                    on_press_complete: () async { await ii_login(context); }
                )) 
            ]);
            
        }        
        
        
        return Center(
            child: Container(
                constraints: BoxConstraints(maxWidth: 800),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                        ScaffoldBodyHeader('TRANSFER-ICP'),
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


class IcpBalanceAndLoadIcpBalance extends StatelessWidget {
    IcpBalanceAndLoadIcpBalance({super.key});
    
    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);

        
        return Padding(
            padding: EdgeInsets.fromLTRB(13.0, 18, 13,13),
            child: Column(
                children: [
                    Text('ICP-BALANCE: ${state.user!.icp_balance != null ? state.user!.icp_balance!.icp : 'unknown'}', style: TextStyle(fontSize:17)),
                    Text('timestamp: ${state.user!.icp_balance != null ? seconds_of_the_nanos(state.user!.icp_balance!.timestamp_nanos) : 'unknown'}', style: TextStyle(fontSize:9)),
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
                                    await state.user!.fresh_icp_balance();
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



final String? Function(String?) icp_id_string_validator = (String? value) {
    if (value == null || value.trim().length != 64) {
        return 'Icp ids are 64 characters long';
    }
    for (String char in value.trim().toLowerCase().split('')) {
        if (lower_case_hex_chars.contains(char) == false && number_chars.contains(char) == false) {
            return 'Icp ids are in the hex format. hex format characters are 0-9 a-f.';
        }
    }
    List<int> b = hexstringasthebytes(value.trim().toLowerCase());
    Crc32 crc32_checksum_compute = Crc32()..add(b.sublist(4));
    if (aresamebytes(crc32_checksum_compute.close(), b.sublist(0,4)) == false) {
        return 'The checksum does not match, invalid icp-id.';
    } 
    return null;                            
};
 

final String? Function(String?) icp_validator = (String? value) {
    String e_s = 'Number >= 0 with a max ${IcpTokens.DECIMAL_PLACES} decimal point places';
    if (value == null || value.trim() == '') {
        return e_s;
    }
    try {
        IcpTokens icpts = IcpTokens.oftheDouble(double.parse(value!.trim()));
    } catch(e) {
        return e_s;
    }
    return null;           
};



class UserTransferIcpForm extends StatefulWidget {
    UserTransferIcpForm({super.key});
    @override 
    State createState() => UserTransferIcpFormState(); 
}
class UserTransferIcpFormState extends State<UserTransferIcpForm> {
    GlobalKey<FormState> form_key = GlobalKey<FormState>();
    
    late IcpTokens icp;
    late String to;
    late Nat64 memo;
    

    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
        
        const double datatable_text_fontsize = 13.0;
        
        return Form(
            key: form_key,
            child: Column(
                children: <Widget>[
                    Container(
                        width: double.infinity,
                        padding: EdgeInsets.fromLTRB(11,7,11,17),
                        child: DataTable(
                            headingRowHeight: 0,
                            showBottomBorder: true,
                            //dataRowHeight: 14,
                            dividerThickness: 0.0,
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
                                        DataCell(Text('ICP TRANSFER FEE XDR: ', style: TextStyle(fontSize: datatable_text_fontsize))),
                                        DataCell(Text('${state.cts_fees.cts_transfer_icp_fee.cycles/CYCLES_PER_XDR}-xdr', style: TextStyle(fontSize: datatable_text_fontsize))),
                                    ]
                                ),
                                DataRow(
                                    cells: [
                                        DataCell(Text('CURRENT XDR-ICP RATE: ', style: TextStyle(fontSize: datatable_text_fontsize))),
                                        DataCell(Text('${state.xdr_icp_rate_with_a_timestamp!.xdr_icp_rate.xdr_permyriad_per_icp/BigInt.from(10000)}', style: TextStyle(fontSize: datatable_text_fontsize))),
                                    ]
                                ),
                                DataRow(
                                    cells: [
                                        DataCell(Text('ICP LEDGER FEES: ', style: TextStyle(fontSize: datatable_text_fontsize))),
                                        DataCell(Text('${ICP_LEDGER_TRANSFER_FEE_TIMES_TWO}-icp', style: TextStyle(fontSize: datatable_text_fontsize))),
                                    ]
                                ),
                                DataRow(
                                    cells: [
                                        DataCell(Text('ICP TRANSFER TOTAL COST: ', style: TextStyle(fontSize: datatable_text_fontsize))),
                                        DataCell(Text('${cycles_to_icptokens(state.cts_fees.cts_transfer_icp_fee, state.xdr_icp_rate_with_a_timestamp!.xdr_icp_rate) + ICP_LEDGER_TRANSFER_FEE_TIMES_TWO}-icp', style: TextStyle(fontSize: datatable_text_fontsize))),
                                    ]
                                ),
                            ]
                        )
                    ),
                    TextFormField(
                        decoration: InputDecoration(
                            labelText: 'for: ',
                        ),
                        onSaved: (String? value) { to = value!.trim().toLowerCase(); },
                        validator: icp_id_string_validator          
                    ),
                    TextFormField(
                        decoration: InputDecoration(
                            labelText: 'icp: '
                        ),
                        onSaved: (String? value) { icp = IcpTokens.oftheDouble(double.parse(value!.trim())); },
                        validator: icp_validator
                    ),
                    TextFormField(
                        decoration: InputDecoration(
                            labelText: 'memo: '
                        ),
                        onSaved: (String? value) { memo = value == null || value == '' ? Nat64(BigInt.from(0)) : Nat64(BigInt.parse(value)); },
                        validator: (String? value) {
                            String error_string = 'Invalid memo. An icp memo is a number between 0 and 2^64 - 1';
                            try {
                                Nat64 n = Nat64(value == null || value == '' ? BigInt.from(0) : BigInt.parse(value, radix: 10));
                            } catch(e) {
                                return error_string;
                            }
                            return null;
                        }                        
                    ),
                    Padding(
                        padding: EdgeInsets.fromLTRB(7, 17, 7,7),
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: blue),
                            child: Text('TRANSFER ICP'),
                            onPressed: () async {
                                if (form_key.currentState!.validate()==true) {
                                    
                                    form_key.currentState!.save();
                                    
                                    TransferIcpQuest transfer_icp_quest = TransferIcpQuest(
                                        icp:icp,
                                        icp_fee: ICP_LEDGER_TRANSFER_FEE, 
                                        to:to,
                                        memo:memo,
                                    );
                                    
                                    state.loading_text = 'transferring icp ...';
                                    state.is_loading = true;
                                    MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                                    
                                    late TransferIcpSuccess transfer_icp_success;
                                    try {
                                        transfer_icp_success = await state.user!.transfer_icp(transfer_icp_quest);
                                    } catch(e) {
                                        await showDialog(
                                            context: state.context,
                                            builder: (BuildContext context) {
                                                return AlertDialog(
                                                    title: Text('Transfer Icp Error:'),
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
                                    
                                    form_key.currentState!.reset();
                                    state.loading_text = 'Icp transfer is success. Block height: ${transfer_icp_success.block_height.value}\nloading icp balance and transfers list ...';
                                    main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);
                                    
                                    try {
                                        await Future.wait([
                                            state.user!.fresh_icp_balance(),
                                            state.user!.fresh_icp_transfers(),
                                        ]);
                                    } catch(e) {
                                        await showDialog(
                                            context: state.context,
                                            builder: (BuildContext context) {
                                                return AlertDialog(
                                                    title: Text('Error when loading the user icp balance and the transfers list:'),
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
                                
                                    await showDialog(
                                        context: state.context,
                                        builder: (BuildContext context) {
                                            return AlertDialog(
                                                title: Text('Icp Transfer Success:'),
                                                content: Text('transfer block height: ${transfer_icp_success.block_height}'),
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
                                    
                                }
                            }
                        )
                    )
                ]
            )
        );
    }
}



class BurnIcpMintCyclesForm extends StatefulWidget {
    BurnIcpMintCyclesForm({super.key});
    State createState() => BurnIcpMintCyclesFormState();
}
class BurnIcpMintCyclesFormState extends State<BurnIcpMintCyclesForm> {
    GlobalKey<FormState> form_key = GlobalKey<FormState>();
    
    late IcpTokens burn_icp;
    
    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
                
        return Form(
            key: form_key,
            child: Column(
                children: <Widget>[
                    Container(
                        width: double.infinity,
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
                                        DataCell(Text('BURN ICP MINT CYCLES FEE XDR: ')),
                                        DataCell(Text('${state.cts_fees.burn_icp_mint_cycles_fee.cycles/CYCLES_PER_XDR}-xdr')),
                                    ]
                                ),
                            ]
                        )
                    ),
                    TextFormField(
                        decoration: InputDecoration(
                            labelText: 'burn icp: ',
                        ),
                        onSaved: (String? value) { burn_icp = IcpTokens.oftheDouble(double.parse(value!.trim())); },
                        validator: icp_validator
                    ),
                    Padding(
                        padding: EdgeInsets.all(7),
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: blue),
                            child: Text('BURN ICP MINT CYCLES'),
                            onPressed: () async {
                                if (form_key.currentState!.validate()==true) {
                                    
                                    form_key.currentState!.save();
                                    
                                    state.loading_text = 'burning icp and minting cycles ...';
                                    state.is_loading = true;
                                    MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                                    
                                    late BurnIcpMintCyclesSuccess burn_icp_mint_cycles_success;
                                    try {
                                        burn_icp_mint_cycles_success = await state.user!.burn_icp_mint_cycles(burn_icp);
                                    } catch(e) {
                                        await showDialog(
                                            context: state.context,
                                            builder: (BuildContext context) {
                                                return AlertDialog(
                                                    title: Text('Burn Icp Mint Cycles Error:'),
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
                                    
                                    form_key.currentState!.reset();
                                    state.loading_text = 'Burn icp mint cycles is success. \ncycles-mint: ${burn_icp_mint_cycles_success.mint_cycles_for_the_user} \nloading icp balance, icp transfers, and cycles-bank cycles-balance ...';
                                    main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);
                                    
                                    try {
                                        await Future.wait([
                                            state.user!.fresh_icp_balance(),
                                            state.user!.fresh_icp_transfers(),
                                            state.user!.cycles_bank!.fresh_metrics(),
                                        ]);
                                    } catch(e) {
                                        await showDialog(
                                            context: state.context,
                                            builder: (BuildContext context) {
                                                return AlertDialog(
                                                    title: Text('Error when loading the icp balance, icp transfers, and cycles-bank cycles-balance:'),
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
                                                title: Text('Burn Icp Mint Cycles Success:'),
                                                content: Text('cycles-mint: ${burn_icp_mint_cycles_success.mint_cycles_for_the_user}'),
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
                            }
                        )
                    )
                ]
            )
        );
    }
}




final String cts_main_icp_id = common.icp_id(cts.principal); 

class IcpTransferListItem extends StatelessWidget {
    late final IcpTransfer icp_transfer;
    IcpTransferListItem(IcpTransfer icp_transfer_): icp_transfer = icp_transfer_, super(key: ValueKey('IcpTransferListItem: ${icp_transfer_.block_height}'));
    
    Widget build(BuildContext context) {        
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
        
        bool is_cts_transfer_icp_fee = icp_transfer.memo == '4851594152738179398' && icp_transfer.from_account_identifier == state.user!.user_icp_id && icp_transfer.to_account_identifier == cts_main_icp_id;

        bool is_out = icp_transfer.from_account_identifier == state.user!.user_icp_id;
        bool is_in = icp_transfer.to_account_identifier == state.user!.user_icp_id;
        
        late String listtile_title;
        if (is_cts_transfer_icp_fee) {
            listtile_title = 'CTS TRANSFER-ICP FEE';
        } else {
            listtile_title = 'ICP-TRANSFER' + (is_out ? ' OUT' : '') + (is_in ? ' IN' : '');
        }
        
        return Container(
            padding: EdgeInsets.all(11),            
            constraints: BoxConstraints(maxWidth: 300),
            child: Card(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                        ListTile(
                            title: Text(listtile_title),
                            subtitle: Text('BLOCK-HEIGHT: ${icp_transfer.block_height}'),
                        ),
                        Expanded(
                            child: Container(
                                padding: EdgeInsets.fromLTRB(17,7,17,7),
                                width: double.infinity, 
                                child: SingleChildScrollView(
                                    child: Column(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                            SelectableText((is_out ? 'for: ${icp_transfer.to_account_identifier} ' : '') + (is_in ? '${is_out ? '\n' : ''}by: ${icp_transfer.from_account_identifier}' : '')),
                                            SelectableText('icp: ${icp_transfer.amount}'),
                                            SelectableText('memo: ${icp_transfer.memo}'),
                                            SelectableText('icp-ledger-fee: ${icp_transfer.fee}'),
                                            SelectableText('timestamp: ${icp_transfer.timestamp_seconds}'),
                                        ]
                                    )
                                )
                            )
                        )
                    ]
                )
            )
        );
    }
}




class CyclesBankScaffoldBody extends StatelessWidget {
    CyclesBankScaffoldBody({Key? key}) : super(key: key);
    static CyclesBankScaffoldBody create({Key? key}) => CyclesBankScaffoldBody(key: key);
    
    final ScrollController cycles_transfers_out_scroll_controller = ScrollController();
    final ScrollController cycles_transfers_in_scroll_controller = ScrollController();    
    
    
    @override
    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
        state.context = context;
        
        
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
A CYCLES-BANK is a bank for the native stable-currency: CYCLES on the world-computer. \n\nThe CYCLES currency - different than other crypto-currencies - must be held by a smart-contract on the ICP-blockchain and cannot be held by a key-pair alone. A CYCLES-BANK is a smart-contract living on the Internet-Computer-Blockchain that holds CYCLES, transfers CYCLES, and takes in-coming CYCLES-transfers made by a CYCLES-BANK. 

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
                                    DataCell(Text('${ICP_LEDGER_TRANSFER_FEE_TIMES_TWO}-icp')),
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
                Container(
                    padding: EdgeInsets.fromLTRB(7,13,7,0),
                    child: Center(
                        child: Column(
                            children: [
                                Text('USER-ICP-ID: '),
                                SelectableText('${state.user!.user_icp_id}\n', style: TextStyle(fontSize: 14)),
                            ]
                        )
                    )
                ),
                IcpBalanceAndLoadIcpBalance(),
                Padding(
                    padding: EdgeInsets.all(0),//fromLTRB(17, 17, 17, 17.0),
                    child: Container(),
                    /*Divider(
                        height: 13.0,   
                        thickness: 4.0,
                        indent: 34.0,
                        endIndent: 34.0,
                        //color: 
                    ),*/
                ),
                Container(
                    width: double.infinity,
                    height: 50,
                    padding: EdgeInsets.fromLTRB(11,0,11,0),
                    child: OutlineButton(
                        button_text: 'PURCHASE CYCLES-BANK',
                        on_press_complete: () async {  
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
                                        title: Text('Cycles-bank purchase success:'),
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
            column_children.add(
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
                )
            );
            column_children.add(
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
                )
            );
            
            if (state.user!.cycles_bank!.metrics != null) {
                CyclesBankMetrics metrics = state.user!.cycles_bank!.metrics!;
                
                List<CyclesTransferOut> cycles_transfers_out_reversed = state.user!.cycles_bank!.cycles_transfers_out.reversed.toList();
                List<CyclesTransferIn> cycles_transfers_in_reversed = state.user!.cycles_bank!.cycles_transfers_in.reversed.toList();
                /*
                for (CyclesTransferOut cto in cycles_transfers_out_reversed) {
                    print([cto.id, cto.cycles_sent, cto.cycles_refunded, cto.fee_paid]);
                }
                for (CyclesTransferIn cti in cycles_transfers_in_reversed) {
                    print([cti.id, cti.cycles]);
                }
                */
                
                
                column_children.addAll([
                    Container(
                        width: double.infinity,
                        child: Column(
                            children: [
                                Container(
                                    padding: EdgeInsets.fromLTRB(7,10,7,27),
                                    child: SelectableText('CYCLES: ${metrics.cycles_balance}', style: TextStyle(fontSize: 17)),
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
                                //padding: EdgeInsets.fromLTRB(13,7,13,7),
                                child: Center(
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
                                                    DataCell(SelectableText('${seconds_of_the_nanos(metrics.user_canister_creation_timestamp_nanos)}')),
                                                ],
                                            ),
                                            DataRow(
                                                cells: <DataCell>[
                                                    DataCell(Text('lifetime-termination: ')),
                                                    DataCell(SelectableText('${metrics.lifetime_termination_timestamp_seconds}')),
                                                ],
                                            ),
                                            DataRow(
                                                cells: <DataCell>[
                                                    DataCell(Text('ctsfuel: ')),
                                                    DataCell(SelectableText('${metrics.ctsfuel_balance.cycles/Cycles.T_CYCLES_DIVIDABLE_BY}')),
                                                ]
                                            ),
                                            DataRow(
                                                cells: <DataCell>[
                                                    DataCell(Text('storage-usage: ')),
                                                    DataCell(SelectableText('${(metrics.storage_usage / BigInt.from(1024*1024)).toStringAsFixed(5)}-MiB')),
                                                ]
                                            ),
                                            DataRow(
                                                cells: <DataCell>[
                                                    DataCell(Text('storage-size: ')),
                                                    DataCell(SelectableText('${metrics.storage_size_mib}-MiB')),
                                                ]
                                            )
                                        ]    
                                    )
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
                        padding: EdgeInsets.all(7),
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
                        child: Text('CYCLES-TRANSFERS-OUT', style: TextStyle(fontSize: 17)),
                    ),
                    LimitedBox(
                        maxHeight: 337,
                        child: Container(
                            constraints: BoxConstraints(),
                            padding: EdgeInsets.all(17),
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
                        child: Text('CYCLES-TRANSFERS-IN', style: TextStyle(fontSize: 17)),
                    ),
                    LimitedBox(
                        maxHeight: 307,
                        child: Container(
                            constraints: BoxConstraints(),
                            padding: EdgeInsets.all(17),
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
        }
    
        return Center(
            child: Container(
                constraints: BoxConstraints(maxWidth: 900),//731),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                        ScaffoldBodyHeader('CYCLES-BANK'),
                        Expanded(
                            child: ListView(
                                padding: EdgeInsets.all(17),
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



enum CyclesTransferMemoType {
    Text,
    Nat,
    Blob
}

final String? Function(String?) cycles_transfer_memo_validator_text = (String? value) {
    return null;
};
final String? Function(String?) cycles_transfer_memo_validator_nat = (String? value) {
    if (value == null || value == '') {
        return 'Must be a number';
    }
    try {
        Nat nat = Nat(BigInt.parse(value, radix: 10));
    } catch(e) {
        return 'Must be a number >= 0 and without decimal places';
    }
    return null;
};
final String? Function(String?) cycles_transfer_memo_validator_blob = (String? value) {
    if (value == null || value == '') {
        return null;
    }
    for (String char in value.trim().toLowerCase().split('')) {
        if (lower_case_hex_chars.contains(char) == false && number_chars.contains(char) == false) {
            return 'Blob is in the hex format. hex format characters are 0-9 a-f.';
        }
    }
    if (value.trim().length > 64) {
        return 'max 32 bytes for the now.';
    }
    return null;        
};


final String? Function(String?) cycles_validator = (String? v) {
    if (v == null || v == '') {
        return 'Must be a number';
    }
    try {
        Cycles cycles = Cycles(cycles: BigInt.parse(v, radix: 10));
    } catch(e) {
        return 'Must be a number >= 0 and without decimal places';
    }
    return null;
};


class CyclesBankTransferCyclesForm extends StatefulWidget {
    CyclesBankTransferCyclesForm({super.key});
    State createState() => CyclesBankTransferCyclesFormState();
}
class CyclesBankTransferCyclesFormState extends State<CyclesBankTransferCyclesForm> {
    GlobalKey<FormState> form_key = GlobalKey<FormState>();
    
    late Principal for_the_canister;
    late Cycles cycles;
    late CyclesTransferMemo cycles_transfer_memo;
    
    CyclesTransferMemoType cycles_transfer_memo_type = CyclesTransferMemoType.Text;
    
    
    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
        
        
        late String? Function(String?) cycles_transfer_memo_validator;
        switch (cycles_transfer_memo_type) {
            case CyclesTransferMemoType.Text: 
                cycles_transfer_memo_validator = cycles_transfer_memo_validator_text;
            break;
            case CyclesTransferMemoType.Nat: 
                cycles_transfer_memo_validator = cycles_transfer_memo_validator_nat;
            break;
            case CyclesTransferMemoType.Blob: 
                cycles_transfer_memo_validator = cycles_transfer_memo_validator_blob;
            break;
        }
        
        return Form(
            key: form_key,
            child: Column(
                children: <Widget>[
                    TextFormField(
                        decoration: InputDecoration(
                            labelText: 'For the cycles-bank: ',
                        ),
                        onSaved: (String? v) { for_the_canister = Principal(v!); },
                        validator: (String? v) {
                            if (v == null || v.trim() == '') {
                                return 'Write the text-principal-id of the cycles-bank that will cept the cycles';
                            }
                            late Principal p;
                            try {
                                p = Principal(v.trim());
                            } catch(e) {
                                return 'invalid cycles-bank-principal-id';
                            }
                            if (p.bytes.length == 0) {
                                return 'value must be the text-principal-id of the cycles-bank';
                            }
                            if (p.bytes.length >= 29) {
                                return 'Must be a cycles-bank princpal-id';
                            }
                            return null;
                        }
                    ),
                    TextFormField(
                        decoration: InputDecoration(
                            labelText: 'Cycles: ',
                        ),
                        onSaved: (String? v) { cycles = Cycles(cycles: BigInt.parse(v!, radix: 10)); },
                        validator: cycles_validator
                    ),
                    DropdownButtonFormField<CyclesTransferMemoType>(
                        decoration: InputDecoration(
                            labelText: 'Cycles Transfer Memo: ',
                        ),
                        items: const [
                            DropdownMenuItem<CyclesTransferMemoType>(child: Text('Text'), value: CyclesTransferMemoType.Text ),
                            DropdownMenuItem<CyclesTransferMemoType>(child: Text('Nat'), value: CyclesTransferMemoType.Nat ),
                            DropdownMenuItem<CyclesTransferMemoType>(child: Text('Blob'), value: CyclesTransferMemoType.Blob ),                            
                        ],
                        value: cycles_transfer_memo_type,
                        onChanged: (CyclesTransferMemoType? select_cycles_transfer_memo_type) { 
                            if (select_cycles_transfer_memo_type is CyclesTransferMemoType) { 
                                setState(() {
                                    this.cycles_transfer_memo_type = select_cycles_transfer_memo_type; 
                                });
                            }
                        }
                    ),
                    TextFormField(
                        //decoration: InputDecoration(
                        //    labelText: 'Cycles Transfer Memo: ',
                        //),
                        onSaved: (String? v) { 
                            switch (cycles_transfer_memo_type) {
                                case CyclesTransferMemoType.Text: 
                                    cycles_transfer_memo = CyclesTransferMemo.text(candid.Text(v ?? ''));
                                break;
                                case CyclesTransferMemoType.Nat: 
                                    cycles_transfer_memo = CyclesTransferMemo.nat(Nat(BigInt.parse(v == null || v == '' ? '0' : v!, radix: 10)));
                                break;
                                case CyclesTransferMemoType.Blob: 
                                    cycles_transfer_memo = CyclesTransferMemo.blob(Blob(v == null || v.trim() == '' ? [] : hexstringasthebytes(v.trim().toLowerCase())));
                                break;
                            }
                        },
                        validator: cycles_transfer_memo_validator
                    ),
                    Padding(
                        padding: EdgeInsets.all(7),
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: blue),
                            child: Text('TRANSFER CYCLES'),
                            onPressed: () async {
                                if (form_key.currentState!.validate()==true) {
                                    form_key.currentState!.save();
                                    
                                    UserTransferCyclesQuest transfer_cycles_quest = UserTransferCyclesQuest(
                                        for_the_canister:for_the_canister,
                                        cycles:cycles, 
                                        cycles_transfer_memo:cycles_transfer_memo,
                                    );
                                    
                                    state.loading_text = 'transferring cycles ...';
                                    state.is_loading = true;
                                    MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                                    
                                    late BigInt cycles_transfer_out_id;
                                    try {
                                        cycles_transfer_out_id = await state.user!.cycles_bank!.transfer_cycles(transfer_cycles_quest);
                                    } catch(e) {
                                        print(e);
                                        await showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                                return AlertDialog(
                                                    title: Text('Transfer Cycles Error:'),
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
                                    
                                    form_key.currentState!.reset();                                                                        
                                    
                                    state.loading_text = 'cycles transfer success. cycles_transfer_id: ${cycles_transfer_out_id}\nloading cycles balance and transfers list ...';
                                    main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);
                                
                                    await showDialog(
                                        context: state.context,
                                        builder: (BuildContext context) {
                                            return AlertDialog(
                                                title: Text('Cycles Transfer Success:'),
                                                content: Text('cycles_transfer_id: ${cycles_transfer_out_id}'),
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
                                        await Future.wait([
                                            state.user!.cycles_bank!.fresh_metrics(),
                                            state.user!.cycles_bank!.fresh_cycles_transfers_out()
                                        ]);
                                    } catch(e) {
                                        await showDialog(
                                            context: state.context,
                                            builder: (BuildContext context) {
                                                return AlertDialog(
                                                    title: Text('Error when loading the cycles balance and the transfers list:'),
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
                            }
                        )
                    )
                ]
            )
        );  
    }
}


class CTSFuelForTheCyclesBalanceForm extends StatefulWidget {
    CTSFuelForTheCyclesBalanceForm({super.key});
    State createState() => CTSFuelForTheCyclesBalanceFormState();
}
class CTSFuelForTheCyclesBalanceFormState extends State<CTSFuelForTheCyclesBalanceForm> {
    GlobalKey<FormState> form_key = GlobalKey<FormState>();
    
    late Cycles cycles_for_the_ctsfuel;
    
    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
        
        return Form(
            key: form_key,
            child: Wrap(
                children: [
                    TextFormField(
                        decoration: InputDecoration(
                            labelText: 'Cycles for the CTSFuel:',
                        ),
                        onSaved: (String? v) { cycles_for_the_ctsfuel = Cycles(cycles: BigInt.parse(v!, radix: 10)); },
                        validator: cycles_validator
                    ),    
                    Padding(
                        padding: EdgeInsets.all(7),
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: blue),
                            child: Text('TOPUP CTSFUEL'),
                            onPressed: () async {
                                if (form_key.currentState!.validate()==true) {
                                    form_key.currentState!.save();
                                    
                                    state.loading_text = 'ctsfuel topup ...';
                                    state.is_loading = true;
                                    MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                                    
                                    try {
                                        await state.user!.cycles_bank!.cycles_balance_for_the_ctsfuel(cycles_for_the_ctsfuel);
                                    } catch(e) {
                                        await showDialog(
                                            context: state.context,
                                            builder: (BuildContext context) {
                                                return AlertDialog(
                                                    title: Text('CTSFuel Topup Error:'),
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
                                
                                    form_key.currentState!.reset();                                                                        
                                
                                    await showDialog(
                                        context: state.context,
                                        builder: (BuildContext context) {
                                            return AlertDialog(
                                                title: Text('CTSFUEL TOPUP SUCCESS'),
                                                content: Text('CTSFUEL-BALANCE: ${state.user!.cycles_bank!.metrics!.ctsfuel_balance.cycles/Cycles.T_CYCLES_DIVIDABLE_BY}'),
                                                actions: <Widget>[
                                                    TextButton(
                                                        onPressed: () => Navigator.pop(context),
                                                        child: const Text('OK'),
                                                    ),
                                                ]
                                            );
                                        }
                                    );
                                    
                                    state.loading_text = 'ctsfuel topup success.\nloading ctsfuel balance ...';
                                    main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);
                                    
                                    try {
                                        await state.user!.cycles_bank!.fresh_metrics();
                                    } catch(e) {
                                        await showDialog(
                                            context: state.context,
                                            builder: (BuildContext context) {
                                                return AlertDialog(
                                                    title: Text('Error when loading the ctsfuel balance:'),
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
                            }
                        )
                    )
                ]
            )
        );
    }
}





class GrowStorageSizeForm extends StatefulWidget {
    GrowStorageSizeForm({super.key});
    State createState() => GrowStorageSizeFormState();
}
class GrowStorageSizeFormState extends State<GrowStorageSizeForm> {
    GlobalKey<FormState> form_key = GlobalKey<FormState>();
    
    late BigInt new_storage_size_mib; //ChangeStorageSizeQuest
    
    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
        
        return Form(
            key: form_key,
            child: Wrap(
                children: [
                    TextFormField(
                        decoration: InputDecoration(
                            labelText: 'Set Storage Size MiB',
                        ),
                        onSaved: (String? v) { new_storage_size_mib = BigInt.parse(v!, radix: 10); },
                        validator: (String? v) {
                            String e_s = 'Must be a whole number';
                            if (v == null || v == '') {
                                return e_s;
                            }
                            try {
                                BigInt bi = BigInt.parse(v);
                            } catch(e) {
                                return e_s;
                            }
                            return null;
                        }
                    ),
                    Padding(
                        padding: EdgeInsets.all(7),
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: blue),
                            child: Text('GROW STORAGE'),
                            onPressed: () async {
                                if (form_key.currentState!.validate()==true) {
                                    form_key.currentState!.save();
                                    
                                    state.loading_text = 'growing storage ...';
                                    state.is_loading = true;
                                    MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                                    
                                    try {
                                        await state.user!.cycles_bank!.change_storage_size( 
                                            ChangeStorageSizeQuest(
                                                new_storage_size_mib: new_storage_size_mib
                                            )
                                        );
                                    } catch(e) {
                                        await showDialog(
                                            context: state.context,
                                            builder: (BuildContext context) {
                                                return AlertDialog(
                                                    title: Text('Grow Storage Error:'),
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
                                    
                                    form_key.currentState!.reset();
                                    state.user!.cycles_bank!.metrics!.storage_size_mib = new_storage_size_mib;
                                    
                                    await showDialog(
                                        context: state.context,
                                        builder: (BuildContext context) {
                                            return AlertDialog(
                                                title: Text('Grow Storage Success.'),
                                                content: Text('New cycles-bank storage-size Mib: ${state.user!.cycles_bank!.metrics!.storage_size_mib}'),
                                                actions: <Widget>[
                                                    TextButton(
                                                        onPressed: () => Navigator.pop(context),
                                                        child: const Text('OK'),
                                                    ),
                                                ]
                                            );
                                        }
                                    );
                                    
                                    state.loading_text = 'loading cycles-balance ...';
                                    MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                                    
                                    try {
                                        await state.user!.cycles_bank!.fresh_metrics();
                                    } catch(e) {
                                        await showDialog(
                                            context: state.context,
                                            builder: (BuildContext context) {
                                                return AlertDialog(
                                                    title: Text('Error loading cycles-balance'),
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
                                    
                                    state.is_loading = false;
                                    main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);
                                    
                                }
                            }
                        )
                    )
                ]
            ),
        );
    }
}




class LengthenLifetimeForm extends StatefulWidget {
    LengthenLifetimeForm({super.key});
    State createState() => LengthenLifetimeFormState();
}
class LengthenLifetimeFormState extends State<LengthenLifetimeForm> {
    GlobalKey<FormState> form_key = GlobalKey<FormState>();
    
    late BigInt set_lifetime_termination_timestamp_seconds;
    
    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
        
        return Form(
            key: form_key,
            child: Wrap(
                children: [
                    TextFormField(
                        decoration: InputDecoration(
                            labelText: 'Set Lifetime Termination Unix Timestamp Seconds',
                        ),
                        onSaved: (String? v) { set_lifetime_termination_timestamp_seconds = BigInt.parse(v!, radix: 10); },
                        validator: (String? v) {
                            String e_s = 'Must be a whole number';
                            if (v == null || v == '') {
                                return e_s;
                            }
                            late BigInt bi;
                            try {
                                bi = BigInt.parse(v);
                            } catch(e) {
                                return e_s;
                            }
                            if (bi < state.user!.cycles_bank!.metrics!.lifetime_termination_timestamp_seconds) {
                                return 'Must lengthen the lifetime';
                            } 
                            return null;
                        }
                    ),
                    Padding(
                        padding: EdgeInsets.all(7),
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: blue),
                            child: Text('SET LIFETIME'),
                            onPressed: () async {
                                if (form_key.currentState!.validate()==true) {
                                    form_key.currentState!.save();
                                    
                                    state.loading_text = 'lengthening cycles-bank lifetime ...';
                                    state.is_loading = true;
                                    MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                                    
                                    late BigInt new_lifetime_termination_timestamp_seconds;
                                    try {
                                        new_lifetime_termination_timestamp_seconds = await state.user!.cycles_bank!.lengthen_lifetime( 
                                            LengthenLifetimeQuest(
                                                set_lifetime_termination_timestamp_seconds: set_lifetime_termination_timestamp_seconds
                                            )
                                        );
                                    } catch(e) {
                                        await showDialog(
                                            context: state.context,
                                            builder: (BuildContext context) {
                                                return AlertDialog(
                                                    title: Text('Grow Storage Error:'),
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
                                    
                                    form_key.currentState!.reset();
                                    
                                    state.user!.cycles_bank!.metrics!.lifetime_termination_timestamp_seconds = new_lifetime_termination_timestamp_seconds;
                                    
                                    await showDialog(
                                        context: state.context,
                                        builder: (BuildContext context) {
                                            return AlertDialog(
                                                title: Text('Lengthen Lifetime Success.'),
                                                content: Text('New cycles-bank lifetime-termination-timestamp: ${state.user!.cycles_bank!.metrics!.lifetime_termination_timestamp_seconds}'),
                                                actions: <Widget>[
                                                    TextButton(
                                                        onPressed: () => Navigator.pop(context),
                                                        child: const Text('OK'),
                                                    ),
                                                ]
                                            );
                                        }
                                    );
                                    
                                    state.loading_text = 'loading cycles-balance ...';
                                    MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                                    
                                    try {
                                        await state.user!.cycles_bank!.fresh_metrics();
                                    } catch(e) {
                                        await showDialog(
                                            context: state.context,
                                            builder: (BuildContext context) {
                                                return AlertDialog(
                                                    title: Text('Error loading cycles-balance'),
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
                                    
                                    state.is_loading = false;
                                    main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);
                                    
                                }
                            }
                        )
                    )
                ]
            ),
        );
    }
}









class CyclesTransferInListItem extends StatelessWidget {
    final CyclesTransferIn cycles_transfer_in;
    CyclesTransferInListItem(CyclesTransferIn cycles_transfer_in): cycles_transfer_in = cycles_transfer_in, super(key: ValueKey('CyclesTransferInListItem: ${cycles_transfer_in.id}'));
    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
                
        /*bool is_mint = 
            cycles_transfer_in.cycles_transfer_memo.containsKey('Blob') 
            && bytesasahexstring((cycles_transfer_in.cycles_transfer_memo['Blob'] as Blob).bytes) == '4354532d4255524e2d4943502d4d494e542d4359434c4553' 
            && cycles_transfer_in.by_the_canister.text == cts.principal.text;
        */
        
        return Container(
            padding: EdgeInsets.all(11),
            constraints: BoxConstraints(maxWidth: 350),
            child: Card(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                        ListTile(
                            title: Text('CYCLES TRANSFER IN'),
                            subtitle: Text('ID: ${cycles_transfer_in.id}'),
                        ),
                        Expanded(
                            child: Container(
                                padding: EdgeInsets.fromLTRB(17,7,17,7),
                                width: double.infinity, 
                                child: SingleChildScrollView(
                                    child: Column(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                            SelectableText('cycles: ${cycles_transfer_in.cycles}'),
                                            SelectableText('cycles-transfer-memo: ${cycles_transfer_in.cycles_transfer_memo}'),
                                            SelectableText('by: ${cycles_transfer_in.by_the_canister.text}'),
                                            SelectableText('timestamp: ${seconds_of_the_nanos(cycles_transfer_in.timestamp_nanos)}'),
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

class CyclesTransferOutListItem extends StatelessWidget {
    final CyclesTransferOut cycles_transfer_out;
    CyclesTransferOutListItem(CyclesTransferOut cycles_transfer_out): cycles_transfer_out = cycles_transfer_out, super(key: ValueKey('CyclesTransferOutListItem: ${cycles_transfer_out.id}'));
    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
                
        return Container(
            constraints: BoxConstraints(maxWidth: 350),
            padding: EdgeInsets.all(11),
            child: Card(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                        ListTile(
                            title: Text('CYCLES TRANSFER OUT'),
                            subtitle: Text('ID: ${cycles_transfer_out.id}'),
                        ),
                        Expanded(
                            child: Container(
                                padding: EdgeInsets.fromLTRB(17,7,17,7),
                                width: double.infinity, 
                                child: SingleChildScrollView(
                                    child: Column(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                            SelectableText('for: ${cycles_transfer_out.for_the_canister.text}'),
                                            SelectableText('cycles_sent: ${cycles_transfer_out.cycles_sent}'),
                                            SelectableText('cycles_refunded: ${cycles_transfer_out.cycles_refunded != null ? cycles_transfer_out.cycles_refunded! : 'waiting for the callback'}'),
                                            SelectableText('cycles-transfer-memo: ${cycles_transfer_out.cycles_transfer_memo}'),
                                            SelectableText('transfer-call-status: ${cycles_transfer_out.cycles_refunded == null ? 'waiting for the callback' : cycles_transfer_out.opt_cycles_transfer_call_error == null ? 'complete' : 'error: ${cycles_transfer_out.opt_cycles_transfer_call_error!}'}'),
                                            SelectableText('cycles_transferrer_fee: ${cycles_transfer_out.fee_paid}'),
                                            SelectableText('timestamp: ${seconds_of_the_nanos(cycles_transfer_out.timestamp_nanos)}'),
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
        state.context = context;
        
        
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
                                        state.cycles_market_data.fresh_cycles_positions(),
                                        state.cycles_market_data.fresh_icp_positions(),
                                        state.cycles_market_data.fresh_cycles_positions_purchases(),
                                        state.cycles_market_data.fresh_icp_positions_purchases(),
                                        state.user!.cycles_bank!.fresh_metrics(),
                                        state.user!.cycles_bank!.fresh_cm_icp_balance(),
                                        state.user!.cycles_bank!.fresh_cm_cycles_positions(),
                                        state.user!.cycles_bank!.fresh_cm_icp_positions(),
                                        state.user!.cycles_bank!.fresh_cm_cycles_positions_purchases(),
                                        state.user!.cycles_bank!.fresh_cm_icp_positions_purchases(),
                                        state.user!.cycles_bank!.fresh_cm_message_cycles_position_purchase_positor_logs(),
                                        state.user!.cycles_bank!.fresh_cm_message_cycles_position_purchase_purchaser_logs(),
                                        state.user!.cycles_bank!.fresh_cm_message_icp_position_purchase_positor_logs(),
                                        state.user!.cycles_bank!.fresh_cm_message_icp_position_purchase_purchaser_logs(),
                                        state.user!.cycles_bank!.fresh_cm_message_void_cycles_position_positor_logs(),
                                        state.user!.cycles_bank!.fresh_cm_message_void_icp_position_positor_logs(),
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
                                        padding: EdgeInsets.all(7), 
                                        child: Column(
                                            children: [
                                                Text('CYCLES-BANK CYCLES BALANCE:'),
                                                Text('${state.user!.cycles_bank!.metrics != null ? state.user!.cycles_bank!.metrics!.cycles_balance : 'unknown'}', style: TextStyle(fontSize:14))
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
                                    Padding(
                                        padding:EdgeInsets.all(7),
                                        child: Text('CYCLES-BANK\'S CYCLES-MARKET ICP-ID: ${state.user!.cycles_bank!.cm_icp_id}')
                                    ),
                                    Text('ICP-BALANCE: ${state.user!.cycles_bank!.cm_icp_balance != null ? state.user!.cycles_bank!.cm_icp_balance! : 'unknown'}'),
                                    Text('timestamp: ${state.user!.cycles_bank!.cm_icp_balance_with_a_timestamp != null ? seconds_of_the_nanos(state.user!.cycles_bank!.cm_icp_balance_with_a_timestamp!.timestamp_nanos) : 'unknown'}', style: TextStyle(fontSize:9)),
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
                                    Container(
                                        padding: EdgeInsets.all(7),
                                        child: CyclesBankCMTransferIcpForm(key: ValueKey('CyclesBankScaffoldBody CyclesBankCMTransferIcpForm'))
                                    )
                                ]
                            ) 
                        )
                    ]
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
            
            
            print(state.cycles_market_data.icp_positions);
            print(state.cycles_market_data.cycles_positions);
            print(state.cycles_market_data.icp_positions_purchases);
            print(state.cycles_market_data.cycles_positions_purchases);
            print(current_user_cycles_positions);
            print(current_user_icp_positions);
            print(cycles_bank_cm_cycles_positions_logs);
            print(cycles_bank_cm_icp_positions_logs);
            print(user_cycles_positions_ids_map_cm_message_cycles_position_purchase_positor_logs);
            print(user_icp_positions_ids_map_cm_message_icp_position_purchase_positor_logs);


            if (cycles_bank_cm_cycles_positions_logs.length > 0) {
                column_children.addAll([
                    Container(
                        width: double.infinity,
                        child: Text('USER-CYCLES-POSITIONS', style: TextStyle(fontSize: 17)),
                    ),
                    LimitedBox(
                        maxHeight: 507,
                        child: Container(
                            constraints: BoxConstraints(),
                            padding: EdgeInsets.all(17),
                            child: ScrollConfiguration(
                                behavior: ScrollConfiguration.of(context).copyWith(dragDevices: ScrollConfiguration.of(context).dragDevices.toSet()..add(dart_ui.PointerDeviceKind.mouse), ),
                                child: Scrollbar(
                                    controller: user_cycles_positions_scroll_controller,
                                    child: ListView.builder(
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
                        maxHeight: 507,
                        child: Container(
                            constraints: BoxConstraints(),
                            padding: EdgeInsets.all(17),
                            child: ScrollConfiguration(
                                behavior: ScrollConfiguration.of(context).copyWith(dragDevices: ScrollConfiguration.of(context).dragDevices.toSet()..add(dart_ui.PointerDeviceKind.mouse), ),
                                child: Scrollbar(
                                    controller: user_icp_positions_scroll_controller,
                                    child: ListView.builder(
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
                        maxHeight: 507,
                        child: Container(
                            constraints: BoxConstraints(),
                            padding: EdgeInsets.all(17),
                            child: ScrollConfiguration(
                                behavior: ScrollConfiguration.of(context).copyWith(dragDevices: ScrollConfiguration.of(context).dragDevices.toSet()..add(dart_ui.PointerDeviceKind.mouse), ),
                                child: Scrollbar(
                                    controller: user_cycles_positions_purchases_scroll_controller,
                                    child: ListView.builder(
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
                        maxHeight: 507,
                        child: Container(
                            constraints: BoxConstraints(),
                            padding: EdgeInsets.all(17),
                            child: ScrollConfiguration(
                                behavior: ScrollConfiguration.of(context).copyWith(dragDevices: ScrollConfiguration.of(context).dragDevices.toSet()..add(dart_ui.PointerDeviceKind.mouse), ),
                                child: Scrollbar(
                                    controller: user_icp_positions_purchases_scroll_controller,
                                    child: ListView.builder(
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
                                state.cycles_market_data.fresh_cycles_positions(),
                                state.cycles_market_data.fresh_icp_positions(),
                                state.cycles_market_data.fresh_cycles_positions_purchases(),
                                state.cycles_market_data.fresh_icp_positions_purchases()
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
            Container(
                width: double.infinity,
                child: Text('CYCLES-POSITIONS', style: TextStyle(fontSize: 17)),
            ),
            LimitedBox(
                maxHeight: 407,
                child: Container(
                    constraints: BoxConstraints(),
                    padding: EdgeInsets.all(17),
                    child: ScrollConfiguration(
                        behavior: ScrollConfiguration.of(context).copyWith(dragDevices: ScrollConfiguration.of(context).dragDevices.toSet()..add(dart_ui.PointerDeviceKind.mouse), ),
                        child: Scrollbar(
                            controller: cycles_positions_scroll_controller,
                            child: ListView.builder(
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
            Container(
                width: double.infinity,
                child: Text('ICP-POSITIONS', style: TextStyle(fontSize: 17)),
            ),
            LimitedBox(
                maxHeight: 407,
                child: Container(
                    constraints: BoxConstraints(),
                    padding: EdgeInsets.all(17),
                    child: ScrollConfiguration(
                        behavior: ScrollConfiguration.of(context).copyWith(dragDevices: ScrollConfiguration.of(context).dragDevices.toSet()..add(dart_ui.PointerDeviceKind.mouse), ),
                        child: Scrollbar(
                            controller: icp_positions_scroll_controller,
                            child: ListView.builder(
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
            Container(
                width: double.infinity,
                child: Text('CYCLES-POSITIONS-PURCHASES', style: TextStyle(fontSize: 17)),
            ),
            LimitedBox(
                maxHeight: 407,
                child: Container(
                    constraints: BoxConstraints(),
                    padding: EdgeInsets.all(17),
                    child: ScrollConfiguration(
                        behavior: ScrollConfiguration.of(context).copyWith(dragDevices: ScrollConfiguration.of(context).dragDevices.toSet()..add(dart_ui.PointerDeviceKind.mouse), ),
                        child: Scrollbar(
                            controller: cycles_positions_purchases_scroll_controller,
                            child: ListView.builder(
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
            Container(
                width: double.infinity,
                child: Text('ICP-POSITIONS-PURCHASES', style: TextStyle(fontSize: 17)),
            ),
            LimitedBox(
                maxHeight: 407,
                child: Container(
                    constraints: BoxConstraints(),
                    padding: EdgeInsets.all(17),
                    child: ScrollConfiguration(
                        behavior: ScrollConfiguration.of(context).copyWith(dragDevices: ScrollConfiguration.of(context).dragDevices.toSet()..add(dart_ui.PointerDeviceKind.mouse), ),
                        child: Scrollbar(
                            controller: icp_positions_purchases_scroll_controller,
                            child: ListView.builder(
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
        
        
        
        
        /*
        return Center(
            child: Container(
                constraints: BoxConstraints(maxWidth: 731),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
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
        */
        
        
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




class CyclesBankCMTransferIcpForm extends StatefulWidget {
    CyclesBankCMTransferIcpForm({super.key});
    State<CyclesBankCMTransferIcpForm> createState() => CyclesBankCMTransferIcpFormState();
}
class CyclesBankCMTransferIcpFormState extends State<CyclesBankCMTransferIcpForm> {
    GlobalKey<FormState> form_key = GlobalKey<FormState>();
    
    late IcpTokens withdraw_icp;
    late String to;
    IcpTokens icp_fee = ICP_LEDGER_TRANSFER_FEE;
    
    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
                
        return Form(
            key: form_key,
            child: Column(
                children: <Widget>[               
                    Container(
                        width: double.infinity,
                        child: Center(
                            child: Text('WITHDRAW ICP')
                        ),
                    ),
                    Container(
                        width: double.infinity,
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
                                        DataCell(Text('CYCLES-MARKET WITHDRAW ICP FEE: ')),
                                        DataCell(Text('0.05-TCycles/XDR')),
                                    ]
                                ),
                                DataRow(
                                    cells: [
                                        DataCell(Text('ICP LEDGER TRANSFER FEE: ')),
                                        DataCell(Text('${ICP_LEDGER_TRANSFER_FEE}-icp')),
                                    ]
                                )
                            ]
                        )
                    ),
                    TextFormField(
                        decoration: InputDecoration(
                            labelText: 'for: ',
                        ),
                        onSaved: (String? value) { to = value!.trim().toLowerCase(); },
                        validator: icp_id_string_validator
                    ),
                    TextFormField(
                        decoration: InputDecoration(
                            labelText: 'icp: '
                        ),
                        onSaved: (String? value) { withdraw_icp = IcpTokens.oftheDouble(double.parse(value!.trim())); },
                        validator: icp_validator
                    ),
                    Padding(
                        padding: EdgeInsets.all(7),
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: blue),
                            child: Text('WITHDRAW ICP'),
                            onPressed: () async {
                                if (form_key.currentState!.validate()==true) {
                                    
                                    form_key.currentState!.save();
                                    
                                    CyclesMarketTransferIcpBalanceQuest cm_transfer_icp_balance_quest = CyclesMarketTransferIcpBalanceQuest(
                                        icp: withdraw_icp,
                                        icp_fee: icp_fee, 
                                        to: to,
                                    );
                                    
                                    state.loading_text = 'withdraw icp ...';
                                    state.is_loading = true;
                                    MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                                    
                                    late BigInt withdraw_icp_block_height;
                                    try {
                                        withdraw_icp_block_height = await state.user!.cycles_bank!.cm_transfer_icp_balance(cm_transfer_icp_balance_quest);
                                    } catch(e) {
                                        await showDialog(
                                            context: state.context,
                                            builder: (BuildContext context) {
                                                return AlertDialog(
                                                    title: Text('Cycles-Market Withdraw Icp Error:'),
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
                                    
                                    form_key.currentState!.reset();
                                    state.loading_text = 'Withdraw ICP success. \nblock height: ${withdraw_icp_block_height}\nloading cycles-market icp-balance and icp-transfers';
                                    main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);
                                    
                                    try {
                                        await Future.wait([
                                            state.user!.cycles_bank!.fresh_cm_icp_balance(),
                                            state.user!.cycles_bank!.fresh_cm_icp_transfers(),
                                            state.user!.cycles_bank!.fresh_cm_icp_transfers_out(),
                                        ]);
                                    } catch(e) {
                                        await showDialog(
                                            context: state.context,
                                            builder: (BuildContext context) {
                                                return AlertDialog(
                                                    title: Text('Error when loading the cycles-market icp-balance and icp-transfers:'),
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
                                                title: Text('Cycles-Market Withdraw Icp Success:'),
                                                content: Text('transfer block height: ${withdraw_icp_block_height}'),
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
                            }
                        )
                    )
                ]
            )
        );
    }
}




final String? Function(String?) xdr_icp_rate_validator = (String? v) {
    String e_s = 'Must be a number with a max ${XDRICPRate.DECIMAL_PLACES} decimal places';
    if (v == null || v.trim() == '') {
        return e_s;
    }
    try {
        XDRICPRate tr = XDRICPRate.oftheDouble(double.parse(v.trim())); 
    } catch(e) {
        return e_s;    
    }
    return null;
};





class CyclesBankCMCreateCyclesPositionForm extends StatefulWidget {
    CyclesBankCMCreateCyclesPositionForm({super.key});
    State createState() => CyclesBankCMCreateCyclesPositionFormState();
}
class CyclesBankCMCreateCyclesPositionFormState extends State<CyclesBankCMCreateCyclesPositionForm> {
    GlobalKey<FormState> form_key = GlobalKey<FormState>();
    
    late Cycles cycles_for_the_position;
    late Cycles minimum_purchase;
    late XDRICPRate xdr_icp_rate;
    
    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
                
        return Form(
            key: form_key,
            child: Column(
                children: <Widget>[               
                    Container(
                        width: double.infinity,
                        child: Center(
                            child: Text('CREATE CYCLES-POSITION')
                        ),
                    ),
                    Container(
                        width: double.infinity,
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
                                        DataCell(Text('CREATE CYCLES-POSITION FEE: ')),
                                        DataCell(Text('0.05-TCycles/XDR')),
                                    ]
                                )                            
                            ]
                        )
                    ),
                    TextFormField(
                        decoration: InputDecoration(
                            labelText: 'cycles for the position: ',
                        ),
                        onSaved: (String? value) { cycles_for_the_position = Cycles(cycles: BigInt.parse(value!, radix: 10)); },
                        validator: cycles_validator
                    ),
                    TextFormField(
                        decoration: InputDecoration(
                            labelText: 'minimum purchase: '
                        ),
                        onSaved: (String? value) { minimum_purchase = Cycles(cycles: BigInt.parse(value!, radix: 10)); },
                        validator: cycles_validator
                    ),
                    TextFormField(
                        decoration: InputDecoration(
                            labelText: 'TCycles per ICP rate: '
                        ),
                        onSaved: (String? value) { xdr_icp_rate = XDRICPRate.oftheDouble(double.parse(value!.trim())); },
                        validator: xdr_icp_rate_validator
                    ),
                    Padding(
                        padding: EdgeInsets.all(7),
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: blue),
                            child: Text('CREATE CYCLES-POSITION'),
                            onPressed: () async {
                                if (form_key.currentState!.validate()==true) {
                                    
                                    form_key.currentState!.save();
                                    
                                    CreateCyclesPositionQuest cm_create_cycles_position_quest = CreateCyclesPositionQuest(
                                        cycles: cycles_for_the_position,
                                        minimum_purchase: minimum_purchase,
                                        xdr_icp_rate: xdr_icp_rate
                                    );
                                    
                                    state.loading_text = 'create cycles-position ...';
                                    state.is_loading = true;
                                    MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                                    
                                    late CreateCyclesPositionSuccess create_cycles_position_success;
                                    try {
                                        create_cycles_position_success = await state.user!.cycles_bank!.cm_create_cycles_position(cm_create_cycles_position_quest);
                                    } catch(e) {
                                        await showDialog(
                                            context: state.context,
                                            builder: (BuildContext context) {
                                                return AlertDialog(
                                                    title: Text('cycles-market create cycles-position error:'),
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
                                    
                                    form_key.currentState!.reset();
                                    state.loading_text = 'create cycles-position success. \ncycles-position ID: ${create_cycles_position_success.position_id}\nloading cycles-market cycles-positions and cycles-bank cycles-balance ...';
                                    main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);
                                    
                                    try {
                                        await Future.wait([
                                            state.cycles_market_data.fresh_cycles_positions(),
                                            state.user!.cycles_bank!.fresh_metrics(),
                                            state.user!.cycles_bank!.fresh_cm_cycles_positions(),
                                        ]);
                                    } catch(e) {
                                        await showDialog(
                                            context: state.context,
                                            builder: (BuildContext context) {
                                                return AlertDialog(
                                                    title: Text('Error when loading the cycles-market cycles-positions and cycles-bank cycles-balance'),
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
                                                title: Text('Cycles-Market Create CYCLES-POSITION Success:'),
                                                content: Text('cycles-position ID: ${create_cycles_position_success.position_id}'),
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
                            }
                        )
                    )
                ]
            )
        );
    }
}


class CyclesBankCMCreateIcpPositionForm extends StatefulWidget {
    CyclesBankCMCreateIcpPositionForm({super.key});
    State<CyclesBankCMCreateIcpPositionForm> createState() => CyclesBankCMCreateIcpPositionFormState();
}
class CyclesBankCMCreateIcpPositionFormState extends State<CyclesBankCMCreateIcpPositionForm> {
    GlobalKey<FormState> form_key = GlobalKey<FormState>();
    
    late IcpTokens icp_for_the_position; 
    late IcpTokens minimum_purchase;
    late XDRICPRate xdr_icp_rate;
    
    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
                
        return Form(
            key: form_key,
            child: Column(
                children: <Widget>[               
                    Container(
                        width: double.infinity,
                        child: Center(
                            child: Text('CREATE ICP-POSITION')
                        ),
                    ),
                    Container(
                        width: double.infinity,
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
                                        DataCell(Text('CREATE ICP-POSITION FEE: ')),
                                        DataCell(Text('0.05-TCycles/XDR')),
                                    ]
                                )                            
                            ]
                        )
                    ),
                    TextFormField(
                        decoration: InputDecoration(
                            labelText: 'icp for the position: ',
                        ),
                        onSaved: (String? value) { icp_for_the_position = IcpTokens.oftheDouble(double.parse(value!.trim())); },
                        validator: icp_validator
                    ),
                    TextFormField(
                        decoration: InputDecoration(
                            labelText: 'minimum purchase: '
                        ),
                        onSaved: (String? value) { minimum_purchase = IcpTokens.oftheDouble(double.parse(value!.trim())); },
                        validator: icp_validator
                    ),
                    TextFormField(
                        decoration: InputDecoration(
                            labelText: 'XDR/TCycles per ICP rate: '
                        ),
                        onSaved: (String? value) { xdr_icp_rate = XDRICPRate.oftheDouble(double.parse(value!.trim())); },
                        validator: xdr_icp_rate_validator
                    ),
                    Padding(
                        padding: EdgeInsets.all(7),
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: blue),
                            child: Text('CREATE ICP-POSITION'),
                            onPressed: () async {
                                if (form_key.currentState!.validate()==true) {
                                    
                                    form_key.currentState!.save();
                                    
                                    CreateIcpPositionQuest cm_create_icp_position_quest = CreateIcpPositionQuest(
                                        icp: icp_for_the_position,
                                        minimum_purchase: minimum_purchase,
                                        xdr_icp_rate: xdr_icp_rate
                                    );
                                    
                                    state.loading_text = 'create icp-position ...';
                                    state.is_loading = true;
                                    MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                                    
                                    late CreateIcpPositionSuccess create_icp_position_success;
                                    try {
                                        create_icp_position_success = await state.user!.cycles_bank!.cm_create_icp_position(cm_create_icp_position_quest);
                                    } catch(e) {
                                        await showDialog(
                                            context: state.context,
                                            builder: (BuildContext context) {
                                                return AlertDialog(
                                                    title: Text('cycles-market create icp-position error:'),
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
                                    
                                    form_key.currentState!.reset();
                                    state.loading_text = 'create icp-position success. \icp-position ID: ${create_icp_position_success.position_id}\nloading cycles-market icp-positions, icp-balance, and cycles-balance ...';
                                    main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);
                                    
                                    try {
                                        await Future.wait([
                                            state.cycles_market_data.fresh_icp_positions(),
                                            state.user!.cycles_bank!.fresh_metrics(),
                                            state.user!.cycles_bank!.fresh_cm_icp_balance(),
                                            state.user!.cycles_bank!.fresh_cm_icp_positions(),
                                        ]);
                                    } catch(e) {
                                        await showDialog(
                                            context: state.context,
                                            builder: (BuildContext context) {
                                                return AlertDialog(
                                                    title: Text('Error when loading the cycles-market icp-positions, icp-balance, and cycles-balance.'),
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
                                                title: Text('Cycles-Market Create ICP-POSITION Success:'),
                                                content: Text('icp-position ID: ${create_icp_position_success.position_id}'),
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
                            }
                        )
                    )
                ]
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
                                                        else Text('on-the-market: false')
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
                                                            padding: EdgeInsets.all(11),
                                                            child: Card(
                                                                child: Column(
                                                                    mainAxisSize: MainAxisSize.min,
                                                                    children: <Widget>[
                                                                        ListTile(
                                                                            title: Text('PURCHASE'),
                                                                            subtitle: Text('ID: ${purchase.cm_message_cycles_position_purchase_positor_quest.purchase_id}'),
                                                                        ),
                                                                        Column(
                                                                            mainAxisAlignment: MainAxisAlignment.start,
                                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                                            children: [
                                                                                Text('purchaser: ${purchase.cm_message_cycles_position_purchase_positor_quest.purchaser}'),
                                                                                Text('cycles-purchase: ${purchase.cm_message_cycles_position_purchase_positor_quest.cycles_purchase}'),
                                                                                Text('icp-payment: ${purchase.cm_message_cycles_position_purchase_positor_quest.icp_payment}'),
                                                                                Text('timestamp: ${seconds_of_the_nanos(purchase.cm_message_cycles_position_purchase_positor_quest.purchase_timestamp_nanos)}'),
                                                                            ]
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
                        if (this.cm_message_void_cycles_position_positor_log == null && current_position != null) Padding(
                            padding: EdgeInsets.all(7),
                            child: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: blue),
                                child: Text('VOID POSITION'),
                                onPressed: () async {
                                    
                                }
                            )
                        )
                        else if (this.cm_message_void_cycles_position_positor_log != null) Container(
                            child: Column(
                                children: [
                                    Text('void-cycles: ${this.cm_message_void_cycles_position_positor_log!.void_cycles}'),
                                    Text('void-timestamp: ${this.cm_message_void_cycles_position_positor_log!.cm_message_void_cycles_position_positor_quest.timestamp_nanos}'),
                                ]
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
                                                        else Text('on-the-market: false') 
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
                                                            padding: EdgeInsets.all(11),
                                                            child: Card(
                                                                child: Column(
                                                                    mainAxisSize: MainAxisSize.min,
                                                                    children: <Widget>[
                                                                        ListTile(
                                                                            title: Text('PURCHASE'),
                                                                            subtitle: Text('ID: ${purchase.cm_message_icp_position_purchase_positor_quest.purchase_id}'),
                                                                        ),
                                                                        Column(
                                                                            mainAxisAlignment: MainAxisAlignment.start,
                                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                                            children: [
                                                                                Text('purchaser: ${purchase.cm_message_icp_position_purchase_positor_quest.purchaser}'),
                                                                                Text('icp-purchase: ${purchase.cm_message_icp_position_purchase_positor_quest.icp_purchase}'),
                                                                                Text('cycles-payment: ${purchase.cycles_payment}'),
                                                                                Text('timestamp: ${seconds_of_the_nanos(purchase.cm_message_icp_position_purchase_positor_quest.purchase_timestamp_nanos)}'),
                                                                            ]
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
                        if (this.cm_message_void_icp_position_positor_log == null && current_position != null) Padding(
                            padding: EdgeInsets.all(7),
                            child: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: blue),
                                child: Text('VOID POSITION'),
                                onPressed: () async {
                                    
                                }
                            )
                        )
                        else if (this.cm_message_void_icp_position_positor_log != null) Container(
                            child: Column(
                                children: [
                                    Text('void-icp: ${this.cm_message_void_icp_position_positor_log!.cm_message_void_icp_position_positor_quest.void_icp}'),
                                    Text('void-timestamp: ${this.cm_message_void_icp_position_positor_log!.cm_message_void_icp_position_positor_quest.timestamp_nanos}'),
                                ]
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
            child: Card(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                        ListTile(
                            title: Text('USER CYCLES POSITION PURCHASE'),
                            subtitle: Text('PURCHASE ID: ${cm_cycles_position_purchase.id}'),
                        ),
                        Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Text('cycles-purchase: ${cm_cycles_position_purchase.cycles}'),
                                Text('icp-payment: ${cycles_to_icptokens(cm_cycles_position_purchase.cycles, cm_cycles_position_purchase.cycles_position_xdr_permyriad_per_icp_rate)}'),
                                Text('xdr-icp-rate: ${cm_cycles_position_purchase.cycles_position_xdr_permyriad_per_icp_rate}'),
                                Text('cycles-position-positor: ${cm_cycles_position_purchase.cycles_position_positor}'),
                                Text('cycles-position-id: ${cm_cycles_position_purchase.cycles_position_id}'),
                                Text('purchase-position-fee: ${cm_cycles_position_purchase.purchase_position_fee}'),
                                Text('timestamp: ${seconds_of_the_nanos(cm_cycles_position_purchase.timestamp_nanos)}'),
                                Text('payout-status: ${cm_message_cycles_position_purchase_purchaser_log == null ? 'pending' : 'complete'}'),
                            ]
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
            child: Card(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                        ListTile(
                            title: Text('USER ICP POSITION PURCHASE'),
                            subtitle: Text('PURCHASE ID: ${cm_icp_position_purchase.id}'),
                        ),
                        Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Text('icp-purchase: ${cm_icp_position_purchase.icp}'),
                                Text('cycles-payment: ${icptokens_to_cycles(cm_icp_position_purchase.icp, cm_icp_position_purchase.icp_position_xdr_permyriad_per_icp_rate)}'),
                                Text('xdr-icp-rate: ${cm_icp_position_purchase.icp_position_xdr_permyriad_per_icp_rate}'),
                                Text('icp-position-positor: ${cm_icp_position_purchase.icp_position_positor}'),
                                Text('icp-position-id: ${cm_icp_position_purchase.icp_position_id}'),
                                Text('purchase-position-fee: ${cm_icp_position_purchase.purchase_position_fee}'),
                                Text('timestamp: ${seconds_of_the_nanos(cm_icp_position_purchase.timestamp_nanos)}'),
                                Text('payout-status: ${cm_message_icp_position_purchase_purchaser_log == null ? 'pending' : 'complete'}')
                            ]
                        ),
                        
                    ]
                )
            )
        );
    }
}




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
                        Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Text('positor: ${cycles_position.positor.text}'),
                                Text('cycles: ${cycles_position.cycles}'),
                                Text('minimum-purchase: ${cycles_position.minimum_purchase}'),
                                Text('xdr-icp-rate: ${cycles_position.xdr_permyriad_per_icp_rate}'),
                                Text('timestamp: ${seconds_of_the_nanos(cycles_position.timestamp_nanos)}'),
                            ]
                        ),
                        Padding(
                            padding: EdgeInsets.all(7),
                            child: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: blue),
                                child: Text('PURCHASE'),
                                onPressed: () async {
                                    
                                }
                            )
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
                        Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Text('positor: ${icp_position.positor.text}'),
                                Text('icp: ${icp_position.icp}'),
                                Text('minimum-purchase: ${icp_position.minimum_purchase}'),
                                Text('xdr-icp-rate: ${icp_position.xdr_permyriad_per_icp_rate}'),
                                Text('timestamp: ${seconds_of_the_nanos(icp_position.timestamp_nanos)}'),
                            ]
                        ),
                        Padding(
                            padding: EdgeInsets.all(7),
                            child: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: blue),
                                child: Text('PURCHASE'),
                                onPressed: () async {
                                    //await showDialog();
                                }
                            )
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
                        Column(
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
                        Column(
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
                    ]
                )
            )
        );
    }
}






// ---------------------------------------------

class BuyWalletPage extends Page {
    BuyWalletPage({LocalKey? key}) : super(key: key);
    static BuyWalletPage create({LocalKey? key}) => BuyWalletPage(key: key);

    Route createRoute(BuildContext context) {
        return PageRouteBuilder(
            settings: this,
            pageBuilder: (context, animation, animation2) {
                final tween = Tween(begin: Offset(0.0, 1.0), end: Offset.zero);
                final curveTween = CurveTween(curve: Curves.easeInOut);
                return SlideTransition(
                    position: animation.drive(curveTween).drive(tween),
                    child: BuyWalletPageWidget()
                );
            }
        );
    }
}
class BuyWalletPageWidget extends StatefulWidget {
    BuyWalletPageWidget({Key? key}) : super(key: key);
    State<StatefulWidget> createState() => _BuyWalletPageWidgetState();
}
class _BuyWalletPageWidgetState extends State<StatefulWidget> {
    
    String? caller_text;

    @override
    Widget build(BuildContext context) {
        return Column(
            children: [
                OutlinedButton(
                    child: Text('buy wallet now'),
                    onPressed: () async {
                        print('buying wallet ....');
                        
                        
                        
                    }
                ),
                OutlinedButton(
                    child: Text('back'),
                    onPressed: () {
                        Navigator.pop(context);
                    }
                )
            ]
        );
    }
}











// -----------------------------------------------------------



class ScaffoldBodyHeader extends StatelessWidget {
    final String header_text;
    ScaffoldBodyHeader(this.header_text);
    Widget build(BuildContext context) {
        return Column(
            children: [
                Padding(
                    padding: EdgeInsets.fromLTRB(17.0, 19.0, 17.0, 17.0),
                    child: Container(
                        child: Text(header_text, style: TextStyle(fontSize: 19))
                    )
                ),
                Divider(
                    height: 13.0,   
                    thickness: 4.0,
//                    indent: 34.0,
//                    endIndent: 34.0,
                    //color: 
                )
            ]
        ); 
    }
    

}


ii_login(BuildContext context) async {
    CustomState state = MainStateBind.get_state<CustomState>(context);
    MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
    state.context = context;
    
    
    SubtleCryptoECDSAP256Caller legatee_caller = await SubtleCryptoECDSAP256Caller.new_keys(); 
    
    
    late WindowBase identityWindow;
    
    window.addEventListener('message', (Event event) async {
        
        late MessageEvent message_event;
        if (event is MessageEvent) {
            message_event = event as MessageEvent;
        } else { throw Exception('message event?'); }
        
        if (message_event.origin == 'https://identity.ic0.app') {
        
            if (message_event.data['kind'] == 'authorize-ready') {
            
                identityWindow.postMessage(
                    InternetIdentityAuthorize(
                        kind: "authorize-client", 
                        sessionPublicKey: legatee_caller.public_key_DER,
                        maxTimeToLive: 1000000000*60*60*24*30
                    ),
                    "https://identity.ic0.app"
                );
            }
            
            if (message_event.data['kind'] == 'authorize-client-success') {
                identityWindow.close();
                //window.console.log(message_event.data);
                List<Legation> user_legations = List<Legation>.generate(message_event.data['delegations'].length, (int i) {
                    var sl = message_event.data['delegations'][i];
                    js.context.callMethod('start_logMessages');
                    window.console.log(sl['delegation']['expiration']);
                    String expiration_string = js.context.callMethod('get_last_logMessage_toString').replaceAll('n', ''); 
                    print(expiration_string);
                    return Legation(
                        legator_public_key_DER: i == 0 ? Uint8List.fromList(message_event.data['userPublicKey'].toList()) : Uint8List.fromList(message_event.data['delegations'][i-1]['delegation']['pubkey'].toList()), 
                        legator_signature: Uint8List.fromList(sl['signature'].toList()),
                        legatee_public_key_DER: Uint8List.fromList(sl['delegation']['pubkey'].toList()),
                        expiration_unix_timestamp_nanoseconds: BigInt.parse(expiration_string), 
                        target_canisters_ids: sl['delegation']['targets'] != null ? sl['delegation']['targets'].toList().map<Principal>((String ps)=>Principal(ps)).toList() : null 
                    );
                });

                state.loading_text = 'loading user ...';
                main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);
                
                state.user = User(
                    state: state,
                    caller: legatee_caller,
                    legations: user_legations,
                );
                
                await state.save_state_in_the_browser_storage();
                
                try {
                    await state.loadfirststate();
                } catch(e) {
                    state.loading_text = 'Error: ${e}';
                    main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);    
                    await showDialog(
                        context: state.context,
                        builder: (BuildContext context) {
                            return AlertDialog(
                                title: Text('Error:'),
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
                    return;
                }
                
                state.is_loading = false;
                main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);
            }
            
            if (message_event.data['kind'] == 'authorize-client-failure') {
                print('authorize-client-failure:\n${message_event.data['text']}');
                state.loading_text = 'Error: authorize-client-failure:\n${message_event.data['text']}';
                main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);
                await showDialog(
                    context: state.context,
                    builder: (BuildContext context) {
                        return AlertDialog(
                            title: Text('Error: ii-authorize-client-failure:'),
                            content: Text('${message_event.data['text']}'),
                            actions: <Widget>[
                                TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('OK'),
                                ),
                            ]
                        );
                    }   
                );
                return;
            }
        }
    });
    
    identityWindow = window.open('https://identity.ic0.app/#authorize', 'identityWindow');  

    state.is_loading = true;
    state.loading_text = 'ii login ...';
    MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
}














