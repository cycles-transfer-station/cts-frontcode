import 'dart:typed_data';
import 'dart:convert';
import 'dart:html' show window, CryptoKey, Event;
import 'dart:indexed_db';
import 'dart:js';
import 'package:js/js.dart';
import 'package:js/js_util.dart';


import 'package:ic_tools/ic_tools.dart';
import 'package:ic_tools/tools.dart';
import 'package:ic_tools/candid.dart' show
    c_backwards,
    c_forwards,
    CandidType,
    Nat,
    Nat64,
    Option,
    Vector,
    Blob,
    Record,
    Variant,
    PrincipalReference
;
import 'package:ic_tools/common.dart' as common;
import 'package:ic_tools/common_web.dart' show SubtleCryptoECDSAP256Caller;


import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';

import 'urls.dart';
import './cts.dart';






class CustomState { // with ChangeNotifier  // do i want change notifier here? false.

    CustomUrl current_url = CustomUrl('welcome');
    
    String loading_text = 'loading ...';
    bool is_loading = true; // state starts loading. in the load_first_state function, the state sets is_loading = false and then completes and the router calls tifyListeners 
    
    
    
    User? user;
        
    LatestKnownXDRICPRate? latest_known_xdr_icp_rate;
    
    
    
    
    

    Future<Exception?> loadfirststate() async {
    
        /*TEST*/
        /*
        SubtleCryptoECDSAP256Caller test_caller = await SubtleCryptoECDSAP256Caller.new_keys(); 
        
        print(c_backwards(await cts.call(
            calltype: CallType.call,
            method_name: 'see_caller',
            caller: test_caller
        )));
        
        Uint8List test_message = Uint8List.fromList([1,2,3]);
        print(await SubtleCryptoECDSAP256Caller.verify(
            message: test_message,
            signature: await test_caller.private_key_authorize_function(test_message),
            public_key_DER: test_caller.public_key_DER
        ));
        */
        
        
        //SubtleCryptoECDSAP256Caller test_caller = await SubtleCryptoECDSAP256Caller.new_keys(); 
        //print(test_caller);
        
       
        

        
         
        /*
        Uint8List public_key_DER = (await promiseToFuture(callMethod(window.crypto!.subtle!, 'exportKey', ['spki', public_key]))).asUint8List();
        
        test_caller = SubtleCryptoECDSAP256Caller(
            public_key_DER: public_key_DER, 
            private_key: private_key, 
            public_key: public_key
        );
        
        print(test_caller);        
        */
        
      
      
      
        // --------------------------------------
      
        
        if (IndexDB.is_support_here() != true) {
            window.alert('indexdb not supported. the user is log-out when the page closes.');
        }
        
        
        
        print('get state of the browser storage');
        await this.get_state_of_the_browser_storage();
        
        if (this.user != null) {
                
            if (this.user!.cts_user_canister == null) {
                print('find cts user canister');
                Exception? find_cts_user_canister_possible_error = await this.user!.find_cts_user_canister();
                if (find_cts_user_canister_possible_error != null) {
                    return find_cts_user_canister_possible_error;
                }
                
                // if UserNotFound
                if (this.user!.cts_user_canister == null) {
                    print('fresh_latest_known_user_icp_ledger_balance');
                    Exception? fresh_latest_known_user_icp_ledger_balance_possible_error = await this.user!.fresh_latest_known_user_icp_ledger_balance();
                    if (fresh_latest_known_user_icp_ledger_balance_possible_error != null) {
                        return fresh_latest_known_user_icp_ledger_balance_possible_error; 
                    }
                    
                    print('fresh_latest_known_xdr_icp_rate');
                    Exception? fresh_latest_known_xdr_icp_rate_possible_error = await this.fresh_latest_known_xdr_icp_rate();
                    if (fresh_latest_known_xdr_icp_rate_possible_error != null) {
                        return fresh_latest_known_xdr_icp_rate_possible_error;
                    }
                }
                
            }
        
            
        }
        
        print('save state in the browser_storage');
        await this.save_state_in_the_browser_storage();
    }


    Future<Exception?> fresh_latest_known_xdr_icp_rate() async {
        // call the cmc
        //query call with the certification-data
    }


    Future<void> save_state_in_the_browser_storage() async {
    
        if (this.user != null) {
            List<Map> legations_maps = [];
            for (Legation legation in this.user!.legations) {
                legations_maps.add(
                    {
                        'legatee_public_key_DER': legation.legatee_public_key_DER,
                        'expiration_unix_timestamp_nanoseconds': legation.expiration_unix_timestamp_nanoseconds.toRadixString(10),
                        'target_canisters_ids': legation.target_canisters_ids != null ? legation.target_canisters_ids!.map<String>((Principal p)=>p.text).toList() : null,  
                        'legator_public_key_DER': legation.legator_public_key_DER,
                        'legator_signature': legation.legator_signature 
                    }
                );
            }
            
            Map user_map = {
                'crypto_key_public': await this.user!.caller.public_key,
                'crypto_key_private': this.user!.caller.private_key,
                'legations': legations_maps
            };
            
            UserMapIDB user_map_js = UserMapIDB(
                crypto_key_public: await this.user!.caller.public_key,
                crypto_key_private: this.user!.caller.private_key,
                legations: JsArray.from(legations_maps.map<JsObject>((Map legation_map)=>JsObject.jsify(legation_map))), 
            ); 
            
            
            try {
                IndexDB idb = await IndexDB.open('cts', ['state']);
                if (
                    await idb.add_object(
                        object_store_name: 'state', 
                        key: 'user_crypto_key_public', 
                        value: await this.user!.caller.public_key,
                        
                    ) == false
                ) {
                    await idb.put_object(
                        object_store_name: 'state', 
                        key: 'user_crypto_key_public', 
                        value: await this.user!.caller.public_key
                    );  
                }                
                if (
                    await idb.add_object(
                        object_store_name: 'state', 
                        key: 'user_crypto_key_private', 
                        value: this.user!.caller.private_key
                    ) == false
                ) {
                    await idb.put_object(
                        object_store_name: 'state', 
                        key: 'user_crypto_key_private', 
                        value: this.user!.caller.private_key
                    );  
                }                
                if (
                    await idb.add_object(
                        object_store_name: 'state', 
                        key: 'user_legations', 
                        value: this.user!.legations.map<JSLegation>((Legation l)=>JSLegation.ofaLegation(l)).toList(), 
                    ) == false
                ) {
                    await idb.put_object(
                        object_store_name: 'state', 
                        key: 'user_legations', 
                        value: this.user!.legations.map<JSLegation>((Legation l)=>JSLegation.ofaLegation(l)).toList(), 
                    );  
                }                
                
                idb.shutdown();
            } catch(e) {
                window.alert('idb error saving the user state: ${e}');                        
            }
        }
        
               
    }
    
    
    Future<void> get_state_of_the_browser_storage() async {
    
        try {
            IndexDB idb = await IndexDB.open('cts', ['state']);
            //print(idb.object_store_names());
            
            // user
            CryptoKey user_crypto_key_public = await idb.get_object(
                object_store_name: 'state', 
                key: 'user_crypto_key_public'
            ) as CryptoKey;
            
            CryptoKey user_crypto_key_private = await idb.get_object(
                object_store_name: 'state', 
                key: 'user_crypto_key_private'
            ) as CryptoKey;

            List<Legation> legations = (await idb.get_object(
                object_store_name: 'state', 
                key: 'user_legations'
            ) as List<dynamic>).cast<JSLegation>().map<Legation>((JSLegation jslegation)=>JSLegation.asaLegation(jslegation)).toList(); 

            idb.shutdown();
            
            //prException?int(legations.length);

            //if (possible_o != null) {
                //JsObject user_map = JsObject.fromBrowserObject(possible_o!);                      
            User user_of_the_idb = User(
                caller: await SubtleCryptoECDSAP256Caller.of_the_cryptokeys(public_key: user_crypto_key_public, private_key: user_crypto_key_private),
                legations: legations
                /*
                legations_maps.map<Legation>(
                    (legation_map){
                        return Legation(
                            legatee_public_key_DER: legation_map['legatee_public_key_DER'],
                            expiration_unix_timestamp_nanoseconds: BigInt.parse(legation_map['expiration_unix_timestamp_nanoseconds'], radix: 10),
                            target_canisters_ids: legation_map['target_canisters_ids'] != null ? legation_map['target_canisters_ids'].map<Principal>((String ps)=>Principal(ps)).toList() : null,  
                            legator_public_key_DER: legation_map['legator_public_key_DER'],
                            legator_signature: legation_map['legator_signature'], 
                        );
                    }
                ).toList() 
                */
            );    
            //print(user_of_the_idb.caller);
            if (user_of_the_idb.expiration_unix_timestamp_nanoseconds == null || get_current_time_nanoseconds() < user_of_the_idb.expiration_unix_timestamp_nanoseconds! - BigInt.from(1000000000*60*20) ) {
                this.user = user_of_the_idb;
                //print(this.user!.caller);
            }
//            }
            
            
            
        } catch(e) {
            // no error, let the user log in
            window.console.log(e);
        }

    }
    
}






@JS()
@anonymous
class UserMapIDB {
    external CryptoKey get crypto_key_public;
    external CryptoKey get crypto_key_private;
    external List<Map> get legations; 
    
    external factory UserMapIDB({
        CryptoKey crypto_key_public,
        CryptoKey crypto_key_private,
        JsArray<JsObject> legations, 
    }); 
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
    
    String icp_balance_string() {
        String s = this.icp_balance_e8s.toRadixString(10);
        while (s.length < 9) { s = '0$s'; }
        int split_i = s.length - 8;
        s = '${s.substring(0, split_i)}.${s.substring(split_i)}';
        while (s[s.length - 1] == '0' && s.length > 3/*minimum '0.0'*/) { s = s.substring(0, s.length - 1); }
        return s;   
    }
}


class LatestKnownXDRICPRate {
    BigInt xdr_permyriad_per_icp;
    BigInt timestamp_nanos;
    LatestKnownXDRICPRate({required this.xdr_permyriad_per_icp, required this.timestamp_nanos});
}






class User {
    final SubtleCryptoECDSAP256Caller caller;
    final List<Legation> legations;
    
    late final Uint8List user_topup_balance_subaccount_bytes;
    late final Uint8List user_topup_icp_id;
    
    Uint8List get public_key_DER => legations.length >= 1 ? legations[0].legator_public_key_DER : caller.public_key_DER;
    Principal get principal => Principal.ofthePublicKeyDER(this.public_key_DER);
    
    CTSUserCanister? cts_user_canister;
    
    LatestKnownIcpBalance? latest_known_user_icp_ledger_balance;
    
    User({
        required this.caller,
        required this.legations,        
        this.cts_user_canister,
        this.latest_known_user_icp_ledger_balance,
    }) {
        user_topup_balance_subaccount_bytes = User.get_user_subaccount_bytes(this.principal);
        user_topup_icp_id = hexstringasthebytes(cts.principal.icp_id(subaccount_bytes: user_topup_balance_subaccount_bytes));
    }

    
    static Uint8List get_user_subaccount_bytes(Principal user_principal) { 
        Uint8List user_subaccount_bytes = Uint8List.fromList([ ...utf8.encode('UT'), user_principal.bytes.length, ...user_principal.bytes ]);
        while (user_subaccount_bytes.length < 32) { user_subaccount_bytes.add(0); }
        if (user_subaccount_bytes.length != 32) { throw Exception('wrong user subaccount length'); }
        return user_subaccount_bytes;
    }
    
    
    BigInt? get expiration_unix_timestamp_nanoseconds => this.legations.isNotEmpty ? this.legations.first.expiration_unix_timestamp_nanoseconds : null;
    
    
    Future<Exception?> find_cts_user_canister() async {

        late List<CandidType> find_user_canister_cs;
        try {
            find_user_canister_cs = c_backwards(await cts.call(
                calltype: CallType.call,
                method_name: 'find_user_canister',
                put_bytes: c_forwards([]),
                caller: this.caller,
                legations: this.legations,
            ));
        } catch(e) {
            return Exception('Find CTS User Call Error:\n${e.toString()}');
        }
        if (find_user_canister_cs[0] is Variant) {
            Variant find_user_canister_sponse = find_user_canister_cs[0] as Variant;
            if (find_user_canister_sponse.containsKey('Ok')) {
                Option opt_user_canister_id = find_user_canister_sponse['Ok'] as Option;
                if (opt_user_canister_id.value != null) {
                    this.cts_user_canister = CTSUserCanister((opt_user_canister_id.value as PrincipalReference).principal!, this);
                } else {
                    // set this.cts_user = null, which means the call: find_user_canister is success and the user is not found. let the user purchase a cts-user-canister
                    this.cts_user_canister = null;
                }
            }
            else if (find_user_canister_sponse.containsKey('Err')) {
                Variant find_user_canister_sponse_error = find_user_canister_sponse['Err'] as Variant; 
                if (find_user_canister_sponse_error.containsKey('FindUserInTheUsersMapCanistersError')) {
                    Variant find_user_in_the_users_map_canisters_error = find_user_canister_sponse_error['FindUserInTheUsersMapCanistersError'] as Variant;
                    if (find_user_in_the_users_map_canisters_error.containsKey('UsersMapCanistersFindUserCallFails')) {
                        String alert_dialog_content_string = 'Users-Map-Canisters Call-Fails:';
                        for (Record users_map_canister_call_fail in (find_user_canister_sponse_error['UsersMapCanistersFindUserCallFails'] as Vector).cast_vector<Record>()) {
                            alert_dialog_content_string = alert_dialog_content_string+' \n${users_map_canister_call_fail[0]}, error: ${users_map_canister_call_fail[1]}';                   
                        }
                        return Exception('Find CTS User Error:\n${alert_dialog_content_string}');
                    } else {
                        return Exception('Unknown find_user_in_the_users_map_canisters_error. \n${find_user_in_the_users_map_canisters_error}');
                    }  
                } else if (find_user_canister_sponse_error.containsKey('UserIsInTheNewUsersMap')) {
                    await this.call_new_user();
                } else {
                    return Exception('Unknown find_user_canister_sponse_error. \n${find_user_canister_sponse_error}');
                } 
            } else {
                return Exception('Unknown find_user_canister_sponse. \n${find_user_canister_sponse}');
            }
        } else {
            return Exception('Unknown find_user_canister_sponse candidtype. \n${find_user_canister_cs[0]}');
        }
    
    }






    Future<Exception?> fresh_latest_known_user_icp_ledger_balance() async {
        late Nat64 icp_balance_e8s_nat64;
        try {
            icp_balance_e8s_nat64 = (c_backwards(await common.ledger.call(
                calltype: CallType.call,
                method_name: 'account_balance',
                put_bytes: c_forwards([
                    Record.oftheMap({
                        'account': Blob(this.user_topup_icp_id)
                    })
                ])
            ))[0] as Record)['e8s'] as Nat64;
        } catch(error) {
            return Exception('fresh user icp ledger balance error: \n${error}');
        }
        
        this.latest_known_user_icp_ledger_balance = LatestKnownIcpBalance(
            icp_balance_e8s: icp_balance_e8s_nat64.value is BigInt ? icp_balance_e8s_nat64.value : BigInt.from(icp_balance_e8s_nat64.value),
            timestamp_nanos: get_current_time_nanoseconds() //  of the ic-sponse-certificate
        );
    
    }







    
    Future<Exception?> call_new_user() async {
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
            return Exception('call new_user error: ${e}');
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
                if (new_user_error.containsKey('FoundUserCanister')) { 
                    this.cts_user_canister = CTSUserCanister((new_user_error['FoundUserCanister'] as PrincipalReference).principal!, this);
                } else {
                    return Exception('new_user_error: ${new_user_error}');
                }
            }
        } else {
            return Exception('unknown new_user_sponse: ${new_user_sponse}');
        }
    }






}






class CTSUserCanister extends Canister {

    LatestKnownCyclesBalance? latest_known_cycles_balance;
    LatestKnownIcpBalance? latest_known_icp_balance;

    CTSUserCanister(
        Principal user_canister_id,
        User user,
        {
            this.latest_known_cycles_balance,
            this.latest_known_icp_balance,
    }) : super(user_canister_id) {
        
        user_call_f = ({required CallType calltype, required String method_name, Uint8List? put_bytes, Duration timeout_duration = const Duration(minutes: 5)}) {
            return super.call(calltype: calltype, method_name: method_name, put_bytes: put_bytes, caller: user.caller, legations: user.legations, timeout_duration: timeout_duration);
        };
    
    }
    
    late Future<Uint8List> Function({required CallType calltype, required String method_name, Uint8List? put_bytes, Duration timeout_duration}) user_call_f;
    
    Future<Uint8List> user_call({required CallType calltype, required String method_name, Uint8List? put_bytes, Duration timeout_duration = const Duration(minutes: 5)}) {
        return user_call_f(calltype: calltype, method_name: method_name, put_bytes: put_bytes, timeout_duration: timeout_duration);
    }
    
    
    Future<Exception?> fresh_user_cycles_balance() async {
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
                timestamp_nanos: get_current_time_nanoseconds() // take of the ic-sponse-certificate [?]
            );
        } catch(e) {
            return Exception('see user cycles balance call error:\n${e.toString()}');
        }
    }
    
    Future<Exception?> fresh_user_icp_balance() async {
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
                    icp_balance_e8s: user_icp_balance_e8s,
                    timestamp_nanos: get_current_time_nanoseconds() // take of the ic-sponse-certificate [?]
                );
            } 
            else if (user_icp_balance_call_sponse.containsKey('Err')) {
                return Exception('see user icp balance error:\n${user_icp_balance_call_sponse['Err']}');
            }
            else {
                return Exception('see user icp balance sponse unknown \n${user_icp_balance_call_sponse}');
            }
        } catch(e) {
            return Exception('see user icp balance call error:\n${e.toString()}');
        }
    
    }
    
    
    
    
    
    
    
    
    
    
    
    
}





//'cts_user_subtlecrypto_caller'

class IndexDB {
    
    static bool is_support_here() => window.indexedDB != null;
    
    final String name;
    Object idb_open_db_quest; // save the q bc it needs to stay 
    Object/*IDBDatabase*/ idb_database;
    
    
    
    IndexDB({required this.name, required this.idb_database, required this.idb_open_db_quest});
    
    static Future<IndexDB> open(String db_name, List<String> object_stores_names) async {
        var/*IDBOpenDBRequest*/ q = callMethod(window.indexedDB!, 'open', [db_name, 1]);
        late Object/*IDBDatabase*/ idb_database;
        
        setProperty(q, 
            'onupgradeneeded',
            allowInterop((event) {
                window.console.log('upgradeneeded');
                idb_database = getProperty(getProperty(event, 'target'), 'result');
                callMethod(idb_database, 'addEventListener', [
                    'error',
                    allowInterop((Event event) {
                        window.console.log(event);
                        window.alert('idb error');  
                    })  
                ]);
                for (String object_store_name in object_stores_names) {
                    Object/*IDBObjectStore.)*/ idb_object_store = callMethod(idb_database, 'createObjectStore', [ object_store_name ]);
                }
            })
        );
        
        bool onsuccessorerror = false;
        setProperty(q, 
            'onsuccess',
            allowInterop((event) {
                idb_database = getProperty(q, 'result');
                onsuccessorerror = true;
                
            })
        );
        setProperty(q, 
            'onerror',
            allowInterop((event) {
                onsuccessorerror = true;
            })
        );
        
        // poll the result
        while (onsuccessorerror == false || getProperty(q, 'readyState') == 'pending') {
            await Future.delayed(Duration(milliseconds: 300));
        }        
        if (getProperty(q, 'readyState') != 'done') { throw Exception('unknown idb open request readyState'); }
        
        if (getProperty(q, 'error') == null) {
            return IndexDB(
                name: db_name, 
                idb_database: idb_database, 
                idb_open_db_quest: q,
            );
        } else {
            throw getProperty(q, 'error');
            //throw Exception('idb open request error');
        }
    
    }    
    
    
    List<String> object_store_names() {
        return getProperty(this.idb_database, 'objectStoreNames');
    }
    
    
    
    Future<dynamic> get_object({required String object_store_name, required String key}) async {
        Object/*IDBTransaction)*/ transaction = callMethod(this.idb_database, 'transaction', [
            [object_store_name], 
            'readonly'/*'readwrite'*/, 
            IDBDatabaseTransactionOptions(durability: 'strict')
        ]);
        
        callMethod(transaction, 'addEventListener', [
            'complete',
            allowInterop((Event event) {

            })
        ]);
        
        Object/*IDBObjectStore*/ object_store = callMethod(transaction, 'objectStore', [object_store_name]);
        
        Object/*IDBRequest*/ idb_quest_object_store_open_cursor = callMethod(object_store, 'openCursor', []);
        late Object?/*IDBCursorWithValue*/ object_store_cursor_with_value; 
        
        bool onsuccess_cursor_complete_orerror = false;
        Object? value;
        setProperty(idb_quest_object_store_open_cursor, 
            'onsuccess',
            allowInterop((event) {
                object_store_cursor_with_value = getProperty(getProperty(event, 'target'), 'result');
                if (object_store_cursor_with_value != null) {
                    if (getProperty(object_store_cursor_with_value!, 'key') == key) {
                        value = getProperty(object_store_cursor_with_value!, 'value');
                        onsuccess_cursor_complete_orerror = true;
                    } else {
                        callMethod(object_store_cursor_with_value!, 'continue', []); // continue must be call within the onsuccess handler before any awaits
                    }
                } else {
                    onsuccess_cursor_complete_orerror = true;
                }
            })
        );
        setProperty(idb_quest_object_store_open_cursor, 
            'onerror',
            allowInterop((event) {
                onsuccess_cursor_complete_orerror = true;
            })
        );
        
        while (onsuccess_cursor_complete_orerror == false || getProperty(idb_quest_object_store_open_cursor, 'readyState') == 'pending') {
            await Future.delayed(Duration(milliseconds: 300));
        }
        if (getProperty(idb_quest_object_store_open_cursor, 'error') == null) {
            return value;
        } else {
            throw getProperty(idb_quest_object_store_open_cursor, 'error');
        }
        
    }
    
    
    // returns true if the object-add is success and false if the key is already in the object_store. use put to update a key.
    Future<bool> add_object({required String object_store_name, required String key, required Object value}) async {
        Object/*IDBTransaction)*/ transaction = callMethod(this.idb_database, 'transaction', [
            [object_store_name], 
            'readonly', // here to check if the key is already in the object_store
            IDBDatabaseTransactionOptions(durability: 'strict')
        ]);
        
        Object/*IDBObjectStore*/ object_store = callMethod(transaction, 'objectStore', [object_store_name]);
        
        Object/*IDBRequest*/ idb_quest_object_store_open_cursor = callMethod(object_store, 'openCursor', []);
        
        late Object?/*can be null if 0 objects*//*IDBCursorWithValue*/ object_store_cursor_with_value; 
        
        bool onsuccess_cursor_complete_orerror = false;
        bool is_key_in_the_object_store = false;
        setProperty(idb_quest_object_store_open_cursor, 
            'onsuccess',
            allowInterop((event) {
                object_store_cursor_with_value = getProperty(getProperty(event, 'target'), 'result');
                if (object_store_cursor_with_value != null) {
                    if (getProperty(object_store_cursor_with_value!, 'key') == key) {
                        is_key_in_the_object_store = true;
                        onsuccess_cursor_complete_orerror = true;
                    } else {
                        callMethod(object_store_cursor_with_value!, 'continue', []); // continue must be call within the onsuccess handler before any awaits
                    }
                } else {
                    onsuccess_cursor_complete_orerror = true;
                }
            })
        );
        setProperty(idb_quest_object_store_open_cursor, 
            'onerror',
            allowInterop((event) {
                onsuccess_cursor_complete_orerror = true;
            })
        );
        
        while (onsuccess_cursor_complete_orerror == false || getProperty(idb_quest_object_store_open_cursor, 'readyState') == 'pending') {
            await Future.delayed(Duration(milliseconds: 300));
        }
        
        if (getProperty(idb_quest_object_store_open_cursor, 'error') == null) {
            if (is_key_in_the_object_store == true) {
                return false;
            }
        } else {
            throw getProperty(idb_quest_object_store_open_cursor, 'error');

        }

        
        Object/*IDBTransaction)*/ transaction2 = callMethod(this.idb_database, 'transaction', [
            [object_store_name], 
            'readwrite', 
            IDBDatabaseTransactionOptions(durability: 'strict')
        ]);
        
        Object/*IDBObjectStore*/ object_store2 = callMethod(transaction2, 'objectStore', [object_store_name]);
        
        bool transaction_complete = false;
        callMethod(transaction2, 'addEventListener', [
            'complete',
            allowInterop((event) {
                transaction_complete = true;
            })
        ]);
        
        Object/*IDBRequest*/ idb_quest_object_store_add = callMethod(object_store2, 'add', [value, key]);

        while (getProperty(idb_quest_object_store_add, 'readyState') == 'pending') {
            await Future.delayed(Duration(milliseconds: 300));
        }
        if (getProperty(idb_quest_object_store_add, 'error') == null) {
            // the add in the queue now wait for the complete
            while (transaction_complete == false) { await Future.delayed(Duration(milliseconds: 300)); }
            return true;
        } else {
            throw getProperty(idb_quest_object_store_add, 'error');
        }
        
        
    }
    
    
    // returns true if the object-put/update is success and false if the key is not found in the object_store. use add to add a new key.
    Future<bool> put_object({required String object_store_name, required String key, required Object value}) async {
        Object/*IDBTransaction)*/ transaction = callMethod(this.idb_database, 'transaction', [
            [object_store_name], 
            'readwrite', 
            IDBDatabaseTransactionOptions(durability: 'strict')
        ]);
        
        Object/*IDBObjectStore*/ object_store = callMethod(transaction, 'objectStore', [object_store_name]);
        
        Object/*IDBRequest*/ idb_quest_object_store_open_cursor = callMethod(object_store, 'openCursor', []);
        late Object?/*IDBCursorWithValue*/ object_store_cursor_with_value; 
        
        bool onsuccess_cursor_complete_orerror = false;
        bool is_key_in_the_object_store = false;
        setProperty(idb_quest_object_store_open_cursor, 
            'onsuccess',
            allowInterop((event) async {
                object_store_cursor_with_value = getProperty(getProperty(event, 'target'), 'result');
                if (object_store_cursor_with_value != null) {
                    if (getProperty(object_store_cursor_with_value!, 'key') == key) {
                        // update
                        Object/*IDBRequest*/ idb_quest_update = callMethod(object_store_cursor_with_value!, 'update', [value]);
                        // await here is ok bc we call cursor.update before this await and we wont call cursor.continue after this
                        while (getProperty(idb_quest_update, 'readyState') == 'pending') { await Future.delayed(Duration(milliseconds: 300)); } 
                        if (getProperty(idb_quest_update, 'error') == null) {
                            is_key_in_the_object_store = true;
                            onsuccess_cursor_complete_orerror = true;
                        } else {
                            throw getProperty(idb_quest_update, 'error');
                        }
                    } else {
                        callMethod(object_store_cursor_with_value!, 'continue', []); // continue must be call within the onsuccess handler before any awaits
                    }
                } else {
                    onsuccess_cursor_complete_orerror = true;
                }
            })
        );
        setProperty(idb_quest_object_store_open_cursor, 
            'onerror',
            allowInterop((event) {
                onsuccess_cursor_complete_orerror = true;
            })
        );
        
        while (onsuccess_cursor_complete_orerror == false || getProperty(idb_quest_object_store_open_cursor, 'readyState') == 'pending') {
            await Future.delayed(Duration(milliseconds: 300));
        }
        if (getProperty(idb_quest_object_store_open_cursor, 'error') == null) {
            if (is_key_in_the_object_store == true) {
                return true;
            } else {
                return false;
            }
        } else {
            throw getProperty(idb_quest_object_store_open_cursor, 'error');
        }
        
        
    }
    
    
    void shutdown() {
        callMethod(this.idb_database, 'close', []);
    }
    

}




@JS()
@anonymous
class IDBDatabaseTransactionOptions  {
    external String get durability;
    
    external factory IDBDatabaseTransactionOptions({
        String durability
    });
}


@JS()
@anonymous
class JSLegation  {
    external Uint8List get legatee_public_key_DER;
    external String get expiration_unix_timestamp_nanoseconds;
    external List<String>? get target_canisters_ids;  
    external Uint8List get legator_public_key_DER;
    external Uint8List get legator_signature; 
    
    external factory JSLegation({
        Uint8List legatee_public_key_DER,
        String expiration_unix_timestamp_nanoseconds,
        List<String>? target_canisters_ids,
        Uint8List legator_public_key_DER,
        Uint8List legator_signature,
        
    });
    
    
    static JSLegation ofaLegation(Legation legation) {
        return JSLegation(
            legatee_public_key_DER: legation.legatee_public_key_DER,
            expiration_unix_timestamp_nanoseconds: legation.expiration_unix_timestamp_nanoseconds.toRadixString(10),
            target_canisters_ids: legation.target_canisters_ids != null ? legation.target_canisters_ids!.map<String>((Principal p)=>p.text).toList() : null,
            legator_public_key_DER: legation.legator_public_key_DER,
            legator_signature: legation.legator_signature, 
        );
    }
    
    static Legation asaLegation(JSLegation jslegation) {
        return Legation(
            legatee_public_key_DER: jslegation.legatee_public_key_DER,
            expiration_unix_timestamp_nanoseconds: BigInt.parse(jslegation.expiration_unix_timestamp_nanoseconds, radix:10),
            target_canisters_ids: jslegation.target_canisters_ids != null ? jslegation.target_canisters_ids!.map<Principal>((String ps)=>Principal(ps)).toList() : null,
            legator_public_key_DER: jslegation.legator_public_key_DER,
            legator_signature: jslegation.legator_signature, 
        );
    }
}















































