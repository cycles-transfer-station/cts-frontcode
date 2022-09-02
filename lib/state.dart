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
    Nat8,
    Nat32,
    Bool
    ;
import 'package:ic_tools/candid.dart' as candid;

import 'package:ic_tools/common.dart' as common;
import 'package:ic_tools/common_web.dart' show SubtleCryptoECDSAP256Caller;


import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';

import 'indexdb.dart';
import 'urls.dart';
import 'cts.dart';
import 'cycles_market.dart';
import 'user.dart';
import 'cycles_bank.dart';



const String Ok  = 'Ok';
const String Err = 'Err';






class CustomState { // with ChangeNotifier  // do i want change notifier here? false.

    CustomUrl current_url = CustomUrl('welcome');
    
    String loading_text = 'loading ...';
    bool is_loading = true; // state starts loading. the router sets the is_loading=false and calls tifyListeners() on a successfull completion of the load_first_state function. 
    
    
    XDRICPRateWithATimestamp? xdr_icp_rate;
    
    CyclesMarket cycles_market = CyclesMarket(cycles_market.principal);
    
    User? user;
        
    
    
    
    

    Future<void> loadfirststate() async { 
        
        if (IndexDB.is_support_here() != true) {
            window.alert('indexdb not supported. the user is log-out when the page closes.');
        }
        
        
        print('get state of the browser storage');
        await this.get_state_of_the_browser_storage();
        
        print('fresh_xdr_icp_rate');
        await this.fresh_xdr_icp_rate();

        
        if (this.user != null) {
        
            print('fresh_icp_balance');
            await this.user!.fresh_icp_balance();
            
            if (this.user!.cycles_bank == null) {
                print('find_cycles_bank');
                await this.user!.find_cycles_bank();           
            }
        
            
        }
        
        print('save state in the browser_storage');
        await this.save_state_in_the_browser_storage();
    }


    Future<void> fresh_xdr_icp_rate() async {
        // call the cmc
        //query call with the certification-data
        
        Uint8List sponse = await common.cycles_mint.call(
            calltype: CallType.query,
            method_name: 'get_icp_xdr_conversion_rate',
        );
        List<CandidType> cs = c_backwards(sponse);
        Record rc = cs[0] as Record;
        Uint8List certificate_bytes = Blob.oftheVector((rc['certificate'] as Vector).cast_vector<Nat8>()).bytes;
        Map certificate = cbor.cborbytesasadart(certificate_bytes);
        await verify_certificate(certificate);
        dynamic time = lookuppathvalueinaniccertificatetree(certificate['tree'], ['time']);
        BigInt btime = time is int ? BigInt.from(time) : time; //as BigInt
        if (btime < get_current_time_nanoseconds() - BigInt.from(30*1000000000)) { throw Exception('time is too old on the certificate'); }
        Uint8List certified_data = lookuppathvalueinaniccertificatetree(certificate['tree'], ['canister', common.cycles_mint.principal.bytes, 'certified_data']);
        List canister_hash_tree = cbor.cborbytesasadart((rc['hash_tree'] as Blob).bytes);
        Uint8List treeroothash = constructicsystemstatetreeroothash(canister_hash_tree);
        if (!aresamebytes(certified_data, treeroothash)) { throw Exception('certified data doesn\'t match the tree'); }
        Record certified_icpxdrrate = c_backwards(lookuppathvalueinaniccertificatetree(canister_hash_tree, ["ICP_XDR_CONVERSION_RATE"], 'blob'))[0] as Record;
        //Record r = rc['data'] as Record;
        //print(r['xdr_permyriad_per_icp']);
        //print(r['timestamp_seconds']);
        Nat64 certified_xdr_permyriad_per_icp = certified_icpxdrrate['xdr_permyriad_per_icp'] as Nat64;
        Nat64 certified_timestamp_seconds = certified_icpxdrrate['timestamp_seconds'] as Nat64;

        this.xdr_icp_rate = XDRICPRateWithATimestamp(
            xdr_permyriad_per_icp: certified_xdr_permyriad_per_icp.value,
            timestamp_seconds: certified_timestamp_seconds.value 
        );        
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
                            
            User user_of_the_idb = User(
                caller: await SubtleCryptoECDSAP256Caller.of_the_cryptokeys(public_key: user_crypto_key_public, private_key: user_crypto_key_private),
                legations: legations
            );    
            //print(user_of_the_idb.caller);
            if (user_of_the_idb.expiration_unix_timestamp_nanoseconds == null || get_current_time_nanoseconds() < user_of_the_idb.expiration_unix_timestamp_nanoseconds! - BigInt.from(1000000000*60*20) ) {
                this.user = user_of_the_idb;
                //print(this.user!.caller);
            }
            
            
        } catch(e) {
            // no error, let the user log in
            window.console.log('get state of the browser storage idb error: $e');
        }

    }
    
}








typedef Cycles = BigInt; 


class IcpTokens extends Record {
    final BigInt e8s;
    IcpTokens({required this.e8s}) { 
        super['e8s'] = Nat64(this.e8s);
    }
    String toString() {
        String s = this.e8s.toRadixString(10);
        while (s.length < 9) { s = '0$s'; }
        int split_i = s.length - 8;
        s = '${s.substring(0, split_i)}.${s.substring(split_i)}';
        while (s[s.length - 1] == '0' && s.length > 3/*minimum '0.0'*/) { s = s.substring(0, s.length - 1); }
        return s;   
    }
    static IcpTokens oftheRecord(CandidType icptokensrecord) {
        Nat64 e8s_nat64 = (icptokensrecord as Record)['e8s'] as Nat64; 
        return IcpTokens(
            e8s: e8s_nat64.value
        );
    }
    static IcpTokens ofthedouble(double icp) {
        if (check_double_decimal_point_places(icp) > 8) {
            throw Exception('max 8 decimal places for the icp');
        }
        return IcpTokens(
            e8s: BigInt.parse((icp * 100000000.toDouble()).toString().split('.')[0])
        );
    }
}


class CyclesWithATimestamp {
    final Cycles cycles;
    final BigInt timestamp_nanos;
    CyclesWithATimestamp({required this.cycles, BigInt? opt_timestamp_nanos}) : timestamp_nanos = opt_timestamp_nanos==null ? get_current_time_nanoseconds() : opt_timestamp_nanos;
}

class IcpTokensWithATimestamp {
    final IcpTokens icp;
    final BigInt timestamp_nanos;
    IcpTokensWithATimestamp({required this.icp, BigInt? opt_timestamp_nanos}) : timestamp_nanos = opt_timestamp_nanos==null ? get_current_time_nanoseconds() : opt_timestamp_nanos;
}

class XDRICPRateWithATimestamp {
    final BigInt xdr_permyriad_per_icp;
    final BigInt timestamp_seconds;
    XDRICPRateWithATimestamp({required this.xdr_permyriad_per_icp, required this.timestamp_seconds});
}







class CallError {
    final int error_code;
    final String error_message;
    CallError({required this.error_code, required this.error_message});
    
    static CallError oftheRecord(Record r) {
        return CallError(
            error_code: (r[0] as Nat32).value,
            errror_message: (r[1] as candid.Text).value
        );
    }
    
    String toString() {
        return 'error_code: ${this.error_code}, error_message: ${this.error_message}';
    }
}







class CyclesTransferMemo extends Variant {
    CyclesTransferMemo._();
    
    static CyclesTransferMemo blob(Blob blob) {
        CyclesTransferMemo ctm = CyclesTransferMemo._();
        ctm['Blob'] = blob;
        return ctm;
    }
    static CyclesTransferMemo text(candid.Text text) {
        CyclesTransferMemo ctm = CyclesTransferMemo._();
        ctm['Text'] = text;
        return ctm;
    }
    static CyclesTransferMemo nat(Nat nat) {
        CyclesTransferMemo ctm = CyclesTransferMemo._();
        ctm['Nat'] = nat;
        return ctm;
    }
    static CyclesTransferMemo oftheVariant(Variant ctmvariant) {
        match_variant<void>(ctmvariant, {
            'Blob': (c) { if (c is! Blob) { throw Exception('CyclesTransferMemo Blob must be with the value of the Blob.'); } },
            'Text': (c) { if (c is! candid.Text) { throw Exception('CyclesTransferMemo Text must be with the value of the Text.'); } },
            'Nat': (c) { if (c is! Nat) { throw Exception('CyclesTransferMemo Nat must be with the value of the Nat.'); } }
        });
        CyclesTransferMemo ctm = CyclesTransferMemo._();
        ctm[ctmvariant.keys.first] = ctmvariant.values.first;
        return ctm;
    }
    
}














// ------------------------------------------------------------

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















































