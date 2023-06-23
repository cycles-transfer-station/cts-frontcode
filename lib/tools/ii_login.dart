import 'dart:typed_data';
import 'dart:html';
import 'dart:js' as js;
import 'dart:js_util';

import 'package:flutter/material.dart';
import 'package:ic_tools/ic_tools.dart';
import 'package:ic_tools/common_web.dart' show IICaller, AuthorizeClientFailure;

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





