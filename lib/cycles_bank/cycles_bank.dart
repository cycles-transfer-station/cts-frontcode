


import 'dart:typed_data';

import 'package:ic_tools/ic_tools.dart';
import 'package:ic_tools/tools.dart';
import 'package:ic_tools/candid.dart';
import 'package:ic_tools/common.dart';
import 'package:ic_tools/common.dart' as common;


import '../user.dart';
import '../config/state.dart';
import '../cycles_market/cycles_market.dart';
import '../transfer_icp/icp_ledger.dart';




typedef UserBank = CyclesBank;

class CyclesBank extends Canister {
    User user;

    CyclesBankMetrics? metrics;
    
    List<CyclesTransferIn> cycles_transfers_in = [];
    List<CyclesTransferOut> cycles_transfers_out = [];
    
    List<Icrc1Ledger> known_icrc1_ledgers = [...Icrc1Ledgers.all, ];
    Icrc1Ledger? current_icrc1_ledger = null;
    Map<Icrc1Ledger, BigInt> icrc1_balances_cache = {};
    Map<Icrc1Ledger, List<Icrc1Transaction>> icrc1_transactions_cache = {};
    List<IcpTransfer> icp_transfers = []; // icp-transfer logs are different than the icrc1-transfer-logs
    final String icp_id; // so we dont hash everytime
    
    
    // cycles-market fields
    Map<Icrc1TokenTradeContract, CyclesBankCMTradeContractData> cm_trade_contracts = {};
    // only need cause icp ledger has different account ids and transaction log
    late final String cm_icp_id; //cm_icp_id = common.icp_id(cycles_market_icp_icrc1token_trade_contract.principal, subaccount_bytes: principal_as_an_icpsubaccountbytes(principal)), 
    List<IcpTransfer> cm_icp_transfers = [];
    
    
            
    CyclesBank(
        super.principal,
        this.user,
    ): icp_id = common.icp_id(principal);
    
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
    
    Future<void> fresh_known_cm_trade_contracts_of_the_cm_main() async {
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
    
    Future<void> fresh_icrc1_transactions([Icrc1Ledger? icrc1_ledger]) {
        List<Icrc1Ledger> ledgers = icrc1_ledger != null ? [icrc1_ledger] : this.known_icrc1_ledgers;
        return Future.wait(
            ledgers.map<Future<void>>((l)=>Future(()async{
                print('fresh icrc1 transactions future ${l.name}');
                if (l.ledger.principal == common.SYSTEM_CANISTERS.ledger.principal) {
                    // for the do! hook up with the dashboard icp-ledger-api
                    //print('get_icp_transfers');
                    //print(this.icp_id);
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
    
    Future<BigInt/*cycles_transfer_id*/> transfer_cycles(UserTransferCyclesQuest q) async {
        Variant transfer_cycles_sponse = c_backwards(
            await this.user.call(
                this,
                method_name: 'transfer_cycles',
                put_bytes: c_forwards([q]),
                calltype: CallType.call,
            )
        )[0] as Variant;
        BigInt cycles_transfer_out_id = match_variant<BigInt>(transfer_cycles_sponse, {
            Ok: (cycles_transfer_id_nat_ctype) {
                return (cycles_transfer_id_nat_ctype as Nat).value;
            },
            Err: (transfer_cycles_error) {
                match_variant<Never>(transfer_cycles_error as Variant, {
                    'CTSFuelTooLow': (nul) {
                        throw Exception('The CTSFuel in the cycles-bank is too low. Put CTSFuel into the cycles-bank.');
                    },
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
                    'CyclesTransferrerTransferCyclesError': (cycles_transferrer_transfer_cycles_error) {
                        match_variant<Never>(cycles_transferrer_transfer_cycles_error as Variant, {
                            'MsgCyclesTooLow': (transfer_cycles_fee_record) {
                                throw Exception('Please file this error:\nCyclesTransferrerTransferCyclesError MsgCyclesTooLow transfer_cycles_fee: ${Cycles.oftheNat((transfer_cycles_fee_record as Record)['transfer_cycles_fee'] as Nat)}');
                            },
                            'MaxOngoingCyclesTransfers': (nul) {
                                throw Exception('The cycles_transferrer is busy, try soon.');
                            },
                            'CyclesTransferQuestCandidCodeError': (text) {
                                throw Exception('Please file this error: \nCyclesTransferrerTransferCyclesError CyclesTransferQuestCandidCodeError \n${(text as Text).value}');
                            }                           
                        });
                    },
                    'CyclesTransferrerTransferCyclesCallError': (call_error_record){
                        throw Exception('Error of the transfer_cycles-call of the cycles_transferrer: \n${CallError.of_the_record(call_error_record as Record)}');
                    }
                });
            }
        });
        this.metrics!.cycles_transfers_out_len = this.metrics!.cycles_transfers_out_len + BigInt.from(1);
        return cycles_transfer_out_id;
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
    
    
    
    
    
    
    
    // ---------------------
    
    // cycles-market methods
    
    
    
    // put on the cb
    
    

    Future<void> load_cm_user_positions([Icrc1TokenTradeContract? icrc1token_trade_contract]) async {
        List<Icrc1TokenTradeContract> icrc1token_trade_contracts = icrc1token_trade_contract != null ? [icrc1token_trade_contract] : this.cm_trade_contracts.keys.toList();
        await Future.wait(
            icrc1token_trade_contracts.map((icrc1token_trade_contract)=>Future(()async{
                
                List<PositionLog> gather_user_current_positions = [];
                int? latest_logs_b_chunk_len = null; 
                
                while (true) {
                    Uint8List logs_b_chunk = await icrc1token_trade_contract.canister.call(
                        method_name: 'view_user_current_positions',
                        calltype: CallType.query,
                        put_bytes: c_forwards_one(
                            Record.of_the_map({
                                'index_key': this.principal,
                                'opt_start_before_id': Option<Nat>(value: gather_user_current_positions.isEmpty ? null : Nat(gather_user_current_positions.first.id), value_type: Nat()),
                            })
                        ),
                    );
                
                    int logs_b_chunk_len = logs_b_chunk.length;
                                            
                    gather_user_current_positions = [
                        ...logs_b_chunk.chunks(PositionLog.STABLE_MEMORY_SERIALIZE_SIZE).map((b)=>PositionLog.oftheStableMemorySerialization(b, token_decimal_places: icrc1token_trade_contract.ledger_data.decimals)),
                        ...gather_user_current_positions
                    ];
                    
                    if ((latest_logs_b_chunk_len != null && logs_b_chunk_len < latest_logs_b_chunk_len) || logs_b_chunk_len == 0) {
                        break;
                    }
                    latest_logs_b_chunk_len = logs_b_chunk_len;
                    
                }
                
                Map gather_user_current_positions_as_map = Map<BigInt, PositionLog>.fromIterable(
                    gather_user_current_positions,
                    key: (pl)=>pl.id,
                    value: (pl)=> pl
                );
                List<BigInt> for_the_do_fresh_these_position_ids_in_the_storage_log = [];        
                for (PositionLog pl in this.cm_trade_contracts[icrc1token_trade_contract]!.current_user_positions_logs) {
                    if (gather_user_current_positions_as_map.containsKey(pl.id) == false) {
                        for_the_do_fresh_these_position_ids_in_the_storage_log.add(pl.id);
                    }
                }
                
                this.cm_trade_contracts[icrc1token_trade_contract]!.current_user_positions_logs = gather_user_current_positions;
                
                
                // storage_logs start with the ones in the buffer 
                
                
                
                BigInt? last_known_storage_log_position_id = this.cm_trade_contracts[icrc1token_trade_contract]!.user_positions_logs_storage.isEmpty ? null : this.cm_trade_contracts[icrc1token_trade_contract]!.user_positions_logs_storage.last.id;
                List<PositionLog> gather_user_positions_log_storage = [];
                latest_logs_b_chunk_len = null; 
                bool catch_up_complete = false;
                while (true) {
                    
                    Uint8List logs_b_chunk = await icrc1token_trade_contract.canister.call(
                        method_name: 'view_user_positions_logs',
                        calltype: CallType.query,
                        put_bytes: c_forwards_one(
                            Record.of_the_map({
                                'index_key': this.principal,
                                'opt_start_before_id': Option<Nat>(value: gather_user_positions_log_storage.isEmpty ? null : Nat(gather_user_positions_log_storage.first.id), value_type: Nat()),
                            })
                        ),
                    );
                    
                    int logs_b_chunk_len = logs_b_chunk.length;
                                            
                    gather_user_positions_log_storage = [
                        ...logs_b_chunk.chunks(PositionLog.STABLE_MEMORY_SERIALIZE_SIZE).map((b)=>PositionLog.oftheStableMemorySerialization(b, token_decimal_places: icrc1token_trade_contract.ledger_data.decimals)),
                        ...gather_user_positions_log_storage
                    ];
                    
                    if ((latest_logs_b_chunk_len != null && logs_b_chunk_len < latest_logs_b_chunk_len!) || logs_b_chunk_len == 0) {
                        break;
                    }
                    latest_logs_b_chunk_len = logs_b_chunk_len;
                    
                    if (last_known_storage_log_position_id != null && gather_user_positions_log_storage.first.id <= last_known_storage_log_position_id!) {
                        gather_user_positions_log_storage = gather_user_positions_log_storage.skipWhile((e)=>e.id <= last_known_storage_log_position_id).toList();
                        catch_up_complete = true;
                        break;
                    } 
                }
                
                
                List<StorageCanister>? scs;
                
                if (catch_up_complete == false) {
                
                    scs = (c_backwards_one(await icrc1token_trade_contract.canister.call(
                        method_name: 'view_positions_storage_canisters',
                        calltype: CallType.query,
                    )) as Vector).cast_vector<Record>().map<StorageCanister>((r) => StorageCanister.of_the_record(r)).toList();
                            
                    for (StorageCanister sc in scs!.reversed) {
                        
                        int chunk_size = 1024 * 512 * 3 ~/ sc.log_size;
                        
                        while (true) {
                            Uint8List logs_b_chunk = await Canister(sc.canister_id).call(
                                calltype: CallType.query, 
                                method_name: sc.view_logs_method_name,
                                put_bytes: c_forwards([
                                    this.principal,
                                    Option<Nat>(value: gather_user_positions_log_storage.isEmpty ? null : Nat(gather_user_positions_log_storage.first.id), value_type: Nat()),
                                    Nat32(chunk_size),
                                ])
                            );
                            int logs_b_chunk_size = logs_b_chunk.length ~/ sc.log_size;
                            
                            gather_user_positions_log_storage  = [
                                ...logs_b_chunk.chunks(sc.log_size).map((b)=>PositionLog.oftheStableMemorySerialization(b, token_decimal_places: icrc1token_trade_contract.ledger_data.decimals)),
                                ...gather_user_positions_log_storage
                            ];
                            
                            if (last_known_storage_log_position_id != null && gather_user_positions_log_storage.first.id <= last_known_storage_log_position_id!) {
                                gather_user_positions_log_storage = gather_user_positions_log_storage.skipWhile((e)=>e.id <= last_known_storage_log_position_id).toList();
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
                
                this.cm_trade_contracts[icrc1token_trade_contract]!.user_positions_logs_storage.addAll(gather_user_positions_log_storage);
        
                
                // for_the_do_fresh_these_position_ids_in_the_storage_log
                
                
                latest_logs_b_chunk_len = null; 
                while (for_the_do_fresh_these_position_ids_in_the_storage_log.isNotEmpty) {
                    Uint8List logs_b_chunk = await icrc1token_trade_contract.canister.call(
                        method_name: 'view_user_positions_logs',
                        calltype: CallType.query,
                        put_bytes: c_forwards_one(
                            Record.of_the_map({
                                'index_key': this.principal,
                                'opt_start_before_id': Option<Nat>(value: Nat(for_the_do_fresh_these_position_ids_in_the_storage_log.last + BigInt.from(1)), value_type: Nat()),
                            })
                        ),
                    );
                        
                    int logs_b_chunk_len = logs_b_chunk.length;
                                                
                    List<PositionLog> positions_chunk = logs_b_chunk.chunks(PositionLog.STABLE_MEMORY_SERIALIZE_SIZE).map((b)=>PositionLog.oftheStableMemorySerialization(b, token_decimal_places: icrc1token_trade_contract.ledger_data.decimals)).toList();
                    Map positions_chunk_map = Map.fromIterable(
                        positions_chunk,
                        key: (e)=>e.id,
                        value: (e)=>e
                    );
                        
                    int i = 0;
                    while (i<for_the_do_fresh_these_position_ids_in_the_storage_log.length) {
                        BigInt plid = for_the_do_fresh_these_position_ids_in_the_storage_log[i];
                        if (positions_chunk_map.containsKey(plid)) {
                            this.cm_trade_contracts[icrc1token_trade_contract]!.user_positions_logs_storage[this.cm_trade_contracts[icrc1token_trade_contract]!.user_positions_logs_storage.indexWhere((l)=> l.id == plid)] = positions_chunk_map[plid];
                            for_the_do_fresh_these_position_ids_in_the_storage_log.removeAt(i);                       
                        } else {
                            i = i + 1;
                        }
                    }
                        
                    if ((latest_logs_b_chunk_len != null && logs_b_chunk_len < latest_logs_b_chunk_len!) || logs_b_chunk_len == 0) {
                        break;
                    }
                    latest_logs_b_chunk_len = logs_b_chunk_len;
                        
                }
                
                if (for_the_do_fresh_these_position_ids_in_the_storage_log.isNotEmpty) {
                    if (scs == null) {
                        scs = (c_backwards_one(await icrc1token_trade_contract.canister.call(
                            method_name: 'view_positions_storage_canisters',
                            calltype: CallType.query,
                        )) as Vector).cast_vector<Record>().map<StorageCanister>((r) => StorageCanister.of_the_record(r)).toList();
                    }
                    for (StorageCanister sc in scs!.reversed) {
                            
                        int chunk_size = 1024 * 512 * 3 ~/ sc.log_size;
                            
                        while (true) {
                            Uint8List logs_b_chunk = await Canister(sc.canister_id).call(
                                calltype: CallType.query, 
                                method_name: sc.view_logs_method_name,
                                put_bytes: c_forwards([
                                    this.principal,
                                    Option<Nat>(value: Nat(for_the_do_fresh_these_position_ids_in_the_storage_log.last + BigInt.from(1)), value_type: Nat()),
                                    Nat32(chunk_size),
                                ])
                            );
                            int logs_b_chunk_size = logs_b_chunk.length ~/ sc.log_size;
                                
                            List<PositionLog> positions_chunk = logs_b_chunk.chunks(PositionLog.STABLE_MEMORY_SERIALIZE_SIZE).map((b)=>PositionLog.oftheStableMemorySerialization(b, token_decimal_places: icrc1token_trade_contract.ledger_data.decimals)).toList();
                            Map positions_chunk_map = Map.fromIterable(
                                positions_chunk,
                                key: (e)=>e.id,
                                value: (e)=>e
                            );
                                
                            int i = 0;
                            while (i<for_the_do_fresh_these_position_ids_in_the_storage_log.length) {
                                BigInt plid = for_the_do_fresh_these_position_ids_in_the_storage_log[i];
                                if (positions_chunk_map.containsKey(plid)) {
                                    this.cm_trade_contracts[icrc1token_trade_contract]!.user_positions_logs_storage[this.cm_trade_contracts[icrc1token_trade_contract]!.user_positions_logs_storage.indexWhere((l)=> l.id == plid)] = positions_chunk_map[plid];
                                    for_the_do_fresh_these_position_ids_in_the_storage_log.removeAt(i);                       
                                } else {
                                    i = i + 1;
                                }
                            }
                                    
                            if (for_the_do_fresh_these_position_ids_in_the_storage_log.isEmpty == true) {
                                break;
                            } 
                                
                            if (logs_b_chunk_size < chunk_size) {
                                break;
                            }
                        }
                            
                        if (for_the_do_fresh_these_position_ids_in_the_storage_log.isEmpty == true) {
                            break;
                        }
                    }
                }  
            }))
        );
           
    }
    
 
    
    
    
    
    
    
    
    
    
    
    
    
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
    Future<void> fresh_cm_trade_contracts_token_balances([Icrc1TokenTradeContract? icrc1token_trade_contract]) async {
        List<Icrc1TokenTradeContract> icrc1token_trade_contracts = icrc1token_trade_contract != null ? [icrc1token_trade_contract] : this.cm_trade_contracts.keys.toList();
        await Future.wait(
            icrc1token_trade_contracts.map((tc)=>Future(()async{                
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
            }))
        );
    }
    
    /*
    // is this backwards? the fresh icp transactions part in the fresh_icrc1ledger_transactions function does prepend? test
    Future<void> fresh_cm_icp_transfers() async {
        throw Unimplemented();
        this.cm_icp_transfers.addAll(
            await get_icp_transfers(
                this.cm_icp_id, 
                already_have: this.cm_icp_transfers.length
            )
        );
    }
    */
    
    
    // use future locks on the load/fresh logs fns like for the cm trade logs
    /*
    Future<void> load_trade_logs() async {
        if (this.load_trade_logs_future != null) {
            await this.load_trade_logs_future!;
        } else {
            this.load_trade_logs_future = create_load_trade_logs_future();
            await this.load_trade_logs_future!;
            this.load_trade_logs_future == null;
        } 
    }
    
    Future<void> create_load_trade_logs_future() async {
     
    */
    /*
    Future<void> fresh_cm_cycles_positions([Icrc1TokenTradeContract? icrc1token_trade_contract]) async {
        List<Icrc1TokenTradeContract> icrc1token_trade_contracts = icrc1token_trade_contract != null ? [icrc1token_trade_contract] : this.cm_trade_contracts.keys.toList();
        await Future.wait(
            icrc1token_trade_contracts.map((tc)=>Future(()async{
                this.cm_trade_contracts[tc]!.logs.cm_cycles_positions.addAll(
                    await cb_download_mechanism(
                        icrc1token_trade_contract: tc,
                        len_so_far: this.cm_trade_contracts[tc]!.logs.cm_cycles_positions.length,
                        download_method_name: 'download_cm_cycles_positions', 
                        function: CMCyclesPosition.of_the_record,
                    )
                );
            }))   
        );
    }             
    
    Future<void> fresh_cm_token_positions([Icrc1TokenTradeContract? icrc1token_trade_contract]) async {
        List<Icrc1TokenTradeContract> icrc1token_trade_contracts = icrc1token_trade_contract != null ? [icrc1token_trade_contract] : this.cm_trade_contracts.keys.toList();
        await Future.wait(
            icrc1token_trade_contracts.map((tc)=>Future(()async{
                this.cm_trade_contracts[tc]!.logs.cm_token_positions.addAll(
                    await cb_download_mechanism(
                        icrc1token_trade_contract: tc,
                        len_so_far: this.cm_trade_contracts[tc]!.logs.cm_token_positions.length,
                        download_method_name: 'download_cm_token_positions', 
                        function: CMTokenPosition.of_the_record,
                    )
                );
            }))   
        );        
    }
    
    Future<void> fresh_cm_cycles_positions_purchases([Icrc1TokenTradeContract? icrc1token_trade_contract]) async {
        List<Icrc1TokenTradeContract> icrc1token_trade_contracts = icrc1token_trade_contract != null ? [icrc1token_trade_contract] : this.cm_trade_contracts.keys.toList();
        await Future.wait(
            icrc1token_trade_contracts.map((tc)=>Future(()async{
                this.cm_trade_contracts[tc]!.logs.cm_cycles_positions_purchases.addAll(
                    await cb_download_mechanism(
                        icrc1token_trade_contract: tc,
                        len_so_far: this.cm_trade_contracts[tc]!.logs.cm_cycles_positions_purchases.length,
                        download_method_name: 'download_cm_cycles_positions_purchases', 
                        function: CMCyclesPositionPurchase.of_the_record,
                    )
                );
            }))   
        );
    }
    
    Future<void> fresh_cm_token_positions_purchases([Icrc1TokenTradeContract? icrc1token_trade_contract]) async {
        List<Icrc1TokenTradeContract> icrc1token_trade_contracts = icrc1token_trade_contract != null ? [icrc1token_trade_contract] : this.cm_trade_contracts.keys.toList();
        await Future.wait(
            icrc1token_trade_contracts.map((tc)=>Future(()async{
                this.cm_trade_contracts[tc]!.logs.cm_token_positions_purchases.addAll(
                    await cb_download_mechanism(
                        icrc1token_trade_contract: tc,
                        len_so_far: this.cm_trade_contracts[tc]!.logs.cm_token_positions_purchases.length,
                        download_method_name: 'download_cm_token_positions_purchases', 
                        function: CMTokenPositionPurchase.of_the_record,
                    )
                );
            }))   
        );
    }
    
    Future<void> fresh_cm_token_transfers_out([Icrc1TokenTradeContract? icrc1token_trade_contract]) async {
        List<Icrc1TokenTradeContract> icrc1token_trade_contracts = icrc1token_trade_contract != null ? [icrc1token_trade_contract] : this.cm_trade_contracts.keys.toList();
        await Future.wait(
            icrc1token_trade_contracts.map((tc)=>Future(()async{
                this.cm_trade_contracts[tc]!.logs.cm_token_transfers_out.addAll(
                    await cb_download_mechanism(
                        icrc1token_trade_contract: tc,
                        len_so_far: this.cm_trade_contracts[tc]!.logs.cm_token_transfers_out.length,
                        download_method_name: 'download_cm_token_transfers_out', 
                        function: CMTokenTransferOut.of_the_record,
                    )
                );
            }))   
        );
    }
    
    
    Future<void> fresh_cm_message_cycles_position_purchase_positor_logs([Icrc1TokenTradeContract? icrc1token_trade_contract]) async {
        List<Icrc1TokenTradeContract> icrc1token_trade_contracts = icrc1token_trade_contract != null ? [icrc1token_trade_contract] : this.cm_trade_contracts.keys.toList();
        await Future.wait(
            icrc1token_trade_contracts.map((tc)=>Future(()async{
                this.cm_trade_contracts[tc]!.logs.cm_message_cycles_position_purchase_positor_logs.addAll(
                    await cb_download_mechanism(
                        icrc1token_trade_contract: tc,
                        len_so_far: this.cm_trade_contracts[tc]!.logs.cm_message_cycles_position_purchase_positor_logs.length,
                        download_method_name: 'download_cm_message_cycles_position_purchase_positor_logs', 
                        function: CMMessageCyclesPositionPurchasePositorLog.of_the_record,
                    )
                );
            }))   
        );
    }
    
    Future<void> fresh_cm_message_cycles_position_purchase_purchaser_logs([Icrc1TokenTradeContract? icrc1token_trade_contract]) async {
        List<Icrc1TokenTradeContract> icrc1token_trade_contracts = icrc1token_trade_contract != null ? [icrc1token_trade_contract] : this.cm_trade_contracts.keys.toList();
        await Future.wait(
            icrc1token_trade_contracts.map((tc)=>Future(()async{
                this.cm_trade_contracts[tc]!.logs.cm_message_cycles_position_purchase_purchaser_logs.addAll(
                    await cb_download_mechanism(
                        icrc1token_trade_contract: tc,
                        len_so_far: this.cm_trade_contracts[tc]!.logs.cm_message_cycles_position_purchase_purchaser_logs.length,
                        download_method_name: 'download_cm_message_cycles_position_purchase_purchaser_logs', 
                        function: CMMessageCyclesPositionPurchasePurchaserLog.of_the_record,
                    )
                );
            }))   
        );
    }
    
    Future<void> fresh_cm_message_token_position_purchase_positor_logs([Icrc1TokenTradeContract? icrc1token_trade_contract]) async {
        List<Icrc1TokenTradeContract> icrc1token_trade_contracts = icrc1token_trade_contract != null ? [icrc1token_trade_contract] : this.cm_trade_contracts.keys.toList();
        await Future.wait(
            icrc1token_trade_contracts.map((tc)=>Future(()async{
                this.cm_trade_contracts[tc]!.logs.cm_message_token_position_purchase_positor_logs.addAll(
                    await cb_download_mechanism(
                        icrc1token_trade_contract: tc,
                        len_so_far: this.cm_trade_contracts[tc]!.logs.cm_message_token_position_purchase_positor_logs.length,
                        download_method_name: 'download_cm_message_token_position_purchase_positor_logs', 
                        function: CMMessageTokenPositionPurchasePositorLog.of_the_record,
                    )
                );
            }))   
        );
    }
    
    Future<void> fresh_cm_message_token_position_purchase_purchaser_logs([Icrc1TokenTradeContract? icrc1token_trade_contract]) async {
        List<Icrc1TokenTradeContract> icrc1token_trade_contracts = icrc1token_trade_contract != null ? [icrc1token_trade_contract] : this.cm_trade_contracts.keys.toList();
        await Future.wait(
            icrc1token_trade_contracts.map((tc)=>Future(()async{
                this.cm_trade_contracts[tc]!.logs.cm_message_token_position_purchase_purchaser_logs.addAll(
                    await cb_download_mechanism(
                        icrc1token_trade_contract: tc,
                        len_so_far: this.cm_trade_contracts[tc]!.logs.cm_message_token_position_purchase_purchaser_logs.length,
                        download_method_name: 'download_cm_message_token_position_purchase_purchaser_logs', 
                        function: CMMessageTokenPositionPurchasePurchaserLog.of_the_record,
                    )
                );
            }))   
        );
    }
    
    Future<void> fresh_cm_message_void_cycles_position_positor_logs([Icrc1TokenTradeContract? icrc1token_trade_contract]) async {
        List<Icrc1TokenTradeContract> icrc1token_trade_contracts = icrc1token_trade_contract != null ? [icrc1token_trade_contract] : this.cm_trade_contracts.keys.toList();
        await Future.wait(
            icrc1token_trade_contracts.map((tc)=>Future(()async{
                this.cm_trade_contracts[tc]!.logs.cm_message_void_cycles_position_positor_logs.addAll(
                    await cb_download_mechanism(
                        icrc1token_trade_contract: tc,
                        len_so_far: this.cm_trade_contracts[tc]!.logs.cm_message_void_cycles_position_positor_logs.length,
                        download_method_name: 'download_cm_message_void_cycles_position_positor_logs', 
                        function: CMMessageVoidCyclesPositionPositorLog.of_the_record,
                    )
                );
            }))   
        );
    }

    Future<void> fresh_cm_message_void_token_position_positor_logs([Icrc1TokenTradeContract? icrc1token_trade_contract]) async {
        List<Icrc1TokenTradeContract> icrc1token_trade_contracts = icrc1token_trade_contract != null ? [icrc1token_trade_contract] : this.cm_trade_contracts.keys.toList();
        await Future.wait(
            icrc1token_trade_contracts.map((tc)=>Future(()async{
                this.cm_trade_contracts[tc]!.logs.cm_message_void_token_position_positor_logs.addAll(
                    await cb_download_mechanism(
                        icrc1token_trade_contract: tc,
                        len_so_far: this.cm_trade_contracts[tc]!.logs.cm_message_void_token_position_positor_logs.length,
                        download_method_name: 'download_cm_message_void_token_position_positor_logs', 
                        function: CMMessageVoidTokenPositionPositorLog.of_the_record,
                    )
                );
            }))   
        );
    }
    */
    Future<void> load_cm_data() async {
        await Future.wait([
            this.fresh_cm_trade_contracts_token_balances(),
            /*
            this.fresh_cm_cycles_positions(),
            this.fresh_cm_token_positions(),
            this.fresh_cm_cycles_positions_purchases(),
            this.fresh_cm_token_positions_purchases(),
            this.fresh_cm_token_transfers_out(),
            this.fresh_cm_message_cycles_position_purchase_positor_logs(),
            this.fresh_cm_message_cycles_position_purchase_purchaser_logs(),
            this.fresh_cm_message_token_position_purchase_positor_logs(),
            this.fresh_cm_message_token_position_purchase_purchaser_logs(),
            this.fresh_cm_message_void_cycles_position_positor_logs(),
            this.fresh_cm_message_void_token_position_positor_logs(),
            */
        ]);
    }

    

    Future<BigInt/*position-id*/> cm_buy_tokens(Icrc1TokenTradeContract icrc1token_trade_contract, MatchTokensQuest q) async {
        throw Exception('unimplemented');
    }

    Future<BigInt/*position-id*/> cm_sell_tokens(Icrc1TokenTradeContract icrc1token_trade_contract, MatchTokensQuest q) async {
        throw Exception('unimplemented');
    }
    
    /*
    Future<CreateCyclesPositionSuccess> cm_create_cycles_position(Icrc1TokenTradeContract icrc1token_trade_contract, CreateCyclesPositionQuest q) async {
        Variant sponse = c_backwards(
            await user.call(
                this,
                method_name: 'cm_create_cycles_position',
                put_bytes: c_forwards([icrc1token_trade_contract, q]),
                calltype: CallType.call
            )
        )[0] as Variant;
        CreateCyclesPositionSuccess create_cycles_position_success = match_variant<CreateCyclesPositionSuccess>(sponse, {
            Ok: (create_cycles_position_success) {
                return CreateCyclesPositionSuccess.of_the_record(create_cycles_position_success as Record);
            },
            Err: (create_cycles_position_error) {
                match_variant<Never>(create_cycles_position_error as Variant, {
                    'CTSFuelTooLow': (nul) {
                        throw Exception('The CTSFuel is too low. Topup the CTSFuel in this cycles-bank.');
                    },
                    'MemoryIsFull': (nul) {
                        throw Exception('The memory is full in the cycles-bank. Grow the memory or free some space.');
                    },
                    'CyclesBalanceTooLow': (r_ctype) {
                        Record r = r_ctype as Record;
                        this.metrics!.cycles_balance = Cycles.oftheNat(r['cycles_balance']!);
                        throw Exception('The cycles-balance is too low in the cycles-bank.\ncycles-balance: ${Cycles.oftheNat(r['cycles_balance']!)}\ncycles-market-create-position-fee: ${Cycles.oftheNat(r['cycles_market_create_position_fee']!)}');
                    },
                    'CyclesMarketCreateCyclesPositionCallError': (call_error_record) {
                        throw Exception('cycles-market create_cycles_position call error:\n${CallError.of_the_record(call_error_record as Record)}');    
                    },
                    'CyclesMarketCreateCyclesPositionError': (cycles_market_create_cycles_position_error) {
                        match_variant<Never>(cycles_market_create_cycles_position_error as Variant, {
                            'MinimumPurchaseMustBeEqualOrLessThanTheCyclesPosition': (nul) {
                                throw Exception('The minimum-purchase of the position must be equal or less than the position.');
                            },
                            'MsgCyclesTooLow': (fee_record) {
                                throw Exception('File this error: \nMsgCyclesTooLow create_position_fee: ${Cycles.oftheNat((fee_record as Record)['create_position_fee']!)}');
                            },
                            'CyclesMarketIsBusy': (nul) {
                                throw Exception('The cycles-market is busy. try soon.');
                            },
                            'CyclesMarketIsFull': (nul) {
                                throw Exception('File this: The cycles-market is full.');
                            },
                            'CyclesMarketIsFull_MinimumRateAndMinimumCyclesPositionForABump': (r_ctype) {
                                Record r = r_ctype as Record;
                                throw Exception('The cycles-market cycles-positions are full. If you create a cycles-position with a minimum cycles-per-token-rate: ${Cycles.oftheNat(r['minimum_rate_for_a_bump'] as Nat)} and with a minimum cycles-position: ${Cycles.oftheNat(r['minimum_cycles_position_for_a_bump']!)} then you will bump the most expensive cycles-position and take its place.');
                            },
                            'MinimumCyclesPosition': (cycles_nat) {
                                throw Exception('The minimum cycles for a cycles-position is: ${Cycles.oftheNat(cycles_nat)}');
                            },
                            'MinimumPurchaseCannotBeZero': (nul) {
                                throw Exception('The position minimum-purchase must greater than 0.');
                            },
                            'CyclesMustBeAMultipleOfTheCyclesPerTokenRate': (nul) {
                                throw Exception('The positon\'s-cycles must be a multiple of the cycles_per_token_rate');
                            },
                            'MinimumPurchaseMustBeAMultipleOfTheCyclesPerTokenRate': (nul) {
                                throw Exception('The positon\'s-minimum-purchase must be a multiple of the cycles_per_token_rate');
                            },
                        });
                    }
                });           
            }
        });   
        await this.fresh_cm_cycles_positions(icrc1token_trade_contract);
        return create_cycles_position_success;
    }
    
    Future<CreateTokenPositionSuccess> cm_create_token_position(Icrc1TokenTradeContract icrc1token_trade_contract, CreateTokenPositionQuest q) async {
        Variant sponse = c_backwards(
            await user.call(
                this,
                method_name: 'cm_create_token_position',
                calltype: CallType.call,
                put_bytes: c_forwards([icrc1token_trade_contract, q])
            )
        )[0] as Variant;
        CreateTokenPositionSuccess create_token_position_success = match_variant<CreateTokenPositionSuccess>(sponse, {
            Ok: (ok_record) {
                return CreateTokenPositionSuccess.of_the_record(ok_record as Record);
            },
            Err: (user_cm_create_token_position_error) {
                return match_variant<Never>(user_cm_create_token_position_error as Variant, {
                    'CTSFuelTooLow': (nul) {
                        throw Exception('The CTSFuel is too low. Topup the CTSFuel in this cycles-bank.');
                    },
                    'MemoryIsFull': (nul) {
                        throw Exception('The memory is full in the cycles-bank. Grow the memory or free some space.');
                    },
                    'CyclesBalanceTooLow': (r_ctype) {
                        Record r = r_ctype as Record;
                        this.metrics!.cycles_balance = Cycles.oftheNat(r['cycles_balance']!);
                        throw Exception('The cycles-balance is too low in the cycles-bank.\ncycles-balance: ${Cycles.oftheNat(r['cycles_balance']!)}\ncycles-market-create-position-fee: ${Cycles.oftheNat(r['cycles_market_create_position_fee']!)}');
                    },
                    'CyclesMarketCreateTokenPositionCallError': (call_error_record) {
                        throw Exception('cycles-market create_icp_position call error:\n${CallError.of_the_record(call_error_record as Record)}');    
                    },
                    'CyclesMarketCreateTokenPositionCallSponseCandidDecodeError': (r_ctype) {
                        Record r = r_ctype as Record;
                        throw Exception('Error decoding cycles-market create_token_position response:\ncandid_error: ${(r['candid_error'] as Text).value}\nsponse_bytes: ${(r['sponse_bytes'] as Blob).bytes}');
                    },
                    'CyclesMarketCreateTokenPositionError': (cycles_market_create_token_position_error) {
                        return match_variant<Never>(cycles_market_create_token_position_error as Variant, {
                            'MinimumPurchaseMustBeEqualOrLessThanTheTokenPosition': (nul) {
                                throw Exception('The minimum-purchase of the position must be equal or less than the position.');
                            },
                            'MsgCyclesTooLow': (fee_record) {
                                throw Exception('File this error: \nMsgCyclesTooLow create_position_fee: ${Cycles.oftheNat((fee_record as Record)['create_position_fee']!)}');
                            },
                            'CyclesMarketIsFull': (nul) {
                                throw Exception('File this: The cycles-market is full.');
                            },
                            'CyclesMarketIsBusy': (nul) {
                                throw Exception('The cycles-market is busy. try soon.');
                            },
                            'CallerIsInTheMiddleOfACreateTokenPositionOrPurchaseCyclesPositionOrTransferTokenBalanceCall': (nul) {
                                throw Exception('The cycles-bank is in the middle of a call for the cycles-market.');    
                            },
                            'CheckUserCyclesMarketTokenLedgerBalanceError':(call_error_record) {
                                throw Exception('Error calling the token-ledger for the cycles-market-token-balance.\n${CallError.of_the_record(call_error_record as Record)}');
                            },
                            'UserTokenBalanceTooLow': (user_token_balance_record) {
                                this.cm_trade_contracts[icrc1token_trade_contract]!.trade_contract_token_balance = ((user_token_balance_record as Record)['user_token_balance'] as Nat).value;
                                throw Exception('The cycles-market-token-balance is too low. The token-balance must be enough to cover the token-position (${q.tokens}) plus the token-ledger-transfer-fees for each possible purchase according to the minimum-purchase (${Tokens(quantums: (q.tokens ~/ q.minimum_purchase) * icrc1token_trade_contract.ledger_data.fee, decimal_places: icrc1token_trade_contract.ledger_data.decimals)}). \ncurrent-token-balance: ${Tokens(quantums: this.cm_trade_contracts[icrc1token_trade_contract]!.trade_contract_token_balance, decimal_places: icrc1token_trade_contract.ledger_data.decimals)}');
                            },
                            'CyclesMarketIsFull_MaximumRateAndMinimumTokenPositionForABump': (r_ctype) {
                                Record r = r_ctype as Record;
                                throw Exception('The cycles-market token-positions are full. If you create a token-position with a maximum cycles-per-token-rate: ${Cycles.oftheNat(r['maximum_rate_for_a_bump'] as Nat)} and with a minimum token-position: ${Tokens.of_the_nat(r['minimum_token_position_for_a_bump'] as Nat, decimal_places: icrc1token_trade_contract.ledger_data.decimals)} then you will bump the most expensive token-position and take its place.');
                            },
                            'MinimumTokenPosition': (tokens) {
                                throw Exception('The minimum tokens for a token-position is: ${Tokens.of_the_nat(tokens, decimal_places: icrc1token_trade_contract.ledger_data.decimals)}');
                            },
                            'MinimumPurchaseCannotBeZero': (nul) {
                                throw Exception('The position minimum-purchase must greater than 0.');
                            },
                        });
                    }
                });
            }
        });        
        await this.fresh_cm_token_positions(icrc1token_trade_contract);
        return create_token_position_success;    
    }
    
    
    Future<PurchaseCyclesPositionSuccess> cm_purchase_cycles_position(Icrc1TokenTradeContract icrc1token_trade_contract, CyclesPosition cycles_position, Cycles purchase_cycles) async {
        Variant sponse = c_backwards(
            await user.call(
                this,
                method_name: 'cm_purchase_cycles_position',
                calltype: CallType.call,
                put_bytes: c_forwards([
                    icrc1token_trade_contract,
                    CyclesBankCMPurchaseCyclesPositionQuest(
                        cycles_market_purchase_cycles_position_quest: CyclesMarketPurchaseCyclesPositionQuest(
                            cycles_position_id: cycles_position.id,
                            cycles: purchase_cycles,
                        ),
                        cycles_position_cycles_per_token_rate: cycles_position.cycles_per_token_rate,
                        cycles_position_positor: cycles_position.positor
                    )
                ])
            )
        ).first as Variant;
        PurchaseCyclesPositionSuccess purchase_cycles_position_success = match_variant<PurchaseCyclesPositionSuccess>(sponse, {
            Ok: (ok) {
                return PurchaseCyclesPositionSuccess.of_the_record(ok as Record);
            }, 
            Err: (purchase_cycles_position_error) {
                return match_variant<Never>(purchase_cycles_position_error as Variant, {
                    'CTSFuelTooLow': (nul) {
                        throw Exception('The CTSFuel is too low. Topup the CTSFuel in this cycles-bank.');
                    },
                    'MemoryIsFull': (nul) {
                        throw Exception('The memory is full in the cycles-bank. Grow the memory or free some space.');
                    },
                    'CyclesBalanceTooLow': (r_ctype) {
                        Record r = r_ctype as Record;
                        this.metrics!.cycles_balance = Cycles.oftheNat(r['cycles_balance']!);
                        throw Exception('The cycles-balance is too low in the cycles-bank.\ncycles-balance: ${Cycles.oftheNat(r['cycles_balance']!)}\ncycles-market-purchase-position-fee: ${Cycles.oftheNat(r['cycles_market_purchase_position_fee']!)}');
                    },
                    'CyclesMarketPurchaseCyclesPositionCallError': (call_error_record) {
                        throw Exception('cycles-market purchase_cycles_position call error:\n${CallError.of_the_record(call_error_record as Record)}');                    
                    },
                    'CyclesMarketPurchaseCyclesPositionCallSponseCandidDecodeError': (r_ctype) {
                        Record r = r_ctype as Record;
                        throw Exception('Error decoding cycles-market purchase_cycles_position response:\ncandid_error: ${(r['candid_error'] as Text).value}\nsponse_bytes: ${(r['sponse_bytes'] as Blob).bytes}');
                    },
                    'CyclesMarketPurchaseCyclesPositionError': (cycles_market_purchase_cycles_position_error) {
                        return match_variant<Never>(cycles_market_purchase_cycles_position_error as Variant, {
                            'MsgCyclesTooLow': (fee_record) {
                                throw Exception('File this error: \nMsgCyclesTooLow purchase_position_fee: ${Cycles.oftheNat((fee_record as Record)['purchase_position_fee']!)}');
                            },
                            'CyclesMarketIsBusy': (nul) {
                                throw Exception('The cycles-market is busy. try soon.');
                            },
                            'CallerIsInTheMiddleOfACreateTokenPositionOrPurchaseCyclesPositionOrTransferTokenBalanceCall': (nul) {
                                throw Exception('The cycles-bank is in the middle of a call for the cycles-market.');    
                            },
                            'CheckUserCyclesMarketTokenLedgerBalanceError': (call_error_record) {
                                throw Exception('Error calling the ${icrc1token_trade_contract.ledger_data.symbol}-ledger for the cycles-market-token-balance.\n${CallError.of_the_record(call_error_record as Record)}');
                            },
                            'UserTokenBalanceTooLow': (user_token_balance_record) {
                                this.cm_trade_contracts[icrc1token_trade_contract]!.trade_contract_token_balance = ((user_token_balance_record as Record)['user_token_balance'] as Nat).value;
                                Tokens cycles_position_purchase_cycles_token_cost = Tokens(
                                    quantums: cycles_transform_tokens(purchase_cycles, cycles_position.cycles_per_token_rate),
                                    decimal_places: icrc1token_trade_contract.ledger_data.decimals
                                ); 
                                throw Exception('The user\'s-cycles-market-${icrc1token_trade_contract.ledger_data.symbol}-balance is too low for the purchase. \ncycles-market-${icrc1token_trade_contract.ledger_data.symbol}-balance: ${Tokens(quantums: this.cm_trade_contracts[icrc1token_trade_contract]!.trade_contract_token_balance, decimal_places: icrc1token_trade_contract.ledger_data.decimals)}\npurchase_cycles: ${purchase_cycles}\n${icrc1token_trade_contract.ledger_data.symbol}-cost of these cycles in this cycles-position: ${cycles_position_purchase_cycles_token_cost}, ${icrc1token_trade_contract.ledger_data.symbol}-ledger-transfer-fee: ${icrc1token_trade_contract.ledger_data.fee_tokens}');
                            },
                            'CyclesPositionNotFound':(nul) {
                                throw Exception('The cycles-position: ${cycles_position.id} is not found.');
                            },
                            'CyclesPositionCyclesIsLessThanThePurchaseQuest': (cycles_position_cycles_record) {
                                // update the cycles-position-cycles
                                throw Exception('The cycles-position: ${cycles_position.id} has ${Cycles.oftheNat((cycles_position_cycles_record as Record)['cycles_position_cycles']! as Nat)}-cycles.');
                            },
                            'CyclesPositionMinimumPurchaseIsGreaterThanThePurchaseQuest': (cycles_position_minimum_purchase_record) {
                                throw Exception('File this error: CyclesPositionMinimumPurchaseIsGreaterThanThePurchaseQuest\nThe minimum-purchase of this cycles-position is ${Cycles.oftheNat((cycles_position_minimum_purchase_record as Record)['cycles_position_minimum_purchase']!)}');
                            },
                            'PurchaseCyclesMustBeAMultipleOfTheCyclesPerTokenRate': (nul) {
                                throw Exception('The purchase-cycles must be a multiple of the cycles_per_token_rate');
                            }
                        });
                    }
                });
            }
        });
        await this.fresh_cm_cycles_positions_purchases(icrc1token_trade_contract);
        return purchase_cycles_position_success;
    }
    
    Future<PurchaseTokenPositionSuccess> cm_purchase_token_position(Icrc1TokenTradeContract icrc1token_trade_contract, TokenPosition token_position, Tokens purchase_tokens) async {
        Variant sponse = c_backwards(
            await user.call(
                this,
                method_name: 'cm_purchase_token_position',
                calltype: CallType.call,
                put_bytes: c_forwards([
                    icrc1token_trade_contract,
                    CyclesBankCMPurchaseTokenPositionQuest(
                        cycles_market_purchase_token_position_quest: CyclesMarketPurchaseTokenPositionQuest(
                            token_position_id: token_position.id, 
                            tokens: purchase_tokens
                        ),
                        token_position_cycles_per_token_rate: token_position.cycles_per_token_rate,
                        token_position_positor: token_position.positor
                    )
                ])
            )
        ).first as Variant;
        PurchaseTokenPositionSuccess purchase_token_position_success = match_variant<PurchaseTokenPositionSuccess>(sponse, {
            Ok:(ok){
                return PurchaseTokenPositionSuccess.of_the_record(ok as Record);
            },
            Err: (cycles_bank_cm_purchase_token_position_error){
                return match_variant<Never>(cycles_bank_cm_purchase_token_position_error as Variant, {
                    'CTSFuelTooLow': (nul) {
                        throw Exception('The CTSFuel is too low. Topup the CTSFuel in this cycles-bank.');
                    },
                    'MemoryIsFull': (nul) {
                        throw Exception('The memory is full in the cycles-bank. Grow the memory or free some space.');
                    },
                    'CyclesBalanceTooLow': (r_ctype) {
                        Record r = r_ctype as Record;
                        this.metrics!.cycles_balance = Cycles.oftheNat(r['cycles_balance']!);
                        throw Exception('The cycles-balance is too low in the cycles-bank.\ncycles-balance: ${Cycles.oftheNat(r['cycles_balance']!)}\ncycles-market-purchase-position-fee: ${Cycles.oftheNat(r['cycles_market_purchase_position_fee']!)}\ncost for a purchase of the ${purchase_tokens}-${icrc1token_trade_contract.ledger_data.symbol} of the token-position: ${token_position.id} with the cycles_per_token-rate: ${token_position.cycles_per_token_rate} is: ${tokens_transform_cycles(purchase_tokens.quantums, token_position.cycles_per_token_rate)}');
                    },
                    'CyclesMarketPurchaseTokenPositionCallError': (call_error_record) {
                        throw Exception('cycles-market purchase_token_position call error:\n${CallError.of_the_record(call_error_record as Record)}');                    
                    },
                    'CyclesMarketPurchaseTokenPositionCallSponseCandidDecodeError': (r_ctype) {
                        Record r = r_ctype as Record;
                        throw Exception('Error decoding cycles-market purchase_token_position response:\ncandid_error: ${(r['candid_error'] as Text).value}\nsponse_bytes: ${(r['sponse_bytes'] as Blob).bytes}');
                    },
                    'CyclesMarketPurchaseTokenPositionError': (cycles_market_purchase_token_position_error) {
                        return match_variant<Never>(cycles_market_purchase_token_position_error as Variant, {
                            'MsgCyclesTooLow': (fee_record) {
                                throw Exception('File this error: \nMsgCyclesTooLow purchase_position_fee: ${Cycles.oftheNat((fee_record as Record)['purchase_position_fee']!)}');
                            },
                            'CyclesMarketIsBusy': (nul) {
                                throw Exception('The cycles-market is busy. try soon.');
                            },
                            'TokenPositionNotFound': (nul) {
                                throw Exception('The token-position: ${token_position.id} is not found.');
                            },
                            'TokenPositionTokensIsLessThanThePurchaseQuest': (token_position_tokens_record) {
                                throw Exception('This token-position: ${token_position.id} has ${Tokens.of_the_nat((token_position_tokens_record as Record)['token_position_tokens'] as Nat, decimal_places: icrc1token_trade_contract.ledger_data.decimals)}-tokens.');
                            },
                            'TokenPositionMinimumPurchaseIsGreaterThanThePurchaseQuest':(token_position_minimum_purchase_record){
                                throw Exception('File this error: TokenPositionMinimumPurchaseIsGreaterThanThePurchaseQuest\nThe minimum-purchase of this token-position is ${Tokens.of_the_nat((token_position_minimum_purchase_record as Record)['token_position_minimum_purchase'] as Nat, decimal_places: icrc1token_trade_contract.ledger_data.decimals)}');
                            }
                        });
                    }
                });
            }
        });
        await this.fresh_cm_token_positions_purchases(icrc1token_trade_contract);
        return purchase_token_position_success;
    }
    */
    
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
                                throw Exception('Minimum wait time to void a position is ${(r['minimum_wait_time_seconds'] as Nat).value.toInt() / 60 / 60}-hour(s). This position can void in ${( ( ( (r['position_creation_timestamp_seconds'] as Nat).value + (r['minimum_wait_time_seconds'] as Nat).value ) - get_current_time_seconds() ) / BigInt.from(60) ).toStringAsFixed(3)}-minutes.');
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
                            'MsgCyclesTooLow': (r){
                                throw Exception('File this error: MsgCyclesTooLow \n${r}');
                            },
                            'CyclesMarketIsBusy': (nul) {
                                throw Exception('The cycles-market is busy. try soon.');
                            },
                            'CallerIsInTheMiddleOfACreateTokenPositionOrPurchaseCyclesPositionOrTransferTokenBalanceCall': (nul){
                                throw Exception('The cycles-bank is in the middle of a call for the cycles-market.');
                            },
                            'CheckUserCyclesMarketTokenLedgerBalanceCallError': (call_error_record) {
                                throw Exception('${icrc1token_trade_contract.ledger_data.symbol}-ledger token-balance call error: \n${CallError.of_the_record(call_error_record as Record)}');
                            },
                            'UserTokenBalanceTooLow': (user_token_balance_record) {
                                this.cm_trade_contracts[icrc1token_trade_contract]!.trade_contract_token_balance = ((user_token_balance_record as Record)['user_token_balance'] as Nat).value;
                                throw Exception('The cycles-market-${icrc1token_trade_contract.ledger_data.symbol}-balance is too low for this transfer.\n${icrc1token_trade_contract.ledger_data.symbol}-balance: ${Tokens(quantums: this.cm_trade_contracts[icrc1token_trade_contract]!.trade_contract_token_balance, decimal_places: icrc1token_trade_contract.ledger_data.decimals)}');
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
    
    
    



}


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
    Vector<Principal> cycles_transferrer_canisters;
    Principal user_id;
    BigInt user_canister_creation_timestamp_nanos;
    BigInt storage_usage;
    BigInt cycles_transfers_id_counter;
    BigInt cycles_transfers_in_len;
    BigInt cycles_transfers_out_len;
    Map<Principal/*icrc1tokentradecontractcanisterid*/, CMTradeContractLogsLengths> cm_trade_contracts_logs_lengths;
    
    CyclesBankMetrics._({
        required this.global_allocator_counter,
        required this.cycles_balance,
        required this.ctsfuel_balance,
        required this.storage_size_mib,
        required this.lifetime_termination_timestamp_seconds,
        required this.cycles_transferrer_canisters,
        required this.user_id,
        required this.user_canister_creation_timestamp_nanos,
        required this.storage_usage,
        required this.cycles_transfers_id_counter,
        required this.cycles_transfers_in_len,
        required this.cycles_transfers_out_len,
        required this.cm_trade_contracts_logs_lengths,
    });
    static CyclesBankMetrics of_the_record(Record r) {
        return CyclesBankMetrics._(
            global_allocator_counter: (r['global_allocator_counter'] as Nat64).value,
            cycles_balance: Cycles.oftheNat(r['cycles_balance'] as Nat),
            ctsfuel_balance: CTSFuel.oftheNat(r['ctsfuel_balance'] as Nat),
            storage_size_mib: (r['storage_size_mib'] as Nat).value,
            lifetime_termination_timestamp_seconds: (r['lifetime_termination_timestamp_seconds'] as Nat).value,
            cycles_transferrer_canisters: ((r['cycles_transferrer_canisters'] as Vector).cast_vector<Principal>()), 
            user_id: (r['user_id'] as Principal),
            user_canister_creation_timestamp_nanos: (r['user_canister_creation_timestamp_nanos'] as Nat).value,
            storage_usage: (r['storage_usage'] as Nat).value,
            cycles_transfers_id_counter: (r['cycles_transfers_id_counter'] as Nat).value,
            cycles_transfers_in_len: (r['cycles_transfers_in_len'] as Nat).value,
            cycles_transfers_out_len: (r['cycles_transfers_out_len'] as Nat).value,
            cm_trade_contracts_logs_lengths: { 
                for (Record c in (r['cm_trade_contracts_logs_lengths'] as Vector).cast_vector<Record>()) 
                    (c[0] as Record)['trade_contract_canister_id'] as Principal: CMTradeContractLogsLengths.of_the_record(c)
            },
        );
    }
}



class CMTradeContractLogsLengths {
    CMCallsOutLengths cm_calls_out_lengths;
    CMMessageLogsLengths cm_message_logs_lengths;
    CMTradeContractLogsLengths._({
        required this.cm_calls_out_lengths,
        required this.cm_message_logs_lengths,
    });
    static CMTradeContractLogsLengths of_the_record(Record r) {
        return CMTradeContractLogsLengths._(
            cm_calls_out_lengths: CMCallsOutLengths.of_the_record(r['cm_calls_out_lengths'] as Record),
            cm_message_logs_lengths: CMMessageLogsLengths.of_the_record(r['cm_message_logs_lengths'] as Record),    
        );
    }
}

class CMCallsOutLengths {
    BigInt cm_cycles_positions_length;
    BigInt cm_token_positions_length;
    BigInt cm_cycles_positions_purchases_length;
    BigInt cm_token_positions_purchases_length;    
    BigInt cm_token_transfers_out_length;
    CMCallsOutLengths._({
        required this.cm_cycles_positions_length,
        required this.cm_token_positions_length,
        required this.cm_cycles_positions_purchases_length,
        required this.cm_token_positions_purchases_length,   
        required this.cm_token_transfers_out_length,
    });
    static CMCallsOutLengths of_the_record(Record r) {
        return CMCallsOutLengths._(
            cm_cycles_positions_length: (r['cm_cycles_positions_length'] as Nat64).value,
            cm_token_positions_length: (r['cm_token_positions_length'] as Nat64).value,
            cm_cycles_positions_purchases_length: (r['cm_cycles_positions_purchases_length'] as Nat64).value,
            cm_token_positions_purchases_length: (r['cm_token_positions_purchases_length'] as Nat64).value,   
            cm_token_transfers_out_length: (r['cm_token_transfers_out_length'] as Nat64).value,
        );
    }
}

class CMMessageLogsLengths {
    BigInt cm_message_cycles_position_purchase_positor_logs_length;
    BigInt cm_message_cycles_position_purchase_purchaser_logs_length;
    BigInt cm_message_token_position_purchase_positor_logs_length;
    BigInt cm_message_token_position_purchase_purchaser_logs_length;
    BigInt cm_message_void_cycles_position_positor_logs_length;
    BigInt cm_message_void_token_position_positor_logs_length;
    CMMessageLogsLengths._({
        required this.cm_message_cycles_position_purchase_positor_logs_length,
        required this.cm_message_cycles_position_purchase_purchaser_logs_length,
        required this.cm_message_token_position_purchase_positor_logs_length,
        required this.cm_message_token_position_purchase_purchaser_logs_length,
        required this.cm_message_void_cycles_position_positor_logs_length,
        required this.cm_message_void_token_position_positor_logs_length,
    });    
    static CMMessageLogsLengths of_the_record(Record r) {
        return CMMessageLogsLengths._(
            cm_message_cycles_position_purchase_positor_logs_length: (r['cm_message_cycles_position_purchase_positor_logs_length'] as Nat64).value,
            cm_message_cycles_position_purchase_purchaser_logs_length: (r['cm_message_cycles_position_purchase_purchaser_logs_length'] as Nat64).value,
            cm_message_token_position_purchase_positor_logs_length: (r['cm_message_token_position_purchase_positor_logs_length'] as Nat64).value,
            cm_message_token_position_purchase_purchaser_logs_length: (r['cm_message_token_position_purchase_purchaser_logs_length'] as Nat64).value,
            cm_message_void_cycles_position_positor_logs_length: (r['cm_message_void_cycles_position_positor_logs_length'] as Nat64).value,
            cm_message_void_token_position_positor_logs_length: (r['cm_message_void_token_position_positor_logs_length'] as Nat64).value,
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
    final Cycles fee_paid; // cycles_transferrer_fee

    CyclesTransferOut._({
        required this.id,    
        required this.for_the_canister,    
        required this.cycles_sent,    
        required this.cycles_refunded,    
        required this.cycles_transfer_memo,    
        required this.timestamp_nanos,    
        required this.opt_cycles_transfer_call_error,    
        required this.fee_paid
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
            fee_paid: Cycles.oftheNat(Nat((r['fee_paid'] as Nat64).value))
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



/*
    
class LengthenLifetimeQuest extends Record {
    final BigInt set_lifetime_termination_timestamp_seconds;
    LengthenLifetimeQuest({required this.set_lifetime_termination_timestamp_seconds}) {
        this['set_lifetime_termination_timestamp_seconds'] = Nat(this.set_lifetime_termination_timestamp_seconds);
    }
}



class ChangeStorageSizeQuest extends Record {
    final BigInt new_storage_size_mib;
    ChangeStorageSizeQuest({required this.new_storage_size_mib}) {
        this['new_storage_size_mib'] = Nat(this.new_storage_size_mib);
    }
}

*/





// ------------- CYCLES-MARKET -------------


/*
class MatchTokensQuest extends Record {
    final Tokens tokens;
    final CyclesPerTokenRate cycles_per_token_rate;
    MatchTokensQuest({
        required this.tokens,
        required this.cycles_per_token_rate
    }) {
        this['tokens'] = tokens;
        this['cycles_per_token_rate'] = cycles_per_token_rate;
    }
}
*/




/*
// ------------- cm create/purchase position quests and sponses -------------


class CreateCyclesPositionQuest extends Record {
    final Cycles cycles;
    final Cycles minimum_purchase;
    final Cycles cycles_per_token_rate;
    CreateCyclesPositionQuest({
        required this.cycles,
        required this.minimum_purchase,
        required this.cycles_per_token_rate
    }) {
        this['cycles']= this.cycles;
        this['minimum_purchase']= this.minimum_purchase;
        this['cycles_per_token_rate']= this.cycles_per_token_rate;
    }
    static CreateCyclesPositionQuest of_the_record(Record r) {
        return CreateCyclesPositionQuest(
            cycles: Cycles.oftheNat(r['cycles'] as Nat),
            minimum_purchase: Cycles.oftheNat(r['minimum_purchase'] as Nat),
            cycles_per_token_rate: Cycles.oftheNat(r['cycles_per_token_rate'] as Nat),
        );
        
    }

}


class CreateCyclesPositionSuccess {
    final BigInt position_id;
    CreateCyclesPositionSuccess({
        required this.position_id
    });
    static CreateCyclesPositionSuccess of_the_record(Record r) {
        return CreateCyclesPositionSuccess(
            position_id: (r['position_id'] as Nat).value
        );
    }
}



class CreateTokenPositionQuest extends Record {
    final BigInt tokens;
    final BigInt minimum_purchase;
    final Cycles cycles_per_token_rate;
    CreateTokenPositionQuest({
        required this.tokens,
        required this.minimum_purchase,
        required this.cycles_per_token_rate
    }) {
        this['tokens']= Nat(this.tokens);
        this['minimum_purchase']= Nat(this.minimum_purchase);
        this['cycles_per_token_rate']= this.cycles_per_token_rate;
    }
    static CreateTokenPositionQuest of_the_record(Record r) {
        return CreateTokenPositionQuest(
            tokens: (r['tokens'] as Nat).value,
            minimum_purchase: (r['minimum_purchase'] as Nat).value,
            cycles_per_token_rate: Cycles.oftheNat(r['cycles_per_token_rate'] as Nat),
        );
    }
}


class CreateTokenPositionSuccess {
    final BigInt position_id;
    CreateTokenPositionSuccess({
        required this.position_id
    });
    static CreateTokenPositionSuccess of_the_record(Record r) {
        return CreateTokenPositionSuccess(
            position_id: (r['position_id'] as Nat).value
        );
    }
}


class CyclesBankCMPurchaseCyclesPositionQuest extends Record {
    final CyclesMarketPurchaseCyclesPositionQuest cycles_market_purchase_cycles_position_quest;
    final Cycles cycles_position_cycles_per_token_rate;                                              // for the cycles-bank-log
    final Principal cycles_position_positor;
    CyclesBankCMPurchaseCyclesPositionQuest({
        required this.cycles_market_purchase_cycles_position_quest,
        required this.cycles_position_cycles_per_token_rate,
        required this.cycles_position_positor,
    }) {
        this['cycles_market_purchase_cycles_position_quest'] = this.cycles_market_purchase_cycles_position_quest;
        this['cycles_position_cycles_per_token_rate'] = this.cycles_position_cycles_per_token_rate;
        this['cycles_position_positor'] = this.cycles_position_positor;
    }
}

class CyclesMarketPurchaseCyclesPositionQuest extends Record {
    final BigInt cycles_position_id;
    final Cycles cycles;
    CyclesMarketPurchaseCyclesPositionQuest({
        required this.cycles_position_id,
        required this.cycles,
    }) {
        this['cycles_position_id'] = Nat(this.cycles_position_id);
        this['cycles'] = this.cycles;
    }
}


class PurchaseCyclesPositionSuccess {
    final BigInt purchase_id;
    PurchaseCyclesPositionSuccess._({
        required this.purchase_id
    });
    static PurchaseCyclesPositionSuccess of_the_record(Record r) {
        return PurchaseCyclesPositionSuccess._(
            purchase_id: (r['purchase_id'] as Nat).value
        );
    }
}



class CyclesBankCMPurchaseTokenPositionQuest extends Record {
    final CyclesMarketPurchaseTokenPositionQuest cycles_market_purchase_token_position_quest;
    final Cycles token_position_cycles_per_token_rate;
    final Principal token_position_positor;
    CyclesBankCMPurchaseTokenPositionQuest({
        required this.cycles_market_purchase_token_position_quest,
        required this.token_position_cycles_per_token_rate,
        required this.token_position_positor,
    }) {
        this['cycles_market_purchase_token_position_quest'] = this.cycles_market_purchase_token_position_quest;
        this['token_position_cycles_per_token_rate'] = this.token_position_cycles_per_token_rate;
        this['token_position_positor'] = this.token_position_positor;
    }
}

class CyclesMarketPurchaseTokenPositionQuest extends Record {
    final BigInt token_position_id;
    final Tokens tokens;
    CyclesMarketPurchaseTokenPositionQuest({
        required this.token_position_id,
        required this.tokens
    }) {
        this['token_position_id'] = Nat(this.token_position_id);
        this['tokens'] = this.tokens;
    }
}



class PurchaseTokenPositionSuccess {
    final BigInt purchase_id;
    PurchaseTokenPositionSuccess._({
        required this.purchase_id
    });
    static PurchaseTokenPositionSuccess of_the_record(Record r) {
        return PurchaseTokenPositionSuccess._(
            purchase_id: (r['purchase_id'] as Nat).value
        );
    }
}
*/


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



// ----------------- 
/*

class CMCyclesPosition {
    final BigInt id;
    final CreateCyclesPositionQuest create_cycles_position_quest;   
    final Cycles create_position_fee;
    final BigInt timestamp_nanos; 
    
    CMCyclesPosition._({
        required this.id,   
        required this.create_cycles_position_quest,
        required this.create_position_fee,
        required this.timestamp_nanos, 
    });
    
    static CMCyclesPosition of_the_record(Record r) {
        return CMCyclesPosition._(
            id: (r['id'] as Nat).value,
            create_cycles_position_quest: CreateCyclesPositionQuest.of_the_record(r['create_cycles_position_quest'] as Record),
            create_position_fee: Cycles(cycles: (r['create_position_fee'] as Nat64).value),
            timestamp_nanos: (r['timestamp_nanos'] as Nat).value,
        );
    }
}


class CMTokenPosition {
    final BigInt id;   
    final CreateTokenPositionQuest create_token_position_quest;
    final Cycles create_position_fee;
    final BigInt timestamp_nanos;

    CMTokenPosition._({
        required this.id,   
        required this.create_token_position_quest,
        required this.create_position_fee,
        required this.timestamp_nanos
    });
    
    static CMTokenPosition of_the_record(Record r) {
        return CMTokenPosition._(
            id: (r['id'] as Nat).value,   
            create_token_position_quest: CreateTokenPositionQuest.of_the_record(r['create_token_position_quest'] as Record),
            create_position_fee: Cycles(cycles: (r['create_position_fee'] as Nat64).value),
            timestamp_nanos: (r['timestamp_nanos'] as Nat).value
        );
    }

}


class CMCyclesPositionPurchase {
    final BigInt cycles_position_id;
    final Cycles cycles_position_cycles_per_token_rate;
    final Principal cycles_position_positor;
    final BigInt id;
    final Cycles cycles;
    final Cycles purchase_position_fee;
    final BigInt timestamp_nanos;
    
    CMCyclesPositionPurchase._({
        required this.cycles_position_id,
        required this.cycles_position_cycles_per_token_rate,
        required this.cycles_position_positor,
        required this.id,
        required this.cycles,
        required this.purchase_position_fee,
        required this.timestamp_nanos,
    }); 
    
    static CMCyclesPositionPurchase of_the_record(Record r) {
        return CMCyclesPositionPurchase._(
            cycles_position_id: (r['cycles_position_id'] as Nat).value,
            cycles_position_cycles_per_token_rate: Cycles.oftheNat(r['cycles_position_cycles_per_token_rate'] as Nat),
            cycles_position_positor: r['cycles_position_positor'] as Principal,
            id: (r['id'] as Nat).value,
            cycles: Cycles.oftheNat(r['cycles'] as Nat),
            purchase_position_fee: Cycles(cycles: (r['purchase_position_fee'] as Nat64).value),
            timestamp_nanos: (r['timestamp_nanos'] as Nat).value,        
        );
    } 
}

class CMTokenPositionPurchase{
    final BigInt token_position_id;
    final Cycles token_position_cycles_per_token_rate;
    final Principal token_position_positor;
    final BigInt id;
    final BigInt tokens;
    final Cycles purchase_position_fee;
    final BigInt timestamp_nanos;
    
    CMTokenPositionPurchase._({
        required this.token_position_id,
        required this.token_position_cycles_per_token_rate,
        required this.token_position_positor,
        required this.id,
        required this.tokens,
        required this.purchase_position_fee,
        required this.timestamp_nanos,
    });
    
    static CMTokenPositionPurchase of_the_record(Record r) {
        return CMTokenPositionPurchase._(
            token_position_id: (r['token_position_id'] as Nat).value,
            token_position_cycles_per_token_rate: Cycles.oftheNat(r['token_position_cycles_per_token_rate'] as Nat),
            token_position_positor: r['token_position_positor'] as Principal,
            id: (r['id'] as Nat).value,
            tokens: (r['tokens'] as Nat).value,
            purchase_position_fee: Cycles(cycles: (r['purchase_position_fee'] as Nat64).value),
            timestamp_nanos: (r['timestamp_nanos'] as Nat).value    
        );
    } 
}

class CMTokenTransferOut{
    final BigInt tokens;
    final BigInt token_ledger_transfer_fee;
    final Icrc1Account to;
    final BigInt block_height;
    final BigInt timestamp_nanos;
    final Cycles transfer_token_balance_fee;
    CMTokenTransferOut._({
        required this.tokens,
        required this.token_ledger_transfer_fee,
        required this.to,
        required this.block_height,
        required this.timestamp_nanos,
        required this.transfer_token_balance_fee
    });
    static CMTokenTransferOut of_the_record(Record r) {
        return CMTokenTransferOut._(
            tokens: (r['tokens'] as Nat).value,
            token_ledger_transfer_fee: (r['token_ledger_transfer_fee'] as Nat).value,
            to: Icrc1Account.of_the_record(r['to'] as Record),
            block_height: (r['block_height'] as Nat).value,
            timestamp_nanos: (r['timestamp_nanos'] as Nat).value,
            transfer_token_balance_fee: Cycles(cycles: (r['transfer_token_balance_fee'] as Nat64).value)
        );
    }
}

*/





// ------------- CM-MESSAGE-LOGS -------------

/*
class CMCyclesPositionPurchasePositorMessageQuest {
    final BigInt cycles_position_id;
    final BigInt purchase_id;
    final Principal purchaser;
    final BigInt purchase_timestamp_nanos;
    final Cycles cycles_purchase;
    final Cycles cycles_position_cycles_per_token_rate;
    final BigInt token_payment;
    final BigInt token_transfer_block_height;
    final BigInt token_transfer_timestamp_nanos;
    
    CMCyclesPositionPurchasePositorMessageQuest._({
        required this.cycles_position_id,
        required this.purchase_id,
        required this.purchaser,
        required this.purchase_timestamp_nanos,
        required this.cycles_purchase,
        required this.cycles_position_cycles_per_token_rate,
        required this.token_payment,
        required this.token_transfer_block_height,
        required this.token_transfer_timestamp_nanos,
    });
    static CMCyclesPositionPurchasePositorMessageQuest of_the_record(Record r) {
        return CMCyclesPositionPurchasePositorMessageQuest._(
            cycles_position_id: (r['cycles_position_id'] as Nat).value,
            purchase_id: (r['purchase_id'] as Nat).value,
            purchaser: (r['purchaser'] as Principal),
            purchase_timestamp_nanos: (r['purchase_timestamp_nanos'] as Nat).value,
            cycles_purchase: Cycles.oftheNat(r['cycles_purchase'] as Nat),
            cycles_position_cycles_per_token_rate: Cycles.oftheNat(r['cycles_position_cycles_per_token_rate'] as Nat),
            token_payment: (r['token_payment'] as Nat).value,
            token_transfer_block_height: (r['token_transfer_block_height'] as Nat).value,
            token_transfer_timestamp_nanos: (r['token_transfer_timestamp_nanos'] as Nat).value,            
        );
    }
}

class CMMessageCyclesPositionPurchasePositorLog {
    final BigInt timestamp_nanos;
    final CMCyclesPositionPurchasePositorMessageQuest cm_message_cycles_position_purchase_positor_quest; 
    CMMessageCyclesPositionPurchasePositorLog._({
        required this.timestamp_nanos,
        required this.cm_message_cycles_position_purchase_positor_quest
    });
    static CMMessageCyclesPositionPurchasePositorLog of_the_record(Record r) {
        return CMMessageCyclesPositionPurchasePositorLog._(
            timestamp_nanos: (r['timestamp_nanos'] as Nat).value,
            cm_message_cycles_position_purchase_positor_quest: CMCyclesPositionPurchasePositorMessageQuest.of_the_record(r['cm_message_cycles_position_purchase_positor_quest'] as Record)
        );
    }
}



class CMCyclesPositionPurchasePurchaserMessageQuest {
    final BigInt cycles_position_id;
    final Principal cycles_position_positor;
    final Cycles cycles_position_cycles_per_token_rate;
    final BigInt purchase_id;
    final BigInt purchase_timestamp_nanos;
    final BigInt token_payment;
    
    CMCyclesPositionPurchasePurchaserMessageQuest._({
        required this.cycles_position_id,
        required this.cycles_position_positor,
        required this.cycles_position_cycles_per_token_rate,
        required this.purchase_id,
        required this.purchase_timestamp_nanos,
        required this.token_payment,
    });
    static CMCyclesPositionPurchasePurchaserMessageQuest of_the_record(Record r) {
        return CMCyclesPositionPurchasePurchaserMessageQuest._(
            cycles_position_id: (r['cycles_position_id'] as Nat).value,
            cycles_position_positor: (r['cycles_position_positor'] as Principal),
            cycles_position_cycles_per_token_rate: Cycles.oftheNat(r['cycles_position_cycles_per_token_rate'] as Nat),
            purchase_id: (r['purchase_id'] as Nat).value,
            purchase_timestamp_nanos: (r['purchase_timestamp_nanos'] as Nat).value,
            token_payment: (r['token_payment'] as Nat).value,
        );
    }
}


class CMMessageCyclesPositionPurchasePurchaserLog {
    final BigInt timestamp_nanos;
    final Cycles cycles_purchase;
    final CMCyclesPositionPurchasePurchaserMessageQuest cm_message_cycles_position_purchase_purchaser_quest;
    CMMessageCyclesPositionPurchasePurchaserLog._({
        required this.timestamp_nanos,
        required this.cycles_purchase,
        required this.cm_message_cycles_position_purchase_purchaser_quest
    });
    static CMMessageCyclesPositionPurchasePurchaserLog of_the_record(Record r) {
        return CMMessageCyclesPositionPurchasePurchaserLog._(
            timestamp_nanos: (r['timestamp_nanos'] as Nat).value,
            cycles_purchase: Cycles.oftheNat(r['cycles_purchase'] as Nat),
            cm_message_cycles_position_purchase_purchaser_quest: CMCyclesPositionPurchasePurchaserMessageQuest.of_the_record(r['cm_message_cycles_position_purchase_purchaser_quest'] as Record)
        );
    } 
}


class CMTokenPositionPurchasePositorMessageQuest {
    final BigInt token_position_id;
    final Cycles token_position_cycles_per_token_rate;
    final Principal purchaser;
    final BigInt purchase_id;
    final BigInt token_purchase;
    final BigInt purchase_timestamp_nanos;
    CMTokenPositionPurchasePositorMessageQuest._({
        required this.token_position_id,
        required this.token_position_cycles_per_token_rate,
        required this.purchaser,
        required this.purchase_id,
        required this.token_purchase,
        required this.purchase_timestamp_nanos,
    });
    static CMTokenPositionPurchasePositorMessageQuest of_the_record(Record r) {
        return CMTokenPositionPurchasePositorMessageQuest._(
            token_position_id: (r['token_position_id'] as Nat).value, 
            token_position_cycles_per_token_rate: Cycles.oftheNat(r['token_position_cycles_per_token_rate'] as Nat),
            purchaser: (r['purchaser'] as Principal),
            purchase_id: (r['purchase_id'] as Nat).value,
            token_purchase: (r['token_purchase'] as Nat).value,
            purchase_timestamp_nanos: (r['purchase_timestamp_nanos'] as Nat).value,            
        );
    }
}


class CMMessageTokenPositionPurchasePositorLog {
    
    final BigInt timestamp_nanos;
    final Cycles cycles_payment;
    final CMTokenPositionPurchasePositorMessageQuest cm_message_token_position_purchase_positor_quest;
    
    CMMessageTokenPositionPurchasePositorLog._({
        required this.timestamp_nanos,
        required this.cycles_payment,
        required this.cm_message_token_position_purchase_positor_quest,
    });
    
    static CMMessageTokenPositionPurchasePositorLog of_the_record(Record r) {
        return CMMessageTokenPositionPurchasePositorLog._(
            timestamp_nanos: (r['timestamp_nanos'] as Nat).value,
            cycles_payment: Cycles.oftheNat(r['cycles_payment'] as Nat),
            cm_message_token_position_purchase_positor_quest: CMTokenPositionPurchasePositorMessageQuest.of_the_record(r['cm_message_token_position_purchase_positor_quest'] as Record),        
        );
    }
}



class CMTokenPositionPurchasePurchaserMessageQuest {
    final BigInt token_position_id;
    final BigInt purchase_id;
    final Principal positor;
    final BigInt purchase_timestamp_nanos;
    final Cycles cycles_payment;
    final Cycles token_position_cycles_per_token_rate;
    final BigInt token_purchase;
    final BigInt token_transfer_block_height;
    final BigInt token_transfer_timestamp_nanos;

    CMTokenPositionPurchasePurchaserMessageQuest._({
        required this.token_position_id,
        required this.purchase_id,
        required this.positor,
        required this.purchase_timestamp_nanos,
        required this.cycles_payment,
        required this.token_position_cycles_per_token_rate,
        required this.token_purchase,
        required this.token_transfer_block_height,
        required this.token_transfer_timestamp_nanos,      
    });

    static CMTokenPositionPurchasePurchaserMessageQuest of_the_record(Record r) {
        return CMTokenPositionPurchasePurchaserMessageQuest._(
            token_position_id: (r['token_position_id'] as Nat).value,  
            purchase_id: (r['purchase_id'] as Nat).value,
            positor: (r['positor'] as Principal),
            purchase_timestamp_nanos: (r['purchase_timestamp_nanos'] as Nat).value,
            cycles_payment: Cycles.oftheNat(r['cycles_payment'] as Nat),
            token_position_cycles_per_token_rate: Cycles.oftheNat(r['token_position_cycles_per_token_rate'] as Nat),
            token_purchase: (r['token_purchase'] as Nat).value,
            token_transfer_block_height: (r['token_transfer_block_height'] as Nat).value,
            token_transfer_timestamp_nanos: (r['token_transfer_timestamp_nanos'] as Nat).value,        
        );
    }
}

class CMMessageTokenPositionPurchasePurchaserLog {
    final BigInt timestamp_nanos;
    final CMTokenPositionPurchasePurchaserMessageQuest cm_message_token_position_purchase_purchaser_quest;
    CMMessageTokenPositionPurchasePurchaserLog._({
        required this.timestamp_nanos,
        required this.cm_message_token_position_purchase_purchaser_quest,
    });
    static CMMessageTokenPositionPurchasePurchaserLog of_the_record(Record r) {
        return CMMessageTokenPositionPurchasePurchaserLog._(
            timestamp_nanos: (r['timestamp_nanos'] as Nat).value,
            cm_message_token_position_purchase_purchaser_quest: CMTokenPositionPurchasePurchaserMessageQuest.of_the_record(r['cm_message_token_position_purchase_purchaser_quest'] as Record) 
        );
    }    
}






class CMVoidCyclesPositionPositorMessageQuest {
    final BigInt position_id;
    final BigInt timestamp_nanos;    
    CMVoidCyclesPositionPositorMessageQuest._({
        required this.position_id,
        required this.timestamp_nanos,
    });
    static CMVoidCyclesPositionPositorMessageQuest of_the_record(Record r) {
        return CMVoidCyclesPositionPositorMessageQuest._(
            position_id: (r['position_id'] as Nat).value,
            timestamp_nanos: (r['timestamp_nanos'] as Nat).value,
        );
    }
}


class CMMessageVoidCyclesPositionPositorLog {
    final BigInt timestamp_nanos;
    final Cycles void_cycles;
    final CMVoidCyclesPositionPositorMessageQuest cm_message_void_cycles_position_positor_quest;

    CMMessageVoidCyclesPositionPositorLog._({
        required this.timestamp_nanos,
        required this.void_cycles,
        required this.cm_message_void_cycles_position_positor_quest,
    });
    static CMMessageVoidCyclesPositionPositorLog of_the_record(Record r) {
        return CMMessageVoidCyclesPositionPositorLog._(
            timestamp_nanos: (r['timestamp_nanos'] as Nat).value, 
            void_cycles: Cycles.oftheNat(r['void_cycles'] as Nat),
            cm_message_void_cycles_position_positor_quest: CMVoidCyclesPositionPositorMessageQuest.of_the_record(r['cm_message_void_cycles_position_positor_quest'] as Record),            
        );
    }
}



class CMVoidTokenPositionPositorMessageQuest {
    final BigInt position_id;
    final BigInt void_tokens;
    final BigInt timestamp_nanos;
    CMVoidTokenPositionPositorMessageQuest._({
        required this.position_id,
        required this.void_tokens,
        required this.timestamp_nanos,
    });
    static CMVoidTokenPositionPositorMessageQuest of_the_record(Record r) {
        return CMVoidTokenPositionPositorMessageQuest._(
            position_id: (r['position_id'] as Nat).value, 
            void_tokens: (r['void_tokens'] as Nat).value,
            timestamp_nanos: (r['timestamp_nanos'] as Nat).value,     
        );
    }
}


class CMMessageVoidTokenPositionPositorLog {
    final BigInt timestamp_nanos;
    final CMVoidTokenPositionPositorMessageQuest cm_message_void_token_position_positor_quest;
    CMMessageVoidTokenPositionPositorLog._({
        required this.timestamp_nanos,
        required this.cm_message_void_token_position_positor_quest,
    });
    static CMMessageVoidTokenPositionPositorLog of_the_record(Record r) {
        return CMMessageVoidTokenPositionPositorLog._(
            timestamp_nanos: (r['timestamp_nanos'] as Nat).value,
            cm_message_void_token_position_positor_quest: CMVoidTokenPositionPositorMessageQuest.of_the_record(r['cm_message_void_token_position_positor_quest'] as Record)        
        );
    }
}

*/

// -----------------


class CyclesBankCMTradeContractData {
    
    BigInt trade_contract_token_balance = BigInt.from(0);
    //List<Icrc1Transaction> token_ledger_transactions_cache = [];
    //CMTradeContractLogs logs = CMTradeContractLogs();
        
        
    // show user positions logs sort by creation date, latest first, with an option to show only open/current positions 
    // show fee takes out each payout and total fees paid for the position
    List<PositionLog> current_user_positions_logs = []; 
    // if a log is not in the current_user_positions_logs 
    // but is in the user_positions_logs_storage & the storage-log-shows 
    // that the position has not terminated yet, that means that the 
    // update_storage_position fn is ongoing and the position has terminated
    // but the update is not availbale yet till the payout/update-storage-position runs. 
    
    List<PositionLog> user_positions_logs_storage = [];
    
        
        
    
}
/*
class CMTradeContractLogs {
    
    List<CMCyclesPosition> cm_cycles_positions = [];
    List<CMTokenPosition> cm_token_positions = [];
    List<CMCyclesPositionPurchase> cm_cycles_positions_purchases = [];
    List<CMTokenPositionPurchase> cm_token_positions_purchases = [];
    List<CMTokenTransferOut> cm_token_transfers_out = [];
    
    List<CMMessageCyclesPositionPurchasePositorLog> cm_message_cycles_position_purchase_positor_logs = [];
    List<CMMessageCyclesPositionPurchasePurchaserLog> cm_message_cycles_position_purchase_purchaser_logs = [];
    List<CMMessageTokenPositionPurchasePositorLog> cm_message_token_position_purchase_positor_logs = [];
    List<CMMessageTokenPositionPurchasePurchaserLog> cm_message_token_position_purchase_purchaser_logs = [];
    List<CMMessageVoidCyclesPositionPositorLog> cm_message_void_cycles_position_positor_logs = [];
    List<CMMessageVoidTokenPositionPositorLog> cm_message_void_token_position_positor_logs = [];
    
}



*/

