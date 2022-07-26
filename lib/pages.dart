import 'dart:typed_data';
import 'dart:html';
import 'dart:js' as js;
import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:ic_tools/ic_tools.dart';
import 'package:ic_tools/candid.dart' show c_backwards, PrincipalReference;
import 'package:ic_tools/tools.dart';
import 'package:ic_tools/common.dart' as common;
import 'package:ic_tools/common_web.dart';

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
                    child: WelcomePageWidget()
                );
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
        
        
        
        
        if (state.user == null) {
            column_children.add(
                OutlineButton(
                    button_text: 'test user login',
                    on_press_complete: () async {
                        /*test*/
                        state.is_loading = true;
                        state.loading_text = 'loading test';
                        MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                                
                        //CallerEd25519 user_caller = CallerEd25519(
                        //    public_key: Uint8List.fromList([250,16,64,7,35,238,104,233,191,156,14,131,25,180,140,149,150,121,196,140,182,57,254,239,218,137,24,25,234,238,215,92]),
                        //    private_key: Uint8List.fromList([120,47,130,3,239,149,252,232,58,208,103,95,175,172,68,18,37,40,191,193,201,190,159,142,27,192,137,3,34,176,2,146])
                        //);
                        
                        SubtleCryptoECDSAP256Caller test_caller = await SubtleCryptoECDSAP256Caller.new_keys(); 
                        
                        state.user = User(
                            caller: test_caller,
                            legations: [],
                        );
                        
                        await state.save_state_in_the_browser_storage();
                        
                        Exception? loadfirststate_possible_e = await state.loadfirststate();
                        if (loadfirststate_possible_e != null) {
                            window.alert(loadfirststate_possible_e.toString());
                            state.loading_text = 'Error: ${loadfirststate_possible_e}';
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
                    on_press_complete: () async {
                        // ii login
                        //                              

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
                                    
                                    Exception? loadfirststate_possible_e = await state.loadfirststate();
                                    if (loadfirststate_possible_e != null) {
                                        window.alert(loadfirststate_possible_e.toString());
                                        state.loading_text = 'Error: ${loadfirststate_possible_e}';
                                        main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);    
                                        return;
                                    }
                                    
                                    state.is_loading = false;
                                    main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);
                                }
                                
                                if (message_event.data['kind'] == 'authorize-client-failure') {
                                    print('authorize-client-failure:\n${message_event.data['text']}');
                                    window.alert('authorize-client-failure:\n${message_event.data['text']}');
                                    state.loading_text = 'Error: authorize-client-failure:\n${message_event.data['text']}';
                                    main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);    
                                    return;
                                }
                            }
                        });
                        
                        identityWindow = window.open('https://identity.ic0.app/#authorize', 'identityWindow');  
                    
                        state.is_loading = true;
                        state.loading_text = 'ii login ...';
                        MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                    }  
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
                    Divider(
                        height: 13.0,   
                        thickness: 4.0,
                        indent: 17.0,
                        endIndent: 17.0,
                        //color: 
                    )
                ]
            );
            
            if (state.user!.cts_user_canister == null) {
                
                column_children.add(
                    Padding(
                        padding: EdgeInsets.all(17.0),
                        child: Text.rich(     //  'coming soon ...'  'Before creating a CTS user, send 10Tcycles worth of ICP, ')     
                            TextSpan(
                                text: '',
                                children: <InlineSpan>[
                                    TextSpan(
                                        text: 'USER TOPUP ICP ID: '
                                    ),
                                    WidgetSpan(
                                        child: SelectableText(bytesasahexstring(state.user!.user_topup_icp_id), style: TextStyle(fontSize: 11)),
                                    ),
                                    TextSpan(
                                        text:
'''

\nICP: ${state.user!.latest_known_user_icp_ledger_balance != null ? state.user!.latest_known_user_icp_ledger_balance!.icp_balance_string() : 'unknown'}
'''
                                    ),
                                    WidgetSpan(
                                        child: SelectableText(
'''                                        
timestamp: ${state.user!.latest_known_user_icp_ledger_balance != null ? (state.user!.latest_known_user_icp_ledger_balance!.timestamp_nanos / BigInt.from(1000000000)).toInt() : 'unknown'}
'''                                     
                                            ,
                                            style: TextStyle(fontSize:9)
                                        )
                                    ),
                                    
                                ]
                            )
                        )
                    )
                );
                
                column_children.add(
                    /*Align(
                        alignment: Alignment.centerLeft,
                        child: */TextButton(
                            child: Text('fresh user icp balance', style: TextStyle(fontSize:11)),
                            onPressed: () async {
                                state.loading_text = 're-freshing user icp balance ...';
                                state.is_loading = true;
                                MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                                
                                Exception? fresh_latest_known_user_icp_ledger_balance_possible_e = await state.user!.fresh_latest_known_user_icp_ledger_balance();
                                if (fresh_latest_known_user_icp_ledger_balance_possible_e != null) {
                                    window.alert('Error re-freshing the user icp balance: ${fresh_latest_known_user_icp_ledger_balance_possible_e}');
                                }
                                
                                state.is_loading = false;
                                main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);
                            }
                        )
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
                            
                            if (state.user!.latest_known_user_icp_ledger_balance == null || state.user!.latest_known_user_icp_ledger_balance!.icp_balance_e8s < current_membership_start_cost_icp_e8s) {
                                state.loading_text = 're-freshing user icp balance ...';
                                main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);
                                
                                await state.user!.fresh_latest_known_user_icp_ledger_balance();
                            
                            }
                            
                        } */
                    )/*)*/
                );
            }
            
            else /*if (state.user!.cts_user_canister != null) */{
            
            
            
            }
            
        }
        
        
        
        return Scaffold(
            appBar: AppBar(
                title: Center(child: const Text(':CYCLES-TRANSFER-STATION.')),
            ),
            body: Column(                
                children: column_children,
                crossAxisAlignment: CrossAxisAlignment.center 
            ), 
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





















