import 'dart:typed_data';
import 'dart:html';
import 'dart:convert';

import 'package:ic_tools/ic_tools.dart';
import 'package:ic_tools/tools.dart';
import 'package:ic_tools/candid.dart' show
    c_backwards,
    c_forwards,
    CandidType,
    Nat,
    Vector,
    Record,
    Variant,
    PrincipalReference
;

import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';

import 'urls.dart';
import './cts.dart';



typedef LegateeCaller = Caller;




class CustomState { // with ChangeNotifier  // do i want change notifier here?

    CustomUrl current_url = CustomUrl('welcome');
    
    Tuple3<Principal, LegateeCaller, List<Legation>>? ii_user; 
    
    CTSUser? cts_user;

    

    // check the expiration
    void get_ii_user_of_the_localStorage() {
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


    Future<void> find_cts_user_of_the_ii_user() async {
        this.cts_user = null;
        
        if (this.ii_user == null) {
            return;
        }
                
        // first check localStorage
        if (window.localStorage.containsKey('cts_user_json')) {
            Map cts_user_json_map = jsonDecode(window.localStorage['cts_user_json']!);
            if (
                cts_user_json_map.containsKey('user_id') 
                && cts_user_json_map['user_id'] == this.ii_user!.item1.text
                && cts_user_json_map.containsKey('user_canister') // make a clean_browser_user_data button for when a user_canister changes
            ) {
                this.cts_user = CTSUser(
                    user_id: Principal(cts_user_json_map['user_id']),
                    user_canister: Canister(Principal(cts_user_json_map['user_canister'])),
                    caller: this.ii_user!.item2,
                    legations: this.ii_user!.item3,
                );
                if (
                    cts_user_json_map.containsKey('last_known_user_icp_balance') 
                    && cts_user_json_map['last_known_user_icp_balance'].containsKey('user_icp_balance_e8s') 
                    && cts_user_json_map['last_known_user_icp_balance'].containsKey('timestamp_nanos')
                ) { 
                    this.cts_user!.last_known_user_icp_balance = LastKnownUserIcpBalance(
                        user_icp_balance_e8s: BigInt.parse(cts_user_json_map['last_known_user_icp_balance']['user_icp_balance_e8s']),
                        timestamp_nanos: BigInt.parse(cts_user_json_map['last_known_user_icp_balance']['timestamp_nanos'])
                    ); 
                }
                if (
                    cts_user_json_map.containsKey('last_known_user_cycles_balance') 
                    && cts_user_json_map['last_known_user_cycles_balance'].containsKey('user_cycles_balance') 
                    && cts_user_json_map['last_known_user_cycles_balance'].containsKey('timestamp_nanos')
                ) { 
                    this.cts_user!.last_known_user_cycles_balance = LastKnownUserCyclesBalance(
                        user_cycles_balance: BigInt.parse(cts_user_json_map['last_known_user_cycles_balance']['user_cycles_balance']),
                        timestamp_nanos: BigInt.parse(cts_user_json_map['last_known_user_cycles_balance']['timestamp_nanos'])
                    ); 
                }
            }
        }
        
        // then if not successfull, call find_user_canister on the cts
        if (this.cts_user == null) {
            late List<CandidType> find_user_canister_cs;
            try {
                find_user_canister_cs = c_backwards(await cts.call(
                    calltype: CallType.call,
                    method_name: 'find_user_canister',
                    put_bytes: c_forwards([]),
                    caller: this.ii_user!.item2,
                    legations: this.ii_user!.item3,
                ));
            } catch(e) {
                /*
                await showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext context) {
                        return AlertDialog(
                            title: Text('Find CTS User Call Error'),
                            content: Text(e.toString()),
                            elevation: 25.0,
                            //shape:   
                        );
                    }
                );
                */
                window.alert('Find CTS User Call Error:\n${e.toString()}');
                window.location.reload();
            }
            if (find_user_canister_cs[0] is Variant) {
                Variant find_user_canister_sponse = find_user_canister_cs[0] as Variant;
                if (find_user_canister_sponse.containsKey('Ok')) {
                    this.cts_user = CTSUser(
                        user_id: this.ii_user!.item1,
                        user_canister: Canister((find_user_canister_sponse['Ok'] as PrincipalReference).principal!),
                        caller: this.ii_user!.item2,
                        legations: this.ii_user!.item3,
                    );
                }
                else if (find_user_canister_sponse.containsKey('Err')) {
                    Variant find_user_canister_sponse_error = find_user_canister_sponse['Err'] as Variant; 
                    if (find_user_canister_sponse_error.containsKey('UserNotFound')) {
                        // leave this.cts_user null, which means the call: find_user_canister is success and the user is not found. let the user purchase a cts-user-canister
                    } else if (find_user_canister_sponse_error.containsKey('UsersMapCanistersFindUserCallFails')) {
                        String alert_dialog_content_string = 'Users-Map-Canisters Call-Fails:';
                        for (Record users_map_canister_call_fail in (find_user_canister_sponse_error['UsersMapCanistersFindUserCallFails'] as Vector).cast_vector<Record>()) {
                            alert_dialog_content_string = alert_dialog_content_string+' \n${users_map_canister_call_fail[0]}, error: ${users_map_canister_call_fail[1]}';
                        }
                        /*
                        await showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (BuildContext context) {
                                return AlertDialog(
                                    title: Text('Find CTS User Error'),
                                    content: Text(alert_dialog_content_string),
                                    elevation: 25.0,
                                    //shape:   
                                );
                            }
                        );
                        */
                        window.alert('Find CTS User Error:\n${alert_dialog_content_string}');
                        window.location.reload();
                        
                        
                    }
                }
            }
        }
    
    }








    Future<void> loadfirststate() async {
        //await Future.delayed(Duration(seconds: 5));
        
        this.get_ii_user_of_the_localStorage();
        
        if (this.ii_user != null) {
            await this.find_cts_user_of_the_ii_user();
        }
        
        
        
    }

    void save_in_localstorage() {
        
    }

    
}




/*
class IIUser {
    principal
    legatee_caller
    legations
}
*/

class LastKnownUserCyclesBalance {
    BigInt user_cycles_balance;
    BigInt timestamp_nanos;
    LastKnownUserCyclesBalance({required this.user_cycles_balance, required this.timestamp_nanos});
}


class LastKnownUserIcpBalance {
    BigInt user_icp_balance_e8s;
    BigInt timestamp_nanos;
    LastKnownUserIcpBalance({required this.user_icp_balance_e8s, required this.timestamp_nanos});
}


class CTSUser {

    final Principal user_id;
    final Canister user_canister;
    Caller caller; // legatee caller for an ii-user
    List<Legation> legations = [];
    
    LastKnownUserIcpBalance? last_known_user_icp_balance;
    LastKnownUserCyclesBalance? last_known_user_cycles_balance;
    
    CTSUser({
        required this.user_id,
        required this.user_canister,
        required this.caller,
        required this.legations,
        this.last_known_user_icp_balance,
        this.last_known_user_cycles_balance
    });
    
    
    Future<void> fresh_user_cycles_balance() async {
        
        try {
            List<CandidType> user_cycles_balance_call_sponse_candids = c_backwards(await this.user_canister.call(
                calltype: CallType.call,
                method_name: 'user_cycles_balance',
                put_bytes: c_forwards([]), // candid bytes with 0 params
                caller: this.caller,
                legations: this.legations
            ));
            // check for variant Err . but now there is no Err on the user_cycles_balance method
            dynamic user_cycles_balance_dyn = ((user_cycles_balance_call_sponse_candids[0] as Variant)['Ok'] as Nat).value;
            BigInt user_cycles_balance = user_cycles_balance_dyn is BigInt ? user_cycles_balance_dyn : BigInt.from(user_cycles_balance_dyn);
            BigInt timestamp_nanos = get_current_time_nanoseconds(); // take of the ic-sponse-certificate [?]
            this.last_known_user_cycles_balance = LastKnownUserCyclesBalance(
                user_cycles_balance: user_cycles_balance,
                timestamp_nanos: timestamp_nanos
            );
            
        } catch(e) {
            /*
            await showDialog(
                context: context,
                barrierDismissible: true,
                builder: (BuildContext context) {
                    return AlertDialog(
                        title: Text('See User Cycles Balance Call Error'),
                        content: Text(e.toString()),
                        elevation: 25.0,
                        //shape:   
                    );
                }
            );
            */
            window.alert('See User Cycles Balance Call Error:\n${e.toString()}');
            
            
        }
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
}



