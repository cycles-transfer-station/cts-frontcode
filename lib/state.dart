import 'dart:typed_data';
import 'dart:html';
import 'dart:convert';

import 'package:ic_tools/ic_tools.dart';
import 'package:ic_tools/tools.dart';
import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';

import 'urls.dart';


typedef LegateeCaller = Caller;




class CustomState { // with ChangeNotifier  // do i want change notifier here?

    CustomUrl current_url = CustomUrl('welcome');
    
    Tuple3<Principal, LegateeCaller, List<Legation>>? ii_user; 
    

    // check the expiration
    get_ii_user_of_the_localStorage() {
        if (window.localStorage.containsKey('ii_json')) {
            Map ii_map = jsonDecode(window.localStorage['ii_json']!);
            if ( ii_map.containsKey('legations') ) {   
                List<Legation> legations = [];
                for (int i = 0; i < ii_map['legations'].length; i++) {
                    var l = ii_map['legations'][i];
                    BigInt expiration_unix_timestamp_nanoseconds = BigInt.parse(l['delegation']['expiration'], radix: 10);
                    if ( expiration_unix_timestamp_nanoseconds - get_current_time_nanoseconds() < BigInt.from(1000000000*60*5) ) {
                        return null;
                    }
                    legations.add(
                        Legation(
                            legatee_public_key_DER: Uint8List.fromList(l['delegation']['pubkey'].cast<int>()),
                            expiration_unix_timestamp_nanoseconds: expiration_unix_timestamp_nanoseconds, 
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

                Principal user_principal = Principal.ofthePublicKeyDER(legations[0].legator_public_key_DER);                         
                print('user_principal: $user_principal');    
            
                this.ii_user = Tuple3(user_principal, legatee_caller, legations);
            }
        }
    
    
    
    }



    Future<void> loadfirststate() async {
        //await Future.delayed(Duration(seconds: 5));
        
        this.get_ii_user_of_the_localStorage();
        
        
        
    }

    void save_in_localstorage() {
        
    }

    
}








