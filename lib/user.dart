import 'dart:typed_data';
import 'dart:html';
import 'dart:math';

import 'package:ic_tools/ic_tools.dart';
import 'package:ic_tools/candid.dart';
import 'package:ic_tools/tools.dart';
import 'package:ic_tools/common.dart';
import 'package:ic_tools/common_web.dart';

import 'transfer_icp/icp_ledger.dart';
import 'cycles_bank/cycles_bank.dart';
import 'config/state.dart';
import 'tools/tools.dart';

class User {
    CustomState state;
    
    final IICaller caller;
    
    BigInt? get expiration_timestamp_nanoseconds => caller.legations.expiration_timestamp_nanoseconds;
    Uint8List get public_key_DER => caller.public_key_DER;
    Principal get principal => caller.principal;
    
    late final Uint8List user_icp_subaccount_bytes;
    late final String user_icp_id;
    
    IcpTokensWithATimestamp? icp_balance;
    List<IcpTransfer> icp_transfers = [];
    CyclesBank? cycles_bank;
    
    UserBank? get bank => this.cycles_bank;
    void set bank(UserBank? b) { this.cycles_bank = b; } 
    
    User({
        required this.state,
        required this.caller,
        this.icp_balance,
        this.cycles_bank,
    }) {
        this.user_icp_subaccount_bytes = principal_as_an_icpsubaccountbytes(this.principal);
        this.user_icp_id = icp_id(cts.principal, subaccount_bytes: user_icp_subaccount_bytes);
    }

        
    Future<Uint8List> call(Canister canister, {required CallType calltype, required String method_name, Uint8List? put_bytes, Duration timeout_duration = const Duration(minutes: 10)}) {
        return canister.call(caller:this.caller, calltype:calltype, method_name:method_name, put_bytes:put_bytes, timeout_duration:timeout_duration);
    }
    
    
    
    Future<void> fresh_icp_balance() async {
    
        Record icptokens_record = (c_backwards(await SYSTEM_CANISTERS.ledger.call(
            calltype: CallType.query,
            method_name: 'account_balance',
            put_bytes: c_forwards([
                Record.of_the_map({
                    'account': Blob(hexstringasthebytes(this.user_icp_id))
                })
            ])
        )))[0] as Record;
        
        this.icp_balance = IcpTokensWithATimestamp(
            icp: IcpTokens.of_the_record(icptokens_record)
        );
    }

    Future<void> fresh_icp_transfers() async {
        this.icp_transfers = [
            ...await get_icp_transfers(
                this.user_icp_id, 
                already_have: this.icp_transfers.length
            ),
            ...this.icp_transfers
        ];
    }
        


    // ---------------------
    

    
    
    
    // ----------------------
    
    
    
    Map<String, Never Function(CandidType)> find_user_in_the_cbs_maps_error_match_map = {
        'CBSMapsFindUserCallFails': (vec) {
            String error_string = 'Find the user\'s cycles-bank error: \ncycles-banks-maps-canisters call error(s): ';
            for (Record call_fail in (vec as Vector).cast_vector<Record>()) {
                error_string = error_string + '\ncbs_map: ${(call_fail[0] as Principal).text}, ${CallError.of_the_record(call_fail[1] as Record)}';                   
            }
            throw Exception(error_string);
        }
    };
    
    Map<String, Never Function(CandidType)> get ledger_topup_cycles_cmc_icp_transfer_error_match_map => {
        'IcpTransferCallError': (call_error) {
            throw Exception('Icp ledger transfer call error:\n${CallError.of_the_record(call_error as Record)}');
        },
        'IcpTransferError': (icp_transfer_error) {
            return match_variant<Never>(icp_transfer_error as Variant, icp_transfer_error_match_map);
        }
    };

    Map<String, Never Function(CandidType)> get icp_transfer_error_match_map => {
        'BadFee': (expected_fee_record) {
            throw Exception('Bad Fee set on the transfer. expected_fee: ${IcpTokens.of_the_record((expected_fee_record as Record)['expected_fee']!)}');
        },
        'InsufficientFunds': (balance_record) {
            IcpTokens current_balance = IcpTokens.of_the_record((balance_record as Record)['balance']!);
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
            Option<Principal> opt_user_canister_id = CandidType.as_option<Principal>(find_cycles_bank_sponse[Ok]!);
            if (opt_user_canister_id.value != null) {
                this.cycles_bank = CyclesBank(opt_user_canister_id.value!, this);
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
                    window.alert('create_membership is complete.\ncycles_bank: ${this.cycles_bank}');
                }).catchError((e){
                    window.alert('create_membership error: \n${e}');
                });
            }
            throw Exception('user is in the middle of a different create_membership call.');
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
        'LengthenMembershipCall': (must_call_complete_record) {
            if (((must_call_complete_record as Record)['must_call_complete'] as Bool).value == true) {
                complete_lengthen_membership()
                .then((x){
                    window.alert('lengthen_membership is complete.');
                }).catchError((e){
                    window.alert('lengthen_membership error: \n${e}');
                });
            }
            throw Exception('user is in the middle of a different lengthen_membership call.');
        },
        'LengthenMembershipCBCyclesPaymentCall': (must_call_complete_record) {
            if (((must_call_complete_record as Record)['must_call_complete'] as Bool).value == true) {
                complete_lengthen_membership_cb_cycles_payment()
                .then((x){
                    window.alert('lengthen_membership is complete.');
                }).catchError((e){
                    window.alert('lengthen_membership error: \n${e}');
                });
            }
            throw Exception('user is in the middle of a different lengthen_membership call.');
        }
    };


    // -----------------------------


    Map<String, Future<void> Function(CandidType)> get purchase_cycles_bank_error_match_map => {
        'MidCallError': (mid_call_error) async {
            print('create_membership mid_call_error: ${mid_call_error}');
            return await this.complete_purchase_cycles_bank();          
        },
        'FoundCyclesBank':(cycles_bank_principal) async {
            this.cycles_bank = CyclesBank((cycles_bank_principal as Principal), this);    
        },
        'UserIcpLedgerBalanceTooLow':(user_icp_ledger_balance_too_low_ctype) async {
            Record user_icp_ledger_balance_too_low_error = user_icp_ledger_balance_too_low_ctype as Record;
            IcpTokens cycles_bank_cost_icp = IcpTokens.of_the_record(user_icp_ledger_balance_too_low_error['membership_cost_icp']!);
            IcpTokens user_icp_ledger_balance = IcpTokens.of_the_record(user_icp_ledger_balance_too_low_error['user_icp_ledger_balance']!);
            this.icp_balance = IcpTokensWithATimestamp(icp: user_icp_ledger_balance);
            IcpTokens icp_ledger_transfer_fee = IcpTokens.of_the_record(user_icp_ledger_balance_too_low_error['icp_ledger_transfer_fee']!);
            IcpTokens must_be_with_the_icp_balance = IcpTokens(e8s: cycles_bank_cost_icp.e8s + (icp_ledger_transfer_fee.e8s*BigInt.from(2)));
            try{ await state.fresh_xdr_icp_rate(); }catch(e){ print('fresh_xdr_icp_rate error: ${etext(e)}'); }
            throw Exception('User icp balance is too low.\ncurrent membership cost icp: ${ must_be_with_the_icp_balance }\ncurrent user icp balance: ${user_icp_ledger_balance}');
        }, 
        'UserIsInTheMiddleOfADifferentCall': (user_is_in_the_middle_of_a_different_call_variant) async {
            match_variant<Never>(user_is_in_the_middle_of_a_different_call_variant as Variant, user_is_in_the_middle_of_a_different_call_variant_match_map);
        },
        'ReferralUserCannotBeTheCaller': (n) async {
            throw Exception('The referral-user cannot be the caller.');
        },
        'CheckIcpBalanceCallError': (call_error_record) async {
            throw Exception('Error when checking the user\'s icp balance:\n${CallError.of_the_record(call_error_record as Record)}');
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
            throw Exception('System error when creating a membership. please file this error:\n${cmc_notify_error}');
        }
    };
    
    Map<String, Future<void> Function(CandidType)> get purchase_cycles_bank_result_match_map => {
        Ok: (purchase_cycles_bank_success_ctype) async {
            Record purchase_cycles_bank_success = purchase_cycles_bank_success_ctype as Record;
            this.cycles_bank = CyclesBank((purchase_cycles_bank_success['cycles_bank_canister_id'] as Principal), this);  
            
            this.cycles_bank!.fresh_known_cm_trade_contracts_of_the_cm_main();
            await Future.wait([
                this.fresh_icp_balance(),                
                this.cycles_bank!.fresh_metrics(),
                this.cycles_bank!.fresh_icrc1_balances(),
                this.cycles_bank!.fresh_icrc1_transactions(),
                Future(()async{
                    int i = 0;
                    while (true) { // might get a malicious replica
                        Blob cts_cb_authorization = c_backwards_one(
                            await call(
                                cts,
                                method_name: "get_cb_auth",
                                calltype: CallType.query,
                                put_bytes: c_forwards_one(this.cycles_bank!.principal),
                            )
                        ) as Blob;
                        try {
                            await call(
                                this.cycles_bank!,
                                method_name: "user_upload_cts_cb_authorization",
                                put_bytes: c_forwards_one(cts_cb_authorization),
                                calltype: CallType.call,
                            );
                            break;
                        } catch(e) {
                            print('error uploading cts-cb-auth into the cb.\n${e}');
                            i += 1;
                            if (i == 5) {
                                break;
                            }
                            continue;
                        }
                    }
                })
            ]);
        },
        Err: (purchase_cycles_bank_error) async {
            return await match_variant<Future<void>>(purchase_cycles_bank_error as Variant, purchase_cycles_bank_error_match_map);
        }  
    };

    Map<String, Future<void> Function(CandidType)> get complete_purchase_cycles_bank_error_match_map => {
        'UserIsNotInTheMiddleOfAPurchaseCyclesBankCall': (n) async {
            throw Exception('user is not in the middle of a create_membership call.');
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


    Future<void> purchase_cycles_bank({required Principal? opt_referral_user_id}) async {
        await Future.wait([
            this.fresh_icp_balance(),
            state.fresh_xdr_icp_rate()
        ]);
        IcpTokens cycles_bank_total_cost_icp = IcpTokens(e8s: cycles_transform_tokens(state.cts_fees.membership_cost_per_year_cycles, state.cmc_cycles_per_icp_rate) + BigInt.from(1)/*bc cycles_transform_tokens cuts off any remainder cycles*/ + ICP_LEDGER_TRANSFER_FEE_TIMES_TWO.e8s);
        if (this.icp_balance!.icp < cycles_bank_total_cost_icp) {
            throw Exception('user icp balance is too low.\ncurrent membership cost icp: ${cycles_bank_total_cost_icp}-icp\ncurrent user icp balance: ${this.icp_balance!.icp}');
        }
        Variant purchase_cycles_bank_result = c_backwards(
            await call(
                cts,
                calltype: CallType.call,
                method_name: 'create_membership',
                put_bytes: c_forwards([
                    Record.of_the_map({
                        'opt_referral_user_id': Option(value: opt_referral_user_id, value_type: Principal.type_mode())
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
                method_name: 'complete_create_membership',
                put_bytes: c_forwards([])
            )
        )[0] as Variant;
        return await match_variant<Future<void>>(complete_purchase_cycles_bank_result, complete_purchase_cycles_bank_result_match_map);
    }
    



    // ----------------------
    
    
    
    Map<String, Future<TransferIcpSuccess> Function(CandidType)> get transfer_icp_result_match_map => {
        Ok: (transfer_icp_success) async {
            return TransferIcpSuccess.of_the_record(transfer_icp_success);
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
            throw Exception('Error when checking the user icp balance on the ledger.\n${CallError.of_the_record(call_error as Record)}');
        },
        'CTSIsBusy': (n) async {
            throw Exception('The CTS is busy, try soon.');
        },
        'CheckCurrentXdrPerMyriadPerIcpCmcRateError': (check_current_xdr_icp_cmc_rate_error) async {
            print('check_current_xdr_icp_cmc_rate_error: ${check_current_xdr_icp_cmc_rate_error}');
            throw Exception('Error when checking the current xdr-icp rate.');
        },
        'MaxTransfer': (max_transfer_record) async {
            throw Exception('The amount overflows. icp-transfer-amount + icp-fee*2: ${ICP_LEDGER_TRANSFER_FEE_TIMES_TWO} + the current cts-transfer-icp-fee: ${IcpTokens.of_the_record((max_transfer_record as Record)['cts_transfer_icp_fee'] as Record)}, must be less than ${(BigInt.from(2).pow(64)-BigInt.from(1))/BigInt.from(10).pow(8)}');
        },
        'UserIcpLedgerBalanceTooLow': (user_icp_ledger_balance_too_low_record) async {
            Record r = user_icp_ledger_balance_too_low_record as Record;
            IcpTokens user_icp_ledger_balance = IcpTokens.of_the_record(r['user_icp_ledger_balance']!);
            this.icp_balance = IcpTokensWithATimestamp(icp: user_icp_ledger_balance);
            IcpTokens cts_transfer_icp_fee = IcpTokens.of_the_record(r['cts_transfer_icp_fee']!);
            throw Exception(user_cts_icp_balance_is_too_low_for_the_icp_transfer(user_icp_ledger_balance, state.cts_fees.cts_transfer_icp_fee, cts_transfer_icp_fee));
        },
        'IcpTransferCallError': (call_error) async {
            throw Exception('Icp ledger transfer call error:\n${CallError.of_the_record(call_error as Record)}');
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
    
    late IcpTokens latest_try_to_transfer_icp;
    String user_cts_icp_balance_is_too_low_for_the_icp_transfer(IcpTokens cts_user_icp_balance, Cycles cts_transfer_icp_fee_cycles, IcpTokens cts_transfer_icp_fee_icp) {
        return 'user-cts-icp-balance is too low. \nuser-cts-icp-balance: ${cts_user_icp_balance}\ntried to transfer icp: ${latest_try_to_transfer_icp}\ncts-icp-transfer-fee: ${cts_transfer_icp_fee_icp}-icp (${cts_transfer_icp_fee_cycles.cycles/Cycles.T_CYCLES_DIVIDABLE_BY}-xdr)\nicp-ledger-fees: ${ICP_LEDGER_TRANSFER_FEE_TIMES_TWO}'; // user icp balance is too low. current balance: ${this.icp_balance!.icp}\nCTS transfer-icp fee: ${cts_transfer_icp_fee}\nicp-ledger-transfer-fee * 2: ${ICP_LEDGER_TRANSFER_FEE_TIMES_TWO}'); 
    }
    
    Future<TransferIcpSuccess> transfer_icp(TransferIcpQuest transfer_icp_quest) async {
        latest_try_to_transfer_icp = transfer_icp_quest.icp;
        await this.fresh_icp_balance();
        await state.fresh_xdr_icp_rate();
        IcpTokens cts_transfer_icp_fee = IcpTokens(e8s: cycles_transform_tokens(state.cts_fees.cts_transfer_icp_fee, state.cmc_cycles_per_icp_rate));
        if (this.icp_balance!.icp < transfer_icp_quest.icp + cts_transfer_icp_fee + ICP_LEDGER_TRANSFER_FEE_TIMES_TWO) {
            throw Exception(user_cts_icp_balance_is_too_low_for_the_icp_transfer(this.icp_balance!.icp, state.cts_fees.cts_transfer_icp_fee, cts_transfer_icp_fee));
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



    // --------------------------
    
    
    Map<String, Future<LengthenMembershipSuccess> Function(CandidType)> lengthen_membership_result_match_map(Future<LengthenMembershipSuccess> Function() complete_fn) => {
        Ok: (lengthen_membership_success) async {
            return LengthenMembershipSuccess.of_the_record(lengthen_membership_success as Record);
        },
        Err: (lengthen_membership_error) async {
            return await match_variant<Future<LengthenMembershipSuccess>>(lengthen_membership_error as Variant, lengthen_membership_error_match_map(complete_fn));
        }
    };
    
    Map<String, Future<LengthenMembershipSuccess> Function(CandidType)> complete_lengthen_membership_result_match_map(Future<LengthenMembershipSuccess> Function() complete_fn) => {
        Ok: (lengthen_membership_success) async {
            return await lengthen_membership_result_match_map(complete_fn)[Ok]!(lengthen_membership_success);
        },
        Err: (complete_lengthen_membership_error) async {
            return await match_variant<Future<LengthenMembershipSuccess>>(complete_lengthen_membership_error as Variant, complete_lengthen_membership_error_match_map(complete_fn));
        }
    };
    
    Map<String, Future<LengthenMembershipSuccess> Function(CandidType)> lengthen_membership_error_match_map(Future<LengthenMembershipSuccess> Function() complete_fn) => {
        'LengthenYearsCannotBeZero': (nul) async {
            throw Exception('Lengthen years cannot be zero');
        },
        'UserIsInTheMiddleOfADifferentCall': (user_is_in_the_middle_of_a_different_call) async {
            return match_variant<Never>(user_is_in_the_middle_of_a_different_call as Variant, user_is_in_the_middle_of_a_different_call_variant_match_map);
        },
        'CTSIsBusy': (nul) async {
            throw Exception('The CTS is busy. try soon.');
        },
        'MembershipNotFound': (nul) async {
            throw Exception('CTS membership not found. Create a membership first before lengthening the membership.');
        },
        'FindUserInTheCBSMapsError': (find_user_in_the_cbs_maps_error) async {
            try {
                match_variant<Never>(find_user_in_the_cbs_maps_error as Variant, find_user_in_the_cbs_maps_error_match_map);
            } catch(e) {
                print(e);
            }
            throw Exception('Error finding the membership data. try soon.');
        },
        'CallerIsNotTheCyclesBankOfTheUser': (n) async {
            throw Exception('CallerIsNotTheCyclesBankOfTheUser');
        },
        'CheckIcpBalanceCallError': (call_error) async {
            throw Exception('Error checking the user\'s ICP balance, try soon. \n${CallError.of_the_record(call_error as Record)}');
        },
        'CheckCurrentXdrPerMyriadPerIcpCmcRateError': (check_current_xdr_icp_cmc_rate_error) async {
            print('check_current_xdr_icp_cmc_rate_error: ${check_current_xdr_icp_cmc_rate_error}');
            throw Exception('Error when checking the current xdr-icp rate.');
        },
        'UserIcpLedgerBalanceTooLow': /*{
            membership_cost_per_year_cycles: Cycles,
            current_xdr_permyriad_per_icp_rate: u64, 
            icp_ledger_transfer_fee: IcpTokens,
            user_icp_ledger_balance: IcpTokens,
        }*/ (record) async {
            Record r = record as Record;
            Cycles membership_cost_per_year_cycles = Cycles.oftheNat(r['membership_cost_per_year_cycles'] as Nat);
            state.cts_fees.membership_cost_per_year_cycles = membership_cost_per_year_cycles;
            IcpTokens user_icp_ledger_balance = IcpTokens.of_the_record(r['user_icp_ledger_balance'] as Record);
            this.icp_balance = IcpTokensWithATimestamp(
                icp: user_icp_ledger_balance
            );
            throw Exception('User CTS ICP balance is too low. \nuser cts icp balance: ${user_icp_ledger_balance}');
        },
        'MidCallError': (/*covariant Variant*/ lengthen_membership_mid_call_error_ctype) async {
            Variant lengthen_membership_mid_call_error = lengthen_membership_mid_call_error_ctype as Variant;
            print(lengthen_membership_mid_call_error.keys.first);
            for (String s in [
                'PositCyclesIntoTheCyclesBankCallError',
                'LedgerTopupCyclesCmcIcpTransferError',
                'LedgerTopupCyclesCmcNotifyError',
                'CollectIcpTransferCallError',
                'CollectIcpTransferError',
                'CBSMUpdateUserCallError',
                'CBUpdateMembershipLengthCallError',
            ]) {
                if (candid_text_hash(s) == lengthen_membership_mid_call_error.keys.first) {
                    print(s);
                    break;
                }
            }
            print(lengthen_membership_mid_call_error.values.first);
            return await complete_fn();
        },
        
    };
    
    Map<String, Future<LengthenMembershipSuccess> Function(CandidType)> complete_lengthen_membership_error_match_map(Future<LengthenMembershipSuccess> Function() complete_fn) => {
        'UserIsNotInTheMiddleOfALengthenMembershipCall': (n) async {
            throw Exception('User is not in the middle of a lengthen_membership call.');
        },
        'LengthenMembershipError': (lengthen_membership_error) async {
            return await match_variant<Future<LengthenMembershipSuccess>>(lengthen_membership_error as Variant, lengthen_membership_error_match_map(complete_fn));
        }
          
    };
    
    Future<LengthenMembershipSuccess> lengthen_membership(LengthenMembershipQuest lengthen_membership_quest) async {
        // check icp balance is enough
        Variant lengthen_membership_result = c_backwards(
            await call(
                cts,
                calltype: CallType.call,
                method_name: 'lengthen_membership',
                put_bytes: c_forwards([lengthen_membership_quest])
            )
        )[0] as Variant;
        return await match_variant<Future<LengthenMembershipSuccess>>(lengthen_membership_result, lengthen_membership_result_match_map(complete_lengthen_membership));
    }
    
    Future<LengthenMembershipSuccess> complete_lengthen_membership() async {
        Variant complete_lengthen_membership_result = c_backwards(
            await call(
                cts,
                calltype: CallType.call,
                method_name: 'complete_lengthen_membership',
                put_bytes: c_forwards([])
            )
        )[0] as Variant;
        return await match_variant<Future<LengthenMembershipSuccess>>(complete_lengthen_membership_result, complete_lengthen_membership_result_match_map(complete_lengthen_membership));
    }

    Future<LengthenMembershipSuccess> complete_lengthen_membership_cb_cycles_payment() async {
        Variant complete_lengthen_membership_result = c_backwards(
            await call(
                cts,
                calltype: CallType.call,
                method_name: 'complete_lengthen_membership_cb_cycles_payment',
                put_bytes: c_forwards([])
            )
        )[0] as Variant;
        return await match_variant<Future<LengthenMembershipSuccess>>(complete_lengthen_membership_result, complete_lengthen_membership_result_match_map(complete_lengthen_membership_cb_cycles_payment));
    }
    
    
    

}




class LengthenMembershipQuest extends Record {
    final BigInt lengthen_years;
    LengthenMembershipQuest({required this.lengthen_years}) {
        this['lengthen_years'] = Nat(this.lengthen_years);
    }
}

class LengthenMembershipSuccess {
    final BigInt lifetime_termination_timestamp_seconds;
    LengthenMembershipSuccess._({required this.lifetime_termination_timestamp_seconds});
    static LengthenMembershipSuccess of_the_record(Record r) {
        return LengthenMembershipSuccess._(
            lifetime_termination_timestamp_seconds: (r['lifetime_termination_timestamp_seconds'] as Nat).value,
        );
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
    
    static TransferIcpSuccess of_the_record(CandidType transfer_icp_success_record) {
        Record r = transfer_icp_success_record as Record;
        return TransferIcpSuccess(
            block_height: r['block_height'] as Nat64
        );
    }
    
    String toString() {
        return 'block_height: ${this.block_height.value}';
    }       
}


