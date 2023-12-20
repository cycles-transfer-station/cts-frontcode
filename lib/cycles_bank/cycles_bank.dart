

import 'dart:collection';
import 'dart:typed_data';
import 'dart:html' show window;

import 'package:ic_tools/ic_tools.dart';
import 'package:ic_tools/tools.dart';
import 'package:ic_tools/candid.dart';
import 'package:ic_tools/common.dart';
import 'package:ic_tools/common.dart' as common;


import '../user.dart';
import '../config/state.dart';
import '../cycles_market/cycles_market.dart';
import '../transfer_icp/icp_ledger.dart';
import '../tools/tools.dart';



typedef UserBank = CyclesBank;

class CyclesBank extends Canister {
    User user;

    CyclesBankMetrics? metrics;
    
    List<CyclesTransferIn> cycles_transfers_in = [];
    List<CyclesTransferOut> cycles_transfers_out = [];
    
    List<Icrc1Ledger> known_icrc1_ledgers = [ if (is_on_local) Icrc1Ledgers.ICP, if (is_on_local == false) ...Icrc1Ledgers.all ];
    Icrc1Ledger? current_icrc1_ledger = null;
    Map<Icrc1Ledger, BigInt> icrc1_balances_cache = {};
    Map<Icrc1Ledger, List<Icrc1Transaction>> icrc1_transactions_cache = {};
    List<IcpTransfer> icp_transfers = []; // icp-transfer logs are different than the icrc1-transfer-logs
    final String icp_id; // so we dont hash everytime
    
    
    // cycles-market fields
    Map<Icrc1TokenTradeContract, CyclesBankCMTradeContractData> cm_trade_contracts = {};
    // only need cause icp ledger has different account ids and transaction log
    //late final String cm_icp_id; //cm_icp_id = common.icp_id(cycles_market_icp_icrc1token_trade_contract.principal, subaccount_bytes: principal_as_an_icpsubaccountbytes(principal)), 
    List<IcpTransfer> cm_icp_transfers = [];
    
    
            
    CyclesBank(
        super.principal,
        this.user,
    ): icp_id = common.icp_id(principal) {
        
        load_local_root_key_onto_a_canister(this).then((_x){});      
    }
    
    Future<void> fresh_metrics() async {
        Record metrics_record = c_backwards(
            await this.user.call(
                this,
                method_name: 'metrics',
                calltype: CallType.query,
                put_bytes: c_forwards([])
            )
        )[0] as Record;
        this.metrics = CyclesBankMetrics.of_the_record(metrics_record);
        
        //print('cm_message_cycles_position_purchase_positor_logs_len: ${this.metrics!.cm_message_cycles_position_purchase_positor_logs_len}');
    }
    
    void fresh_known_cm_trade_contracts_of_the_cm_main() {
        for (Icrc1TokenTradeContract tc in this.user.state.cm_main.icrc1token_trade_contracts) {
            if (this.known_icrc1_ledgers.contains(tc.ledger_data) == false) {
                this.known_icrc1_ledgers.add(tc.ledger_data);
            }
            if (this.cm_trade_contracts.containsKey(tc) == false) {
                this.cm_trade_contracts[tc] = CyclesBankCMTradeContractData();
            }
        }
    }
    
    Future<void> fresh_icrc1_balances([Icrc1Ledger? icrc1_ledger]) async {
        List<Icrc1Ledger> ledgers = icrc1_ledger != null ? [icrc1_ledger] : this.known_icrc1_ledgers;
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
        //print(this.icrc1_balances_cache);
    }
    // helper for fresh_icrc1_transactions
    Future<Variant> _call_icrc1_index_transactions(Icrc1Ledger l, [Nat? start]) async {
        return c_backwards(await l.index!.call(
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

    Future<void> fresh_icrc1_transactions([Icrc1Ledger? icrc1_ledger]) async {
        if (is_on_local) {
            return;
        } else {
            return fresh_icrc1_transactions_(icrc1_ledger);
        }
    }    
    Future<void> fresh_icrc1_transactions_([Icrc1Ledger? icrc1_ledger]) {
        List<Icrc1Ledger> ledgers = icrc1_ledger != null ? [icrc1_ledger] : this.known_icrc1_ledgers;
        return Future.wait(
            ledgers.map<Future<void>>((l)=>Future(()async{
                print('fresh icrc1 transactions future ${l.name}');
                if (l.ledger.principal == common.SYSTEM_CANISTERS.ledger.principal) {
                    // for the do! hook up with the new icp index canister
                    this.icp_transfers = [
                        ...await get_icp_transfers(this.icp_id, already_have: this.icp_transfers.length),
                        ...this.icp_transfers
                    ];
                } else /*tokens besides icp*/ {
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
    
    //Future<void> delete_ functionality coming soon
    
    Future<TransferCyclesSponse> transfer_cycles(UserTransferCyclesQuest q) async {
        // get the cts-cb-authorization of the q.for_the_canister, 
        late Uint8List b;
        try {
            b = await this.user.call(
                Canister(q.for_the_canister),
                method_name: 'get_cts_cb_auth',
                calltype: CallType.query,
            );
        } on CallException catch(e) {
            if (e.reject_code == BigInt.from(3)) {
                throw Exception('For the canister must be a CYCLES-BANK.');
            } else {
                rethrow;
            }
        } catch(e) {
            rethrow;
        }
        
        Record callee_user_and_cts_cb_authorization = c_backwards_one(b) as Record;
        Variant transfer_cycles_sponse = c_backwards(
            await this.user.call(
                this,
                method_name: 'transfer_cycles',
                put_bytes: c_forwards([q, callee_user_and_cts_cb_authorization]),
                calltype: CallType.call,
            )
        )[0] as Variant;
        TransferCyclesSponse sponse = match_variant<TransferCyclesSponse>(transfer_cycles_sponse, {
            Ok: (s) {
                return TransferCyclesSponse.of_the_record(s as Record);
            },
            Err: (transfer_cycles_error) {
                match_variant<Never>(transfer_cycles_error as Variant, {
                    'MemoryIsFull': (nul) {
                        throw Exception('The cycles-bank memory is full. Grow the memory-size of the cycles-bank or delete some data.');
                    },
                    'InvalidCyclesTransferMemoSize': (max_size_bytes_record) {
                        throw Exception('This cycles-bank supports sending a cycles-transfer-memo of a max ${((max_size_bytes_record as Record)['max_size_bytes'] as Nat).value} bytes.');
                    },
                    'InvalidTransferCyclesAmount': (minimum_user_transfer_cycles_record) {
                        throw Exception('The minimum cycles that can be sent through this cycles-bank is: ${Cycles.oftheNat((minimum_user_transfer_cycles_record as Record)['minimum_user_transfer_cycles'] as Nat)}');
                    },
                    'CyclesBalanceTooLow': (r_ctype) {
                        Record r = r_ctype as Record;
                        this.metrics!.cycles_balance = Cycles.oftheNat(r['cycles_balance'] as Nat);
                        throw Exception('The cycles-balance in the cycles-bank is too low to transfer these cycles. \ncycles_balance: ${Cycles.oftheNat(r['cycles_balance'] as Nat)}\ntransfer cycles fee: ${Cycles.oftheNat(r['cycles_transferrer_transfer_cycles_fee'] as Nat)}');
                    },
                    'CyclesTransferCallPerformError': (call_error) {
                        throw Exception('cycles-transfer call perform error: ${CallError.of_the_record(call_error as Record)}');
                    }
                });
            }
        });
        this.metrics!.cycles_transfers_out_len = this.metrics!.cycles_transfers_out_len + BigInt.from(1);
        return sponse;
    }
    

    Future<List<T>> cb_download_mechanism<T>({
        Icrc1TokenTradeContract? icrc1token_trade_contract, // use for the cm-logs download methods 
        required String download_method_name,
        required int len_so_far,
        required T Function(Record) function
    }) async {
        int? opt_start_before_i;
        List<T> gather_logs = [];
        int? logs_len; // set once on the first call.
        while (true) {
            
            Record download_sponse = c_backwards(await this.user.call(
                this,
                method_name: download_method_name,
                calltype: CallType.query,
                put_bytes: c_forwards([
                    if (icrc1token_trade_contract != null) icrc1token_trade_contract,
                    Record.of_the_map({
                        'opt_start_before_i': Option<Nat64>(value: opt_start_before_i.nullmap((n)=>Nat64(BigInt.from(n))), value_type: Nat64()),
                        'chunk_size': Nat64(BigInt.from(500))
                    })
                ])
            )).first as Record;
            
            if (logs_len == null) { // only set once on the first call
                logs_len = (download_sponse['logs_len'] as Nat64).value.toInt();
            }
            
            List<T>? logs = download_sponse.find_option<Vector>('logs').nullmap((v)=>v.cast_vector<Record>().map(function).toList());
            
            if (logs == null) {
                break;
            }
            
            gather_logs = [
                ...logs,
                ...gather_logs
            ];
            
            if (len_so_far + gather_logs.length > logs_len) {
                gather_logs.removeRange(0, len_so_far + gather_logs.length - logs_len);
                break;
            }
            if (len_so_far + gather_logs.length == logs_len) {
                break;
            }
            opt_start_before_i = logs_len - gather_logs.length;
            
        }
        return gather_logs;   
    }




    Future<void> fresh_cycles_transfers_in() async {
        this.cycles_transfers_in.addAll(
            await cb_download_mechanism(
                len_so_far: this.cycles_transfers_in.length,
                download_method_name: 'download_cycles_transfers_in', 
                function: CyclesTransferIn.of_the_record,
            )
        );
    }
    
    Future<void> fresh_cycles_transfers_out() async {
        // re-fresh the cycles-transfers-out that still have pending callbacks.
        List<CyclesTransferOut> backup_transfers_with_pending_callbacks = [];// backup in case re-fresh fails
        int i = this.cycles_transfers_out.indexWhere((CyclesTransferOut cto)=>cto.cycles_refunded == null);
        if (i >= 0) {
            backup_transfers_with_pending_callbacks = this.cycles_transfers_out.sublist(i, this.cycles_transfers_out.length);
            this.cycles_transfers_out.removeRange(i, this.cycles_transfers_out.length);
        }
        try {
            this.cycles_transfers_out.addAll(
                await cb_download_mechanism(
                    len_so_far: this.cycles_transfers_out.length,
                    download_method_name: 'download_cycles_transfers_out', 
                    function: CyclesTransferOut.of_the_record,
                )
            );
        } catch(e) {
            this.cycles_transfers_out.addAll(backup_transfers_with_pending_callbacks);
            throw e;
        }
    }
    
    Future<LengthenMembershipSuccess> user_lengthen_membership_cb_cycles_payment(LengthenMembershipQuest q, Cycles msg_cycles) async {
        Variant sponse = c_backwards_one(
            await user.call(
                this,
                method_name: 'user_lengthen_membership_cb_cycles_payment',
                calltype: CallType.call,
                put_bytes: c_forwards([q, msg_cycles])
            )
        ) as Variant;
        return await match_variant<Future<LengthenMembershipSuccess>>(sponse, {
            Ok: (blob) async {
                return await match_variant<Future<LengthenMembershipSuccess>>(
                    c_backwards_one((blob as Blob).bytes) as Variant,
                    this.user.lengthen_membership_result_match_map(this.user.complete_lengthen_membership_cb_cycles_payment)
                );           
            },
            Err: (call_error) async {
                throw Exception("call error when cycles-bank call the cts.\n${CallError.of_the_record(call_error as Record)}");
            }
        });
    }

    
    Future<BigInt/*block_height*/> transfer_icrc1(Icrc1Ledger icrc1_ledger, Uint8List icrc1_transfer_arg_raw) async {
        Variant sponse = c_backwards(
            await user.call(
                this,
                method_name: 'transfer_icrc1',
                calltype: CallType.call,
                put_bytes: c_forwards([icrc1_ledger.ledger.principal, Blob(icrc1_transfer_arg_raw)])
            )
        ).first as Variant;
        BigInt block_height = match_variant<BigInt>(sponse, {
            Ok: (n){
                Variant ledger_transfer_sponse = c_backwards((n as Blob).bytes).first as Variant;
                return match_variant<BigInt>(ledger_transfer_sponse, {
                    Ok: (block_height) {
                        return (block_height as Nat).value;
                    },
                    Err: (icrc1_transfer_error) {
                        return match_variant<Never>(icrc1_transfer_error as Variant, {
                            'BadFee' : (r) {
                                throw Exception('Fee must be: ${Tokens(quantums: ((r as Record)['expected_fee'] as Nat).value, decimal_places: icrc1_ledger.decimals)}');
                            },
                            'BadBurn' : (r) {   
                                throw Exception('BadBurn: min_burn_amount: ${Tokens(quantums: ((r as Record)['min_burn_amount'] as Nat).value, decimal_places: icrc1_ledger.decimals)} ');
                            },
                            'InsufficientFunds' : (r) {
                                throw Exception('InsufficientFunds. current-balance: ${Tokens(quantums: ((r as Record)['balance'] as Nat).value, decimal_places: icrc1_ledger.decimals)}');
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
                        });
                    }
                });
            },
            Err: (call_error){
                throw Exception('ledger transfer call error: ${CallError.of_the_record(call_error as Record)}');        
            },
        });
        return block_height;
    }
    
    

    Future<BigInt> transfer_icp(Uint8List transfer_arg_raw) async {
        Variant sponse = c_backwards(
            await user.call(
                this,
                method_name: 'transfer_icp',
                calltype: CallType.call,
                put_bytes: c_forwards([Blob(transfer_arg_raw)])
            )
        ).first as Variant;
        BigInt block_height = match_variant<BigInt>(sponse, {
            Ok: (n){
                return match_variant<BigInt>(c_backwards((n as Blob).bytes).first as Variant, {
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
            },
            Err: (call_error){
                throw Exception('ledger transfer call error: ${CallError.of_the_record(call_error as Record)}');        
            },
        });
        return block_height;    
    }
    
    // user is in the middle of a different call
     Map<String, Never Function(CandidType)> get user_is_in_the_middle_of_a_different_call_variant_match_map => {
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
    };

    
    
    // -------- burn_icp_mint_cycles
    

    Map<String, Future<BurnIcpMintCyclesSuccess> Function(CandidType)> get burn_icp_mint_cycles_result_match_map => {
        Ok: (burn_icp_mint_cycles_success) async {
            return BurnIcpMintCyclesSuccess.of_the_record(burn_icp_mint_cycles_success);
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
        'LedgerTopupCyclesCmcNotifyRefund': (c) async {
            BigInt rblock = ((c as Record)['block_index'] as Nat64).value;
            String reason = ((c as Record)['reason'] as Text).value;
            throw Exception('The cycles-minter-canister (nns-cmc) refunded your icp at the block-height: ${rblock} with the reason: ${reason}');
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
        Variant burn_icp_mint_cycles_result = c_backwards(
            await user.call(
                this,
                calltype: CallType.call,
                method_name: 'burn_icp_mint_cycles',
                put_bytes: c_forwards([
                    Record.of_the_map({
                        'burn_icp': burn_icp,
                        'burn_icp_transfer_fee': ICP_LEDGER_TRANSFER_FEE,
                    })
                ])
            )
        )[0] as Variant;
        return await match_variant<Future<BurnIcpMintCyclesSuccess>>(burn_icp_mint_cycles_result, burn_icp_mint_cycles_result_match_map);
    }
    
    Future<BurnIcpMintCyclesSuccess> complete_burn_icp_mint_cycles() async {
        Variant complete_burn_icp_mint_cycles_result = c_backwards(
            await user.call(
                this,
                calltype: CallType.call,
                method_name: 'complete_burn_icp_mint_cycles',
                put_bytes: c_forwards([])
            )
        )[0] as Variant;
        return await match_variant<Future<BurnIcpMintCyclesSuccess>>(complete_burn_icp_mint_cycles_result, complete_burn_icp_mint_cycles_result_match_map);
    }

        
    Future<BigInt/*cycles-transfer-out-id*/> management_canister_deposit_cycles(ManagementCanisterDepositCyclesQuest q) async {
        Variant sponse = c_backwards_one(
            await user.call(
                this,
                calltype: CallType.call,
                method_name: 'management_canister_deposit_cycles',
                put_bytes: c_forwards_one(q)
            )
        ) as Variant;
        return await match_variant<BigInt>(sponse, {
            Ok: (nat) {
                return (nat as Nat).value;
            },
            Err: (e) {
                return match_variant<Never>(e as Variant, {
                    'CyclesBalanceTooLow': (r) {
                        throw Exception('Cycles balance too low. \ncurrent cycles balance: ${Cycles.of_the_nat((r as Record)['cycles_balance'] as Nat)}');
                    },
                    'CallError': (ce) {
                        throw Exception('Management Canister Call Error: ${CallError.of_the_record(ce as Record)}');
                    },
                });
            }             
        });
    }
    
    
    // ---------------------
    
    // cycles-market methods
    
    

    
    
    /*
    Future<BigInt> cm_view_token_lock(Icrc1TokenTradeContract icrc1token_trade_contract) async {
        BigInt token_lock = (c_backwards(
            await this.user.call(
                icrc1token_trade_contract.canister,
                calltype: CallType.query,
                method_name: 'view_token_lock',
                put_bytes: c_forwards([
                    Record.of_the_map({
                        'principal_id': this.principal
                    })
                ])
            )
        )[0] as Nat).value;
        return token_lock;
    }
    */
    Future<void> fresh_cm_trade_contracts_token_balances([Icrc1TokenTradeContract? icrc1token_trade_contract]) async {
        List<Icrc1TokenTradeContract> icrc1token_trade_contracts = icrc1token_trade_contract != null ? [icrc1token_trade_contract] : this.cm_trade_contracts.keys.toList();
        await Future.wait(
            icrc1token_trade_contracts.map((tc)=>Future(()async{                
                /*
                List<BigInt> rs = await Future.wait([ 
                    check_icrc1_balance(
                        icrc1_ledger_canister_id: tc.icrc1_ledger_canister_id, 
                        owner: tc.trade_contract_canister_id,
                        subaccount: principal_as_an_icpsubaccountbytes(this.principal),
                        calltype: CallType.query
                    ),
                    this.cm_view_token_lock(tc)
                ]);
                BigInt token_ledger_balance = rs[0];
                BigInt tokens_in_the_lock = rs[1]; 
                BigInt balance = token_ledger_balance - tokens_in_the_lock;
                this.cm_trade_contracts[tc]!.trade_contract_token_balance = balance >= BigInt.from(0) ? balance : BigInt.from(0);
                print('token_ledger_balance: $token_ledger_balance, tokens_in_the_lock: $tokens_in_the_lock');
                */
                this.cm_trade_contracts[tc]!.trade_contract_token_balance = await check_icrc1_balance(
                    icrc1_ledger_canister_id: tc.icrc1_ledger_canister_id, 
                    owner: tc.trade_contract_canister_id,
                    subaccount: principal_as_an_icpsubaccountbytes(this.principal),
                    calltype: CallType.query
                );
            }))
        );
    }
    
    
    
    Future<BigInt> cm_trade_(Icrc1TokenTradeContract tc, Record q, PositionKind kind) async {
        Variant v = c_backwards_one(
            await user.call(
                this, 
                method_name: switch (kind) { PositionKind.Cycles => "cm_trade_cycles", _ => "cm_trade_tokens" },
                calltype: CallType.call,
                put_bytes: c_forwards([tc, q])
            )
        ) as Variant;
        BigInt position_id = match_variant(v, {
            Ok:(s){
                return match_variant(s as Variant, {
                    Ok: (r)=>((r as Record)['position_id'] as Nat).value,
                    Err: (e){
                        return match_variant<Never>(e as Variant,
                            kind == PositionKind.Cycles 
                            ?
                            {
                                'MinimumPosition': (mpr) {
                                    throw Exception('The minimum amount of ${tc.ledger_data.symbol} tokens you can trade is: ${Tokens.of_the_nat((mpr as Record)['minimum_tokens']!, decimal_places: tc.ledger_data.decimals)}.\nThe minimum amount of the CYCLES you can trade is ${Cycles.of_the_nat((mpr as Record)['minimum_cycles']!)}.');
                                },
                                'RateCannotBeZero': (n) {
                                    throw Exception('The trade rate cannot be zero');
                                },
                                'MsgCyclesTooLow': (n) {
                                    throw Exception('MsgCyclesTooLow');
                                },
                                'CyclesMarketIsBusy': (n) {
                                    throw Exception('The Cycles-Market is busy. Try soon.');
                                },
                            }
                            :
                            {
                                'MinimumPosition': (mpr) {
                                    throw Exception('The minimum amount of ${tc.ledger_data.symbol} tokens you can trade is: ${Tokens.of_the_nat((mpr as Record)['minimum_tokens']!, decimal_places: tc.ledger_data.decimals)}.\nThe minimum amount of the CYCLES you can trade is ${Cycles.of_the_nat((mpr as Record)['minimum_cycles']!)}.');
                                },
                                'RateCannotBeZero': (n) {
                                    throw Exception('The trade rate cannot be zero');
                                },
                                'CallerIsInTheMiddleOfADifferentCallThatLocksTheTokenBalance': (n) {
                                    throw Exception('Caller is in the middle of a different call that locks the user token balance.');
                                },
                                'CyclesMarketIsBusy': (n) {
                                    throw Exception('The Cycles-Market is busy. Try soon.');
                                },
                                'CollectTokensForThePositionLedgerTransferCallError': (call_error) {
                                    throw Exception('Call error during collect tokens for the position ledger transfer. \n${CallError.of_the_record(call_error as Record)}');
                                },
                                'CollectTokensForThePositionLedgerTransferError': (token_transfer_error) {
                                    try {
                                        match_variant<Never>(token_transfer_error as Variant, token_transfer_error_match_map(token_decimal_places: tc.ledger_data.decimals));
                                    } catch(e) {
                                        throw Exception('${tc.ledger_data.symbol} ledger transfer error during collect tokens for the position. \n${etext(e)}');
                                    }
                                    throw Exception(''); // ignore
                                }
                            }
                        ); 
                    }
                });
            },
            Err: (e) {
                return match_variant<Never>(e as Variant, 
                    kind == PositionKind.Cycles 
                    ?
                    {
                        'MemoryIsFull': (n) {
                            throw Exception('The bank\'s memory is full.');
                        },
                        'CyclesBalanceTooLow': (r) {
                            throw Exception('The cycles-balance is too low. \ncycles-balance: ${Cycles.oftheNat((r as Record)['cycles_balance'] as Nat)}');
                        },
                        'CMTradeCyclesCallError': (call_error) {
                            throw Exception('Call error during call to the cycles-market.\n${CallError.of_the_record(call_error as Record)}');
                        },
                        'CMTradeCyclesCallSponseCandidDecodeError': (rc) {
                            Record r = rc as Record;
                            throw Exception('Error decoding response from the cycles-market.\nresponse: ${(r['sponse_bytes'] as Blob).bytes}\ncandid_error: ${(r['candid_error'] as Text).value}');
                        },
                    }
                    :
                    {
                        'MemoryIsFull': (n) {
                            throw Exception('The bank\'s memory is full.');
                        },
                        'CMTradeTokensCallError': (call_error) {
                            throw Exception('Call error during call to the cycles-market.\n${CallError.of_the_record(call_error as Record)}');
                        },
                        'CMTradeTokensCallSponseCandidDecodeError': (rc) {
                            Record r = rc as Record;
                            throw Exception('Error decoding response from the cycles-market.\nresponse: ${(r['sponse_bytes'] as Blob).bytes}\ncandid_error: ${(r['candid_error'] as Text).value}');
                        },
                    }
                );
            } 
        });
        return position_id;
    }    

    Future<BigInt/*position-id*/> cm_trade_cycles(Icrc1TokenTradeContract icrc1token_trade_contract, TradeCyclesQuest q) async {
        return await cm_trade_(icrc1token_trade_contract, q, PositionKind.Cycles);
    }

    Future<BigInt/*position-id*/> cm_trade_tokens(Icrc1TokenTradeContract tc, TradeTokensQuest q) async {
        
        await Future.wait([
            this.fresh_icrc1_balances(tc.ledger_data),
            this.fresh_cm_trade_contracts_token_balances(tc),
        ]);
        
        if (this.cm_trade_contracts[tc]!.trade_contract_token_balance < q.tokens.quantums + tc.ledger_data.fee) {
            if (this.icrc1_balances_cache[tc.ledger_data]! < q.tokens.quantums - this.cm_trade_contracts[tc]!.trade_contract_token_balance + (tc.ledger_data.fee * BigInt.from(2))) {
                throw Exception(
"""For a trade of ${q.tokens} tokens, need minimum combined main-account and cm-escrow-account token-balance: ${Tokens(quantums: q.tokens.quantums + (tc.ledger_data.fee * BigInt.from(2)), decimal_places: tc.ledger_data.decimals)}.
Current main-account token-balance: ${Tokens(quantums: this.icrc1_balances_cache[tc.ledger_data]!, decimal_places: tc.ledger_data.decimals)} ${tc.ledger_data.symbol}.
Current cm-escrow-account token-balance: ${Tokens(quantums: this.cm_trade_contracts[tc]!.trade_contract_token_balance, decimal_places: tc.ledger_data.decimals)} ${tc.ledger_data.symbol}.
"""
                );             
            }    
            print('cm_sell_tokens transferring ${q.tokens.quantums - this.cm_trade_contracts[tc]!.trade_contract_token_balance} token quantums');
            print('tc user token balance quantums before transfer ${this.cm_trade_contracts[tc]!.trade_contract_token_balance}');
            await transfer_icrc1(
                tc.ledger_data, 
                c_forwards_one(Record.of_the_map({
                    'to':Icrc1Account(owner: tc.trade_contract_canister_id, subaccount:principal_as_an_icpsubaccountbytes(this.principal)),
                    'fee': Nat(tc.ledger_data.fee),
                    'amount': Nat(q.tokens.quantums - this.cm_trade_contracts[tc]!.trade_contract_token_balance + tc.ledger_data.fee)
                }))
            );
            // test
            //await this.fresh_cm_trade_contracts_token_balances(tc);
            //print('tc user token balance quantums after transfer ${this.cm_trade_contracts[tc]!.trade_contract_token_balance}');
        
        }
        
        try{
            return await cm_trade_(tc, q, PositionKind.Token);
        } catch(cm_trade_error) {
            try {
                await this.fresh_cm_trade_contracts_token_balances(tc);
                if (this.cm_trade_contracts[tc]!.trade_contract_token_balance > tc.ledger_data.fee) {
                    try{
                        await this.cm_transfer_token_balance(
                            tc,
                            CyclesMarketTransferTokenBalanceQuest(
                                tokens: Tokens(quantums: this.cm_trade_contracts[tc]!.trade_contract_token_balance - tc.ledger_data.fee, decimal_places: tc.ledger_data.decimals),
                                token_fee: Tokens(quantums: tc.ledger_data.fee, decimal_places: tc.ledger_data.decimals),
                                to: Icrc1Account(owner: this.principal),
                            )
                        );
                    } catch(cm_transfer_token_balance_error) {
                        print('Error cm_transfer_token_balance:\n${cm_transfer_token_balance_error}');
                    }
                }
            } catch(fresh_cm_tc_token_balance_error) {
                print('Error fresh_cm_trade_contracts_token_balances(tc):\n${fresh_cm_tc_token_balance_error}');
            }
            rethrow; //throw cm_trade_error;
        }
    }
    
    
    Future<void> cm_void_position(Icrc1TokenTradeContract icrc1token_trade_contract, BigInt position_id) async {
        Variant sponse = c_backwards(
            await user.call(
                this,
                method_name: 'cm_void_position',
                calltype: CallType.call,
                put_bytes: c_forwards([
                    icrc1token_trade_contract,
                    CyclesMarketVoidPositionQuest(
                        position_id: position_id
                    )
                ])
            )
        ).first as Variant;
        return match_variant<void>(sponse, {
            Ok: (ok) {
                
            },
            Err: (void_position_error) {
                match_variant<Never>(void_position_error as Variant, {
                    'CTSFuelTooLow': (nul) {
                        throw Exception('The CTSFuel is too low. Topup the CTSFuel in this cycles-bank.');
                    },
                    'CyclesMarketVoidPositionCallError': (call_error_record) {
                        throw Exception('cycles-market void_position call_error:\n${CallError.of_the_record(call_error_record as Record)}');
                    },
                    'CyclesMarketVoidPositionError': (cycles_market_void_position_error) {
                        match_variant<Never>(cycles_market_void_position_error as Variant, {
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
        });
    }

    Future<BigInt/*block_height*/> cm_transfer_token_balance(Icrc1TokenTradeContract icrc1token_trade_contract, CyclesMarketTransferTokenBalanceQuest q) async {
        Variant sponse = c_backwards(
            await user.call(
                this,
                method_name: 'cm_transfer_token_balance',
                calltype: CallType.call,
                put_bytes: c_forwards([icrc1token_trade_contract, q])
            )
        ).first as Variant;
        BigInt block_height = match_variant<BigInt>(sponse, {
            Ok: (block_height_nat) {
                return (block_height_nat as Nat).value;
            },
            Err: (transfer_token_balance_error) {
                return match_variant<Never>(transfer_token_balance_error as Variant, {
                    'CTSFuelTooLow': (nul) {
                        throw Exception('The CTSFuel is too low. Topup the CTSFuel in this cycles-bank.');
                    },
                    'MemoryIsFull': (nul) {
                        throw Exception('The memory is full in the cycles-bank. Grow the memory or free some space.');
                    },
                    'CyclesBalanceTooLow': (r_ctype){
                        Record r = r_ctype as Record;
                        this.metrics!.cycles_balance = Cycles.oftheNat(r['cycles_balance'] as Nat);
                        throw Exception('The cycles-balance is too low on this cycles-bank.\ncycles_balance: ${Cycles.oftheNat(r['cycles_balance'] as Nat)}\ncycles_market_transfer_token_balance_fee: ${Cycles.oftheNat(r['cycles_market_transfer_token_balance_fee']!)}');
                    },
                    'CyclesMarketTransferTokenBalanceCallError': (call_error_record) {
                        throw Exception('cycles_market transfer_token_balance call_error: \n${CallError.of_the_record(call_error_record as Record)}');
                    },
                    'CyclesMarketTransferTokenBalanceCallSponseCandidDecodeError': (r_ctype) {
                        Record r = r_ctype as Record;
                        throw Exception('Error decoding cycles-market transfer_token_balance response:\ncandid_error: ${(r['candid_error'] as Text).value}\nsponse_bytes: ${(r['sponse_bytes'] as Blob).bytes}');
                    },
                    'CyclesMarketTransferTokenBalanceError': (cycles_market_transfer_token_balance_error) {
                        return match_variant<Never>(cycles_market_transfer_token_balance_error as Variant, {
                            'CyclesMarketIsBusy': (nul) {
                                throw Exception('The cycles-market is busy. try soon.');
                            },
                            'CallerIsInTheMiddleOfADifferentCallThatLocksTheTokenBalance': (nul){
                                throw Exception('The cycles-bank is in the middle of a call for the cycles-market.');
                            },
                            'TokenTransferCallError':(call_error_record) {
                                throw Exception('${icrc1token_trade_contract.ledger_data.symbol}-ledger transfer call error: \n${CallError.of_the_record(call_error_record as Record)}');
                            },
                            'TokenTransferError': (token_transfer_error){
                                return match_variant<Never>(token_transfer_error as Variant, token_transfer_error_match_map(token_decimal_places: icrc1token_trade_contract.ledger_data.decimals));
                            }
                        });
                    }                
                });
            }
        });
        //this.fresh_cm_token_transfers_out(icrc1token_trade_contract);
        return block_height;
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

    Future<void> load_cm_user_positions([Icrc1TokenTradeContract? tc]) async {
        List<Icrc1TokenTradeContract> tcs = tc != null ? [tc] : this.cm_trade_contracts.keys.toList();
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
                Uint8List logs_b_chunk = await this.user.call(
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
                    Uint8List logs_b_chunk = await this.user.call(
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
    
        
    
    Future<void> load_cm_data([Icrc1TokenTradeContract? trade_contract]) async {
        await Future.wait([
            this.fresh_cm_trade_contracts_token_balances(trade_contract),
            this.load_cm_user_positions(trade_contract),
            // loads the latest trades of those positions whos trades have been already loaded at least once. because those positions that have not loaded the trades at least once, will load if clicked on.
            Future(()async{
                List<Icrc1TokenTradeContract> trade_contracts = trade_contract != null ? [trade_contract] : this.cm_trade_contracts.keys.toList();
                await Future.wait(
                    trade_contracts.map((tc)=>Future(()async{
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
    
    
    



}


Map<String, Never Function(CandidType)> icp_transfer_error_match_map = {
        'BadFee': (expected_fee_record) {
            throw Exception('Bad Fee set on the transfer. expected_fee: ${IcpTokens.of_the_record((expected_fee_record as Record)['expected_fee']!)}');
        },
        'InsufficientFunds': (balance_record) {
            IcpTokens current_balance = IcpTokens.of_the_record((balance_record as Record)['balance']!);
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


Map<String, Never Function(CandidType)> token_transfer_error_match_map({required int token_decimal_places}) {
    return {
        'BadFee': (expected_fee_record) {
            throw Exception('Bad Fee set on the transfer. expected_fee: ${Tokens.of_the_nat((expected_fee_record as Record)['expected_fee'] as Nat, decimal_places: token_decimal_places)}');
        },
        'InsufficientFunds': (balance_record) {
            // this error does not happen on a cycles-market cm_transfer_token_balance
            Tokens current_balance = Tokens.of_the_nat((balance_record as Record)['balance'] as Nat, decimal_places: token_decimal_places);
            throw Exception('Token balance is too low. current balance: ${current_balance}');
        },
        'TooOld': (nul) {
            throw Exception('Token transfer created_at_time field is too old');
        },
        'CreatedInFuture': (n) {
            throw Exception('Token transfer created_at_time field is too far in the future.');
        },
        'Duplicate': (duplicate_of_record) {
            throw Exception('The Token transfer is a duplicate of the transfer at the block: ${((duplicate_of_record as Record)['duplicate_of'] as Nat).value}');
        },
        'TemporarilyUnavailable': (nul) {
            throw Exception('The ledger is busy, try soon.');
        },
        'GenericError': (rc) {
            Record r = rc as Record;
            throw Exception('Ledger error. error-code: ${(r['error_code'] as Nat).value}, error-message: ${(r['message'] as Text).value}');
        }
    };
}



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



// ------------- METRICS -------------

typedef CTSFuel = Cycles;


class CyclesBankMetrics {
    BigInt global_allocator_counter;
    Cycles cycles_balance;
    CTSFuel ctsfuel_balance;
    BigInt storage_size_mib;
    BigInt lifetime_termination_timestamp_seconds;
    Principal user_id;
    BigInt user_canister_creation_timestamp_nanos;
    BigInt storage_usage;
    BigInt cycles_transfers_id_counter;
    BigInt cycles_transfers_in_len;
    BigInt cycles_transfers_out_len;
    bool cts_cb_authorization;
    
    CyclesBankMetrics._({
        required this.global_allocator_counter,
        required this.cycles_balance,
        required this.ctsfuel_balance,
        required this.storage_size_mib,
        required this.lifetime_termination_timestamp_seconds,
        required this.user_id,
        required this.user_canister_creation_timestamp_nanos,
        required this.storage_usage,
        required this.cycles_transfers_id_counter,
        required this.cycles_transfers_in_len,
        required this.cycles_transfers_out_len,
        required this.cts_cb_authorization,
    });
    static CyclesBankMetrics of_the_record(Record r) {
        return CyclesBankMetrics._(
            global_allocator_counter: (r['global_allocator_counter'] as Nat64).value,
            cycles_balance: Cycles.oftheNat(r['cycles_balance'] as Nat),
            ctsfuel_balance: CTSFuel.oftheNat(r['ctsfuel_balance'] as Nat),
            storage_size_mib: (r['storage_size_mib'] as Nat).value,
            lifetime_termination_timestamp_seconds: (r['lifetime_termination_timestamp_seconds'] as Nat).value,
            user_id: (r['user_id'] as Principal),
            user_canister_creation_timestamp_nanos: (r['user_canister_creation_timestamp_nanos'] as Nat).value,
            storage_usage: (r['storage_usage'] as Nat).value,
            cycles_transfers_id_counter: (r['cycles_transfers_id_counter'] as Nat).value,
            cycles_transfers_in_len: (r['cycles_transfers_in_len'] as Nat).value,
            cycles_transfers_out_len: (r['cycles_transfers_out_len'] as Nat).value,
            cts_cb_authorization: (r['cts_cb_authorization'] as Bool).value,
        );
    }
}





// ------------- CyclesTransfer -------------



abstract class CyclesTransfer {
    BigInt get id;
    BigInt get timestamp_nanos;
}



class CyclesTransferIn implements CyclesTransfer {
    final BigInt id;
    final Principal by_the_canister;
    final Cycles cycles;
    final CyclesTransferMemo cycles_transfer_memo;
    final BigInt timestamp_nanos;
    
    CyclesTransferIn._({
        required this.id,
        required this.by_the_canister,
        required this.cycles,
        required this.cycles_transfer_memo,
        required this.timestamp_nanos,
    });
    
    static CyclesTransferIn of_the_record(Record r) {
        return CyclesTransferIn._(
            id: (r['id'] as Nat).value,
            by_the_canister: r['by_the_canister'] as Principal,
            cycles: Cycles.oftheNat(r['cycles'] as Nat),
            cycles_transfer_memo: CyclesTransferMemo.oftheVariant(r['cycles_transfer_memo'] as Variant),
            timestamp_nanos: (r['timestamp_nanos'] as Nat).value,
        );
    }
}


class CyclesTransferOut implements CyclesTransfer {
    final BigInt id;
    final Principal for_the_canister;
    final Cycles cycles_sent;
    final Cycles? cycles_refunded;   // option cause this field is only filled in the callback and that might not come back because of the callee holding-back the callback cross-upgrades. // if/when a user deletes some CyclesTransferPurchaseLogs, let the user set a special flag to delete the still-not-come-back-user_transfer_cycles by default unset.
    final CyclesTransferMemo cycles_transfer_memo;                           
    final BigInt timestamp_nanos; // time sent
    final CallError? opt_cycles_transfer_call_error; // None means the cycles_transfer-call replied. // save max 20-bytes of the string

    CyclesTransferOut._({
        required this.id,    
        required this.for_the_canister,    
        required this.cycles_sent,    
        required this.cycles_refunded,    
        required this.cycles_transfer_memo,    
        required this.timestamp_nanos,    
        required this.opt_cycles_transfer_call_error,    
    });    
    
    static CyclesTransferOut of_the_record(Record r) {
        Nat? cycles_refunded_nat = r.find_option<Nat>('cycles_refunded');
        Record? opt_cycles_transfer_call_error = r.find_option<Record>('opt_cycles_transfer_call_error');
        return CyclesTransferOut._(
            id: (r['id'] as Nat).value,    
            for_the_canister: r['for_the_canister'] as Principal,    
            cycles_sent: Cycles.oftheNat(r['cycles_sent'] as Nat),    
            cycles_refunded: cycles_refunded_nat != null ? Cycles.oftheNat(cycles_refunded_nat) : null,    
            cycles_transfer_memo: CyclesTransferMemo.oftheVariant(r['cycles_transfer_memo'] as Variant),    
            timestamp_nanos: (r['timestamp_nanos'] as Nat).value,    
            opt_cycles_transfer_call_error: opt_cycles_transfer_call_error != null ? CallError.of_the_record(opt_cycles_transfer_call_error) : null,
        );
    }
}


class UserTransferCyclesQuest extends Record {
    final Principal for_the_canister;
    final Cycles cycles;
    final CyclesTransferMemo cycles_transfer_memo;
    
    UserTransferCyclesQuest({
        required this.for_the_canister,
        required this.cycles,
        required this.cycles_transfer_memo,
    }) {
        this['for_the_canister'] = this.for_the_canister;
        this['cycles'] = this.cycles;
        this['cycles_transfer_memo'] = this.cycles_transfer_memo;
    }
}

class TransferCyclesSponse extends Record {
    final Cycles cycles_refund;
    final BigInt cycles_transfer_id;
    final CallError? opt_cycles_transfer_call_error;
    TransferCyclesSponse({
        required this.cycles_refund,
        required this.cycles_transfer_id,
        required this.opt_cycles_transfer_call_error,
    });
    static TransferCyclesSponse of_the_record(Record r) {
        return TransferCyclesSponse(
            cycles_refund: Cycles.oftheNat(r['cycles_refund'] as Nat),
            cycles_transfer_id: (r['cycles_transfer_id'] as Nat).value,
            opt_cycles_transfer_call_error: r.find_option<Record>('opt_cycles_transfer_call_error').nullmap(CallError.of_the_record)
        );
    }
    
}


class BurnIcpMintCyclesSuccess {
    final Cycles mint_cycles;
    
    BurnIcpMintCyclesSuccess({required this.mint_cycles});
    
    static BurnIcpMintCyclesSuccess of_the_record(CandidType burn_icp_mint_cycles_success_record) {
        Record r = burn_icp_mint_cycles_success_record as Record;
        return BurnIcpMintCyclesSuccess(
            mint_cycles: Cycles.oftheNat(r['mint_cycles'] as Nat),
        );
    }
    
    String toString() {
        return 'cycles-mint: ${this.mint_cycles}';
    }
}


class ManagementCanisterDepositCyclesQuest extends Record {
    final Principal canister_id;
    final Cycles cycles;
    ManagementCanisterDepositCyclesQuest({required this.canister_id, required this.cycles}) {
        this['canister_id'] = this.canister_id;
        this['cycles'] = this.cycles;
    }
}


// ------------- CYCLES-MARKET -------------






class CyclesMarketVoidPositionQuest extends Record {
    BigInt position_id;
    CyclesMarketVoidPositionQuest({
        required this.position_id
    }) {
        this['position_id'] = Nat(this.position_id);
    }
}



class CyclesMarketTransferTokenBalanceQuest extends Record {
    final Tokens tokens;
    final Tokens token_fee;
    final Icrc1Account to;
    final Nat64? created_at_time;
    CyclesMarketTransferTokenBalanceQuest({
        required this.tokens,
        required this.token_fee,
        required this.to,
        this.created_at_time,
    }) {
        this['tokens'] = this.tokens;
        this['token_fee'] = this.token_fee;
        this['to'] = this.to;
        if (this.created_at_time != null) {
            this['created_at_time'] = Option(value: this.created_at_time!);
        }
    }
}




class CyclesBankCMTradeContractData {
    
    BigInt trade_contract_token_balance = BigInt.from(0);
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





