import 'dart:typed_data';
import 'dart:html';
import 'dart:js' as js;
import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:ic_tools/ic_tools.dart';
import 'package:ic_tools/candid.dart' show c_backwards, PrincipalReference;
import 'package:ic_tools/tools.dart';
import 'package:ic_tools/common.dart' as common;

import 'package:tuple/tuple.dart';

import './ii_jslib.dart';
import 'urls.dart';
import 'state.dart';
import 'state_bind.dart';
import './cts.dart';
import 'widgets.dart';







// most state can be held in the MainState and can re-build with MainStateBind.set_state.tifyListeners so the page widgets can be StatelessWidget s





class LoadingPage extends Page {
    
    LoadingPage({LocalKey? key}) : super(key: key);
    
    Route createRoute(BuildContext context) {
        return PageRouteBuilder(
            settings: this,
            // do a cool fade in and fade out 
            pageBuilder: (context, animation, animation2) {
                //final tween = Tween(begin: 0.0, end: 1.0);
                //final curveTween = CurveTween(curve: Curves.fastOutSlowIn);
                //Animation<double> a = CurvedAnimation(
                //    parent: a_c,
                //    curve: Curves.fastOutSlowIn,
                //  );
                //return FadeTransition(
                //);
                /*
                return AnimatedOpacity(
                    duration: Duration(milliseconds: 734),
                    curve: Curves.fastOutSlowIn,
                    opacity: 1.0,    
                    child: Loading()
                );
                */
                final tween = Tween(begin: Offset(0.0, 1.0), end: Offset.zero);
                final curveTween = CurveTween(curve: Curves.easeInOut);
                return SlideTransition(
                    position: animation.drive(curveTween).drive(tween),
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
        return Text('The page is not found');
    }
}



class WelcomePage extends Page {
    WelcomePage({LocalKey? key}) : super(key: key);
    static WelcomePage create({LocalKey? key}) => WelcomePage(key: key);

    Route createRoute(BuildContext context) {
        return PageRouteBuilder(
            settings: this,
            pageBuilder: (context, animation, animation2) {
                /*final tween = Tween(begin: Offset(0.0, 1.0), end: Offset.zero);
                final curveTween = CurveTween(curve: Curves.easeInOut);
                */return /*SlideTransition(
                    position: animation.drive(curveTween).drive(tween),
                    child: */WelcomePageWidget()
                /*)*/;
            }
        );
    }
}
class WelcomePageWidget extends StatelessWidget {
    WelcomePageWidget({Key? key}) : super(key: key);

    @override
    Widget build(BuildContext context) {
    
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
    
    
    
        List<Widget> column_children = [];
        column_children.add(
            Padding(
                padding: EdgeInsets.all(17.0),
                child: Container(
                    child: OutlinedButton(
                        child: Text('test loading '),
                        style: ButtonStyle(
                            foregroundColor: MaterialStateProperty.all(Theme.of(context).colorScheme.onPrimary),
                        ),
                        onPressed: () async {
                            /*test*/
                            state.is_loading = true;
                            state.loading_text = 'loading test';
                            main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);
                            
                            await Future.delayed(Duration(seconds: 5));
                            state.user = null;
                            state.is_loading = false;
                            main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);
                                 
                            
                        }
                    )
                )
            )
        );
        
        
        
        if (state.user == null) {
            column_children.add(
                Padding(
                    padding: EdgeInsets.all(17.0),
                    child: Container(
                        child: OutlinedButton(
                            child: Text('ii login'),
                            style: ButtonStyle(
                                foregroundColor: MaterialStateProperty.all(Theme.of(context).colorScheme.onPrimary),
                            ),
                            onPressed: () async {
                                // ii login
                                //                              
                                
                                CallerEd25519 legatee_caller = CallerEd25519.new_keys();
                                Map user_map = {};
                                user_map['legatee_caller_public_key'] = legatee_caller.public_key; 
                                user_map['legatee_caller_private_key'] = legatee_caller.private_key; 
                                
                                window.localStorage['user_json'] = jsonEncode(user_map); 
                                
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
                                                    maxTimeToLive: 1000000000*60*60*3
                                                ),
                                                "https://identity.ic0.app"
                                            );
                                        }
                                        
                                        if (message_event.data['kind'] == 'authorize-client-success') {
                                            identityWindow.close();
                                            //window.console.log(message_event.data);
                                            Map user_map = jsonDecode(window.localStorage['user_json']!);
                                            CallerEd25519 user_caller = CallerEd25519(
                                                public_key: Uint8List.fromList(user_map['legatee_caller_public_key'].cast<int>()),
                                                private_key: Uint8List.fromList(user_map['legatee_caller_private_key'].cast<int>())
                                            );
                                            List<Legation> user_legations = user_map['legations'] = List<Legation>.generate(message_event.data['delegations'].length, (int i) {
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
                                                /*
                                                Map signed_legation = {
                                                    'delegation': {
                                                        'pubkey': sl['delegation']['pubkey'].toList(),
                                                        'expiration': expiration_string, // as BigInt, // how to get convert LegacyJavaScriptObject for a BigInt? 
                                                        if (sl['delegation']['targets'] != null) 'targets': sl['delegation']['targets'].toList()
                                                    },
                                                    'signature': sl['signature'].toList()
                                                };
                                                return signed_legation;
                                                */
                                            });

                                            await Future.delayed(Duration(seconds: 5));
                                            print('test if tifyListeners cuts the current code. before ');
                                            //CustomState state = MainStateBind.get_state<CustomState>(context_r);
                                            state.is_loading = true;
                                            state.loading_text = 'loading user ...';
                                            main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);
                                            //MainStateBind.set_state<CustomState>(context_r, state, tifyListeners: true);
                                            
                                            await Future.delayed(Duration(seconds: 5));
                                            print('test if tifyListeners cuts the current code ');
                                            
                                            
                                            Principal user_principal = user_legations.length >= 1 ? Principal.ofthePublicKeyDER(user_legations[0].legator_public_key_DER) : user_caller.principal;
                                            
                                            Uint8List user_subaccount_bytes = Uint8List.fromList([ ...utf8.encode('UT'), user_principal.bytes.length, ...user_principal.bytes ]);
                                            while (user_subaccount_bytes.length < 32) { user_subaccount_bytes.add(0); }
                                            
                                            //state = MainStateBind.get_state<CustomState>(context);
                                            state.user = User(
                                                caller: user_caller,
                                                legations: user_legations,
                                                user_cycles_topup_cycles_transfer_memo_blob_bytes: user_subaccount_bytes,
                                                user_icp_topup_icp_id: hexstringasthebytes(cts.principal.icp_id(subaccount_bytes: user_subaccount_bytes))
                                            );
                                            state.save_state_in_the_localstorage();
                                            state.is_loading = false;
                                            main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);
                                            //MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                                            
                                        }
                                        
                                        if (message_event.data['kind'] == 'authorize-client-failure') {
                                            //
                                            print('authorize-client-failure:\n${message_event.data['text']}');
                                            await showDialog(
                                                context: context,
                                                barrierDismissible: true,
                                                builder: (BuildContext context) {
                                                    return AlertDialog(
                                                        title: Text('Internet Identity authorize-client-failure'),
                                                        content: Text(message_event.data['text']),
                                                        elevation: 25.0,
                                                    );
                                                }
                                            );
                                        }
                                    }
                                });

                                state = MainStateBind.get_state<CustomState>(context);
                                state.is_loading = true;
                                state.loading_text = 'ii login ...';
                                MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                                
                                //await Future.delayed(Duration(seconds: 5));
                                
                                identityWindow = window.open('https://identity.ic0.app/#authorize', 'identityWindow');  
                            }
                        )
                    )
                )
            );
        }
        else /*if (state.user != null)*/ {
            column_children.add(
                Padding(
                    padding: EdgeInsets.all(17.0),
                    child: Container(
                        child: Text('user_id: ${state.user!.principal.text}')
                    )
                )
            );
            if (state.user!.cts_user_canister == null) {
                column_children.add(
                    Padding(
                        padding: EdgeInsets.all(17.0),
                        child: Container(
                            child: Text('coming soon ...')   //'Before creating a CTS user, send 5Tcycles worth of ICP, ') 
                        )
                    )
                );
                column_children.add(
                    Padding(
                        padding: EdgeInsets.all(17.0),
                        child: Container(
                            child: OutlinedButton(
                                child: Text('Create CTS User'),
                                style: ButtonStyle(
                                    foregroundColor: MaterialStateProperty.all(Theme.of(context).colorScheme.onPrimary),
                                ),
                                onPressed: null //() async {} 
                            )
                        )
                    )
                );
            }
            
        }
        
        
        
        return Scaffold(
            appBar: AppBar(
                title: Center(child: const Text(':CYCLES-TRANSFER-STATION.')),
            ),
            body: Center(
                child: Column(                  
                    children: column_children 
                        /*
                        OutlinedButton(
                            child: Text('buy this wallet'),
                            style: ButtonStyle(
                                foregroundColor: MaterialStateProperty.all(Theme.of(context).colorScheme.onPrimary),
                            ),
                            onPressed: () {
                                CustomState state = MainStateBind.get_state<CustomState>(context);
                                state.current_url = CustomUrl('welcome__buy_wallet');
                                MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                            }
                        ),
                        */
                )
            ), 
        );
    }
}



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


