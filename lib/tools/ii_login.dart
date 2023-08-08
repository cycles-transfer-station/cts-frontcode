import 'dart:typed_data';
import 'dart:html';
import 'dart:js' as js;
import 'dart:js_util';

import 'package:flutter/material.dart';
import 'package:ic_tools/ic_tools.dart';
import 'package:ic_tools/common_web.dart' show IICaller, AuthorizeClientFailure, SubtleCryptoECDSAP256Keys;
import 'package:ic_tools/common.dart' show transfer_icp, IcpTokens, icp_id;
import 'package:ic_tools/tools.dart' show hexstringasthebytes;

import '../user.dart';
import '../config/state.dart';
import '../config/state_bind.dart';




ii_login(BuildContext context) async {
    CustomState state = MainStateBind.get_state<CustomState>(context);
    MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
        
    state.is_loading = true;
    state.loading_text = 'ii login ...';
    MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
    
    late IICaller ii_caller;
    
    if (window.location.hostname!.contains('localhost') || window.location.hostname!.contains('127.0.0.1')) {
        ii_caller = IICaller(
            keys: await SubtleCryptoECDSAP256Keys.new_keys(),
            legations: []
        );
        await transfer_icp(
            Caller(keys: Ed25519Keys(
                public_key: hexstringasthebytes('52ef30bf9e412a693d644aebe8e22de574759291065dc392382d4e633ac0c2e9'),
                private_key: hexstringasthebytes('3771c1f078763eb5aa8561f642a82bd6f6d4f53de06f5ce07410fc64e765427552ef30bf9e412a693d644aebe8e22de574759291065dc392382d4e633ac0c2e9'.substring(0,64)),
            )),
            icp_id(
                cts.principal, 
                subaccount_bytes: principal_as_an_icpsubaccountbytes(ii_caller.principal)
            ),
            IcpTokens.of_the_double_string('100000'),
        );
    } else {
        try {
            ii_caller = await IICaller.login(
                derivation_origin: [
                    'cycles-transfer-station.com',
                ].contains(window.location.hostname!) ? 'https://${thp4z_id}.ic0.app' 
                : window.location.hostname!.contains('.icp0.io') ? 'https://${window.location.hostname!.replaceFirst('.icp0.io','.ic0.app')}'
                : null
            );
        } catch(e) {
            String error_text = e is AuthorizeClientFailure ? e.text : e.toString();
            state.loading_text = 'Error: authorize-client-failure:\n${error_text}';
            main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);
            await showDialog(
                context: state.context,
                builder: (BuildContext context) {
                    return AlertDialog(
                        title: Text('Error: ii-authorize-client-failure:'),
                        content: Text('${error_text}'),
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
    }
    
    state.loading_text = 'loading user ...';
    main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);
                
    state.user = User(
        state: state,
        caller: ii_caller,
    );

    // portant
    await state.user!.caller.indexdb_save();

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





