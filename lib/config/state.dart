import 'dart:typed_data';
import 'dart:convert';
import 'dart:math';
import 'dart:html' show window, CryptoKey, Event;
import 'dart:js_util';


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
    Bool,
    match_variant,
    candid_text_hash
    ;
import 'package:ic_tools/candid.dart' as candid;
import 'package:ic_tools/common.dart' show IcpTokens;
import 'package:ic_tools/common.dart' as common;
import 'package:ic_tools/common_web.dart' show SubtleCryptoECDSAP256Caller;


import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';

import '../tools/indexdb.dart';
import 'urls.dart';
import '../cycles_market/cycles_market_data.dart';
import '../user.dart';
import '../cycles_bank/cycles_bank.dart';
import '../transfer_icp/icp_ledger.dart';
import '../tests/test.dart' as t;

const String Ok  = 'Ok';
const String Err = 'Err';



late final Canister cts;
late final Canister cycles_market;



late final String cts_main_icp_id;




class CustomState { // with ChangeNotifier  // do i want change notifier here? false.

    CustomState() {
    
        if (window.location.hostname!.contains('thp4z-laaaa-aaaam-qaaea-cai') || window.location.hostname!.contains('cycles-transfer-station.com')) {
            cts = Canister(Principal('thp4z-laaaa-aaaam-qaaea-cai')); 
            cycles_market = Canister(Principal('woddh-aqaaa-aaaal-aazqq-cai'));
        }

        if (window.location.hostname!.contains('bayhi-') || window.location.hostname!.contains('localhost') || window.location.hostname!.contains('127.0.0.1')) {
            cts = Canister(Principal('bayhi-7yaaa-aaaai-qahca-cai'));
            cycles_market = Canister(Principal('mscqy-haaaa-aaaai-aahhq-cai'));
        }
        
        cts_main_icp_id = common.icp_id(cts.principal);
        
        if (cts.principal.text != 'thp4z-laaaa-aaaam-qaaea-cai') {
            print('WARNING! Using the canister: ${cts.principal.text} as the CTS-MAIN. ');
        }
        
    }

    CustomUrl current_url = CustomUrl('welcome');
    
    String loading_text = 'loading ...';
    bool is_loading = true; // state starts loading. the router sets the is_loading=false and calls tifyListeners() on a successfull completion of the load_first_state function. 
    
    
    
    late BuildContext _scontext; 
    
    void set context(BuildContext c) { this._scontext = c; }
    BuildContext get context => this._scontext;
    
    
    late CTSFees cts_fees;
    
    XDRICPRateWithATimestamp? xdr_icp_rate_with_a_timestamp;
    
    CyclesMarketData cycles_market_data = CyclesMarketData();
    
    User? user;
        
    
    
    
    

    Future<void> loadfirststate() async { 
        //await t.m();
        
        
        if (IndexDB.is_support_here() != true) {
            window.alert('indexdb not supported. the user is log-out when the page closes.');
        }
        
        
        print('load cts_fees');
        print('fresh_xdr_icp_rate');
        print('load cycles-market-data');

        await Future.wait([
            this.load_cts_fees(),
            this.fresh_xdr_icp_rate(),
            this.cycles_market_data.load_data(),
            Future(()async{ 
                print('load state of the browser storage');
                await this.load_state_of_the_browser_storage();
                if (this.user != null) {
                    
                    print('user fresh_icp_balance');
                    
                    await Future.wait([
                        this.user!.fresh_icp_balance(),
                        Future(()async{
                            if (this.user!.cycles_bank == null) {
                                print('user find_cycles_bank');
                                await this.user!.find_cycles_bank();
                            }
                            
                            print('save state in the browser_storage');
                            this.save_state_in_the_browser_storage().then((x){});
                            
                            if (this.user!.cycles_bank != null) {
                                try {
                                    print('loading cycles-bank-metrics');
                                    // await this before reading the cb-logs
                                    await this.user!.cycles_bank!.fresh_metrics();
                    
                                    print('loading cycles-transfers-in-out, and cm-data');
                                    await Future.wait([
                                        this.user!.cycles_bank!.fresh_cycles_transfers_out(),
                                        this.user!.cycles_bank!.fresh_cycles_transfers_in(),
                                        this.user!.cycles_bank!.load_cm_data(),
                                    ]);
                                
                                } catch(e) {
                                    print('cycles-bank load metrics, cycles-transfers-in-out, and cm-data error: ${e}');
                                }
                            }        
                        }),
                    ]);
                } 
            }),
        ]);
                
    }



    Future<void> load_cts_fees() async {
        Record cts_fees_record = c_backwards(
            await cts.call(
                method_name: 'see_fees',
                calltype: CallType.query,
                put_bytes: c_forwards([])
            )
        ).first as Record;
        this.cts_fees = CTSFees.oftheRecord(cts_fees_record);
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

        this.xdr_icp_rate_with_a_timestamp = XDRICPRateWithATimestamp(
            xdr_icp_rate: XDRICPRate.oftheXdrPerMyriadPerIcpNat64(certified_xdr_permyriad_per_icp),
            timestamp_seconds: certified_timestamp_seconds.value 
        );        
    }


    Future<void> save_state_in_the_browser_storage() async {
    
        if (this.user != null) {
            
            /*
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
            */
            
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
                        value: this.user!.legations.map<JSLegation>((Legation l)=>jslegation_of_a_legation(l)).toList(), 
                    ) == false
                ) {
                    await idb.put_object(
                        object_store_name: 'state', 
                        key: 'user_legations', 
                        value: this.user!.legations.map<JSLegation>((Legation l)=>jslegation_of_a_legation(l)).toList(), 
                    );  
                }       
                
                if (this.user!.cycles_bank != null) {
                    if (
                        await idb.add_object(
                            object_store_name: 'state', 
                            key: 'user_cycles_bank', 
                            value: '${this.user!.principal.text}:${this.user!.cycles_bank!.principal.text}', 
                        ) == false
                    ) {
                        await idb.put_object(
                            object_store_name: 'state', 
                            key: 'user_cycles_bank', 
                            value: '${this.user!.principal.text}:${this.user!.cycles_bank!.principal.text}', 
                        );  
                    }                
                }
                
                idb.shutdown();
            } catch(e) {
                window.alert('idb error saving the user state: ${e}');                        
            }
        }
        
               
    }
    
    
    Future<void> load_state_of_the_browser_storage() async {
    
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
            ) as List<dynamic>).cast<JSLegation>().map<Legation>((JSLegation jslegation)=>legation_of_a_jslegation(jslegation)).toList(); 

            String? user_cycles_bank = await idb.get_object(
                object_store_name: 'state', 
                key: 'user_cycles_bank'
            ) as String?;

            idb.shutdown();
                            
            User user_of_the_idb = User(
                state: this,
                caller: await SubtleCryptoECDSAP256Caller.of_the_cryptokeys(public_key: user_crypto_key_public, private_key: user_crypto_key_private),
                legations: legations
            );    
            
            if (user_cycles_bank != null) {
                List<String> user_cycles_bank_data = user_cycles_bank.split(':');
                if (user_cycles_bank_data[0] == user_of_the_idb.principal.text) {
                    user_of_the_idb.cycles_bank = CyclesBank(Principal(user_cycles_bank_data[1]), user_of_the_idb);
                }
            }
            
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




class CTSFees {
    final Cycles cycles_bank_cost_cycles;
    final Cycles cts_transfer_icp_fee;
    final Cycles burn_icp_mint_cycles_fee;

    CTSFees._({
        required this.cycles_bank_cost_cycles,
        required this.cts_transfer_icp_fee,
        required this.burn_icp_mint_cycles_fee
    
    });
    
    static CTSFees oftheRecord(Record ctsfees_record) {
        return CTSFees._(
            cycles_bank_cost_cycles: Cycles.oftheNat(ctsfees_record['cycles_bank_cost_cycles'] as Nat),
            cts_transfer_icp_fee: Cycles.oftheNat(ctsfees_record['cts_transfer_icp_fee'] as Nat),
            burn_icp_mint_cycles_fee: Cycles.oftheNat(ctsfees_record['burn_icp_mint_cycles_fee'] as Nat)         
        );
    }

}





Uint8List principal_as_an_icpsubaccountbytes(Principal principal) {
    List<int> bytes = []; // an icp subaccount is 32 bytes
    bytes.add(principal.bytes.length);
    bytes.addAll(principal.bytes);
    while (bytes.length < 32) { bytes.add(0); }
    return Uint8List.fromList(bytes);
}


class Cycles extends Nat {
    BigInt get cycles => super.value;
    
    String toString() {
        BigInt tcycles = this.cycles ~/ Cycles.T_CYCLES_DIVIDABLE_BY;
        BigInt cycles_less_than_1T = this.cycles % Cycles.T_CYCLES_DIVIDABLE_BY;
        String decimal_places = '';
        if (cycles_less_than_1T != BigInt.from(0)) {
            decimal_places = cycles_less_than_1T.toRadixString(10);
            while (decimal_places.length < 12) {
                decimal_places = '0${decimal_places}';
            }
            while (decimal_places[decimal_places.length-1] == '0') {
                decimal_places = decimal_places.substring(0, decimal_places.length-1);    
            }
            decimal_places = '.${decimal_places}';
        }
        String s = '${tcycles}${decimal_places}T';
        return s;
    }
    
    Cycles({required BigInt cycles}) : super(cycles);
    
    static Cycles oftheNat(CandidType nat) {
        return Cycles(
            cycles: (nat as Nat).value
        );
    }
    
    static BigInt T_CYCLES_DIVIDABLE_BY = BigInt.from(pow(10, Cycles.T_CYCLES_DECIMAL_PLACES));
    static int T_CYCLES_DECIMAL_PLACES = 12;    
    static Cycles oftheTCyclesDoubleString(String tcycles_string) {
        tcycles_string = tcycles_string.trim();
        if (tcycles_string == '') {
            throw Exception('must be a number');
        }
        List<String> tcycles_string_split = tcycles_string.split('.');
        if (tcycles_string_split.length > 2) {
            throw Exception('invalid number.');
        } 
        BigInt tcycles = BigInt.parse(tcycles_string_split[0]);
        BigInt cycles_less_than_1T = BigInt.from(0);        
        if (tcycles_string_split.length == 2) {
            String decimal_places = tcycles_string_split[1];        
            if (decimal_places.length > Cycles.T_CYCLES_DECIMAL_PLACES) {
                throw Exception('Max ${Cycles.T_CYCLES_DECIMAL_PLACES} decimal places for the TCycles');
            }
            while (decimal_places.length < Cycles.T_CYCLES_DECIMAL_PLACES) {
                decimal_places = '${decimal_places}0';
            }
            cycles_less_than_1T = BigInt.parse(decimal_places);
        }
        Cycles cycles = Cycles(cycles: (tcycles * Cycles.T_CYCLES_DIVIDABLE_BY) + cycles_less_than_1T);
        return cycles;
    }
    
    Cycles operator + (Cycles t) {
        return Cycles(cycles: this.cycles + t.cycles);
    }    
    Cycles operator - (Cycles t) {
        return Cycles(cycles: this.cycles - t.cycles);
    } 
    Cycles operator * (Cycles t) {
        return Cycles(cycles: this.cycles * t.cycles);
    } 
    Cycles operator ~/ (Cycles t) {
        return Cycles(cycles: this.cycles ~/ t.cycles);
    } 
    bool operator > (Cycles t) {
        return this.cycles > t.cycles;
    } 
    bool operator < (Cycles t) {
        return this.cycles < t.cycles;
    } 
    bool operator >= (Cycles t) {
        return this.cycles >= t.cycles;
    } 
    bool operator <= (Cycles t) {
        return this.cycles <= t.cycles;
    } 
    
} 





final BigInt CYCLES_PER_XDR = Cycles.T_CYCLES_DIVIDABLE_BY;

Cycles icptokens_to_cycles(IcpTokens icpts, XDRICPRate xdr_icp_rate) {
    return Cycles(cycles: 
        icpts.e8s 
        * xdr_icp_rate.xdr_permyriad_per_icp 
        * CYCLES_PER_XDR 
        ~/ (IcpTokens.DIVIDABLE_BY * XDRICPRate.DIVIDABLE_BY)
    );
}

IcpTokens cycles_to_icptokens(Cycles cycles, XDRICPRate xdr_icp_rate) {
    return IcpTokens(e8s:
        cycles.cycles
        * (IcpTokens.DIVIDABLE_BY * XDRICPRate.DIVIDABLE_BY)
        ~/ CYCLES_PER_XDR
        ~/ xdr_icp_rate.xdr_permyriad_per_icp    
    );
}












class CyclesWithATimestamp {
    final BigInt cycles;
    final BigInt timestamp_nanos;
    CyclesWithATimestamp({required this.cycles, BigInt? opt_timestamp_nanos}) : timestamp_nanos = opt_timestamp_nanos==null ? get_current_time_nanoseconds() : opt_timestamp_nanos;
}

class IcpTokensWithATimestamp {
    final IcpTokens icp;
    final BigInt timestamp_nanos;
    IcpTokensWithATimestamp({required this.icp, BigInt? opt_timestamp_nanos}) : timestamp_nanos = opt_timestamp_nanos==null ? get_current_time_nanoseconds() : opt_timestamp_nanos;
}

class XDRICPRateWithATimestamp {
    final XDRICPRate xdr_icp_rate;
    final BigInt timestamp_seconds;
    XDRICPRateWithATimestamp({required this.xdr_icp_rate, required this.timestamp_seconds});
}



class XDRICPRate extends Nat64 {
    BigInt get xdr_permyriad_per_icp => super.value;
    
    XDRICPRate({required BigInt xdr_permyriad_per_icp}): super(xdr_permyriad_per_icp);
    
    static XDRICPRate oftheXdrPerMyriadPerIcpNat64(CandidType nat64) {
        return XDRICPRate(
            xdr_permyriad_per_icp: (nat64 as Nat64).value
        );
    }
    static XDRICPRate oftheDoubleString(String xdr_per_icp_string) {
        xdr_per_icp_string = xdr_per_icp_string.trim();
        if (xdr_per_icp_string == '') {
            throw Exception('must be a number');
        }
        List<String> xdr_per_icp_string_split = xdr_per_icp_string.split('.');
        if (xdr_per_icp_string_split.length > 2) {
            throw Exception('invalid number.');
        }
        BigInt xdr_per_icp = BigInt.parse(xdr_per_icp_string_split[0]);
        BigInt xdr_per_icp_less_than_1 = BigInt.from(0);
        if (xdr_per_icp_string_split.length == 2) {
            String decimal_places = xdr_per_icp_string_split[1];        
            if (decimal_places.length > XDRICPRate.DECIMAL_PLACES) {
                throw Exception('Max ${XDRICPRate.DECIMAL_PLACES} decimal places for the XDR/ICP rate');
            }
            while (decimal_places.length < XDRICPRate.DECIMAL_PLACES) {
                decimal_places = '${decimal_places}0';
            }
            xdr_per_icp_less_than_1 = BigInt.parse(decimal_places);
        }
        XDRICPRate xdricprate = XDRICPRate(xdr_permyriad_per_icp: (xdr_per_icp * XDRICPRate.DIVIDABLE_BY) + xdr_per_icp_less_than_1);
        return xdricprate;
    }
    String toString() {
        return '${this.xdr_permyriad_per_icp/XDRICPRate.DIVIDABLE_BY}';
    }
    
    static int DECIMAL_PLACES = 4;
    static BigInt DIVIDABLE_BY = BigInt.from(pow(10, XDRICPRate.DECIMAL_PLACES));
}




class CallError {
    final int error_code;
    final String error_message;
    CallError({required this.error_code, required this.error_message});
    
    static CallError oftheRecord(Record r) {
        return CallError(
            error_code: (r[0] as Nat32).value,
            error_message: (r[1] as candid.Text).value
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
    
    String toString() {
        if (this.keys.first == candid_text_hash('Text')) {
            return 'Text: ${(this.values.first as candid.Text).value}';
        }
        if (this.keys.first == candid_text_hash('Blob')) {
            return 'Blob: ${bytesasahexstring((this.values.first as Blob).bytes)}';
        }
        if (this.keys.first == candid_text_hash('Nat')) {
            return 'Nat: ${(this.values.first as Nat).value}';
        }
        throw Exception('');
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
    
    /*
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
    */
}

JSLegation jslegation_of_a_legation(Legation legation) {
    return JSLegation(
        legatee_public_key_DER: legation.legatee_public_key_DER,
        expiration_unix_timestamp_nanoseconds: legation.expiration_unix_timestamp_nanoseconds.toRadixString(10),
        target_canisters_ids: legation.target_canisters_ids != null ? legation.target_canisters_ids!.map<String>((Principal p)=>p.text).toList() : null,
        legator_public_key_DER: legation.legator_public_key_DER,
        legator_signature: legation.legator_signature, 
    );
}

Legation legation_of_a_jslegation(JSLegation jslegation) {
    return Legation(
        legatee_public_key_DER: jslegation.legatee_public_key_DER,
        expiration_unix_timestamp_nanoseconds: BigInt.parse(jslegation.expiration_unix_timestamp_nanoseconds, radix:10),
        target_canisters_ids: jslegation.target_canisters_ids != null ? jslegation.target_canisters_ids!.map<Principal>((String ps)=>Principal(ps)).toList() : null,
        legator_public_key_DER: jslegation.legator_public_key_DER,
        legator_signature: jslegation.legator_signature, 
    );
}













































