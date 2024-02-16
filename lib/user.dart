import 'dart:typed_data';
import 'dart:html';
import 'dart:math';
import 'dart:collection';
import 'dart:convert';

import 'package:ic_tools/ic_tools.dart';
import 'package:ic_tools/candid.dart';
import 'package:ic_tools/tools.dart';
import 'package:ic_tools/common.dart';
import 'package:ic_tools/common.dart' as common;
import 'package:ic_tools/common_web.dart';

import 'transfer_icp/icp_ledger.dart';
import 'config/state.dart';
import 'tools/tools.dart';
import 'cycles_market/cycles_market.dart';

class User {
    CustomState state;
    
    final IICaller caller;
    
    BigInt? get expiration_timestamp_nanoseconds => caller.legations.expiration_timestamp_nanoseconds;
    Uint8List get public_key_DER => caller.public_key_DER;
    Principal get principal => caller.principal;
    
    late final String icp_id;
    //List<Icrc1Ledger> known_icrc1_ledgers = [CYCLES_BANK_LEDGER, Icrc1Ledgers.ICP];
    Map<Icrc1Ledger, BigInt> icrc1_balances_cache = {CYCLES_BANK_LEDGER: BigInt.zero, Icrc1Ledgers.ICP: BigInt.zero};
    Map<Icrc1Ledger, List<Icrc1Transaction>> icrc1_transactions_cache = {};
    List<IcpTransfer> icp_transfers = []; // icp-transfer logs are different than the icrc1-transfer-logs    
    List<CyclesTransfer> cycles_transfers = []; // cycles-transfer logs are different than the icrc1-transfer-logs
        
    Map<Icrc1Ledger, Future> first_load_icrc1ledgers_balances = {};
    Map<Icrc1Ledger, Future> first_load_icrc1ledgers_transactions = {};
    Map<Icrc1TokenTradeContract, Future> first_load_tcs = {};
    
    Map<Icrc1TokenTradeContract, UserCMTradeContractData> cm_trade_contracts = {};
    
    // for the mint_cycles through the cycles-bank.
    late final Uint8List bank_mint_cycles_user_icp_subaccount_bytes;
    late final String bank_mint_cycles_user_icp_id;
    BigInt bank_user_subaccount_icp_balance = BigInt.zero; // is load in the loadfirststate

    
    User({
        required this.state,
        required this.caller,
    }) {
        this.icp_id = common.icp_id(this.principal);
        this.bank_mint_cycles_user_icp_subaccount_bytes = principal_as_an_icpsubaccountbytes(this.principal);
        this.bank_mint_cycles_user_icp_id = common.icp_id(CYCLES_BANK_LEDGER.ledger.principal, subaccount_bytes: bank_mint_cycles_user_icp_subaccount_bytes);
    }
            
    Future<Uint8List> call(Canister canister, {required CallType calltype, required String method_name, Uint8List? put_bytes, Duration timeout_duration = const Duration(minutes: 10)}) {
        return canister.call(caller:this.caller, calltype:calltype, method_name:method_name, put_bytes:put_bytes, timeout_duration:timeout_duration);
    }
            
    void fresh_known_cm_trade_contracts_of_the_cm_main() {
        for (Icrc1TokenTradeContract tc in this.state.cm_main.trade_contracts) {
            /*
            if (this.known_icrc1_ledgers.contains(tc.ledger_data) == false) {
                this.known_icrc1_ledgers.add(tc.ledger_data);
            }
            */
            if (this.cm_trade_contracts.containsKey(tc) == false) {
                this.cm_trade_contracts[tc] = UserCMTradeContractData();
            }
        }
    }
    
    Future<void> fresh_icrc1_balances([List<Icrc1Ledger>? icrc1_ledgers]) async {
        List<Icrc1Ledger> ledgers = icrc1_ledgers ?? this.state.known_icrc1_ledgers;
        await Future.wait(
            ledgers.map((l)=>Future(()async{
                BigInt balance = await check_icrc1_balance(
                    icrc1_ledger_canister_id: l.ledger.principal,
                    owner: this.principal,
                    calltype: CallType.query
                );                
                this.icrc1_balances_cache[l] = balance;
            }))    
        );
    }
    // helper for fresh_icrc1_transactions
    Future<Variant> _call_icrc1_index_transactions(Icrc1Ledger l, [Nat? start]) async {
        final Map<String, String> ledger_index = {
            'zfcdd-tqaaa-aaaaq-aaaga-cai': 'zlaol-iaaaa-aaaaq-aaaha-cai', // DKP
            '2ouva-viaaa-aaaaq-aaamq-cai': '2awyi-oyaaa-aaaaq-aaanq-cai', // CHAT
            '73mez-iiaaa-aaaaq-aaasq-cai': '7vojr-tyaaa-aaaaq-aaatq-cai', // Kinic
            '6rdgd-kyaaa-aaaaq-aaavq-cai': '6dfr2-giaaa-aaaaq-aaawq-cai', // Hot or Not
            '4c4fd-caaaa-aaaaq-aaa3a-cai': '5ithz-aqaaa-aaaaq-aaa4a-cai', // ICGhost
            'xsi2v-cyaaa-aaaaq-aabfq-cai': 'xaonm-oiaaa-aaaaq-aabgq-cai', // Modclub
            'rxdbk-dyaaa-aaaaq-aabtq-cai': 'q5mdq-biaaa-aaaaq-aabuq-cai', // Nuance
            'tyyy3-4aaaa-aaaaq-aab7a-cai': 'efv5g-kqaaa-aaaaq-aacaa-cai', // Gold DAO
            'emww2-4yaaa-aaaaq-aacbq-cai': 'e6qbd-qiaaa-aaaaq-aaccq-cai', // TRAX
            'f54if-eqaaa-aaaaq-aacea-cai': 'ft6fn-7aaaa-aaaaq-aacfa-cai', // Neutrinite
            'hvgxa-wqaaa-aaaaq-aacia-cai': 'h3e2i-naaaa-aaaaq-aacja-cai', // Sneed 
        }; 
        return c_backwards(await Canister(Principal.text(ledger_index[l.ledger.principal.text]!)).call(
            calltype: CallType.call,
            method_name: 'get_account_transactions',
            put_bytes: c_forwards([
                Record.of_the_map({
                    'account' : Icrc1Account(owner: this.principal),
                    'start' : Option<Nat>(value: start, value_type: Nat()),
                    'max_results' : Nat(BigInt.from(500)),
                })
            ])
        )).first as Variant;
    } 
    Future<void> fresh_icrc1_transactions([List<Icrc1Ledger>? icrc1_ledgers]) {
        List<Icrc1Ledger> ledgers = icrc1_ledgers ?? this.state.known_icrc1_ledgers;
        return Future.wait(
            ledgers.map<Future<void>>((l)=>Future(()async{
                // ICP transactions
                if (l.ledger.principal == SYSTEM_CANISTERS.ledger.principal) {
                    if (is_on_local == true) {
                        await Future.delayed(Duration(milliseconds: 50)); // for the frames
                        return;
                    }                    
                    // for the do! hook up with the new icp index canister
                    this.icp_transfers = [
                        ...await get_icp_transfers(this.icp_id, already_have: this.icp_transfers.length),
                        ...this.icp_transfers
                    ];
                    
                } else if (l == CYCLES_BANK_LEDGER) {
                    
                    BigInt? earliest_known_id;
                    List<CyclesTransfer> gather = [];
                    while (true) {
                        Record sponse = c_backwards_one(await this.call(
                            CYCLES_BANK_LEDGER.ledger,
                            method_name: 'get_logs_backwards',
                            put_bytes: c_forwards([
                                Icrc1Account(owner: this.principal), 
                                Option<Nat>(value: earliest_known_id.nullmap((id)=>Nat(id)), value_type: Nat())
                            ]),
                            calltype: CallType.query,
                        )) as Record;
                        
                        List<CyclesTransfer> logs = (sponse['logs'] as Vector).cast_vector<Record>().map(CyclesTransfer.of_the_record).toList();
                        
                        gather = [
                            ...logs,
                            ...gather
                        ];
                        
                        if (this.cycles_transfers.length != 0 && gather.length != 0 && this.cycles_transfers.last.id >= gather.first.id) {
                            gather = gather.skipWhile((l)=>l.id <= this.cycles_transfers.last.id).toList();
                            break;
                        }                    
                        
                        if ((sponse['is_last_chunk'] as Bool).value == true || gather.length == 0) {
                            break;
                        }
                        
                        earliest_known_id = logs.first.id;
                    }
    
                    this.cycles_transfers.addAll(gather);     
                    
                } else /*tokens besides icp or cycles*/{ 
                    if (is_on_local == true) {
                        await Future.delayed(Duration(milliseconds: 50)); // for the frames
                        return;
                    }
                    
                    if (this.icrc1_transactions_cache[l] == null) { 
                        this.icrc1_transactions_cache[l] = []; 
                    }
                    if (this.icrc1_transactions_cache[l]!.length == 0) {
                        print('first load');
                        Nat? last_tx_seen = null;
                        late BigInt oldest_tx_id;
                        while (this.icrc1_transactions_cache[l]!.length == 0 || this.icrc1_transactions_cache[l]!.last.block > oldest_tx_id) {
                            print('first load loop');
                            Record data = match_variant(await _call_icrc1_index_transactions(l, last_tx_seen), {
                                Ok: (tr) => tr as Record,
                                Err: (er) => throw Exception('get transactions error: ${((er as Record)['message'] as Text).value}')
                            });
                            BigInt? oldest_tx_id_r = data.find_option<Nat>('oldest_tx_id').nullmap((n)=>n.value);
                            if (oldest_tx_id_r == null) { break; } else { oldest_tx_id = oldest_tx_id_r; }
                            Vector<Record> ts = (data['transactions'] as Vector).cast_vector<Record>();
                            last_tx_seen = ts.length == 0 ? null : ts.last['id'] as Nat;
                            this.icrc1_transactions_cache[l]!.addAll(ts.map<Icrc1Transaction>(Icrc1Transaction.of_the_record).toList());
                        
                        }
                    } else /*get new*/ {
                        print('load new');
                        Nat? last_tx_seen = null;
                        List<Icrc1Transaction> new_transactions = [];
                        while (true) {
                            print('load new loop');
                            Record data = match_variant(await _call_icrc1_index_transactions(l, last_tx_seen), {
                                Ok: (tr) => tr as Record,
                                Err: (er) => throw Exception('get transactions error: ${((er as Record)['message'] as Text).value}'),
                            });
                            Vector<Record> ts = (data['transactions'] as Vector).cast_vector<Record>();
                            last_tx_seen = ts.length == 0 ? null : ts.last['id'] as Nat;
                            List<Icrc1Transaction> new_ts = ts.map<Icrc1Transaction>(Icrc1Transaction.of_the_record).takeWhile((Icrc1Transaction t)=>t.block > this.icrc1_transactions_cache[l]!.first.block).toList(); 
                            new_transactions.addAll(new_ts);
                            if (new_ts.length != ts.length) {
                                break;
                            }
                        }
                        this.icrc1_transactions_cache[l] = [
                            ...new_transactions,
                            ...this.icrc1_transactions_cache[l]!
                        ];
                    }
                }
            }))
        );
    }
    
    Future<BigInt/*block_height*/> transfer_icrc1(Icrc1Ledger icrc1_ledger, Uint8List icrc1_transfer_arg_raw) async {
        Variant sponse = c_backwards(
            await this.call(
                icrc1_ledger.ledger,
                method_name: 'icrc1_transfer',
                calltype: CallType.call,
                put_bytes: icrc1_transfer_arg_raw
            )
        ).first as Variant;
        BigInt block_height = match_variant<BigInt>(sponse, {
            Ok: (block_height) {
                return (block_height as Nat).value;
            },
            Err: (icrc1_transfer_error) {
                return match_variant<Never>(icrc1_transfer_error as Variant, icrc1_transfer_error_match_map(icrc1_ledger));
            }
        });
        return block_height;
    }
    
    Map<String, Never Function(CandidType)> icrc1_transfer_error_match_map(Icrc1Ledger icrc1_ledger) {
        return {
            'BadFee' : (r) {
                throw Exception('Fee must be: ${Tokens(quantums: ((r as Record)['expected_fee'] as Nat).value, decimal_places: icrc1_ledger.decimals)}');
            },
            'BadBurn' : (r) {   
                throw Exception('BadBurn: min_burn_amount: ${Tokens(quantums: ((r as Record)['min_burn_amount'] as Nat).value, decimal_places: icrc1_ledger.decimals)} ');
            },
            'InsufficientFunds' : (r) {
                BigInt balance = ((r as Record)['balance'] as Nat).value;
                // do *not* save the balance here in the icrc1_balances_cache because this map is also used for the cm_transfer_balance TransferError. 
                throw Exception('InsufficientFunds. current-balance: ${Tokens(quantums: balance, decimal_places: icrc1_ledger.decimals)}');
            },
            'TooOld': (n) {
                throw Exception('transaction too old');
            },
            'CreatedInFuture' : (r) {
                throw Exception('transaction created in the future.\ncurrent_time: ${datetime_of_the_nanoseconds(((r as Record)['ledger_time'] as Nat64).value)}');
            },
            'Duplicate' : (r) {
                throw Exception('Transaction duplicate found: ${((r as Record)['duplicate_of'] as Nat).value}');
            },
            'TemporarilyUnavailable': (n) {
                throw Exception('The ${icrc1_ledger.symbol} ledger is busy.');
            },
            'GenericError' : (rc) {
                Record r = rc as Record;
                throw Exception('GenericError. \nerror_code: ${(r['error_code'] as Nat).value}\nmessage: ${(r['message'] as Text).value}');
            }         
        };
    }
    

    Future<BigInt> transfer_icp(Uint8List transfer_arg_raw) async {
        Variant sponse = c_backwards(
            await this.call(
                SYSTEM_CANISTERS.ledger,
                method_name: 'transfer',
                calltype: CallType.call,
                put_bytes: transfer_arg_raw
            )
        ).first as Variant;
        BigInt block_height = match_variant<BigInt>(sponse, {
            Ok: (n64) {
                return (n64 as Nat64).value;
            },
            Err: (icp_transfer_error) {
                match_variant<Never>(icp_transfer_error as Variant, {
                    'BadFee': (expected_fee_record) {
                        throw Exception('Bad Fee set on the transfer. expected_fee: ${IcpTokens.of_the_record((expected_fee_record as Record)['expected_fee']!)}');
                    },
                    'InsufficientFunds': (balance_record) {
                        IcpTokens current_balance = IcpTokens.of_the_record((balance_record as Record)['balance']!);
                        this.icrc1_balances_cache[Icrc1Ledgers.ICP] = current_balance.e8s;
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
                });
            }
        });
        return block_height;    
    }
    
    // ----
    // burn icp mint cycles
    Future<void> fresh_bank_user_subaccount_icp_balance() async {
        this.bank_user_subaccount_icp_balance = await check_icrc1_balance(
            icrc1_ledger_canister_id: SYSTEM_CANISTERS.ledger.principal, 
            owner: CYCLES_BANK_LEDGER.ledger.principal, 
            subaccount: bank_mint_cycles_user_icp_subaccount_bytes, 
            calltype: CallType.query
        );
    }
    
    Future<BurnIcpMintCyclesSuccess> burn_icp_mint_cycles(BigInt burn_icp) async {
        await this.fresh_bank_user_subaccount_icp_balance();
        if (this.bank_user_subaccount_icp_balance < burn_icp + Icrc1Ledgers.ICP.fee) {
            await transfer_icp(
                c_forwards_one(Record.of_the_map({
                    'memo': Nat64(BigInt.from(4)),
                    'amount': IcpTokens(e8s: burn_icp + Icrc1Ledgers.ICP.fee - this.bank_user_subaccount_icp_balance),
                    'fee': ICP_LEDGER_TRANSFER_FEE,
                    'from_subaccount': Option<Blob>(value: null, value_type: Blob.type_mode()),
                    'to': Blob(hexstringasthebytes(this.bank_mint_cycles_user_icp_id)),
                }))
            );
        }
        Variant mint_cycles_result = c_backwards_one(
            await this.call(
                CYCLES_BANK_LEDGER.ledger,
                calltype: CallType.call,
                method_name: 'mint_cycles',
                put_bytes: c_forwards([
                    Record.of_the_map({
                        'to' : Icrc1Account(owner: this.principal),
                        'fee' : Option<Nat>(value: Nat(CYCLES_BANK_LEDGER.fee)),
                        'burn_icp': Nat(burn_icp),
                        'burn_icp_transfer_fee': Nat(Icrc1Ledgers.ICP.fee),
                        'memo' : Option<Blob>(value: Blob(utf8.encode('CTSF'))),
                        'created_at_time' : Option<Nat64>(value:null, value_type: Nat64()),
                    })
                ])
            )
        ) as Variant;
        return await match_variant<Future<BurnIcpMintCyclesSuccess>>(mint_cycles_result, mint_cycles_result_match_map);
    }
    
    Future<BurnIcpMintCyclesSuccess> complete_burn_icp_mint_cycles() async {
        Variant complete_mint_cycles_result = c_backwards(
            await this.call(
                CYCLES_BANK_LEDGER.ledger,
                calltype: CallType.call,
                method_name: 'complete_mint_cycles',
                put_bytes: c_forwards([])
            )
        )[0] as Variant;
        return await match_variant<Future<BurnIcpMintCyclesSuccess>>(complete_mint_cycles_result, complete_mint_cycles_result_match_map);
    }
    
    Map<String, Future<BurnIcpMintCyclesSuccess> Function(CandidType)> get mint_cycles_result_match_map => {
        Ok: (burn_icp_mint_cycles_success) async {
            return BurnIcpMintCyclesSuccess.of_the_record(burn_icp_mint_cycles_success);
        },
        Err: (burn_icp_mint_cycles_error) async {
            return await match_variant<Future<BurnIcpMintCyclesSuccess>>(burn_icp_mint_cycles_error as Variant, mint_cycles_error_match_map);
        }
    };
    
    Map<String, Future<BurnIcpMintCyclesSuccess> Function(CandidType)> get complete_mint_cycles_result_match_map => {
        Ok: (burn_icp_mint_cycles_success) async {
            return await mint_cycles_result_match_map[Ok]!(burn_icp_mint_cycles_success);
        },
        Err: (complete_burn_icp_mint_cycles_error) async {
            return await match_variant<Future<BurnIcpMintCyclesSuccess>>(complete_burn_icp_mint_cycles_error as Variant, complete_mint_cycles_error_match_map);
        }
    };
    
    Map<String, Future<BurnIcpMintCyclesSuccess> Function(CandidType)> get mint_cycles_error_match_map => {
        'GenericError': (rc) async {
            Record r = rc as Record;
            throw Exception('GenericError: \nerror-code: ${(r['error_code'] as Nat).value}, message: ${(r['message'] as Text).value}');
        },
        'CBIsBusy' : (_n) async {
            throw Exception('The Bank is busy. Try soon.');
        },
        'MinimumBurnIcp' : (r) async {
            throw Exception('The minimum ICP is ${IcpTokens(e8s: ((r as Record)['minimum_burn_icp'] as Nat).value)}.');
        },
        'MidCallError':(mint_cycles_mid_call_error) async {
            print('mint_cycles_mid_call_error: ${mint_cycles_mid_call_error}');
            return await complete_burn_icp_mint_cycles();
        },
        'LedgerTopupCyclesCmcNotifyRefund': (c) async {
            BigInt rblock = ((c as Record)['block_index'] as Nat64).value;
            String reason = ((c as Record)['reason'] as Text).value;
            throw Exception('The cycles-minter-canister (nns-cmc) refunded your icp at the block-height: ${rblock} with the reason: ${reason}');
        }, 
        'BadFee': (rc) async {
            BigInt expected_fee = ((rc as Record)['expected_fee'] as Nat).value;
            CYCLES_BANK_LEDGER.fee = expected_fee;
            throw Exception('The cycles fee changed, please try again.');
        },
        'LedgerTopupCyclesCmcIcpTransferError': (ledger_topup_cycles_cmc_icp_transfer_error) async {
            return match_variant<Never>(ledger_topup_cycles_cmc_icp_transfer_error as Variant, {
                'IcpTransferCallError': (call_error) {
                    throw Exception('Icp ledger transfer call error:\n${CallError.of_the_record(call_error as Record)}');
                },
                'IcpTransferError': (icp_transfer_error) {
                    return match_variant<Never>(icp_transfer_error as Variant, icp_transfer_error_match_map);
                }
            });
        },
        'UserIsInTheMiddleOfADifferentCall': (user_is_in_the_middle_of_a_different_call_variant) async {
            print('UserIsInTheMiddleOfADifferentCall: ${user_is_in_the_middle_of_a_different_call_variant}');
            return match_variant<Never>(user_is_in_the_middle_of_a_different_call_variant as Variant, {
                'MintCyclesCall': (rc) {
                    if (((rc as Record)['must_call_complete'] as Bool).value == true) {
                        complete_burn_icp_mint_cycles().then((BurnIcpMintCyclesSuccess x){ window.alert('mint_cycles call complete. ${x.mint_cycles} cycles minted.'); });
                    }
                    throw Exception('Caller is in the middle of a different mint_cycles call. Completing it in the background.');
                }
            }); 
        },
    };

    Map<String, Future<BurnIcpMintCyclesSuccess> Function(CandidType)> get complete_mint_cycles_error_match_map => {
        'UserIsNotInTheMiddleOfAMintCyclesCall': (n) async {
            throw Exception('user is not in the middle of a mint_cycles call.');
        },
        'MintCyclesError': (mint_cycles_error) async {
            return await match_variant<Future<BurnIcpMintCyclesSuccess>>(mint_cycles_error as Variant, mint_cycles_error_match_map);
        }
    };
    
    // ----
    // cycles-out
    Future<BigInt/*block-id*/> management_canister_deposit_cycles(CyclesOutQuest q) async {
        Variant sponse = c_backwards_one(
            await this.call(
                CYCLES_BANK_LEDGER.ledger,
                calltype: CallType.call,
                method_name: 'cycles_out',
                put_bytes: c_forwards_one(q)
            )
        ) as Variant;
        return match_variant<BigInt>(sponse, {
            Ok: (nat) {
                return (nat as Nat).value;
            },
            Err: (e) {
                return match_variant<Never>(e as Variant, {
                    'GenericError' : (rc) {
                        Record r = rc as Record;
                        throw Exception('GenericError: \nerror-code: ${(r['error_code'] as Nat).value}, message: ${(r['message'] as Text).value}');
                    },
                    'BadFee' : (rc) {
                        BigInt expected_fee = ((rc as Record)['expected_fee'] as Nat).value;
                        CYCLES_BANK_LEDGER.fee = expected_fee;
                        throw Exception('The cycles fee changed, please try again.');
                    },
                    'DepositCyclesCallError' : (ce) {
                        throw Exception('Management canister call error: ${CallError.of_the_record(ce as Record)}');
                    },
                    'InsufficientFunds' : (br) {
                        BigInt balance = ((br as Record)['balance'] as Nat).value;
                        this.icrc1_balances_cache[CYCLES_BANK_LEDGER] = balance;
                        throw Exception('InsufficientFunds. current-balance: ${Cycles(cycles: balance)}');
                    }
                });
            }             
        });
    }
    
    // ----
    
    // market methods.
    Future<void> fresh_cm_trade_contracts_balances([List<Icrc1TokenTradeContract>? tcs]) async {
        List<Icrc1TokenTradeContract> icrc1token_trade_contracts = tcs ?? this.cm_trade_contracts.keys.toList();
        await Future.wait(
            icrc1token_trade_contracts.map((tc)=>Future.wait([
                Future(()async{
                    this.cm_trade_contracts[tc]!.trade_contract_token_balance = await check_icrc1_balance(
                        icrc1_ledger_canister_id: tc.icrc1_ledger_canister_id, 
                        owner: tc.trade_contract_canister_id,
                        subaccount: principal_as_an_icpsubaccountbytes(this.principal),
                        calltype: CallType.query
                    );
                }),
                Future(()async{
                    this.cm_trade_contracts[tc]!.trade_contract_cycles_balance = await check_icrc1_balance(
                        icrc1_ledger_canister_id: CYCLES_BANK_LEDGER.ledger.principal, 
                        owner: tc.trade_contract_canister_id,
                        subaccount: principal_as_an_icpsubaccountbytes(this.principal),
                        calltype: CallType.query
                    );
                }),
            ]))
        );
    }
    
    Future<BigInt/*position-id*/> cm_trade_cycles(Icrc1TokenTradeContract tc, TradeCyclesQuest q) async {
        return await cm_trade_(tc, q, PositionKind.Cycles);
    }

    Future<BigInt/*position-id*/> cm_trade_tokens(Icrc1TokenTradeContract tc, TradeTokensQuest q) async {
        return await cm_trade_(tc, q, PositionKind.Token);
    }
    
    Future<BigInt> cm_trade_(Icrc1TokenTradeContract trade_contract, TradeQuest q, PositionKind kind) async {
        
        Icrc1Ledger ledger_data = kind == PositionKind.Token ? trade_contract.ledger_data : CYCLES_BANK_LEDGER;
        
        await Future.wait([
            this.fresh_icrc1_balances([ledger_data]),
            this.fresh_cm_trade_contracts_balances([trade_contract]),
        ]);
        
        BigInt trade_contract_balance = kind == PositionKind.Token ? this.cm_trade_contracts[trade_contract]!.trade_contract_token_balance : this.cm_trade_contracts[trade_contract]!.trade_contract_cycles_balance;
        
        if (trade_contract_balance < q.quantity + ledger_data.fee) {
            if (this.icrc1_balances_cache[ledger_data]! < q.quantity + (ledger_data.fee * BigInt.from(2)) - trade_contract_balance) {
                throw Exception(
"""For a trade of ${Tokens(quantums: q.quantity, decimal_places: ledger_data.decimals)} ${ledger_data.symbol}, need minimum balance: ${Tokens(quantums: q.quantity + (ledger_data.fee * BigInt.from(2)), decimal_places: ledger_data.decimals)} ${ledger_data.symbol}.
Current main-account balance: ${Tokens(quantums: this.icrc1_balances_cache[ledger_data]!, decimal_places: ledger_data.decimals)} ${ledger_data.symbol}.
Current cm-escrow-account balance: ${Tokens(quantums: trade_contract_balance, decimal_places: ledger_data.decimals)} ${ledger_data.symbol}.
"""
                );             
            }    
            await transfer_icrc1(
                ledger_data, 
                c_forwards_one(Record.of_the_map({
                    'to':Icrc1Account(owner: trade_contract.trade_contract_canister_id, subaccount:principal_as_an_icpsubaccountbytes(this.principal)),
                    'fee': Nat(ledger_data.fee),
                    'amount': Nat(q.quantity + ledger_data.fee - trade_contract_balance)
                }))
            );
        }
        
        try{
            Variant v = c_backwards_one(
                await this.call(
                    Canister(trade_contract.trade_contract_canister_id), 
                    method_name: switch (kind) { PositionKind.Cycles => "trade_cycles", _ => "trade_tokens" },
                    calltype: CallType.call,
                    put_bytes: c_forwards_one(q)
                )
            ) as Variant;
            BigInt position_id = match_variant(v, {
                Ok:(s){
                    return ((s as Record)['position_id'] as Nat).value;
                },
                Err: (e) {
                    return match_variant<Never>(e as Variant, {
                        'CreatePositionLedgerTransferError' : (te) {
                            return match_variant(te as Variant, icrc1_transfer_error_match_map(trade_contract.ledger_data));
                        },
                        'CyclesMarketIsBusy': (_n) {
                            throw Exception('The cycles-market is busy. Try soon.');
                        },
                        'RateCannotBeZero': (_n) {
                            throw Exception('The rate cannot be zero');
                        },
                        'CreatePositionLedgerTransferCallError': (ce) {
                            throw Exception('Ledger transfer call error when moving the funds for the position: ${CallError.of_the_record(ce as Record)}');
                        },
                        'MinimumPosition' : (r) {
                            Cycles min_cycles = Cycles.of_the_nat((r as Record)['minimum_cycles'] as Nat);
                            Tokens min_tokens = Tokens.of_the_nat((r as Record)['minimum_tokens'] as Nat, decimal_places: trade_contract.ledger_data.decimals);
                            throw Exception('Amount too little.\nminimum cycles: ${min_cycles}\nminimum ${trade_contract.ledger_data.symbol}: ${min_tokens}');
                        },
                        'CallerIsInTheMiddleOfADifferentCallThatLocksTheBalance': (_n) {
                            throw Exception('You are in the middle of a different call that locks the balance.');
                        },  
                    });
                }
            });
            return position_id;        
        } catch(cm_trade_error) {
            try {
                await this.fresh_cm_trade_contracts_balances([trade_contract]);
                trade_contract_balance = kind == PositionKind.Token ? this.cm_trade_contracts[trade_contract]!.trade_contract_token_balance : this.cm_trade_contracts[trade_contract]!.trade_contract_cycles_balance;
                
                if (trade_contract_balance > ledger_data.fee) {
                    try{
                        await this.cm_transfer_balance(
                            trade_contract,
                            CyclesMarketTransferBalanceQuest(                                
                                amount: trade_contract_balance - ledger_data.fee,
                                ledger_transfer_fee: ledger_data.fee,
                                to: Icrc1Account(owner: this.principal),
                            ),
                            kind
                        );
                    } catch(cm_transfer_balance_error) {
                        print('Error cm_transfer_balance:\n${cm_transfer_balance_error}');
                    }
                }
            } catch(fresh_cm_tc_balance_error) {
                print('Error fresh_cm_trade_contracts_balances(trade_contract):\n${fresh_cm_tc_balance_error}');
            }
            rethrow; //throw cm_trade_error;
        }
    }    

    Future<BigInt/*block_height*/> cm_transfer_balance(Icrc1TokenTradeContract tc, CyclesMarketTransferBalanceQuest q, PositionKind position_kind) async {
        Variant sponse = c_backwards(
            await this.call(
                Canister(tc.trade_contract_canister_id),
                method_name: 'transfer_' + (position_kind == PositionKind.Cycles ? 'cycles' : 'token') + '_balance',
                calltype: CallType.call,
                put_bytes: c_forwards_one(q)
            )
        ).first as Variant;
        BigInt block_height = match_variant<BigInt>(sponse, {
            Ok: (block_height_nat) {
                return (block_height_nat as Nat).value;
            },
            Err: (transfer_balance_error) {
                return match_variant<Never>(transfer_balance_error as Variant, {
                    'CyclesMarketIsBusy' : (_n) {
                        throw Exception('The cycles-market is busy at the moment. Try soon.');
                    },
                    'TransferError': (transfer_error) {
                        return match_variant<Never>(transfer_error as Variant, icrc1_transfer_error_match_map(position_kind == PositionKind.Cycles ? CYCLES_BANK_LEDGER : tc.ledger_data));
                    },
                    'TransferCallError' : (ce) {
                        throw Exception('Ledger transfer call error: ${CallError.of_the_record(ce as Record)}');
                    },
                    'CallerIsInTheMiddleOfADifferentCallThatLocksTheBalance': (_n) {
                        throw Exception('Caller is in the middle of a different call that locks the balance.');
                    },
                });
            }
        });
        return block_height;
    }
    
    Future<void> cm_void_position(Icrc1TokenTradeContract tc, BigInt position_id) async {
        Variant sponse = c_backwards(
            await this.call(
                Canister(tc.trade_contract_canister_id),
                method_name: 'void_position',
                calltype: CallType.call,
                put_bytes: c_forwards_one(
                    CyclesMarketVoidPositionQuest(
                        position_id: position_id
                    )
                )
            )
        ).first as Variant;
        return match_variant<void>(sponse, {
            Ok: (ok) {
                
            },
            Err: (void_position_error) {
                match_variant<Never>(void_position_error as Variant, {
                    'WrongCaller': (nul) {
                        throw Exception('File this error: WrongCaller');
                    },
                    'MinimumWaitTime': (rc) { 
                        Record r = rc as Record;
                        throw Exception('Minimum wait time to cancel a position is ${(r['minimum_wait_time_seconds'] as Nat).value.toInt() / 60}-minute(s). This position can cancel in ${( ( ( (r['position_creation_timestamp_seconds'] as Nat).value + (r['minimum_wait_time_seconds'] as Nat).value ) - get_current_time_seconds() ) / BigInt.from(60) ).toStringAsFixed(1)}-minutes.');
                    },
                    'CyclesMarketIsBusy': (nul) {
                        throw Exception('The cycles-market is busy. try soon.');
                    },
                    'PositionNotFound': (nul) {
                        throw Exception('The position-id: ${position_id} is not found.');
                    },               
                });
            }
        });
    }

    Future<Uint8List> call_view_positions_method(Icrc1TokenTradeContract tc, String method_name, BigInt? opt_start_before_id) async {
        return await tc.canister.call(
            method_name: method_name,
            calltype: CallType.query,
            put_bytes: c_forwards_one(
                Record.of_the_map({
                    'index_key': this.principal,
                    'opt_start_before_id': Option<Nat>(value: opt_start_before_id.nullmap((i)=>Nat(i)), value_type: Nat()),
                })
            ),
        );
    }

    Future<void> load_cm_user_positions([List<Icrc1TokenTradeContract>? trade_contracts]) async {
        List<Icrc1TokenTradeContract> tcs = trade_contracts ?? this.cm_trade_contracts.keys.toList();
        await Future.wait(
            tcs.map((tc)=>Future(()async{
                // current_positions
                List<PositionLog> gather_user_current_positions = [];
                int? latest_logs_b_chunk_len = null; 
                while (true) {
                    Uint8List logs_b_chunk = await call_view_positions_method(tc, 'view_user_current_positions', gather_user_current_positions.isEmpty ? null : gather_user_current_positions.first.id);
                    int logs_b_chunk_len = logs_b_chunk.length;
                    gather_user_current_positions = [
                        ...logs_b_chunk.chunks(PositionLog.STABLE_MEMORY_SERIALIZE_SIZE).map((b)=>PositionLog.oftheStableMemorySerialization(b, token_decimal_places: tc.ledger_data.decimals)),
                        ...gather_user_current_positions
                    ];
                    if ((latest_logs_b_chunk_len != null && logs_b_chunk_len < latest_logs_b_chunk_len) || logs_b_chunk_len == 0) {
                        break;
                    }
                    latest_logs_b_chunk_len = logs_b_chunk_len;
                }
                
                SplayTreeMap<BigInt, PositionLog> gather_user_current_positions_as_map 
                    = SplayTreeMap.fromIterable(gather_user_current_positions, key: (pl)=>pl.id, value: (pl)=>pl);
                    
                this.cm_trade_contracts[tc]!.current_user_positions = gather_user_current_positions_as_map;
                
                // view_void_positions_pending
                List<PositionLogAndVoidPositionPayoutStatus> gather_void_positions_pending = [];
                latest_logs_b_chunk_len = null; 
                while (true) {
                    Uint8List logs_b_chunk = await call_view_positions_method(tc, 'view_void_positions_pending', gather_void_positions_pending.isEmpty ? null : gather_void_positions_pending.first.pl.id); 
                    int logs_b_chunk_len = logs_b_chunk.length;
                    gather_void_positions_pending = [
                        ...logs_b_chunk.chunks(PositionLog.STABLE_MEMORY_SERIALIZE_SIZE + 1).map((b)=>PositionLogAndVoidPositionPayoutStatus(
                            PositionLog.oftheStableMemorySerialization(b.sublist(0, PositionLog.STABLE_MEMORY_SERIALIZE_SIZE), token_decimal_places: tc.ledger_data.decimals),
                            b.last == 1
                        )),
                        ...gather_void_positions_pending
                    ];
                    if ((latest_logs_b_chunk_len != null && logs_b_chunk_len < latest_logs_b_chunk_len) || logs_b_chunk_len == 0) {
                        break;
                    }
                    latest_logs_b_chunk_len = logs_b_chunk_len;
                }
                
                SplayTreeMap<BigInt, PositionLogAndVoidPositionPayoutStatus> gather_void_positions_pending_map 
                    = SplayTreeMap.fromIterable(gather_void_positions_pending, key: (e)=>e.pl.id, value: (e)=>e);
                
                this.cm_trade_contracts[tc]!.user_void_positions_pending = gather_void_positions_pending_map;
                
                // storage_logs start with the ones in the buffer 
                BigInt? last_known_storage_log_position_id = this.cm_trade_contracts[tc]!.user_positions_storage.lastKey();
                List<PositionLog> gather_user_positions_log_storage = [];
                latest_logs_b_chunk_len = null; 
                bool catch_up_complete = false;
                while (true) {
                    Uint8List logs_b_chunk = await call_view_positions_method(tc, 'view_user_positions_logs', gather_user_positions_log_storage.isEmpty ? null : gather_user_positions_log_storage.first.id); 
                    int logs_b_chunk_len = logs_b_chunk.length;
                    List<PositionLog> positions_chunk = logs_b_chunk.chunks(PositionLog.STABLE_MEMORY_SERIALIZE_SIZE).map((b)=>PositionLog.oftheStableMemorySerialization(b, token_decimal_places: tc.ledger_data.decimals)).toList();
                    
                    gather_user_positions_log_storage = [
                        ...positions_chunk,
                        ...gather_user_positions_log_storage
                    ];
                    
                    if (last_known_storage_log_position_id != null 
                    && gather_user_positions_log_storage.isNotEmpty 
                    && gather_user_positions_log_storage.first.id <= last_known_storage_log_position_id
                    ) {
                        catch_up_complete = true;
                        break;
                    }
                    
                    if ((latest_logs_b_chunk_len != null && logs_b_chunk_len < latest_logs_b_chunk_len) || logs_b_chunk_len == 0) {
                        break;
                    }
                    latest_logs_b_chunk_len = logs_b_chunk_len;
                }
                List<StorageCanister>? scs;
                if (catch_up_complete == false) {
                    scs = await tc.view_positions_storage_canisters();
                    //print('positions-storage-canisters: $scs');
                    for (StorageCanister sc in scs.reversed) {
                        int chunk_size = 1024 * 512 * 3 ~/ sc.log_size;
                        while (true) {
                            Uint8List logs_b_chunk = await Canister(sc.canister_id).call(
                                calltype: CallType.query, 
                                method_name: "map_logs_rchunks",
                                put_bytes: c_forwards([
                                    this.principal,
                                    Option<Nat>(value: gather_user_positions_log_storage.isEmpty ? null : Nat(gather_user_positions_log_storage.first.id), value_type: Nat()),
                                    Nat32(chunk_size),
                                ])
                            );
                            int logs_b_chunk_size = logs_b_chunk.length ~/ sc.log_size;
                            
                            List<PositionLog> positions_chunk = logs_b_chunk.chunks(sc.log_size).map((b)=>PositionLog.oftheStableMemorySerialization(b, token_decimal_places: tc.ledger_data.decimals)).toList();
                            
                            gather_user_positions_log_storage  = [
                                ...positions_chunk,
                                ...gather_user_positions_log_storage
                            ];
                            
                            if (last_known_storage_log_position_id != null 
                            && gather_user_positions_log_storage.isNotEmpty 
                            && gather_user_positions_log_storage.first.id <= last_known_storage_log_position_id
                            ) {
                                catch_up_complete = true;
                                break;
                            } 
                            
                            if (logs_b_chunk_size < chunk_size) {
                                break;
                            }
                        }
                        
                        if (catch_up_complete == true) {
                            break;
                        }
                    }  
                }
                
                this.cm_trade_contracts[tc]!.user_positions_storage.addAll(Map.fromIterable(gather_user_positions_log_storage, key: (i)=>i.id, value: (i)=>i));
        
                // fresh positions that are in the storage log, are still not terminated, and are not in the current-positions or void-positions. 
                
                List<BigInt> positions_need_fresh 
                    = this.cm_trade_contracts[tc]!.user_positions_storage.values
                    .where((pl){
                        return pl.position_termination == null 
                        && this.cm_trade_contracts[tc]!.current_user_positions.containsKey(pl.id) == false
                        && this.cm_trade_contracts[tc]!.user_void_positions_pending.containsKey(pl.id) == false;
                    }).map((pl)=>pl.id).toList();

                if (positions_need_fresh.isNotEmpty) {
                    latest_logs_b_chunk_len = null; 
                    while (true) {
                        Uint8List logs_b_chunk = await call_view_positions_method(tc, 'view_user_positions_logs', positions_need_fresh.last + BigInt.one); 
                        int logs_b_chunk_len = logs_b_chunk.length;
                        List<PositionLog> positions_chunk = logs_b_chunk.chunks(PositionLog.STABLE_MEMORY_SERIALIZE_SIZE).map((b)=>PositionLog.oftheStableMemorySerialization(b, token_decimal_places: tc.ledger_data.decimals)).toList();
                        SplayTreeMap positions_chunk_map 
                            = SplayTreeMap.fromIterable(positions_chunk, key: (pl)=>pl.id, value: (pl)=>pl);
                        
                        int i = 0;
                        while (i<positions_need_fresh.length) {
                            BigInt plid = positions_need_fresh[i];
                            if (positions_chunk_map.containsKey(plid)) {
                                this.cm_trade_contracts[tc]!.user_positions_storage[plid] = positions_chunk_map[plid];    
                                positions_need_fresh.removeAt(i);                       
                            } else {
                                i = i + 1;
                            }
                        }
                        
                        if (positions_need_fresh.isEmpty) {
                            break;
                        }
                        if ((latest_logs_b_chunk_len != null && logs_b_chunk_len < latest_logs_b_chunk_len) || logs_b_chunk_len == 0) {
                            break;
                        }
                        latest_logs_b_chunk_len = logs_b_chunk_len;
                            
                    }
                    
                    if (positions_need_fresh.isNotEmpty) {
                        if (scs == null) {
                            scs = await tc.view_positions_storage_canisters();
                            //print('positions-storage-canisters: $scs');
                        }
                        for (StorageCanister sc in scs.reversed) {
                            int chunk_size = 1024 * 512 * 3 ~/ sc.log_size;
                            while (true) {
                                Uint8List logs_b_chunk = await Canister(sc.canister_id).call(
                                    calltype: CallType.query, 
                                    method_name: "map_logs_rchunks",
                                    put_bytes: c_forwards([
                                        this.principal,
                                        Option<Nat>(value: Nat(positions_need_fresh.last + BigInt.from(1)), value_type: Nat()),
                                        Nat32(chunk_size),
                                    ])
                                );
                                int logs_b_chunk_size = logs_b_chunk.length ~/ sc.log_size;
                                    
                                List<PositionLog> positions_chunk = logs_b_chunk.chunks(PositionLog.STABLE_MEMORY_SERIALIZE_SIZE).map((b)=>PositionLog.oftheStableMemorySerialization(b, token_decimal_places: tc.ledger_data.decimals)).toList();
                                Map positions_chunk_map = Map.fromIterable(
                                    positions_chunk,
                                    key: (e)=>e.id,
                                    value: (e)=>e
                                );
                                    
                                int i = 0;
                                while (i<positions_need_fresh.length) {
                                    BigInt plid = positions_need_fresh[i];
                                    if (positions_chunk_map.containsKey(plid)) {
                                        this.cm_trade_contracts[tc]!.user_positions_storage[plid] = positions_chunk_map[plid];    
                                        positions_need_fresh.removeAt(i);                       
                                    } else {
                                        i = i + 1;
                                    }
                                }
                                        
                                if (positions_need_fresh.isEmpty) {
                                    break;
                                } 
                                    
                                if (logs_b_chunk_size < chunk_size) {
                                    break;
                                }
                            }
                                
                            if (positions_need_fresh.isEmpty) {
                                break;
                            }
                        }
                    }
                }  
            }))
        );
    }
        
        
        
    Future<void> load_cm_user_position_trade_logs(Icrc1TokenTradeContract tc, BigInt position_id) async {
        // remove logs after the first one found to still have a pending payout. 
        if (this.cm_trade_contracts[tc]!.user_positions_trade_logs[position_id] != null) {
            BigInt? first_id_of_a_pending_payout; 
            // find pl so we know which position kind it is.
            PositionLog? pl = this.cm_trade_contracts[tc]!.current_user_positions[position_id];
            if (pl == null) {
                pl = this.cm_trade_contracts[tc]!.user_positions_storage[position_id]!;
            }
            // choose payout type based on the user position kind.
            bool Function(TradeLogAndPayoutStatus) tlaps_payout_status_fn = 
                pl.position_kind == PositionKind.Cycles
                ?
                (TradeLogAndPayoutStatus l)=>l.tokens_payout_complete
                :
                (TradeLogAndPayoutStatus l)=>l.cycles_payout_complete;
            for (TradeLogAndPayoutStatus l in this.cm_trade_contracts[tc]!.user_positions_trade_logs[position_id]!.values) {
                if (tlaps_payout_status_fn(l) == false) {
                    first_id_of_a_pending_payout = l.tl.id;
                    break;
                }
            }
            if (first_id_of_a_pending_payout != null) {
                this.cm_trade_contracts[tc]!.user_positions_trade_logs[position_id]!.removeWhere((key, value)=>key>=first_id_of_a_pending_payout!);
            }        
        }
        
        BigInt? last_known_trade_log_id = this.cm_trade_contracts[tc]!.user_positions_trade_logs[position_id].nullmap((tls_map)=>tls_map.lastKey());
        
        List<TradeLogAndPayoutStatus> gather_trades = []; 
        bool catch_up_complete = false;
        for (String method_name in ['view_position_pending_trades', 'view_position_purchases_logs']) {
            int? latest_logs_b_chunk_len = null;
            while (true) {
                Uint8List logs_b_chunk = await this.call(
                    tc.canister,
                    method_name: method_name,
                    calltype: CallType.query,
                    put_bytes: c_forwards_one(Record.of_the_map({
                        'opt_start_before_id': Option<Nat>(value: gather_trades.isEmpty ? null : Nat(gather_trades.first.tl.id), value_type: Nat()),
                        'index_key': Nat(position_id)
                    })),
                );
                
                int logs_b_chunk_len = logs_b_chunk.length;
                    
                int log_b_chunk_size = TradeLog.STABLE_MEMORY_SERIALIZE_SIZE;                   
                late TradeLogAndPayoutStatus Function(Uint8List b) b_code_fn;
                if (method_name == 'view_position_pending_trades') {
                    log_b_chunk_size += 2; 
                    b_code_fn = (b)=>TradeLogAndPayoutStatus(
                        TradeLog.oftheStableMemorySerialization(b.sublist(0, TradeLog.STABLE_MEMORY_SERIALIZE_SIZE), token_decimal_places: tc.ledger_data.decimals),
                        cycles_payout_complete: b[b.length - 2] == 1,
                        tokens_payout_complete: b[b.length - 1] == 1
                    );
                } else {
                    b_code_fn = (b)=> TradeLogAndPayoutStatus(
                        TradeLog.oftheStableMemorySerialization(b, token_decimal_places: tc.ledger_data.decimals),
                        cycles_payout_complete: true,
                        tokens_payout_complete: true,
                    );
                }
                List<TradeLogAndPayoutStatus> trades_chunk = logs_b_chunk.chunks(log_b_chunk_size)
                    .map(b_code_fn)
                    .toList();
                
                gather_trades = [
                    ...trades_chunk,
                    ...gather_trades
                ];
                
                if (last_known_trade_log_id != null && gather_trades.isNotEmpty && gather_trades.first.tl.id <= last_known_trade_log_id) {
                    gather_trades = gather_trades.skipWhile((l)=>l.tl.id <= last_known_trade_log_id).toList();
                    catch_up_complete = true;
                    break;
                }
                
                if ((latest_logs_b_chunk_len != null && logs_b_chunk_len < latest_logs_b_chunk_len) || logs_b_chunk_len == 0) {
                    break;
                }
                latest_logs_b_chunk_len = logs_b_chunk_len;
            }    
            
            if (catch_up_complete) {
                break;
            }
        
        }
        
        // cm_trades_storage-canisters
        if (catch_up_complete == false) {
            int chunk_size = 1400000 ~/ TradeLog.STABLE_MEMORY_SERIALIZE_SIZE;
            await tc.fresh_trades_storage_canisters();
            for (StorageCanister trades_storage_canister in (tc.trades_scs_cache).reversed) {
                while (true) {
                    Uint8List logs_b_chunk = await this.call(
                        tc.canister,
                        method_name: 'map_logs_rchunks',
                        calltype: CallType.query,
                        put_bytes: c_forwards([
                            Nat(position_id), 
                            Option<Nat>(value: gather_trades.isEmpty ? null : Nat(gather_trades.first.tl.id), value_type: Nat()), 
                            Nat32(chunk_size),
                        ])
                    );
                    
                    List<TradeLogAndPayoutStatus> trades_chunk = logs_b_chunk.chunks(TradeLog.STABLE_MEMORY_SERIALIZE_SIZE)
                        .map((b)=>TradeLogAndPayoutStatus(
                            TradeLog.oftheStableMemorySerialization(b, token_decimal_places: tc.ledger_data.decimals),
                            cycles_payout_complete: true,
                            tokens_payout_complete: true,
                        ))
                        .toList();
                    
                    gather_trades = [
                        ...trades_chunk,
                        ...gather_trades
                    ];
                    
                    if (last_known_trade_log_id != null && gather_trades.isNotEmpty && gather_trades.first.tl.id <= last_known_trade_log_id) {
                        gather_trades = gather_trades.skipWhile((l)=>l.tl.id <= last_known_trade_log_id).toList();
                        catch_up_complete = true;
                        break;
                    }
                    
                    if (trades_chunk.length != chunk_size) {
                        break;
                    }
                
                }
                
                if (catch_up_complete) {
                    break;
                }
            }
        }        
        

        this.cm_trade_contracts[tc]!.user_positions_trade_logs[position_id] = SplayTreeMap.from({
            ...?this.cm_trade_contracts[tc]!.user_positions_trade_logs[position_id],
            ...SplayTreeMap.fromIterable(gather_trades, key: (l)=>l.tl.id, value: (l)=>l)
        });
            
    }
    
        
    
    Future<void> load_cm_data([List<Icrc1TokenTradeContract>? trade_contracts]) async {
        await Future.wait([
            this.fresh_cm_trade_contracts_balances(trade_contracts),
            this.load_cm_user_positions(trade_contracts),
            // loads the latest trades of those positions whos trades have been already loaded at least once. because those positions that have not loaded the trades at least once, will load if clicked on.
            Future(()async{
                List<Icrc1TokenTradeContract> tcs = trade_contracts ?? this.cm_trade_contracts.keys.toList();
                await Future.wait(
                    tcs.map((tc)=>Future(()async{
                        await Future.wait(
                            this.cm_trade_contracts[tc]!.user_positions_trade_logs.keys.map((pl_id)=>Future(()async{
                                await this.load_cm_user_position_trade_logs(tc, pl_id);     
                            }))
                        );
                    }))
                );                    
            })
        ]);
    }
    
        
    
    
    
    
    
    
    
    
    
    
    // -------
    
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
            this.icrc1_balances_cache[Icrc1Ledgers.ICP] = current_balance.e8s;
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

}




// ----

// put into the ic_tools common lib
Future<BigInt> check_icrc1_balance({required Principal icrc1_ledger_canister_id, required Principal owner, Uint8List? subaccount, required CallType calltype}) async {
    BigInt balance = (c_backwards(await Canister(icrc1_ledger_canister_id).call(
        method_name: 'icrc1_balance_of',
        put_bytes: c_forwards([
            Record.of_the_map({
                'owner': owner,
                'subaccount': Option<Blob>(value: subaccount.nullmap((b)=>Blob(b)), value_type: Blob.type_mode())
            })
        ]),
        calltype: calltype
    )).first as Nat).value;
    return balance;
}

// ----

class CyclesTransfer {
    
    final BigInt id; // block-height.
    final BigInt timestamp_nanos;
    final BigInt amt;
    final BigInt fee;
    final Uint8List? memo;
    final Variant op;
    
    CyclesTransfer._({
        required this.id,
        required this.timestamp_nanos,
        required this.amt,
        required this.fee,
        required this.memo,
        required this.op,
    });
    
    static CyclesTransfer of_the_record(Record r) {
        Record log = (r[1] as Record);
        Record tx = log['tx'] as Record; 
        return CyclesTransfer._(
            id: (r[0] as Nat).value,
            timestamp_nanos: (log['ts'] as Nat64).value,
            amt: (tx['amt'] as Nat).value,
            fee: (log.find_option<Nat>('fee') ?? tx.find_option<Nat>('fee')!).value,
            memo: tx.find_option<Vector>('memo').nullmap((v)=>Blob.of_the_vector_nat8(v.cast_vector<Nat8>()).bytes),
            op: tx['op'] as Variant,
        );
    }
}
/*
enum CyclesTransferLogOperation {
    Burn
    Mint
    Xfer
}

type Operation = variant {
  Burn : record {
    from : record { principal; opt vec nat8 };
    for_canister : principal;
  };
  Mint : record { to : record { principal; opt vec nat8 }; kind : MintKind };
  Xfer : record {
    to : record { principal; opt vec nat8 };
    from : record { principal; opt vec nat8 };
  };
};

type MintKind = variant {
  CMC : record { icp_block_height : nat64; caller : principal };
  CyclesIn : record { from_canister : principal };
};


*/





// ----

class BurnIcpMintCyclesSuccess {
    final Cycles mint_cycles;
    final BigInt mint_cycles_block_height;
    BurnIcpMintCyclesSuccess({required this.mint_cycles, required this.mint_cycles_block_height});
    static BurnIcpMintCyclesSuccess of_the_record(CandidType burn_icp_mint_cycles_success_record) {
        Record r = burn_icp_mint_cycles_success_record as Record;
        return BurnIcpMintCyclesSuccess(
            mint_cycles: Cycles.oftheNat(r['mint_cycles'] as Nat),
            mint_cycles_block_height: (r['mint_cycles_block_height'] as Nat).value,
        );
    }
    String toString() {
        return 'cycles-mint: ${this.mint_cycles}';
    }
}

// ----

class CyclesOutQuest extends Record {
    final BigInt fee;
    final Uint8List? memo;
    final Cycles cycles;
    final Principal for_canister;
    CyclesOutQuest({
        required this.fee,
        this.memo,
        required this.cycles,
        required this.for_canister,
    }) {
        this['fee'] = Nat(fee);
        this['cycles'] = this.cycles;
        this['for_canister'] = this.for_canister;
        if (this.memo != null) {
            this['memo'] = Blob(this.memo!);
        }
    }
}
    
// ----

class CyclesMarketVoidPositionQuest extends Record {
    BigInt position_id;
    CyclesMarketVoidPositionQuest({
        required this.position_id
    }) {
        this['position_id'] = Nat(this.position_id);
    }
}

class CyclesMarketTransferBalanceQuest extends Record {
    final BigInt amount;
    final BigInt ledger_transfer_fee;
    final Icrc1Account to;
    CyclesMarketTransferBalanceQuest({
        required this.amount,
        required this.ledger_transfer_fee,
        required this.to,
    }) {
        this['amount'] = Nat(this.amount);
        this['ledger_transfer_fee'] = Nat(this.ledger_transfer_fee);
        this['to'] = this.to;
    }
}

// ----

class UserCMTradeContractData {
    
    BigInt trade_contract_token_balance = BigInt.from(0);
    BigInt trade_contract_cycles_balance = BigInt.from(0);
    //List<Icrc1Transaction> token_ledger_transactions_cache = [];
        
    // show user positions logs sort by creation date, latest first, with an option to show only open/current positions 
    // show fee takes out each payout and total fees paid for the position
    
    SplayTreeMap<BigInt, PositionLog> current_user_positions = SplayTreeMap(); // void-position-payout-complete is automatic no here
    SplayTreeMap<BigInt, PositionLogAndVoidPositionPayoutStatus> user_void_positions_pending = SplayTreeMap();
    SplayTreeMap<BigInt, PositionLog> user_positions_storage = SplayTreeMap(); // void-position-payout-complete is automatic yes here
    
    SplayTreeMap<BigInt, SplayTreeMap<BigInt, TradeLogAndPayoutStatus>> user_positions_trade_logs = SplayTreeMap();       
}

class TradeLogAndPayoutStatus {
    TradeLog tl;
    bool cycles_payout_complete;
    bool tokens_payout_complete;
    TradeLogAndPayoutStatus(
        this.tl, 
        {required this.cycles_payout_complete,
        required this.tokens_payout_complete}
    );
}

class PositionLogAndVoidPositionPayoutStatus {
    PositionLog pl;
    bool void_position_payout_complete;
    PositionLogAndVoidPositionPayoutStatus(
        this.pl,
        this.void_position_payout_complete
    );
}



