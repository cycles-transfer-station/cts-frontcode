import 'dart:typed_data';
import 'dart:html';

import 'package:ic_tools/ic_tools.dart';
import 'package:ic_tools/candid.dart';
import 'package:ic_tools/tools.dart';
import 'package:ic_tools/common.dart';
import 'package:ic_tools/common_web.dart' show SubtleCryptoECDSAP256Caller;

import 'icp_ledger.dart';
import 'cycles_bank.dart';
import 'state.dart';

class User {

    final SubtleCryptoECDSAP256Caller caller;
    final List<Legation> legations;
    
    late final BigInt? expiration_unix_timestamp_nanoseconds;
    late final Uint8List public_key_DER;
    late final Principal principal;
    late final Uint8List user_icp_subaccount_bytes;
    late final String user_icp_id;
    
    IcpTokensWithATimestamp? icp_balance;
    List<IcpTransfer> icp_transfers = [];
    CyclesBank? cycles_bank;
    
    User({
        required this.caller,
        required this.legations,
        this.icp_balance,
        this.cycles_bank,
    }) {
        this.expiration_unix_timestamp_nanoseconds = this.legations.isNotEmpty ? this.legations.first.expiration_unix_timestamp_nanoseconds : null;
        this.public_key_DER = legations.length >= 1 ? legations[0].legator_public_key_DER : caller.public_key_DER;
        this.principal = Principal.ofthePublicKeyDER(this.public_key_DER);
        this.user_icp_subaccount_bytes = principal_as_an_icpsubaccountbytes(this.principal);
        this.user_icp_id = icp_id(cts.principal, subaccount_bytes: user_icp_subaccount_bytes);
    }

        
    Future<Uint8List> call(Canister canister, {required CallType calltype, required String method_name, Uint8List? put_bytes, Duration timeout_duration = const Duration(minutes: 10)}) {
        return canister.call(caller:this.caller, legations:this.legations, calltype:calltype, method_name:method_name, put_bytes:put_bytes, timeout_duration:timeout_duration);
    }
    
    
    
    Future<void> fresh_icp_balance() async {
    
        Record icptokens_record = (c_backwards(await ledger.call(
            calltype: CallType.call,
            method_name: 'account_balance',
            put_bytes: c_forwards([
                Record.oftheMap({
                    'account': Blob(hexstringasthebytes(this.user_icp_id))
                })
            ])
        )))[0] as Record;
        
        this.icp_balance = IcpTokensWithATimestamp(
            icp: IcpTokens.oftheRecord(icptokens_record)
        );
    }

    Future<void> fresh_icp_transfers() async {
        this.icp_transfers.addAll(
            await get_icp_transfers(
                this.user_icp_id, 
                already_have: this.icp_transfers.length
            )
        );
    }
        


    // ---------------------
    

    
    
    
    // ----------------------
    
    
    
    Map<String, Never Function(CandidType)> find_user_in_the_cbs_maps_error_match_map = {
        'CBSMapsFindUserCallFails': (vec) {
            String error_string = 'Find the user\'s cycles-bank error: \ncycles-banks-maps-canisters call error(s): ';
            for (Record call_fail in (vec as Vector).cast_vector<Record>()) {
                error_string = error_string + '\ncbs_map: ${(call_fail[0] as Principal).text}, ${CallError.oftheRecord(call_fail[1] as Record)}';                   
            }
            throw Exception(error_string);
        }
    };
    
    Map<String, Never Function(CandidType)> get ledger_topup_cycles_cmc_icp_transfer_error_match_map => {
        'IcpTransferCallError': (call_error) {
            throw Exception('Icp ledger transfer call error:\n${CallError.oftheRecord(call_error as Record)}');
        },
        'IcpTransferError': (icp_transfer_error) {
            return match_variant<Never>(icp_transfer_error as Variant, icp_transfer_error_match_map);
        }
    };

    Map<String, Never Function(CandidType)> get icp_transfer_error_match_map => {
        'BadFee': (expected_fee_record) {
            throw Exception('Bad Fee set on the transfer. expected_fee: ${IcpTokens.oftheRecord((expected_fee_record as Record)['expected_fee']!)}');
        },
        'InsufficientFunds': (balance_record) {
            IcpTokens current_balance = IcpTokens.oftheRecord((balance_record as Record)['balance']!);
            this.icp_balance = IcpTokensWithATimestamp(icp: current_balance);
            throw Exception('Icp balance is too low. current balance: ${current_balance}');
        },
        'TxTooOld': (allowed_window_nanos_record) {
            throw Exception('Icp Transfer created_at_time field is too old');
        },
        'TxCreatedInFuture': (n) {
            throw Exception('Icp Transfer created_at_time field is too far in the future.');
        },
        'TxDuplicate': (duplicate_of_record) {
            throw Exception('The Icp Transfer is a duplicate of the transfer: ${((duplicate_of_record as Record)['duplicate_of'] as Nat64).value}');
        }
    };
    
    
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
                this.cycles_bank = CyclesBank(opt_user_canister_id.value as Principal, this);
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

    // -----------------------
    

    
    
    
     Map<String, Never Function(CandidType)> get user_is_in_the_middle_of_a_different_call_variant_match_map => {
        'PurchaseCyclesBankCall': (must_call_complete_record) {
            if (((must_call_complete_record as Record)['must_call_complete'] as Bool).value == true) {
                complete_purchase_cycles_bank()
                .then((x){
                    window.alert('purchase_cycles_bank is complete.\ncycles_bank: ${this.cycles_bank}');
                }).catchError((e){
                    window.alert('purchase_cycles_bank error: \n${e}');
                });
            }
            throw Exception('user is in the middle of a different purchase_cycles_bank call.');
        },
        'BurnIcpMintCyclesCall': (must_call_complete_record) {
            if (((must_call_complete_record as Record)['must_call_complete'] as Bool).value == true) {
                complete_burn_icp_mint_cycles()
                .then((x){
                    window.alert('burn_icp_mint_cycles is complete. \ncycles-mint: ${x}');
                }).catchError((e){
                    window.alert('burn_icp_mint_cycles error: \n${e}');
                });
            }
            throw Exception('user is in the middle of a different burn_icp_mint_cycles call.');
        },
        'TransferIcpCall': (must_call_complete_record) {
            if (((must_call_complete_record as Record)['must_call_complete'] as Bool).value == true) {
                complete_transfer_icp()
                .then((x){
                    window.alert('transfer_icp is complete. icp-transfer-block-height: ${x}');
                }).catchError((e){
                    window.alert('transfer_icp error: \n${e}');
                });
            }
            throw Exception('user is in the middle of a different transfer_icp call.');
        },
    };


    // -----------------------------


    Map<String, Future<void> Function(CandidType)> get purchase_cycles_bank_error_match_map => {
        'MidCallError': (mid_call_error) async {
            print('purchase_cycles_bank mid_call_error: ${mid_call_error}');
            return await this.complete_purchase_cycles_bank();          
        },
        'FoundCyclesBank':(cycles_bank_principal) async {
            this.cycles_bank = CyclesBank((cycles_bank_principal as PrincipalReference).principal!, this);    
        },
        'UserIcpLedgerBalanceTooLow':(user_icp_ledger_balance_too_low_ctype) async {
            Record user_icp_ledger_balance_too_low_error = user_icp_ledger_balance_too_low_ctype as Record;
            IcpTokens cycles_bank_cost_icp = IcpTokens.oftheRecord(user_icp_ledger_balance_too_low_error['cycles_bank_cost_icp']!);
            IcpTokens user_icp_ledger_balance = IcpTokens.oftheRecord(user_icp_ledger_balance_too_low_error['user_icp_ledger_balance']!);
            this.icp_balance = IcpTokensWithATimestamp(icp: user_icp_ledger_balance);
            IcpTokens icp_ledger_transfer_fee = IcpTokens.oftheRecord(user_icp_ledger_balance_too_low_error['icp_ledger_transfer_fee']!);
            IcpTokens must_be_with_the_icp_balance = IcpTokens(e8s: cycles_bank_cost_icp.e8s + (icp_ledger_transfer_fee.e8s*BigInt.from(2)));
            throw Exception('user icp balance is too low.\ncurrent cycles_bank cost icp: ${ must_be_with_the_icp_balance }\ncurrent user icp balance: ${user_icp_ledger_balance}');
        }, 
        'UserIsInTheMiddleOfADifferentCall': (user_is_in_the_middle_of_a_different_call_variant) async {
            match_variant<Never>(user_is_in_the_middle_of_a_different_call_variant as Variant, user_is_in_the_middle_of_a_different_call_variant_match_map);
        },
        'ReferralUserCannotBeTheCaller': (n) async {
            throw Exception('The referral-user cannot be the caller.');
        },
        'CheckIcpBalanceCallError': (call_error_record) async {
            throw Exception('Error when checking the user\'s icp balance:\n${CallError.oftheRecord(call_error_record as Record)}');
        },
        'CheckCurrentXdrPerMyriadPerIcpCmcRateError': (r) async {
            print(r);
            throw Exception('Error when checking the current xdr-icp rate.');
        },
        'CTSIsBusy': (n) async {
            throw Exception('The CTS is busy, try soon.');
        },
        'ReferralUserCyclesBankNotFound': (n) async {
            throw Exception('The CTS did not find the referral-user\'s cycles-bank. A referral-user must have a cycles-bank.');    
        },
        'CreateCyclesBankCanisterCmcNotifyError': (cmc_notify_error) async {
            print(cmc_notify_error);
            throw Exception('System error when creating a cycles_bank. please file this error:\n${cmc_notify_error}');
        }
    };
    
    Map<String, Future<void> Function(CandidType)> get purchase_cycles_bank_result_match_map => {
        Ok: (purchase_cycles_bank_success_ctype) async {
            Record purchase_cycles_bank_success = purchase_cycles_bank_success_ctype as Record;
            this.cycles_bank = CyclesBank((purchase_cycles_bank_success['cycles_bank_canister_id'] as PrincipalReference).principal!, this);    
        },
        Err: (purchase_cycles_bank_error) async {
            return await match_variant<Future<void>>(purchase_cycles_bank_error as Variant, purchase_cycles_bank_error_match_map);
        }  
    };

    Map<String, Future<void> Function(CandidType)> get complete_purchase_cycles_bank_error_match_map => {
        'UserIsNotInTheMiddleOfAPurchaseCyclesBankCall': (n) async {
            throw Exception('user is not in the middle of a purchase_cycles_bank call.');
        },
        'PurchaseCyclesBankError': (purchase_cycles_bank_error_ctype) async {
            return await match_variant<Future<void>>(purchase_cycles_bank_error_ctype as Variant, purchase_cycles_bank_error_match_map);
        }
    };

    Map<String, Future<void> Function(CandidType)> get complete_purchase_cycles_bank_result_match_map => {
        Ok: (purchase_cycles_bank_success_ctype) async {
            return await purchase_cycles_bank_result_match_map[Ok]!(purchase_cycles_bank_success_ctype);    
        },
        Err: (complete_purchase_cycles_bank_error) async {
            return await match_variant<Future<void>>(complete_purchase_cycles_bank_error as Variant, complete_purchase_cycles_bank_error_match_map);
        }
    };


    Future<void> purchase_cycles_bank(Principal? opt_referral_user_id) async {
        Variant purchase_cycles_bank_result = c_backwards(
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
        return await match_variant<Future<void>>(purchase_cycles_bank_result, purchase_cycles_bank_result_match_map);   
    }

    Future<void> complete_purchase_cycles_bank() async {
        Variant complete_purchase_cycles_bank_result = c_backwards(
            await call(
                cts,
                calltype: CallType.call,
                method_name: 'complete_purchase_cycles_bank',
                put_bytes: c_forwards([])
            )
        )[0] as Variant;
        return await match_variant<Future<void>>(complete_purchase_cycles_bank_result, complete_purchase_cycles_bank_result_match_map);
    }
    


    // -----------------------------
    
    
    Map<String, Future<BurnIcpMintCyclesSuccess> Function(CandidType)> get burn_icp_mint_cycles_result_match_map => {
        Ok: (burn_icp_mint_cycles_success) async {
            return BurnIcpMintCyclesSuccess.oftheRecord(burn_icp_mint_cycles_success);
        },
        Err: (burn_icp_mint_cycles_error) async {
            return await match_variant<Future<BurnIcpMintCyclesSuccess>>(burn_icp_mint_cycles_error as Variant, burn_icp_mint_cycles_error_match_map);
        }
    };
    
    Map<String, Future<BurnIcpMintCyclesSuccess> Function(CandidType)> get complete_burn_icp_mint_cycles_result_match_map => {
        Ok: (burn_icp_mint_cycles_success) async {
            return await burn_icp_mint_cycles_result_match_map[Ok]!(burn_icp_mint_cycles_success);
        },
        Err: (complete_burn_icp_mint_cycles_error) async {
            return await match_variant<Future<BurnIcpMintCyclesSuccess>>(complete_burn_icp_mint_cycles_error as Variant, complete_burn_icp_mint_cycles_error_match_map);
        }
    };
    
    Map<String, Future<BurnIcpMintCyclesSuccess> Function(CandidType)> get burn_icp_mint_cycles_error_match_map => {
        'UserIsInTheMiddleOfADifferentCall': (user_is_in_the_middle_of_a_different_call_variant) async {
            return match_variant<Never>(user_is_in_the_middle_of_a_different_call_variant as Variant, user_is_in_the_middle_of_a_different_call_variant_match_map); 
        },
        'MinimumBurnIcpMintCycles': (minimum_burn_icp_mint_cycles_record) async {
            throw Exception('The minimum amount of icp that you can use to mint cycles is: ${IcpTokens.oftheRecord((minimum_burn_icp_mint_cycles_record as Record)['minimum_burn_icp_mint_cycles']!)}');
        },
        'FindUserInTheCBSMapsError':(find_user_in_the_cbs_maps_error) async {
            return match_variant<Never>(find_user_in_the_cbs_maps_error as Variant, find_user_in_the_cbs_maps_error_match_map);
        },
        'CyclesBankNotFound': (n) async {
            throw Exception('User cycles-bank not found. The user must have a cycles-bank to mint cycles.');
        },
        'CTSIsBusy': (n) async {
            throw Exception('The CTS is busy, try soon.');
        },
        'LedgerTopupCyclesCmcIcpTransferError': (ledger_topup_cycles_cmc_icp_transfer_error) async {
            return match_variant<Never>(ledger_topup_cycles_cmc_icp_transfer_error as Variant, ledger_topup_cycles_cmc_icp_transfer_error_match_map);
        },
        'MidCallError':(burn_icp_mint_cycles_mid_call_error) async {
            print('burn_icp_mint_cycles_mid_call_error: ${burn_icp_mint_cycles_mid_call_error}');
            return await complete_burn_icp_mint_cycles();
        }
    };

    Map<String, Future<BurnIcpMintCyclesSuccess> Function(CandidType)> get complete_burn_icp_mint_cycles_error_match_map => {
        'UserIsNotInTheMiddleOfABurnIcpMintCyclesCall': (n) async {
            throw Exception('user is not in the middle of a burn_icp_mint_cycles call.');
        },
        'BurnIcpMintCyclesError': (burn_icp_mint_cycles_error) async {
            return await match_variant<Future<BurnIcpMintCyclesSuccess>>(burn_icp_mint_cycles_error as Variant, burn_icp_mint_cycles_error_match_map);
        }
    };
    
    
    Future<BurnIcpMintCyclesSuccess> burn_icp_mint_cycles(IcpTokens burn_icp) async {
        if (this.cycles_bank == null) {
            throw Exception('The user must have a cycles-bank to mint cycles.');
        }
        Variant burn_icp_mint_cycles_result = c_backwards(
            await call(
                cts,
                calltype: CallType.call,
                method_name: 'burn_icp_mint_cycles',
                put_bytes: c_forwards([
                    Record.oftheMap({
                        'burn_icp': burn_icp
                    })
                ])
            )
        )[0] as Variant;
        return await match_variant<Future<BurnIcpMintCyclesSuccess>>(burn_icp_mint_cycles_result, burn_icp_mint_cycles_result_match_map);
    }
    
    Future<BurnIcpMintCyclesSuccess> complete_burn_icp_mint_cycles() async {
        Variant complete_burn_icp_mint_cycles_result = c_backwards(
            await call(
                cts,
                calltype: CallType.call,
                method_name: 'complete_burn_icp_mint_cycles',
                put_bytes: c_forwards([])
            )
        )[0] as Variant;
        return await match_variant<Future<BurnIcpMintCyclesSuccess>>(complete_burn_icp_mint_cycles_result, complete_burn_icp_mint_cycles_result_match_map);
    }




    // ----------------------
    
    
    
    Map<String, Future<TransferIcpSuccess> Function(CandidType)> get transfer_icp_result_match_map => {
        Ok: (transfer_icp_success) async {
            return TransferIcpSuccess.oftheRecord(transfer_icp_success);
        },
        Err: (transfer_icp_error) async {
            return await match_variant<Future<TransferIcpSuccess>>(transfer_icp_error as Variant, transfer_icp_error_match_map);
        }
    };
    
    Map<String, Future<TransferIcpSuccess> Function(CandidType)> get complete_transfer_icp_result_match_map => {
        Ok: (transfer_icp_success) async {
            return await transfer_icp_result_match_map[Ok]!(transfer_icp_success);
        },
        Err: (complete_transfer_icp_error) async {
            return await match_variant<Future<TransferIcpSuccess>>(complete_transfer_icp_error as Variant, complete_transfer_icp_error_match_map);
        }
    };
    
    Map<String, Future<TransferIcpSuccess> Function(CandidType)> get transfer_icp_error_match_map => {
        'UserIsInTheMiddleOfADifferentCall': (user_is_in_the_middle_of_a_different_call) async {
            return match_variant<Never>(user_is_in_the_middle_of_a_different_call as Variant, user_is_in_the_middle_of_a_different_call_variant_match_map); 
        },
        'CheckIcpBalanceCallError': (call_error) async {
            throw Exception('Error when checking the user icp balance on the ledger.\n${CallError.oftheRecord(call_error as Record)}');
        },
        'CTSIsBusy': (n) async {
            throw Exception('The CTS is busy, try soon.');
        },
        'CheckCurrentXdrPerMyriadPerIcpCmcRateError': (check_current_xdr_icp_cmc_rate_error) async {
            print('check_current_xdr_icp_cmc_rate_error: ${check_current_xdr_icp_cmc_rate_error}');
            throw Exception('Error when checking the current xdr-icp rate.');
        },
        'MaxTransfer': (max_transfer_record) async {
            throw Exception('The amount overflows. icp-amount + icp-fee*2 + the current cts-transfer-icp-fee: ${(max_transfer_record as Record)['cts_transfer_icp_fee']},  must be less than ${BigInt.from(2).pow(64)-BigInt.from(1)}');
        },
        'UserIcpLedgerBalanceTooLow': (user_icp_ledger_balance_too_low_record) async {
            Record r = user_icp_ledger_balance_too_low_record as Record;
            IcpTokens user_icp_ledger_balance = IcpTokens.oftheRecord(r['user_icp_ledger_balance']!);
            this.icp_balance = IcpTokensWithATimestamp(icp: user_icp_ledger_balance);
            IcpTokens cts_transfer_icp_fee = IcpTokens.oftheRecord(r['cts_transfer_icp_fee']!);
            throw Exception('User icp balance is too low. \nuser icp balance: ${user_icp_ledger_balance}\nCTS-fee for this transfer: ${cts_transfer_icp_fee}\nicp-ledger-fees: 0.0002');
        },
        'IcpTransferCallError': (call_error) async {
            throw Exception('Icp ledger transfer call error:\n${CallError.oftheRecord(call_error as Record)}');
        },
        'IcpTransferError': (icp_transfer_error) async {
            return match_variant<Never>(icp_transfer_error as Variant, icp_transfer_error_match_map);
        },
        'MidCallError': (transfer_icp_mid_call_error) async {
            print('transfer_icp_mid_call_error: ${transfer_icp_mid_call_error}');
            return await complete_transfer_icp();
        }
    };

    Map<String, Future<TransferIcpSuccess> Function(CandidType)> get complete_transfer_icp_error_match_map => {
        'UserIsNotInTheMiddleOfATransferIcpCall': (n) async {
            throw Exception('user is not in the middle of a transfer_icp call.');
        },
        'TransferIcpError': (transfer_icp_error) async {
            return await match_variant<Future<TransferIcpSuccess>>(transfer_icp_error as Variant, transfer_icp_error_match_map);
        }  
    };

    Future<TransferIcpSuccess> transfer_icp(TransferIcpQuest transfer_icp_quest) async {
        await this.fresh_icp_balance();
        IcpTokensWithATimestamp? icp_balance = this.icp_balance;
        if (icp_balance != null) {
            if (icp_balance.icp < transfer_icp_quest.icp) {
                throw Exception('user icp balance is too low. current balance: ${icp_balance.icp}');
            }
        }
        Variant transfer_icp_result = c_backwards(
            await call(
                cts,
                calltype: CallType.call,
                method_name: 'transfer_icp',
                put_bytes: c_forwards([transfer_icp_quest])
            )
        )[0] as Variant;
        return await match_variant<Future<TransferIcpSuccess>>(transfer_icp_result, transfer_icp_result_match_map);
    }
    
    Future<TransferIcpSuccess> complete_transfer_icp() async {
        Variant complete_transfer_icp_result = c_backwards(
            await call(
                cts,
                calltype: CallType.call,
                method_name: 'complete_transfer_icp',
                put_bytes: c_forwards([])
            )
        )[0] as Variant;
        return await match_variant<Future<TransferIcpSuccess>>(complete_transfer_icp_result, complete_transfer_icp_result_match_map);
    }





}




class BurnIcpMintCyclesSuccess {
    final Cycles mint_cycles_for_the_user;
    final Cycles cts_fee_taken;
    
    BurnIcpMintCyclesSuccess({required this.mint_cycles_for_the_user, required this.cts_fee_taken});
    
    static BurnIcpMintCyclesSuccess oftheRecord(CandidType burn_icp_mint_cycles_success_record) {
        Record r = burn_icp_mint_cycles_success_record as Record;
        return BurnIcpMintCyclesSuccess(
            mint_cycles_for_the_user: Cycles.oftheNat(r['mint_cycles_for_the_user'] as Nat),
            cts_fee_taken: Cycles.oftheNat(r['cts_fee_taken'] as Nat)            
        );
    }
    
    String toString() {
        return 'cycles-mint: ${this.mint_cycles_for_the_user}';
    }
}


class TransferIcpQuest extends Record {
    final Nat64 memo;
    final IcpTokens icp;
    final IcpTokens icp_fee;
    final String to;
    
    TransferIcpQuest({
        required this.memo,
        required this.icp,
        required this.icp_fee,
        required this.to
    }) {
        super['memo'] = this.memo;
        super['icp'] = this.icp;
        super['icp_fee'] = this.icp_fee;
        super['to'] = Blob(hexstringasthebytes(this.to));
    }
    
}

class TransferIcpSuccess {
    final Nat64 block_height;

    TransferIcpSuccess({required this.block_height});
    
    static TransferIcpSuccess oftheRecord(CandidType transfer_icp_success_record) {
        Record r = transfer_icp_success_record as Record;
        return TransferIcpSuccess(
            block_height: r['block_height'] as Nat64
        );
    }
    
    String toString() {
        return 'block_height: ${this.block_height.value}';
    }       
}


