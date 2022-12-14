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


import 'package:tuple/tuple.dart';

import '../main.dart';
import '../tools/ii_jslib.dart';
import '../tools/indexdb.dart';
import 'urls.dart';
import 'state.dart';
import 'state_bind.dart';
import '../widgets.dart';
import '../user.dart';
import '../transfer_icp/icp_ledger.dart';
import '../transfer_icp/scaffold_body.dart';
import '../cycles_bank/cycles_bank.dart';
import '../cycles_bank/scaffold_body.dart';
import '../cycles_market/cycles_market_data.dart';
import '../cycles_market/scaffold_body.dart';



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
                child: Text("""Welcome.""")
            )
        );
        
        return Column(                
            children: column_children,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center
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














