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
    PrincipalReference,
    PrincipalCandid,
    Nat8,
    Null,
    ;

import 'package:ic_tools/common.dart' as common;
import 'package:ic_tools/common_web.dart' show SubtleCryptoECDSAP256Caller;


import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';

import 'urls.dart';
import './cts.dart';



const String Ok  = 'Ok';
const String Err = 'Err';






class CustomState { // with ChangeNotifier  // do i want change notifier here? false.

    CustomUrl current_url = CustomUrl('welcome');
    
    String loading_text = 'loading ...';
    bool is_loading = true; // state starts loading. in the load_first_state function, the state sets is_loading = false and then completes and the router calls tifyListeners 
    
    
    XDRICPRateWithATimestamp? xdr_icp_rate;
    
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
        
            print('fresh_user_icp_ledger_balance');
            await this.user!.fresh_user_icp_ledger_balance();
            
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


class BurnIcpMintCyclesSuccess {
    final Cycles mint_cycles_for_the_user;
    final Cycles cts_fee_taken;
    
    BurnIcpMintCyclesSuccess({required this.mint_cycles_for_the_user, required this.cts_fee_taken});
    
    
    static BurnIcpMintCyclesSuccess oftheRecord(CandidType user_burn_icp_mint_cycles_success_record) {
        Record r = user_burn_icp_mint_cycles_success_record as Record;
        return BurnIcpMintCyclesSuccess(
            mint_cycles_for_the_user: (r['mint_cycles_for_the_user'] as Nat).value,
            cts_fee_taken: (r['cts_fee_taken'] as Nat).value            
        );
    }

}




class User {

    final SubtleCryptoECDSAP256Caller caller;
    final List<Legation> legations;
    
    late final BigInt? expiration_unix_timestamp_nanoseconds;
    late final Uint8List public_key_DER;
    late final Principal principal;
    late final Uint8List user_icp_subaccount_bytes;
    late final Uint8List user_icp_id;
    
    
    IcpTokensWithATimestamp? user_icp_ledger_balance;
    CyclesBank? cycles_bank;
    
    User({
        required this.caller,
        required this.legations,
        this.user_icp_ledger_balance,
        this.cycles_bank,
    }) {
        this.expiration_unix_timestamp_nanoseconds = this.legations.isNotEmpty ? this.legations.first.expiration_unix_timestamp_nanoseconds : null;
        this.public_key_DER = legations.length >= 1 ? legations[0].legator_public_key_DER : caller.public_key_DER;
        this.principal = Principal.ofthePublicKeyDER(this.public_key_DER);
        this.user_icp_subaccount_bytes = User.get_user_icp_subaccount_bytes(this.principal);
        this.user_icp_id = hexstringasthebytes(cts.principal.icp_id(subaccount_bytes: user_icp_subaccount_bytes));
    }

    
    static Uint8List get_user_icp_subaccount_bytes(Principal user_principal) { 
        List<int> user_subaccount_bytes = [ user_principal.bytes.length, ...user_principal.bytes ];
        while (user_subaccount_bytes.length < 32) { user_subaccount_bytes.add(0); }
        if (user_subaccount_bytes.length != 32) { throw Exception('wrong user subaccount length'); }
        return Uint8List.fromList(user_subaccount_bytes);
    }
    
        
    Future<Uint8List> call(Canister canister, {required CallType calltype, required String method_name, Uint8List? put_bytes, Duration timeout_duration = const Duration(minutes: 10)}) {
        return canister.call(caller:this.caller, legations:this.legations, calltype:calltype, method_name:method_name, put_bytes:put_bytes, timeout_duration:timeout_duration);
    }
    
    
    
    Future<void> fresh_user_icp_ledger_balance() async {
    
        Record icptokens_record = (c_backwards(await common.ledger.call(
            calltype: CallType.call,
            method_name: 'account_balance',
            put_bytes: c_forwards([
                Record.oftheMap({
                    'account': Blob(this.user_icp_id)
                })
            ])
        )))[0] as Record;
        
        this.user_icp_ledger_balance = IcpTokensWithATimestamp(
            icp: IcpTokens.oftheRecord(icptokens_record)
        );
    }

    
    Future<void> find_cycles_bank() async {

        Variant find_cycles_bank_sponse = c_backwards(
            await call(
                cts,
                calltype: CallType.call,
                method_name: 'find_cycles_bank',
                put_bytes: c_forwards([]),
            )
        )[0] as Variant;
        if (find_cycles_bank_sponse.containsKey(Ok)) {
            Option opt_user_canister_id = find_cycles_bank_sponse[Ok] as Option;
            if (opt_user_canister_id.value != null) {
                this.cycles_bank = CyclesBank((opt_user_canister_id.value as PrincipalReference).principal!, this);
            } else {
                this.cycles_bank = null;
            }
        }
        else if (find_cycles_bank_sponse.containsKey(Err)) {
            Variant find_cycles_bank_sponse_error = find_cycles_bank_sponse[Err] as Variant; 
            if (find_cycles_bank_sponse_error.containsKey('FindUserInTheCBSMapsError')) {
                Variant find_user_in_the_users_map_canisters_error = find_cycles_bank_sponse_error['FindUserInTheCBSMapsError'] as Variant;
                String alert_dialog_content_string = 'Cycles-Banks-Map-Canisters Call-Fails:';
                for (Record users_map_canister_call_fail in (find_cycles_bank_sponse_error['CBSMapsFindUserCallFails'] as Vector).cast_vector<Record>()) {
                    alert_dialog_content_string = alert_dialog_content_string+' \n${users_map_canister_call_fail[0]}, error: ${users_map_canister_call_fail[1]}';                   
                }
                throw Exception('Find Cycles Bank Error:\n${alert_dialog_content_string}');  
            } else if (find_cycles_bank_sponse_error.containsKey('UserIsInTheMiddleOfAPurchaseCyclesBankCall')) {
                if (((find_cycles_bank_sponse_error['UserIsInTheMiddleOfAPurchaseCyclesBankCall'] as Record)['must_call_complete'] as Bool).value) {
                    await complete_purchase_cycles_bank();
                } else {
                    await Future.delayed(Duration(seconds: 10));
                    await find_cycles_bank();
                }
            } else {
                throw Exception('Unknown find_cycles_bank_sponse_error. \n${find_cycles_bank_sponse_error}');
            } 
        } else {
            throw Exception('Unknown find_cycles_bank_sponse. \n${find_cycles_bank_sponse}');
        }    

    }


    Future<void> handle_user_is_in_the_middle_of_a_different_call(Variant user_is_in_the_middle_of_a_different_call_variant) async {
        print(user_is_in_the_middle_of_a_different_call_variant);
        if (user_is_in_the_middle_of_a_different_call_variant.containsKey('')) {
        
        } else if (user_is_in_the_middle_of_a_different_call_variant.containsKey('')) {
        
        } else if (user_is_in_the_middle_of_a_different_call_variant.containsKey('')) 
    }
    
    Future<void> purchase_cycles_bank(Principal? opt_referral_user_id) async {
        Variant purchase_cycles_bank_sponse = c_backwards(
            await call(
                cts,
                calltype: CallType.call,
                method_name: 'purchase_cycles_bank',
                put_bytes: c_forwards([
                    Record.oftheMap({
                        'opt_referral_user_id': Option(value: opt_referral_user_id !=null ? opt_referral_user_id.c : null, value_type: PrincipalReference(isTypeStance:true))
                    })
                ])
            )
        )[0] as Variant;
        if (purchase_cycles_bank_sponse.containsKey(Ok)) {
            return await _handle_purchase_cycles_bank_ok(purchase_cycles_bank_sponse[Ok]!);
        } else if (purchase_cycles_bank_sponse.containsKey(Err)) {
            return await _handle_purchase_cycles_bank_err(purchase_cycles_bank_sponse[Err]!);
        } else {
            throw Exception('unknown purchase_cycles_bank_sponse: ${purchase_cycles_bank_sponse}');
        }   
    }

    Future<void> complete_purchase_cycles_bank() async {
        Variant sponse = c_backwards(
            await call(
                cts,
                calltype: CallType.call,
                method_name: 'complete_purchase_cycles_bank',
                put_bytes: c_forwards([])
            )
        )[0] as Variant;
        if (sponse.containsKey(Ok)) {
            return await _handle_purchase_cycles_bank_ok(sponse[Ok]!);
        } else if (sponse.containsKey(Err)) {
            Variant complete_purchase_cycles_bank_error = sponse[Err] as Variant;
            if (complete_purchase_cycles_bank_error.containsKey('UserIsNotInTheMiddleOfAPurchaseCyclesBankCall')) {
                throw Exception('complete_purchase_cycles_bank error: UserIsNotInTheMiddleOfAPurchaseCyclesBankCall');
            } else if (complete_purchase_cycles_bank_error.containsKey('PurchaseCyclesBankError')) {
                return await _handle_purchase_cycles_bank_err(complete_purchase_cycles_bank_error['PurchaseCyclesBankError']!);    
            } else {
                throw Exception('unknown complete_purchase_cycles_bank_error: ${complete_purchase_cycles_bank_error}');
            }
        } else {
            throw Exception('unknown complete_purchase_cycles_bank_sponse: ${sponse}');
        }
    }

    Future<void> _handle_purchase_cycles_bank_err(CandidType purchase_cycles_bank_err_ctype) async {
        Variant purchase_cycles_bank_error = purchase_cycles_bank_err_ctype as Variant;
        if (purchase_cycles_bank_error.containsKey('MidCallError')) {
            print('purchase_cycles_bank mid_call_error: ${purchase_cycles_bank_error['MidCallError']}');
            return await this.complete_purchase_cycles_bank();
        } else if (purchase_cycles_bank_error.containsKey('FoundCyclesBank')) { 
            this.cycles_bank = CyclesBank((purchase_cycles_bank_error['FoundCyclesBank'] as PrincipalReference).principal!, this);
        } else if (purchase_cycles_bank_error.containsKey('UserIcpLedgerBalanceTooLow')) {
            Record user_icp_ledger_balance_too_low_error = purchase_cycles_bank_error['UserIcpLedgerBalanceTooLow'] as Record;
            IcpTokens cycles_bank_cost_icp = IcpTokens.oftheRecord(user_icp_ledger_balance_too_low_error['cycles_bank_cost_icp']!);
            IcpTokens user_icp_ledger_balance = IcpTokens.oftheRecord(user_icp_ledger_balance_too_low_error['user_icp_ledger_balance']!);
            IcpTokens icp_ledger_transfer_fee = IcpTokens.oftheRecord(user_icp_ledger_balance_too_low_error['icp_ledger_transfer_fee']!);
            IcpTokens must_be_with_the_icp_balance = IcpTokens(e8s: cycles_bank_cost_icp.e8s + (icp_ledger_transfer_fee.e8s*BigInt.from(2)));
            throw Exception('user icp balance is too low.\ncurrent cycles_bank cost icp: ${ must_be_with_the_icp_balance }\ncurrent user icp balance: ${user_icp_ledger_balance}');
        } else if (purchase_cycles_bank_error.containsKey('UserIsInTheMiddleOfADifferentCall')) {
            handle_user_is_in_the_middle_of_a_different_call(purchase_cycles_bank_error['UserIsInTheMiddleOfADifferentCall'] as Variant).then((){
            
            }).catchError((e){
            
            });
            throw Exception('user is in the middle of a different call.');
        } else {
            String purchase_cycles_bank_error_type = 'unknown error: ${purchase_cycles_bank_error.keys.first}';
            for (String possible_error_variant in [
                'ReferralUserCannotBeTheCaller',
                'CheckIcpBalanceCallError',
                'CheckCurrentXdrPerMyriadPerIcpCmcRateError',
                'UserIsInTheMiddleOfAPurchaseCyclesBankCall',
                'CTSIsBusy',
                'ReferralUserNotFound',
                'CreateCyclesBankCanisterCmcNotifyError',
            ]) {
                if (purchase_cycles_bank_error.containsKey(possible_error_variant)) {
                    purchase_cycles_bank_error_type = possible_error_variant;
                }
            }
            if (purchase_cycles_bank_error.values.first is! Null) {
                purchase_cycles_bank_error_type += '\n${purchase_cycles_bank_error.values.first}';
            }
            throw Exception('purchase_cycles_bank error: ${purchase_cycles_bank_error_type}');
        }
    }

    Future<void> _handle_purchase_cycles_bank_ok(CandidType purchase_cycles_bank_ok_ctype) async {
        Record purchase_cycles_bank_success = purchase_cycles_bank_ok_ctype as Record;
        this.cycles_bank = CyclesBank((purchase_cycles_bank_success['cycles_bank_canister_id'] as PrincipalReference).principal!, this);
    }


    // ------------------
    
    // try catch when calling this it can throw
    Future<BurnIcpMintCyclesSuccess> call_user_burn_icp_mint_cycles(IcpTokens burn_icp) async {
        Uint8List sponse_bytes = await call(
            cts,
            calltype: CallType.call,
            method_name: 'user_burn_icp_mint_cycles',
            put_bytes: c_forwards([
                Record.oftheMap({
                    'burn_icp': burn_icp
                })
            ])
        );
        Variant sponse = c_backwards(sponse_bytes)[0] as Variant;
        if (sponse.containsKey(Ok)) {
            return await _handle_user_burn_icp_mint_cycles_ok(sponse[Ok]!);
        } else if (sponse.containsKey(Err)) {
            return await _handle_user_burn_icp_mint_cycles_err(sponse[Err]!);
        } else {
            throw Exception('unknown user_burn_icp_mint_cycles sponse.');
        }
    }
    
    Future<BurnIcpMintCyclesSuccess> call_complete_user_burn_icp_mint_cycles() async {
        throw UnimplementedError();
    }
    
    Future<BurnIcpMintCyclesSuccess> _handle_user_burn_icp_mint_cycles_ok(CandidType ok) async {
        return BurnIcpMintCyclesSuccess.oftheRecord(ok);
    }

    Future<BurnIcpMintCyclesSuccess> _handle_user_burn_icp_mint_cycles_err(CandidType err) async {
        Variant user_burn_icp_mint_cycles_error = err as Variant;
        if (user_burn_icp_mint_cycles_error.containsKey('MidCallError')) {
            print('user_burn_icp_mint_cycles mid-call-error: ${user_burn_icp_mint_cycles_error['MidCallError']}');
            return await call_complete_user_burn_icp_mint_cycles();    
        } else if (user_burn_icp_mint_cycles_error.containsKey('UserIsInTheMiddleOfAUserBurnIcpMintCyclesCallMustCallComplete')) {
            () async { 
                try{
                    BurnIcpMintCyclesSuccess s = await call_complete_user_burn_icp_mint_cycles();
                    window.alert('user_burn_icp_mint_cycles call success: ${s}');
                } catch(e) {
                    window.alert('complete_user_burn_icp_mint_cycles call error: ${e}');
                }
            }().then((){});
            throw Exception('user is in the middle of a different user_burn_icp_mint_cycles call. completing that now in the background.');
        } else if (user_burn_icp_mint_cycles_error.containsKey('UserIsInTheMiddleOfAPurchaseCyclesBankCall')) {
            () async { 
                try{
                    await complete_purchase_cycles_bank();
                    window.alert('purchase_cycles_bank call success. fresh the page.');
                } catch(e) {
                    window.alert('complete_purchase_cycles_bank call error: ${e}');
                }
            }().then((){});
            throw Exception('user is in the middle of a purchase_cycles_bank call. completing that now in the background.');
        } else if (user_burn_icp_mint_cycles_error.containsKey('UserIsInTheMiddleOfAUserTransferIcpCall')) {
            () async { 
                try{
                    BigInt icp_block_height = await call_complete_user_transfer_icp();
                    window.alert('user_transfer_icp call success. block_height: ${icp_block_height}');
                } catch(e) {
                    window.alert('complete_user_transfer_icp call error: ${e}');
                }
            }().then((){});
            throw Exception('user is in the middle of a user_transfer_icp call. completing that now in the background.');
        } else if (user_burn_icp_mint_cycles_error.containsKey('MinimumUserBurnIcpMintCycles')) {
            IcpTokens t = IcpTokens.oftheRecord((user_burn_icp_mint_cycles_error['MinimumUserBurnIcpMintCycles'] as Record)['minimum_user_burn_icp_mint_cycles']!);
            throw Exception('MinimumUserBurnIcpMintCycles: $t');
        } else if (user_burn_icp_mint_cycles_error.containsKey('UserIcpBalanceTooLow')) {
            Record uibtlr = user_burn_icp_mint_cycles_error['UserIcpBalanceTooLow'] as Record;
            throw Exception('user icp balance is too low for this call.\nuser icp balance: ${IcpTokens.oftheRecord(uibtlr['user_icp_balance']!)}\nicp_ledger_transfer_fee: ${IcpTokens.oftheRecord(uibtlr['nicp_ledger_transfer_fee']!)}');
        } else {
            String user_burn_icp_mint_cycles_error_type = 'unknown error: ${user_burn_icp_mint_cycles_error.keys.first}';
            for (String possible_error_variant in [
                'UserIsInTheMiddleOfAUserBurnIcpMintCyclesCall',
                'IcpCheckBalanceCallError',
                'FindUserInTheCBSMapsError',
                'UserCanisterNotFound',
                'MaxUsersBurnIcpMintCycles',
                'LedgerTopupCyclesCmcIcpTransferError',   
            ]) {
                if (user_burn_icp_mint_cycles_error.containsKey(possible_error_variant)) {
                    user_burn_icp_mint_cycles_error_type = possible_error_variant;
                    break;
                }
            }
            if (user_burn_icp_mint_cycles_error.values.first is! Null) {
                user_burn_icp_mint_cycles_error_type += '\n${user_burn_icp_mint_cycles_error.values.first}';
            }
            throw Exception('user_burn_icp_mint_cycles error: ${user_burn_icp_mint_cycles_error_type}');
        }
    }






}


// ---------- :checkpoint.





class CyclesBank extends Canister {
    User user;

    LatestKnownCyclesBalance? latest_known_cycles_balance;
    IcpTokens? latest_known_icp_balance;

    CyclesBank(
        Principal user_canister_id,
        this.user,
        {
            this.latest_known_cycles_balance,
            this.latest_known_icp_balance,
    }) : super(user_canister_id) {
    
    }
    
    Future<void> fresh_user_cycles_balance() async {        
        List<CandidType> user_cycles_balance_call_sponse_candids = c_backwards(await this.user.call(
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
    }
    
    
    // the user must have a user-canister for this method that is why it is on the CyclesBank-class
    Future<void> user_burn_icp_mint_cycles() async {
    
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















































