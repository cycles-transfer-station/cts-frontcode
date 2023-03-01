import 'dart:typed_data';
import 'dart:html';
import 'dart:js' as js;
import 'dart:js_util';

import 'package:flutter/material.dart';
import 'package:ic_tools/ic_tools.dart';
import 'package:ic_tools/common_web.dart';

import '../user.dart';
import '../config/state.dart';
import '../config/state_bind.dart';

import './ii_jslib.dart';



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
                    create_ii_auth_quest(
                        kind: "authorize-client", 
                        sessionPublicKey: legatee_caller.public_key_DER,
                        maxTimeToLive: 1000000000*60*60*24*30,
                        derivationOrigin: window.location.hostname!.contains('cycles-transfer-station.com') ? 'https://${thp4z_id}.ic0.app' : null
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





