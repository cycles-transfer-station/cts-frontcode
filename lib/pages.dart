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
                            child: IcpIdAndBalanceAndLoadIcpBalance()
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
            
            if (state.user!.cycles_bank != null) {
                column_children.addAll([
                    // burn icp mint cycles,  
                    // divider
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
            children: [
                ScaffoldBodyHeader('TRANSFER-ICP'),
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


class IcpIdAndBalanceAndLoadIcpBalance extends StatelessWidget {
    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
        state.context = context;
        
        return Padding(
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
                            labelText: 'to: ',
                        ),
                        onSaved: (String? value) { to = value!.trim().toLowerCase(); },
                        validator: (String? value) {
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
                        }
                    ),
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
                                        await state.user!.fresh_icp_balance();
                                        await state.user!.fresh_icp_transfers();
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


class IcpTransferListItem extends StatelessWidget {
    late final IcpTransfer icp_transfer;
    IcpTransferListItem(IcpTransfer icp_transfer_): icp_transfer = icp_transfer_, super(key: ValueKey('IcpTransferListItem: ${icp_transfer_.block_height}'));
    
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
        
        
        List<Widget> column_children = [];
        
        // maybe put the following widgets into a listview so the page is scrollable
        
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
                                context: state.context,
                                builder: (BuildContext context) {
                                    return AlertDialog(
                                        title: Text('What is a CYCLES-BANK?'),
                                        content: SingleChildScrollView(
                                            child: Text(
''' 
A CYCLES-BANK is a bank for the native stable-currency on the world-computer.

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
                
                // current cost icp
                // current icp-balance
                
                OutlineButton(
                    button_text: 'PURCHASE A CYCLES-BANK',
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
                IcpIdAndBalanceAndLoadIcpBalance()
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
                    SelectableText('CYCLES-BANK ID: ${state.user!.cycles_bank!.principal.text}', style: TextStyle(fontSize: 15)),                
                    Text('CYCLES: ${metrics.cycles_balance}', style: TextStyle(fontSize: 13)),
                    Wrap(
                        children: [
                            Container(
                                alignment: Alignment.centerLeft,
                                child: Column(
                                    children: [
                                        Text('creation timestamp: ${seconds_of_the_nanos(metrics.user_canister_creation_timestamp_nanos)}'),
                                        Text('lifetime-termination: ${metrics.lifetime_termination_timestamp_seconds}'),
                                        Text('CTSFuel: ${metrics.ctsfuel_balance}'),
                                        Text('storage-usage MiB: ${metrics.storage_usage / BigInt.from(1024*1024)}'),
                                        Text('storage-size MiB: ${metrics.storage_size_mib}'),
                                    ]
                                )
                            ),
                            Container(
                                alignment: Alignment.centerLeft,
                                child: Column(
                                    children: [
                                        // topup ctsfuel with the cycles_balance
                                        // grow storage size
                                        // lengthen lifetime
                                    
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
                                    await state.user!.cycles_bank!.fresh_cycles_transfers_in();
                                    await state.user!.cycles_bank!.fresh_cycles_transfers_out();
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
                    ListView(
                        children: cycles_transfers_list_items
                    )                    
                ]);   
            }
        }
    
        return Column(
            children: [
                ScaffoldBodyHeader('CYCLES-BANK'),
                SingleChildScrollView(
                    child: Column(                
                        children: column_children,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center
                    )
                )
            ]
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
        state.context = context;
        
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
                        validator: (String? v) {
                            if (v == null || v == '') {
                                return 'Must be a number';
                            }
                            try {
                                Cycles cycles = Cycles(cycles: BigInt.parse(v, radix: 10));
                            } catch(e) {
                                return 'Must be a number >= 0 and without decimal places';
                            }
                            return null;
                        }
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
                                            cycles_transfer_memo_type = select_cycles_transfer_memo_type; 
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
                                        await state.user!.cycles_bank!.fresh_metrics();
                                        await state.user!.cycles_bank!.fresh_cycles_transfers_out();
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
            Padding(
                padding: EdgeInsets.fromLTRB(17,17,17,17)
            )
        );
        
        
        
        
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
                    indent: 34.0,
                    endIndent: 34.0,
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














