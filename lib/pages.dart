import 'dart:typed_data';
import 'dart:html';
import 'dart:js' as js;
import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:ic_tools/ic_tools.dart';
import 'package:ic_tools/candid.dart' show c_backwards, PrincipalReference;
import 'package:ic_tools/tools.dart';
import 'package:tuple/tuple.dart';

import './ii_jslib.dart';
import 'urls.dart';
import 'state.dart';
import 'state_bind.dart';
import './cts.dart';








// most state can be held in the MainState and can re-build with MainStateBind.set_state.tifyListeners so the page widgets can be StatelessWidget s




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
                final tween = Tween(begin: Offset(0.0, 1.0), end: Offset.zero);
                final curveTween = CurveTween(curve: Curves.easeInOut);
                return SlideTransition(
                    position: animation.drive(curveTween).drive(tween),
                    child: WelcomePageWidget()
                );
            }
        );
    }
}
class WelcomePageWidget extends StatelessWidget {
    const WelcomePageWidget({Key? key}) : super(key: key);

    @override
    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        Tuple3<Principal, LegateeCaller, List<Legation>>? ii_user = state.ii_user;
        Principal? ii_user_principal = ii_user != null ? ii_user.item1 : null;
        
        List<Widget> column_children = [];
        if (state.ii_user == null) {
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
                                // use local storage
                                // 
                                CallerEd25519 legatee_caller = CallerEd25519.new_keys();
                                Map ii_map = {};
                                ii_map['legatee_caller_public_key_hex'] = bytesasahexstring(legatee_caller.public_key); 
                                ii_map['legatee_caller_private_key_hex'] = bytesasahexstring(legatee_caller.private_key); 
                                
                                window.localStorage['ii_json'] = jsonEncode(ii_map); 
                                
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
                                            window.console.log(message_event.data);
                                            Map ii_map = jsonDecode(window.localStorage['ii_json']!);
                                            ii_map['original_user_public_key_DER'] = message_event.data['userPublicKey'].toList();
                                            ii_map['legations'] = List<Map>.generate(message_event.data['delegations'].length, (int i) { // because it is a js thing we are convert to dart
                                                var sl = message_event.data['delegations'][i];
                                                js.context.callMethod('start_logMessages');
                                                window.console.log(sl['delegation']['expiration']);
                                                String expiration_string = js.context.callMethod('get_last_logMessage_toString').replaceAll('n', ''); 
                                                print(expiration_string);
                                                
                                                Map signed_legation = {
                                                    'delegation': {
                                                        'pubkey': sl['delegation']['pubkey'].toList(),
                                                        'expiration': expiration_string, // as BigInt, // how to get convert LegacyJavaScriptObject for a BigInt? 
                                                        if (sl['delegation']['targets'] != null) 'targets': sl['delegation']['targets'].toList()
                                                    },
                                                    'signature': sl['signature'].toList()
                                                };
                                                return signed_legation;
                                            });
                                            window.localStorage['ii_json'] = jsonEncode(ii_map);
                                            
                                            CustomState state = MainStateBind.get_state<CustomState>(context);
                                            state.get_ii_user_of_the_localStorage();
                                            MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                                            
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
                                
                                identityWindow = window.open('https://identity.ic0.app/#authorize', 'identityWindow');  
                            }
                        )
                    )
                )
            );
        }
        else /*if (state.ii_user != null)*/ {
            column_children.add(
                Padding(
                    padding: EdgeInsets.all(17.0),
                    child: Container(
                        child: Text('Internet Identity User Principal: ${state.ii_user!.item1.text}')
                    )
                )
            );
            if (state.cts_user == null) {
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


