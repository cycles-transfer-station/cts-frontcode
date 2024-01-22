

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
    
    
     

    
    
    // -------- burn_icp_mint_cycles
    

    
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





// ------------- METRICS -------------

typedef CTSFuel = Cycles;


class CyclesBankMetrics {
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







