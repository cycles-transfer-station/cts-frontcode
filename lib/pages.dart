import 'dart:typed_data';
import 'dart:html';
import 'dart:js' as js;
import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:ic_tools/ic_tools.dart';
import 'package:ic_tools/candid.dart' show c_backwards;
import 'package:ic_tools/tools.dart';
import 'package:ic_tools/src/tools/cross_platform_tools/js/tools.dart';
import './ii_jslib.dart';

import 'urls.dart';
import 'state.dart';
import 'state_bind.dart';










final Canister cts = Canister(Principal('thp4z-laaaa-aaaam-qaaea-cai'));




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
        return Column(
            children: [
                ElevatedButton(
                    child: Text('buy this wallet'),
                    onPressed: () {
                        CustomState state = MainStateBind.get_state<CustomState>(context);
                        state.current_url = CustomUrl('welcome__buy_wallet');
                        MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                    }
                ),
                ElevatedButton(
                    child: Text('ii login'),
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
                                            //maxTimeToLive: BigInt.parse((1000000000*60*60).toString(), radix: 10)
                                        ),
                                        /*
                                        dartmapasajsstruct({
                                            'kind': "authorize-client", 
                                            'sessionPublicKey': legatee_caller.public_key_DER,
                                            //'maxTimeToLive': BigInt.parse((1000000000*60*60).toString(), radix: 10)
                                        }), 
                                        */
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
                                        print(js.context.callMethod('start_logMessages'));
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
                                    
                                    
                                    /*Map */ii_map = jsonDecode(window.localStorage['ii_json']!);
                                    List<Legation> legations = [];
                                    for (int i = 0; i < ii_map['legations'].length; i++) {
                                        var l = ii_map['legations'][i];
                                        legations.add(
                                            Legation(
                                                legatee_public_key_DER: Uint8List.fromList(l['delegation']['pubkey'].cast<int>()),
                                                expiration_unix_timestamp_nanoseconds: BigInt.parse(l['delegation']['expiration'], radix: 10), 
                                                target_canisters_ids: l['delegation'].containsKey('targets') ? l['delegation']['targets'] : null, 
                                                legator_public_key_DER: i==0 ? Uint8List.fromList(ii_map['original_user_public_key_DER'].cast<int>()) : Uint8List.fromList(ii_map['legations'][i-1]['delegation']['pubkey'].cast<int>()), 
                                                legator_signature: Uint8List.fromList(l['signature'].cast<int>())
                                            )
                                        );
                                            
                                    }
                                    CallerEd25519 legatee_caller = CallerEd25519(
                                        public_key: hexstringasthebytes(ii_map['legatee_caller_public_key_hex']),
                                        private_key: hexstringasthebytes(ii_map['legatee_caller_private_key_hex'])
                                    );
                                    print('legatee_caller: $legatee_caller');
                                    
                                    
                                    print('cts see_caller');
                                    print(c_backwards(await cts.call(
                                        calltype: 'call',
                                        method_name: 'see_caller',
                                        caller: legatee_caller,
                                        legations: legations
                                    )));
                                       
                                }
                                
                                if (message_event.data['kind'] == 'authorize-client-failure') {
                                    //
                                    print('authorize-client-failure:\n${message_event.data['text']}');
                                }
                            }
                        });
                        
                        identityWindow = window.open('https://identity.ic0.app/#authorize', 'identityWindow');
                                
                            
                        
                
                    
                    }
                ),
                
            ]
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


    @override
    Widget build(BuildContext context) {
        return Column(
            children: [
                ElevatedButton(
                    child: Text('buy wallet now'),
                    onPressed: () async {
                        print('buying wallet ....');
                        print(c_backwards(await cts.call(
                            calltype: 'call',
                            method_name: 'see_caller',
                            caller: CallerEd25519.new_keys()

                        )));
                    }
                ),
                ElevatedButton(
                    child: Text('back'),
                    onPressed: () {
                        Navigator.pop(context);
                    }
                ),
            ]
        );
    }
}


