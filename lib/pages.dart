import 'dart:typed_data';
import 'dart:html';
import 'dart:js' as js;
import 'dart:js_util';
import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:ic_tools/ic_tools.dart';
import 'package:ic_tools/candid.dart' show c_backwards, PrincipalReference, Nat64;
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
        state.context = context;
        
        
        
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
        
        List<Widget> column_children = [
            Padding(
                padding: EdgeInsets.fromLTRB(17.0, 19.0, 17.0, 17.0),
                child: Container(
                    child: Text('TRANSFER-ICP', style: TextStyle(fontSize: 19))
                )
            ),
            Padding(
                padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                child: Divider(
                    height: 13.0,   
                    thickness: 4.0,
                    indent: 34.0,
                    endIndent: 34.0,
                    //color: 
                ),
            )
        ];
        
        if (state.user != null) {
            column_children.add(
                /*ListView(children: [ Wra])p*/ Wrap(
                    children: [
                        ConstrainedBox(
                            constraints: BoxConstraints(
                                maxWidth: 500,
                                minWidth: 250
                            ),
                            child: Padding(
                                padding: EdgeInsets.all(17.0),
                                child: Column(
                                    children: [
                                        SelectableText('USER-ICP-ID: ${state.user!.user_icp_id}\n', style: TextStyle(fontSize: 11)),
                                        Text('ICP-BALANCE: ${state.user!.icp_balance != null ? state.user!.icp_balance!.icp : 'unknown'}'),
                                        Text('timestamp: ${state.user!.icp_balance != null ? seconds_of_the_nanos(state.user!.icp_balance!.timestamp_nanos) : 'unknown'}', style: TextStyle(fontSize:9)),
                                        Padding(
                                            padding: EdgeInsets.all(7),
                                            child: ElevatedButton(
                                                style: ElevatedButton.styleFrom(backgroundColor: blue),
                                                child: Text('FRESH', style: TextStyle(fontSize:11)),
                                                onPressed: () async {
                                                    state.loading_text = 'fresh user icp balance ...';
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
                                        child: TransferIcpForm(key: ValueKey('TransferIcpForm on the transfer_icp page.'))  /*Text('')*/
                                    )
                                ]
                            )
                        )
                    ]
                )
            );

            column_children.add(
                Padding(
                    padding: EdgeInsets.fromLTRB(17, 17, 17, 17.0),
                    child: Divider(
                        height: 13.0,   
                        thickness: 4.0,
                        indent: 34.0,
                        endIndent: 34.0,
                        //color: 
                    ),
                )
            );
            
            column_children.addAll([
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
                ListView(
                    children: state.user!.icp_transfers.map<IcpTransferListItem>((IcpTransfer icp_transfer)=>IcpTransferListItem(icp_transfer)).toList()
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
        
        
        return Column(                
            children: column_children,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center
        );
        
    }
}



class TransferIcpForm extends StatefulWidget {
    TransferIcpForm({super.key});
    @override 
    State createState() => TransferIcpFormState(); 
}
class TransferIcpFormState extends State<TransferIcpForm> {
    GlobalKey<FormState> form_key = GlobalKey<FormState>();
    
    late IcpTokens icp;
    late String to;
    late Nat64 memo;
    

    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
        state.context = context;
        
        
        return Form(
            key: form_key,
            child: Column(
                children: <Widget>[
                    TextFormField(
                        decoration: InputDecoration(
                            labelText: 'icp: '
                        ),
                        onSaved: (String? value) { icp = IcpTokens.oftheDouble(double.parse(value!)); },
                        validator: (String? value) {
                            String error_message = 'the value is set as a number with a max ${IcpTokens.DECIMAL_PLACES} decimal point places';
                            if (value == null) {
                                return error_message;
                            }
                            late double d;
                            try {
                                d = double.parse(value);
                            } catch(e) {
                                return error_message;
                            }
                            if (check_double_decimal_point_places(d) > IcpTokens.DECIMAL_PLACES) {
                                return error_message;
                            }
                        }
                    ),
                    TextFormField(
                        decoration: InputDecoration(
                            labelText: 'to: ',
                        ),
                        onSaved: (String? value) { to = value!; },
                        validator: (String? value) {
                            if (value == null || value.trim().length != 64) {
                                return 'Icp ids are 64 characters long';
                            }
                            for (String char in value.split('')) {
                                if (lower_case_hex_chars.contains(char) == false && number_chars.contains(char) == false) {
                                    return 'Icp ids are in the hex format. hex format characters are 0-9 a-f.';
                                }
                            }
                            List<int> b = hexstringasthebytes(value);
                            Crc32 crc32_checksum_compute = Crc32()..add(b.sublist(4));
                            if (aresamebytes(crc32_checksum_compute.close(), b.sublist(0,4)) == false) {
                                return 'The checksum does not match, invalid icp-id.';
                            } 
                            return null;                            
                        }
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
                            child: Text('TRANSFER'),
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
                                    state.loading_text = 'Icp transfer is success. Block height: ${transfer_icp_success.block_height}\nfreshing icp balance and transfers list ...';
                                    main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);
                                    
                                    try {
                                        await state.user!.fresh_icp_balance();
                                        await state.user!.fresh_icp_transfers();
                                    } catch(e) {
                                        await showDialog(
                                            context: state.context,
                                            builder: (BuildContext context) {
                                                return AlertDialog(
                                                    title: Text('Error when checking the user icp balance and the transfers list:'),
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


class IcpTransferListItem extends StatelessWidget {
    late final IcpTransfer icp_transfer;
    IcpTransferListItem(IcpTransfer icp_transfer_): icp_transfer = icp_transfer_, super(key: ValueKey(icp_transfer_.block_height));
    
    Widget build(BuildContext context) {        
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
        
        
        String subtitle = icp_transfer.from_account_identifier == state.user!.user_icp_id ? 'Out' : 'In';
        subtitle = subtitle + ': ';
        subtitle = subtitle + icp_transfer.from_account_identifier == state.user!.user_icp_id ? icp_transfer.to_account_identifier : icp_transfer.from_account_identifier;
        subtitle = subtitle + ': ${icp_transfer.amount}';
        
        return Container(
            child: ListTile(
                title: Text('${icp_transfer.block_height}, memo: ${icp_transfer.memo}'),
                subtitle: Text(subtitle),
                isThreeLine: true
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
        
            
        List<Widget> column_children = [
            Padding(
                padding: EdgeInsets.fromLTRB(17.0, 19.0, 17.0, 17.0),
                child: Container(
                    child: Text('CYCLES-BANK', style: TextStyle(fontSize: 19))
                )
            ),
            Padding(
                padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                child: Divider(
                    height: 13.0,   
                    thickness: 4.0,
                    indent: 34.0,
                    endIndent: 34.0,
                    //color: 
                ),
            )
        ];
    
        
        
    
    
    
        return Column(                
            children: column_children,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center
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
                                state.loading_text = 're-freshing user icp balance ...';
                                main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);
                                
                                await state.user!.fresh_icp_balance();
                            
                            }
                            
                        } */
                    )/*)*/
                );
            }
            
            else /*if (state.user!.cycles_bank != null) */{
            
            
            
            }
*/
        return Text('cycles-bank');        

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
        
    
        return Text('cycles-market');
        
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














