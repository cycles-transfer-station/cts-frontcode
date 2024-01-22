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
    
    late final String icp_id;
    List<Icrc1Ledger> known_icrc1_ledgers = [common.Icrc1Ledgers.ICP];
    Map<Icrc1Ledger, BigInt> icrc1_balances_cache = {};
    Map<Icrc1Ledger, List<Icrc1Transaction>> icrc1_transactions_cache = {};
    List<IcpTransfer> icp_transfers = []; // icp-transfer logs are different than the icrc1-transfer-logs    
    List<CyclesTransfer> cycles_transfers = []; // cycles-transfer logs are different than the icrc1-transfer-logs
    Map<Icrc1TokenTradeContract, UserCMTradeContractData> cm_trade_contracts = {};
    
    Icrc1Ledger? current_icrc1_ledger = null;
    
    // for the mint_cycles through the cycles-bank.
    late final Uint8List bank_mint_cycles_user_icp_subaccount_bytes;
    late final String bank_mint_cycles_user_icp_id;
    
    User({
        required this.state,
        required this.caller,
    }) {
        this.icp_id = icp_id(this.principal);
        this.bank_mint_cycles_user_icp_subaccount_bytes = principal_as_an_icpsubaccountbytes(this.principal);
        this.bank_mint_cycles_user_icp_id = icp_id(bank.principal, subaccount_bytes: bank_user_icp_subaccount_bytes);
    }
            
    Future<Uint8List> call(Canister canister, {required CallType calltype, required String method_name, Uint8List? put_bytes, Duration timeout_duration = const Duration(minutes: 10)}) {
        return canister.call(caller:this.caller, calltype:calltype, method_name:method_name, put_bytes:put_bytes, timeout_duration:timeout_duration);
    }
            
    void fresh_known_cm_trade_contracts_of_the_cm_main() {
        for (Icrc1TokenTradeContract tc in this.state.cm_main.trade_contracts) {
            if (this.known_icrc1_ledgers.contains(tc.ledger_data) == false) {
                this.known_icrc1_ledgers.add(tc.ledger_data);
            }
            if (this.cm_trade_contracts.containsKey(tc) == false) {
                this.cm_trade_contracts[tc] = UserCMTradeContractData();
            }
        }
    }
    
    Future<void> fresh_icrc1_balances([List<Icrc1Ledger>? icrc1_ledgers]) async {
        List<Icrc1Ledger> ledgers = icrc1_ledgers ?? [...this.known_icrc1_ledgers, CYCLES_BANK_LEDGER];
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
        final Map<Canister, Canister> ledger_index = {
            Canister(Principal.text('zfcdd-tqaaa-aaaaq-aaaga-cai')): Canister(Principal.text('zlaol-iaaaa-aaaaq-aaaha-cai')), // DKP
            Canister(Principal.text('2ouva-viaaa-aaaaq-aaamq-cai')): Canister(Principal.text('2awyi-oyaaa-aaaaq-aaanq-cai')), // CHAT
        }; 
        return c_backwards(await ledger_index[l.ledger]!.call(
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
    Future<void> fresh_icrc1_transactions([List<Icrc1Ledger>? icrc1_ledgers]) async {
        if (is_on_local) {
            return;
        } else {
            return fresh_icrc1_transactions_(icrc1_ledgers);
        }
    }
    Future<void> fresh_icrc1_transactions_([List<Icrc1Ledger>? icrc1_ledgers]) {
        List<Icrc1Ledger> ledgers = icrc1_ledgers ?? this.known_icrc1_ledgers;
        return Future.wait(
            ledgers.map<Future<void>>((l)=>Future(()async{
                //print('fresh icrc1 transactions future ${l.name}');
                if (l.ledger.principal == common.SYSTEM_CANISTERS.ledger.principal) {
                    // for the do! hook up with the new icp index canister
                    this.icp_transfers = [
                        ...await get_icp_transfers(this.icp_id, already_have: this.icp_transfers.length),
                        ...this.icp_transfers
                    ];
                } else if (l == CYCLES_BANK_LEDGER) {
                    throw Exception(':PLEMENT!');
                } else /*tokens besides icp or cycles*/ {
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
                this.icrc1_balances_cache[icrc1_ledger] = balance;
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
            await user.call(
                common.SYSTEM_CANISTERS.ledger,
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
            throw Exception('The minimum ICP is ${IcpTokens(e8s: (r['minimum_burn_icp'] as Nat).value)}.');
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
            print('UserIsInTheMiddleOfADifferentCall: ${rc}');
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
    
    Future<BurnIcpMintCyclesSuccess> burn_icp_mint_cycles(BigInt burn_icp) async {
        BigInt current_bank_user_icp_subaccount_balance = await check_icrc1_balance(
            icrc1_ledger_canister_id: common.SYSTEM_CANISTERS.ledger.principal, 
            owner: CYCLES_BANK_LEDGER.ledger.principal, 
            subaccount: bank_mint_cycles_user_icp_subaccount_bytes, 
            calltype: CallType.query
        );
        if (current_bank_user_icp_subaccount_balance < burn_icp + common.Icrc1Ledgers.ICP.fee) {
            await transfer_icp(
                c_forwards_one(Record.of_the_map({
                    'memo': Nat64(BigInt.from(4)),
                    'amount': IcpTokens(e8s: burn_icp + common.Icrc1Ledgers.ICP.fee - current_bank_user_icp_subaccount_balance),
                    'fee': ICP_LEDGER_TRANSFER_FEE,
                    'from_subaccount': Option<Blob>(value: null, value_type: Blob.type_mode()),
                    'to': Blob(hexstringasthebytes(this.bank_mint_cycles_user_icp_id)),
                }))
            );
        }
        Variant mint_cycles_result = c_backwards(
            await user.call(
                CYCLES_BANK_LEDGER.ledger,
                calltype: CallType.call,
                method_name: 'mint_cycles',
                put_bytes: c_forwards([
                    Record.of_the_map({
                        'to' : Icrc1Account{owner: this.principal},
                        'fee' : Option<Nat>(value: Nat(CYCLES_BANK_LEDGER.fee)),
                        'burn_icp': Nat(burn_icp),
                        'burn_icp_transfer_fee': Nat(common.Icrc1Ledgers.ICP.fee),
                        'memo' : Option<Blob>(value: Blob(utf8.encode('CTSF'))),
                        'created_at_time' : Option<Nat64>(value:null, value_type: Nat64()),
                    })
                ])
            )
        )[0] as Variant;
        return await match_variant<Future<BurnIcpMintCyclesSuccess>>(mint_cycles_result, mint_cycles_result_match_map);
    }
    
    Future<BurnIcpMintCyclesSuccess> complete_burn_icp_mint_cycles() async {
        Variant complete_mint_cycles_result = c_backwards(
            await user.call(
                CYCLES_BANK_LEDGER.ledger,
                calltype: CallType.call,
                method_name: 'complete_mint_cycles',
                put_bytes: c_forwards([])
            )
        )[0] as Variant;
        return await match_variant<Future<BurnIcpMintCyclesSuccess>>(complete_mint_cycles_result, complete_mint_cycles_result_match_map);
    }
    
    // ----
    // cycles-out
    Future<BigInt/*block-id*/> management_canister_deposit_cycles(CyclesOutQuest q) async {
        Variant sponse = c_backwards_one(
            await user.call(
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
                        BigInt balance = ((r as Record)['balance'] as Nat).value;
                        this.icrc1_balances_cache[CYCLES_BANK_LEDGER] = balance;
                        throw Exception('InsufficientFunds. current-balance: ${Cycles(cycles: balance)}');
                    }
                });
            }             
        });
    }
    
    // ----
    
    // market methods.
    Future<void> fresh_cm_trade_contracts_balances([Icrc1TokenTradeContract? icrc1token_trade_contract]) async {
        List<Icrc1TokenTradeContract> icrc1token_trade_contracts = icrc1token_trade_contract != null ? [icrc1token_trade_contract] : this.cm_trade_contracts.keys.toList();
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
            ])
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
            this.fresh_cm_trade_contracts_balances(trade_contract),
        ]);
        
        BigInt trade_contract_balance = kind == PositionKind.Token ? this.cm_trade_contracts[tc]!.trade_contract_token_balance : this.cm_trade_contracts[tc]!.trade_contract_cycles_balance;
        
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
                await user.call(
                    tc.trade_contract_canister_id, 
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
                            return match_variant(te as Variant, icrc1_transfer_error_match_map(tc.ledger_data));
                        },
                        'CyclesMarketIsBusy': (_n) {
                            throw Exception('The cycles-market is busy. Try soon.');
                        },
                        'RateCannotBeZero': (_n) {
                            throw Exception('The rate cannot be zero');
                        },
                        'CreatePositionLedgerTransferCallError': (ce) {
                            throw Exception('Ledger transfer call error when moving the funds for the position: ${CallError.of_the_record(ce)}');
                        },
                        'MinimumPosition' : (r) {
                            Cycles min_cycles = Cycles.of_the_nat((r as Record)['minimum_cycles'] as Nat);
                            Tokens min_tokens = Tokens.of_the_nat((r as Record)['minimum_tokens'] as Nat, decimal_places: tc.ledger_data.decimals);
                            throw Exception('Amount too little.\nminimum cycles: ${minimum_cycles}\nminimum ${tc.ledger_data.symbol}: ${minimum_tokens}');
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
                await this.fresh_cm_trade_contracts_balances(trade_contract);
                trade_contract_balance = kind == PositionKind.Token ? this.cm_trade_contracts[tc]!.trade_contract_token_balance : this.cm_trade_contracts[tc]!.trade_contract_cycles_balance;
                
                if (trade_contract_balance > ledger_data.fee) {
                    try{
                        await this.cm_transfer_balance(
                            tc,
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



