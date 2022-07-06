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






class CustomState { // with ChangeNotifier  // do i want change notifier here?

    CustomUrl current_url = CustomUrl('welcome');
    
    User? user; 
    

    

    Future<void> loadfirststate() async {
        
        this.get_state_of_the_localstorage();
        
        if (this.user != null) {
                
            if (this.user.cts_user_canister == null) {
                
                await this.user.find_cts_user_canister();
                
                // if UserNotFound
                if (this.user.cts_user_canister == null) {
                    await this.user.fresh_latest_known_user_icp_ledger_balance();
                }
                
            }
        
            
        }
        
        
        
        this.save_state_in_the_localstorage();
        
    }

    void save_state_in_the_localstorage() {
        // user
        if (this.user != null) {
            
            Map user_map = {};
            
            List<Map> legations_maps = [];
            for (Legation legation in this.user.legations) {
                legations_maps.add(
                    {
                        'delegation': {
                            'pubkey': legation.legatee_public_key_DER,
                            'expiration': legation.expiration_unix_timestamp_nanoseconds.toString(),
                            if (legation.target_canisters_ids != null) 'targets': legation.target_canisters_ids.map<String>((Principal p)=>p.text).toList() 
                        },
                        'signature': legation.legator_signature
                    }
                );
            }
            user_map['legations'] = legations_maps; 
            user_map['original_user_public_key_DER'] = this.user.legations.length >= 1 ? this.user.legations[0].legator_public_key_DER : this.user.caller.public_key_DER;
            user_map['legatee_caller_public_key'] = this.user.caller.public_key;
            user_map['legatee_caller_private_key'] = this.user.caller.private_key;
            user_map['user_cycles_topup_cycles_transfer_memo_blob_bytes'] = this.user.user_cycles_topup_cycles_transfer_memo_blob_bytes;
            user_map['user_icp_topup_icp_id'] = this.user.user_icp_topup_icp_id;            
            
            if (this.user.cts_user_canister != null) {
            
                Map cts_user_canister_map = {
                    'cts_user_canister_id_text': this.user.cts_user_canister.principal.text 
                };                
                
                if (this.user.cts_user_canister.latest_known_cycles_balance != null) {
                    cts_user_canister_map['latest_known_cycles_balance'] = {
                        'cycles_balance': this.user.cts_user_canister.latest_known_cycles_balance.cycles_balance.toString(),
                        'timestamp_nanos': this.user.cts_user_canister.latest_known_cycles_balance.timestamp_nanos.toString()
                    };
                }
                
                if (this.user.cts_user_canister.latest_known_icp_balance) {
                    cts_user_canister_map['latest_known_icp_balance'] = {
                        'icp_balance_e8s': this.user.cts_user_canister.latest_known_icp_balance.icp_balance_e8s.toString(),
                        'timestamp_nanos': this.user.cts_user_canister.latest_known_icp_balance.timestamp_nanos.toString()
                    };
                }


                user_map['cts_user_canister'] = cts_user_canister_map; 
            }
        
        
        
            window.localStorage['user_json'] = jsonEncode(user_map);
        }
    }
    
    void get_state_of_the_localstorage() {
        // user
        if (window.localStorage.containsKey('user_json')) {
            Map user_map = jsonDecode(window.localStorage['user_json']!);
            if (
                user_map.containsKey('legations')
                && user_map.containsKey('original_user_public_key_DER'),
                && user_map.containsKey('legatee_caller_public_key')
                && user_map.containsKey('legatee_caller_private_key')
                && user_map.containsKey('user_cycles_topup_cycles_transfer_memo_blob_bytes'),
                && user_map.containsKey('user_icp_topup_icp_id')
            ) {
                List<Legation> legations = [];
                for (int i = 0; i < user_map['legations'].length; i++) {
                    var l = user_map['legations'][i];
                    BigInt expiration_unix_timestamp_nanoseconds = BigInt.parse(l['delegation']['expiration'], radix: 10);
                    if ( expiration_unix_timestamp_nanoseconds - get_current_time_nanoseconds() < BigInt.from(1000000000*60*5) ) {
                        return;
                    }
                    legations.add(
                        Legation(
                            legatee_public_key_DER: Uint8List.fromList(l['delegation']['pubkey'].cast<int>()),
                            expiration_unix_timestamp_nanoseconds: expiration_unix_timestamp_nanoseconds, 
                            target_canisters_ids: l['delegation'].containsKey('targets') ? (l['delegation']['targets'] as List<String>).map<Principal>((String pstring)=>Principal(pstring)).toList() : null, 
                            legator_public_key_DER: i==0 ? Uint8List.fromList(user_map['original_user_public_key_DER'].cast<int>()) : Uint8List.fromList(user_map['legations'][i-1]['delegation']['pubkey'].cast<int>()), 
                            legator_signature: Uint8List.fromList(l['signature'].cast<int>())
                        )
                    );  
                }

                this.user = User(
                    caller: CallerEd25519(
                        public_key: Uint8List.fromList(user_map['legatee_caller_public_key'].cast<int>()),
                        private_key: Uint8List.fromList(user_map['legatee_caller_private_key'].cast<int>())
                    ), 
                    legations: legations,
                    user_cycles_topup_cycles_transfer_memo_blob_bytes: Uint8List.fromList(user_map['user_cycles_topup_cycles_transfer_memo_blob_bytes'].cast<int>()),
                    user_icp_topup_icp_id: Uint8List.fromList(user_map['user_icp_topup_icp_id'].cast<int>()),
                );
                
                
                if (
                    user_map.containsKey('cts_user_canister')
                    && user_map['cts_user_canister'].containsKey('cts_user_canister_id_text')
                ) {
                    
                    this.user.cts_user_canister = CTSUserCanister(Principal(user_map['cts_user_canister']['cts_user_canister_id_text'] as String), this.user);   
                    
                    Map cts_user_canister_map = user_map['cts_user_canister'];
                    
                    if (
                        cts_user_canister_map.containsKey('latest_known_cycles_balance') 
                        && cts_user_canister_map['latest_known_cycles_balance'].containsKey('cycles_balance') 
                        && cts_user_canister_map['latest_known_cycles_balance'].containsKey('timestamp_nanos')
                    ) { 
                        this.user.cts_user_canister.latest_known_cycles_balance = LatestKnownCyclesBalance(
                            cycles_balance: BigInt.parse(cts_user_canister_map['latest_known_cycles_balance']['cycles_balance']),
                            timestamp_nanos: BigInt.parse(cts_user_canister_map['latest_known_cycles_balance']['timestamp_nanos'])
                        ); 
                    }
                    if (
                        cts_user_canister_map.containsKey('latest_known_icp_balance') 
                        && cts_user_canister_map['latest_known_icp_balance'].containsKey('icp_balance_e8s') 
                        && cts_user_canister_map['latest_known_icp_balance'].containsKey('timestamp_nanos')
                    ) { 
                        this.user.cts_user_canister.latest_known_icp_balance = LatestKnownIcpBalance(
                            icp_balance_e8s: BigInt.parse(cts_user_canister_map['latest_known_icp_balance']['icp_balance_e8s']),
                            timestamp_nanos: BigInt.parse(cts_user_canister_map['latest_known_icp_balance']['timestamp_nanos'])
                        ); 
                    }
                        
                }
                
            }
        }
    

    }

    
}












class LatestKnownCyclesBalance {
    BigInt cycles_balance;
    BigInt timestamp_nanos;
    LatestKnownCyclesBalance({required this.cycles_balance, required this.timestamp_nanos});
}


class LatestKnownIcpBalance {
    BigInt icp_balance_e8s;
    BigInt timestamp_nanos;
    LatestKnownIcpBalance({required this.icp_balance_e8s, required this.timestamp_nanos});
}







class User {
    Caller caller;
    List<Legation> legations;
    
    Principal get principal => legations.length >= 1 ? Principal.ofthePublicKeyDER(legations[0].legator_public_key_DER) : caller.principal; 
    
    Uint8List user_cycles_topup_cycles_transfer_memo_blob_bytes;
    Uint8List user_icp_topup_icp_id;
    
    CTSUserCanister? cts_user_canister;
    LatestKnownIcpBalance? latest_known_user_icp_ledger_balance;
    
    User({
        required this.caller,
        required this.legations,
        required this.user_cycles_topup_cycles_transfer_memo_blob_bytes,
        required this.user_icp_topup_icp_id,
        this.cts_user_canister,
        this.latest_known_user_icp_ledger_balance,
    });

    
    Future<void> find_cts_user_canister() async {

        late List<CandidType> find_user_canister_cs;
        try {
            find_user_canister_cs = c_backwards(await cts.call(
                calltype: CallType.call,
                method_name: 'find_user_canister',
                put_bytes: c_forwards([]),
                caller: this.legatee_caller,
                legations: this.legations,
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
                this.cts_user_canister = CTSUserCanister((find_user_canister_sponse['Ok'] as PrincipalReference).principal!, this);
            }
            else if (find_user_canister_sponse.containsKey('Err')) {
                Variant find_user_canister_sponse_error = find_user_canister_sponse['Err'] as Variant; 
                if (find_user_canister_sponse_error.containsKey('FindUserInTheUsersMapCanistersError')) {
                    Variant find_user_in_the_users_map_canisters_error = find_user_canister_sponse_error['FindUserInTheUsersMapCanistersError'] as Variant;
                    if (find_user_in_the_users_map_canisters_error.containsKey('UserNotFound')) {
                        // leave this.cts_user null, which means the call: find_user_canister is success and the user is not found. let the user purchase a cts-user-canister
                        this.cts_user_canister = null;
                    } else if (find_user_in_the_users_map_canisters_error.containsKey('UsersMapCanistersFindUserCallFails')) {
                        String alert_dialog_content_string = 'Users-Map-Canisters Call-Fails:';
                        for (Record users_map_canister_call_fail in (find_user_canister_sponse_error['UsersMapCanistersFindUserCallFails'] as Vector).cast_vector<Record>()) {
                            alert_dialog_content_string = alert_dialog_content_string+' \n${users_map_canister_call_fail[0]}, error: ${users_map_canister_call_fail[1]}';                   
                        }
                        window.alert('Find CTS User Error:\n${alert_dialog_content_string}');
                        window.location.reload();
                    } else {
                        window.alert('Unknown find_user_in_the_users_map_canisters_error. \n${find_user_in_the_users_map_canisters_error}');
                    }  
                } else if (find_user_canister_sponse_error.containsKey('UserIsInTheNewUsersMap')) {
                    await this.call_new_user();
                } else {
                    window.alert('Unknown find_user_canister_sponse_error. \n${find_user_canister_sponse_error}');
                } 
            } else {
                window.alert('Unknown find_user_canister_sponse. \n${find_user_canister_sponse}');
            }
        } else {
            window.alert('Unknown find_user_canister_sponse candidtype. \n${find_user_canister_cs[0]}');
        }
    
    }






    Future<void> fresh_latest_known_user_icp_ledger_balance() async {
        late Nat64 icp_balance_e8s_nat64;
        try {
            icp_balance_e8s_nat64 = (c_backwards(await ledger.call(
                calltype: CallType.call,
                method_name: 'account_balance',
                put_bytes: c_forwards([
                    Record.oftheMap({
                        'account': Blob(this.user_icp_topup_icp_id)
                    })
                ])
            ))[0] as Record)['e8s'] as Nat64;
        } catch(error) {
            window.alert('user_icp_ledger_balance error: \n${error}');
            window.location.reload(); // ?
        }
        
        this.latest_known_user_icp_ledger_balance = LatestKnownIcpBalance(
            icp_balance_e8s: icp_balance_e8s_nat64.value is BigInt ? icp_balance_e8s_nat64.value : BigInt.from(icp_balance_e8s_nat64.value);
            timestamp_nanos: get_current_time_nanoseconds() //  of the ic-sponse-certificate
        );
    
    }







    
    Future<void> call_new_user() async {
        //call and call till the user_canister.
        // create this.cts_user = CTSUser
        late Variant new_user_sponse;
        try {
            new_user_sponse = c_backwards(
                await cts.call(
                    calltype: CallType.call,
                    method_name: 'new_user',
                    put_bytes: c_forwards([]),
                    caller: this.caller,
                    legations: this.legations
                )
            )[0] as Variant;
        } catch(e) {
            window.alert('call new_user error: ${e}');
            window.location.reload();
        }
        
        if (new_user_sponse.containsKey('Ok') && new_user_sponse['Ok'] is Record) {
            Record new_user_success_data = new_user_sponse['Ok'] as Record;
            if (
                new_user_success_data.containsKey('user_canister') 
                && new_user_success_data['user_canister'] is PrincipalReference 
                && (new_user_success_data['user_canister'] as PrincipalReference).isOpaque == false
            ) {
                this.cts_user_canister = CTSUserCanister((new_user_success_data['user_canister'] as PrincipalReference).principal!, this);
                // fresh cycles balance and icp balance
            }
        } else if (new_user_sponse.containsKey('Err')) {
            Variant new_user_error = new_user_sponse['Err'] as Variant;
            if (new_user_error.containsKey('MidCallError')) {
                print(new_user_error['MidCallError']);
                await this.call_new_user();
            } else {
                window.alert('new_user_error: ${new_user_error}');
            }
        } else {
            window.alert('unknown new_user_sponse: ${new_user_sponse}');
        }
    }



}






class CTSUserCanister extends Canister {

    LatestKnownCyclesBalance? latest_known_cycles_balance;
    LatestKnownIcpBalance? latest_known_icp_balance;

    CTSUserCanister({
        required Principal user_canister_id,
        required User user,
        this.latest_known_cycles_balance,
        this.latest_known_icp_balance,
    }) : super(user_canister_id) {
        
        user_call_f = ({required CallType calltype, required String method_name, Uint8List? put_bytes, Duration timeout_duration = const Duration(minutes: 5)}) {
            return super.call({calltype: calltype, method_name: method_name, put_bytes: put_bytes, caller: user.caller, legations: user.legations, timeout_duration: timeout_duration});
        }
    
    };
    
    late Future<Uint8List> Function({required CallType calltype, required String method_name, Uint8List? put_bytes, Duration timeout_duration = const Duration(minutes: 5)}) user_call_f;
    
    Future<Uint8List> user_call({required CallType calltype, required String method_name, Uint8List? put_bytes, Duration timeout_duration = const Duration(minutes: 5)}) {
        return user_call_f({calltype: calltype, method_name: method_name, put_bytes: put_bytes, timeout_duration: timeout_duration});
    }
    
    
    Future<void> fresh_user_cycles_balance() async {
        try {
            List<CandidType> user_cycles_balance_call_sponse_candids = c_backwards(await this.user_call(
                calltype: CallType.call,
                method_name: 'user_cycles_balance',
                put_bytes: c_forwards([]),
            ));
            // check for variant Err . but now there is no Err on the user_cycles_balance method
            dynamic user_cycles_balance_dyn = ((user_cycles_balance_call_sponse_candids[0] as Variant)['Ok'] as Nat).value;
            BigInt user_cycles_balance = user_cycles_balance_dyn is BigInt ? user_cycles_balance_dyn : BigInt.from(user_cycles_balance_dyn);
            this.latest_known_cycles_balance = LatestKnownCyclesBalance(
                cycles_balance: user_cycles_balance,
                timestamp_nanos: get_current_time_nanoseconds(); // take of the ic-sponse-certificate [?]
            );
        } catch(e) {
            window.alert('see user cycles balance call error:\n${e.toString()}');
        }
    }
    
    Future<void> fresh_user_icp_balance() async {
        try {
            List<CandidType> user_icp_balance_call_sponse_candids = c_backwards(await this.user_call(
                calltype: CallType.call,
                method_name: 'user_icp_balance',
                put_bytes: c_forwards([]),
            ));
            Variant user_icp_balance_call_sponse = user_icp_balance_call_sponse_candids[0] as Variant;
            if (user_icp_balance_call_sponse.containsKey('Ok')) {
                Record icp_tokens = user_icp_balance_call_sponse['Ok'] as Record;
                dynamic user_icp_balance_e8s_dyn = (icp_tokens['e8s'] as Nat64).value;
                BigInt user_icp_balance_e8s = user_icp_balance_e8s_dyn is BigInt ? user_icp_balance_e8s_dyn : BigInt.from(user_icp_balance_e8s_dyn);
                this.latest_known_icp_balance = LatestKnownIcpBalance(
                    icp_balance: user_icp_balance_e8s,
                    timestamp_nanos: get_current_time_nanoseconds(); // take of the ic-sponse-certificate [?]
                );
            } 
            else if user_icp_balance_call_sponse.containsKey('Err') {
                window.alert('see user icp balance error:\n${user_icp_balance_call_sponse['Err']}');
            }
            else {
                window.alert('see user icp balance sponse unknown \n${user_icp_balance_call_sponse}');
            }
        } catch(e) {
            window.alert('see user icp balance call error:\n${e.toString()}');
        }
    
    }
    
    
    
    
    
    
    
    
    
    
    
    
}











