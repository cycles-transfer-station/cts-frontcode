import 'dart:typed_data';
import 'dart:html';
import 'dart:js' as js;
import 'dart:js_util';
import 'dart:convert';

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
                        child: ListView(
                            padding: EdgeInsets.zero,
                            children: [
                                DrawerHeader(
                                    child: state.user==null ? Center(child: OutlineButton(button_text: 'ii login', on_press_complete: () async { await ii_login(context); })) : Text('USER ID: ${state.user!.principal.text}')
                        
                                ),
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
                                )
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
                            child: Text('USER ID: ${state.user!.principal.text}')
                        )
                    ),
                ]
            );

        }
        
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
            column_children.add(
                /*ListView(children: [ Wra])p*/ Wrap(
                    children: [
                        ConstrainedBox(
                            constraints: BoxConstraints(
                                maxWidth: 500,
                                minWidth: 250
                            ),
                            child: Column(
                                children: [
                                    Container(
                                        width: double.infinity,
                                        child: SelectableText('USER-ICP-ID: ${state.user!.user_icp_id}\n', style: TextStyle(fontSize: 11)),
                                    ),
                                    IcpBalanceAndLoadIcpBalance(key: ValueKey('TransferIcpScaffoldBody IcpBalanceAndLoadIcpBalance'))
                                ]
                            )
                        ),
                        ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: 500,
                              minWidth: 250
                            ),
                            child: Column(
                                children: [
                                    Padding(
                                        padding: EdgeInsets.all(17.0),
                                        child: UserTransferIcpForm(key: ValueKey('TransferIcpScaffoldBody UserTransferIcpForm'))  /*Text('')*/
                                    )
                                ]
                            )
                        )
                    ]
                )
            );
            
            if (state.user!.cycles_bank != null) {
                column_children.addAll([
                    // burn icp mint cycles,  
                    Padding(
                        padding: EdgeInsets.fromLTRB(17, 17, 17, 17.0),
                        child: Divider(
                            height: 13.0,   
                            thickness: 4.0,
                            indent: 34.0,
                            endIndent: 34.0,
                            //color: 
                        ),
                    ),
                    Padding(
                        padding: EdgeInsets.all(7),
                        child: BurnIcpMintCyclesForm(key: ValueKey('TransferIcpScaffoldBody BurnIcpMintCyclesForm'))
                    )
                ]);
            }
            
            column_children.addAll([
                Padding(
                    padding: EdgeInsets.fromLTRB(17, 17, 17, 17.0),
                    child: Divider(
                        height: 13.0,   
                        thickness: 4.0,
                        indent: 34.0,
                        endIndent: 34.0,
                        //color: 
                    ),
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
                /*Container(
                    constraints: BoxConstraints(maxHeight: 200),
                    child:ListView(
                        children: [
                */    
                SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                    child:
                        Row(
                            children: state.user!.icp_transfers.map<IcpTransferListItem>((IcpTransfer icp_transfer)=>IcpTransferListItem(icp_transfer)).toList()
                        )
                )
                /*    ],
                    scrollDirection: Axis.horizontal
                )*/
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
                constraints: BoxConstraints(maxWidth: 731),
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
            padding: EdgeInsets.all(13.0),
            child: Column(
                children: [
                    Text('ICP-BALANCE: ${state.user!.icp_balance != null ? state.user!.icp_balance!.icp : 'unknown'}'),
                    Text('timestamp: ${state.user!.icp_balance != null ? seconds_of_the_nanos(state.user!.icp_balance!.timestamp_nanos) : 'unknown'}', style: TextStyle(fontSize:9)),
                    Padding(
                        padding: EdgeInsets.all(7),
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
                                        DataCell(Text('ICP TRANSFER FEE XDR: ')),
                                        DataCell(Text('${state.cts_fees.cts_transfer_icp_fee.cycles/CYCLES_PER_XDR}-xdr')),
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
                                        DataCell(Text('ICP TRANSFER TOTAL COST: ')),
                                        DataCell(Text('${cycles_to_icptokens(state.cts_fees.cts_transfer_icp_fee, state.xdr_icp_rate_with_a_timestamp!.xdr_icp_rate) + ICP_LEDGER_TRANSFER_FEE_TIMES_TWO}-icp')),
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
                        }
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
                        initialValue: '0',
                        onSaved: (String? value) { memo = value == null || value == '' ? Nat64(BigInt.from(0)) : Nat64(BigInt.parse(value)); },
                        validator: (String? value) {
                            if (value != null && value != '') {
                                String error_string = 'Invalid memo. An icp memo is a number between 0 and 2^64 - 1';
                                try {
                                    Nat64 n = Nat64(BigInt.parse(value, radix: 10));
                                } catch(e) {
                                    return error_string;
                                }
                            }
                            return null;
                        }                        
                    ),
                    Padding(
                        padding: EdgeInsets.all(7),
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
                                    state.loading_text = 'Icp transfer is success. Block height: ${transfer_icp_success.block_height}\nloading icp balance and transfers list ...';
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
                                
                                    state.is_loading = false;
                                    main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);
                                    
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
                        }
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



class IcpTransferListItem extends StatelessWidget {
    late final IcpTransfer icp_transfer;
    IcpTransferListItem(IcpTransfer icp_transfer_): icp_transfer = icp_transfer_, super(key: ValueKey('IcpTransferListItem: ${icp_transfer_.block_height}'));
    
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
                            title: Text(icp_transfer.from_account_identifier == state.user!.user_icp_id ? 'OUT' : 'IN'),
                            subtitle: Text('BLOCK-HEIGHT: ${icp_transfer.block_height}'),
                        ),
                        Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Text(icp_transfer.from_account_identifier == state.user!.user_icp_id ? 'for: ${icp_transfer.to_account_identifier}' : 'by: ${icp_transfer.from_account_identifier}'),
                                Text('icp: ${icp_transfer.amount}'),
                                Text('memo: ${icp_transfer.memo}'),
                                Text('icp-ledger-fee: ${icp_transfer.fee}'),
                                Text('timestamp: ${icp_transfer.timestamp_seconds}'),
                            ]
                        ),
                    ]
                )
            )
        );
    }
}




class CyclesBankScaffoldBody extends StatelessWidget {
    CyclesBankScaffoldBody({Key? key}) : super(key: key);
    static CyclesBankScaffoldBody create({Key? key}) => CyclesBankScaffoldBody(key: key);
    
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
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(7,13,7,0),
                    child: SelectableText('USER-ICP-ID: ${state.user!.user_icp_id}\n', style: TextStyle(fontSize: 14)),
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
                Padding(
                    padding: EdgeInsets.all(7),
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
                
                List cycles_transfers = [ 
                    ...state.user!.cycles_bank!.cycles_transfers_in, 
                    ...state.user!.cycles_bank!.cycles_transfers_out 
                ]..sort((ct1,ct2)=>ct1.timestamp_nanos.compareTo(ct2.timestamp_nanos));

                List<Widget> cycles_transfers_list_items = cycles_transfers.map<Widget>((ct)=>cycles_transfer_list_item(ct)).toList();
                
                
                column_children.addAll([
                    Container(
                        width: double.infinity,
                        child: SelectableText('CYCLES-BANK ID: ${state.user!.cycles_bank!.principal.text}', style: TextStyle(fontSize: 15)),                
                    ),
                    Container(
                        width: double.infinity,
                        child: Text('CYCLES: ${metrics.cycles_balance}', style: TextStyle(fontSize: 13)),
                    ),
                    Wrap(
                        children: [
                            Container(
                                constraints: BoxConstraints(maxWidth: 375),
                                width: double.infinity,
                                //alignment: Alignment.centerLeft,
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
                                                DataCell(Text('${seconds_of_the_nanos(metrics.user_canister_creation_timestamp_nanos)}')),
                                            ],
                                        ),
                                        DataRow(
                                            cells: <DataCell>[
                                                DataCell(Text('lifetime-termination: ')),
                                                DataCell(Text('${metrics.lifetime_termination_timestamp_seconds}')),
                                            ],
                                        ),
                                        DataRow(
                                            cells: <DataCell>[
                                                DataCell(Text('ctsfuel: ')),
                                                DataCell(Text('${metrics.ctsfuel_balance.cycles/Cycles.T_CYCLES_DIVIDABLE_BY}')),
                                            ]
                                        ),
                                        DataRow(
                                            cells: <DataCell>[
                                                DataCell(Text('storage-usage: ')),
                                                DataCell(Text('${metrics.storage_usage / BigInt.from(1024*1024)}-MiB')),
                                            ]
                                        ),
                                        DataRow(
                                            cells: <DataCell>[
                                                DataCell(Text('storage-size: ')),
                                                DataCell(Text('${metrics.storage_size_mib}-MiB')),
                                            ]
                                        )
                                    ]    
                                ) 
                            ),
                            Container(
                                constraints: BoxConstraints(maxWidth: 375),
                                width: double.infinity,
                                //alignment: Alignment.centerLeft,
                                child: Column(
                                    children: [
                                        CTSFuelForTheCyclesBalanceForm(key: ValueKey('CyclesBankScaffoldBody CTSFuelForTheCyclesBalanceForm')),
                                        GrowStorageSizeForm(key: ValueKey('CyclesBankScaffoldBody GrowStorageSizeForm')),
                                        LengthenLifetimeForm(key: ValueKey('CyclesBankScaffoldBody LengthenLifetimeForm')),
                                    ]
                                )
                            )
                        ]
                    ),
                    CyclesBankTransferCyclesForm(key: ValueKey('CyclesBankScaffoldBody CyclesBankTransferCyclesForm')),
                    Padding(
                        padding: EdgeInsets.fromLTRB(17, 17, 17, 17.0),
                        child: Divider(
                            height: 13.0,   
                            thickness: 4.0,
                            indent: 34.0,
                            endIndent: 34.0,
                            //color: 
                        ),
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
                    SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child:
                            Row(
                                children: cycles_transfers_list_items
                            )
                    )
                    /*
                    ListView(
                        children: cycles_transfers_list_items,
                        scrollDirection: Axis.horizontal
                    ) 
                    */
                ]);   
            }
        }
    
        return Center(
            child: Container(
                constraints: BoxConstraints(maxWidth: 731),
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
                        )
                    ]
                )
            )
        );
    
/*
            if (state.user!.cycles_bank == null) {
                
                column_children.add(
                );
                
                column_children.add(
                    /*Align(
                        alignment: Alignment.centerLeft,
                        child: */
                    //)
                );
                
                column_children.add(
                    Divider(
                        height: 13.0,   
                        thickness: 4.0,
                        indent: 17.0,
                        endIndent: 17.0,
                        //color: 
                    )
                );
                    
                column_children.add(
                    Padding(
                        padding: EdgeInsets.all(17.0),
                        child: Text.rich(     
                            TextSpan(
                                text: '',
                                children: <InlineSpan>[
                                    TextSpan(
                                        text: 
'''
A CTS-USER-CONTRACT gives the purchaser a  
'''                                     ,
                                    ),
                                ]
                            )
                        )
                    )
                );    
                    
                column_children.add(
                    /*Center(child: */OutlineButton(
                        button_text: 'CREATE CTS USER CONTRACT',
                        on_press_complete: null/*() async {
                            state.loading_text = 'checking the icp-xdr exchange rate ...';
                            state.is_loading = true;
                            MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                            
                            BigInt current_membership_start_cost_icp_e8s = await state.get_current_cts_user_membership_start_cost_icp_e8s();
                            
                            if (state.user!.icp_balance == null || state.user!.icp_balance!.icp_balance_e8s < current_membership_start_cost_icp_e8s) {
                                state.loading_text = 'loading user icp balance ...';
                                main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);
                            
                            }
                            
                        } */
                    )/*)*/
                );
            }
            
            else /*if (state.user!.cycles_bank != null) */{
            
            }
*/

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
                            if (v == null || v == '') {
                                return 'Write the text-principal-id of the cycles-bank that will cept the cycles';
                            }
                            late Principal p;
                            try {
                                p = Principal(v);
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
                    TextFormField(
                        decoration: InputDecoration(
                            prefix: DropdownButtonFormField<CyclesTransferMemoType>(
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
                            labelText: 'Cycles Transfer Memo: ',
                        ),
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
                                        await showDialog(
                                            context: state.context,
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
                                    
                                    state.is_loading = false;
                                    main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);
                                    
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
                                    
                                    state.is_loading = false;
                                    main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);
                                    
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
                                }
                            }
                        )
                    )
                ]
            ),
        );
    }
}











Widget cycles_transfer_list_item(dynamic ct){
    if (ct is CyclesTransferIn) {
        return CyclesTransferInListItem(ct as CyclesTransferIn);
    } else if (ct is CyclesTransferOut) {
        return CyclesTransferOutListItem(ct as CyclesTransferOut); 
    } else {
        throw Exception('look at the function: cycles_transfer_list_item. ct.runtimeType: ${ct.runtimeType}');
    }
}

class CyclesTransferInListItem extends StatelessWidget {
    final CyclesTransferIn cycles_transfer_in;
    CyclesTransferInListItem(CyclesTransferIn _cycles_transfer_in): cycles_transfer_in = _cycles_transfer_in, super(key: ValueKey('CyclesTransferInListItem: ${_cycles_transfer_in.id}'));
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
                            title: Text('IN'),
                            subtitle: Text('ID: ${cycles_transfer_in.id}'),
                        ),
                        Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Text('cycles: ${cycles_transfer_in.cycles}'),
                                Text('cycles-transfer-memo: ${cycles_transfer_in.cycles_transfer_memo}'),
                                Text('by: ${cycles_transfer_in.by_the_canister.text}'),
                                Text('timestamp: ${seconds_of_the_nanos(cycles_transfer_in.timestamp_nanos)}'),
                            ]
                        ),
                    ]
                )
            )            
        );
    }
}

class CyclesTransferOutListItem extends StatelessWidget {
    final CyclesTransferOut cycles_transfer_out;
    CyclesTransferOutListItem(CyclesTransferOut _cycles_transfer_out): cycles_transfer_out = _cycles_transfer_out, super(key: ValueKey('CyclesTransferOutListItem: ${_cycles_transfer_out.id}'));
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
                            title: Text('OUT'),
                            subtitle: Text('ID: ${cycles_transfer_out.id}'),
                        ),
                        Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Text('for: ${cycles_transfer_out.for_the_canister.text}'),
                                Text('cycles_sent: ${cycles_transfer_out.cycles_sent}'),
                                Text('cycles_refunded: ${cycles_transfer_out.cycles_refunded != null ? cycles_transfer_out.cycles_refunded! : 'waiting for the callback'}'),
                                Text('cycles-transfer-memo: ${cycles_transfer_out.cycles_transfer_memo}'),
                                Text('transfer-call-status: ${cycles_transfer_out.cycles_refunded == null ? 'waiting for the callback' : cycles_transfer_out.opt_cycles_transfer_call_error == null ? 'complete' : 'error: ${cycles_transfer_out.opt_cycles_transfer_call_error!}'}'),
                                Text('cycles_transferrer_fee: ${cycles_transfer_out.fee_paid}'),
                                Text('timestamp: ${seconds_of_the_nanos(cycles_transfer_out.timestamp_nanos)}'),
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
                    padding: EdgeInsets.fromLTRB(11,0,11,0),
                    child: OutlineButton(
                        button_text: 'PURCHASE CYCLES-BANK',
                        on_press_complete: () async {
                            state.current_url = CustomUrl('cycles_bank');
                            state.loading_text = 'loading ...';
                            state.loading = true;
                            MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                            state.loading = false;
                            main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);
                        }
                    )
                )
            ]);
        } else if (state.user != null && state.user!.cycles_bank != null) {
            column_children.addAll([
                Wrap(
                    children: [
                        Container(
                            constraints: BoxConstraints(),
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
                            constraints: BoxConstraints(),
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
                        CyclesBankCMCreateCyclesPositionForm(key: ValueKey('CyclesBankScoffoldBody CyclesBankCMCreateCyclesPositionForm')),
                        CyclesBankCMCreateIcpPositionForm(key: ValueKey('CyclesBankScoffoldBody CyclesBankCMCreateIcpPositionForm')),
                    ]
                )
            
            ])
        }
        
        
        column_children.addAll([
            Padding(
                padding: EdgeInsets.all(7),
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: blue),
                    child: Text('LOAD CYCLES-MARKET POSITIONS', style: TextStyle(fontSize:11)),
                    onPressed: () async {
                        state.loading_text = 'loading cycles-market positions ...';
                        state.is_loading = true;
                        MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                        try {
                            await Future.wait([
                                state.cycles_market_data.fresh_cycles_positions(),
                                state.cycles_market_data.fresh_icp_positions()
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
        
        return Column(
            children: [
                ScaffoldBodyHeader('CYCLES-MARKET'),
                SingleChildScrollView(
                    child: Column(                
                        children: column_children,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center
                    )
                )
            ]
        );
    }
}




class CyclesBankCMTransferIcpForm extends StatefulWidget {
    CyclesBankCMTransferIcpForm({super.key});
    State<CyclesBankCMTransferIcpForm> createState => CyclesBankCMTransferIcpFormState();
}$
class CyclesBankCMTransferIcpFormState extends State<CyclesBankCMTransferIcpForm> {
    GlobalKey<FormState> form_key = GlobalKey<FormState>();
    
    late IcpTokens withdraw_icp;
    late String to;
    IcpTokens icp_fee = ICP_LEDGER_TRANSFER_ICP_FEE;  
    
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
                                        icp:icp,
                                        icp_fee: icp_fee, 
                                        to:to,
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
                            labelText: 'minimum_purchase: '
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
                                            state.cycles_market.fresh_cycles_positions(),
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
    
    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
                
        return Form(
            key: form_key,
            child: Column(
                children: <Widget>[               
                    
                ]
            )
        );



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
                        maxTimeToLive: 1000000000*60*60*24
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














