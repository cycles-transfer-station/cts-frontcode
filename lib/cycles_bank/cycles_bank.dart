


import 'dart:typed_data';

import 'package:ic_tools/ic_tools.dart';
import 'package:ic_tools_web/ic_tools_web.dart' show NullMap;
import 'package:ic_tools/tools.dart';
import 'package:ic_tools/candid.dart';
import 'package:ic_tools/common.dart';
import 'package:ic_tools/common.dart' as common;


import '../user.dart';
import '../config/state.dart';
import '../cycles_market/cycles_market_data.dart';
import '../transfer_icp/icp_ledger.dart';






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
    ): icp_id = common.icp_id(super.principal);
    
    Future<void> fresh_metrics() async {
        Record metrics_record = c_backwards(
            await this.user.call(
                this,
                method_name: 'metrics',
                calltype: CallType.query,
                put_bytes: c_forwards([])
            )
        )[0] as Record;
        this.metrics = CyclesBankMetrics.oftheRecord(metrics_record);
        
        //print('cm_message_cycles_position_purchase_positor_logs_len: ${this.metrics!.cm_message_cycles_position_purchase_positor_logs_len}');
    }
    
    Future<void> fresh_known_icrc1_ledgers() async {
        for (Icrc1TokenTradeContract tc in this.user.state.cm_main.icrc1_token_trade_contracts) {
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
                Record.oftheMap({
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
                            this.icrc1_transactions_cache[l]!.addAll(ts.map<Icrc1Transaction>(Icrc1Transaction.oftheRecord).toList());
                        
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
                            List<Icrc1Transaction> new_ts = ts.map<Icrc1Transaction>(Icrc1Transaction.oftheRecord).takeWhile((Icrc1Transaction t)=>t.block > this.icrc1_transactions_cache[l]!.first.block).toList(); 
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
                        throw Exception('Error of the transfer_cycles-call of the cycles_transferrer: \n${CallError.oftheRecord(call_error_record as Record)}');
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
        required T Function(Record) fn
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
                    Record.oftheMap({
                        'opt_start_before_i': Option<Nat64>(value: opt_start_before_i.nullmap((n)=>Nat64(BigInt.from(n))), value_type: Nat64()),
                        'chunk_size': Nat64(500)
                    })
                ])
            )).first as Record;
            
            if (logs_len == null) { // only set once on the first call
                logs_len = (download_sponse['logs_len'] as Nat64).value.toInt();
            }
            
            List<T>? logs = download_sponse.find_option<Vector>('logs').nullmap((v)=>v.cast_vector<Record>().map(fn).toList());
            
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
                function: CyclesTransferIn.oftheRecord,
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
                    function: CyclesTransferOut.oftheRecord,
                )
            );
        } catch(e) {
            this.cycles_transfers_out.addAll(backup_transfers_with_pending_callbacks);
            throw e;
        }
    }
    
    
    
    
    Future<void> cycles_balance_for_the_ctsfuel(Cycles cycles_for_the_ctsfuel) async {
        Variant sponse = c_backwards(
            await user.call(
                this,
                method_name: 'cycles_balance_for_the_ctsfuel',
                put_bytes: c_forwards([cycles_for_the_ctsfuel]),
                calltype: CallType.call
            )
        ).first as Variant;
        match_variant<void>(sponse, {
            Ok:(nul) {
                            
            },
            Err:(cycles_balance_for_the_ctsfuel_balance_error) {
                match_variant<Never>(cycles_balance_for_the_ctsfuel_balance_error as Variant, {
                    'MinimumCyclesForTheCTSFuel': (r) {
                        throw Exception('Minimum cycles for the ctsfuel: ${Cycles.oftheNat((r as Record)['minimum_cycles_for_the_ctsfuel']!)}');
                    },
                    'CyclesBalanceTooLow': (cycles_balance_record) { 
                        this.metrics!.cycles_balance = Cycles.oftheNat((cycles_balance_record as Record)['cycles_balance']!);
                        throw Exception('The cycles_balance is too low.');
                    }
                });
            }
        });    
    }


    Future<BigInt/*new-lifetime-termination-timestamp-seconds*/> lengthen_lifetime(LengthenLifetimeQuest q) async {
        if (this.metrics == null) { await this.fresh_metrics(); }
        Variant sponse = c_backwards(
            await user.call(
                this,
                method_name: 'lengthen_lifetime',
                calltype: CallType.call,
                put_bytes: c_forwards([q])
            )
        ).first as Variant;
        BigInt new_lifetime_termination_timestamp_seconds = match_variant<BigInt>(sponse, {
            Ok: (ok) {
                return (ok as Nat).value;
            },
            Err: (lengthen_lifetime_error) {
                return match_variant<Never>(lengthen_lifetime_error as Variant, {
                    'MinimumSetLifetimeTerminationTimestampSeconds': (nat) {
                        throw Exception('The minimum days that the lifetime of this cycles-bank can lengthen is ${(((nat as Nat).value - this.metrics!.lifetime_termination_timestamp_seconds)/BigInt.from(60)/60/24).toStringAsFixed(3)}');
                    },
                    'CyclesBalanceTooLow': (r_ctype){
                        Record r = r_ctype as Record;
                        this.metrics!.cycles_balance = Cycles.oftheNat(r['cycles_balance']!);
                        throw Exception('The cycles_balance in the cycles-bank is too low.\ncost to lengthen the lifetime for ${ ((q.set_lifetime_termination_timestamp_seconds - this.metrics!.lifetime_termination_timestamp_seconds)/BigInt.from(60)/60/24).toStringAsFixed(3) }-days: ${Cycles.oftheNat(r['lengthen_cost_cycles']!)}\ncycles_balance: ${this.metrics!.cycles_balance}');
                    },
                    'CBSMCallError': (call_error_record) {
                        throw Exception('cbsm call error: ${CallError.oftheRecord(call_error_record as Record)}');
                    }   
                });
            }
        });
        return new_lifetime_termination_timestamp_seconds;
    }

    
    
    Future<void> change_storage_size(ChangeStorageSizeQuest q) async {
        Variant sponse = c_backwards(
            await user.call(
                this,
                method_name: 'change_storage_size',
                calltype: CallType.call,
                put_bytes: c_forwards([q])
            )
        ).first as Variant;
        match_variant<void>(sponse, {
            Ok: (n){
                
            },
            Err: (change_storage_size_error){
                match_variant<Never>(change_storage_size_error as Variant, {
                    'NewStorageSizeMibTooLow':(r_c){
                        throw Exception('The minimum new storage size is: ${((r_c as Record)['minimum_new_storage_size_mib'] as Nat).value}-MiB');
                    },
                    'NewStorageSizeMibTooHigh': (r_c){ 
                        throw Exception('The maximum new storage size is: ${((r_c as Record)['maximum_new_storage_size_mib'] as Nat).value}-MiB');
                    },
                    'CyclesBalanceTooLow': (r_c){
                        this.metrics!.cycles_balance = Cycles.oftheNat((r_c as Record)['cycles_balance']!);
                        throw Exception('The cycles_balance is too low. \nstorage change cycles-cost: ${Cycles.oftheNat((r_c as Record)['new_storage_size_mib_cost_cycles']!)}\ncycles_balance: ${this.metrics!.cycles_balance}');
                    },
                    'ManagementCanisterUpdateSettingsCallError':(call_error_record){
                        throw Exception('management-canister call error: ${CallError.oftheRecord(call_error_record as Record)}');
                    }
                });    
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
                                throw Exception('Fee must be: ${Tokens(token_quantums: ((r as Record)['expected_fee'] as Nat).value, decimal_places: icrc1_ledger.decimals)}');
                            },
                            'BadBurn' : (r) {   
                                throw Exception('BadBurn: min_burn_amount: ${Tokens(token_quantums: ((r as Record)['min_burn_amount'] as Nat).value, decimal_places: icrc1_ledger.decimals)} ');
                            },
                            'InsufficientFunds' : (r) {
                                throw Exception('InsufficientFunds. current-balance: ${Tokens(token_quantums: ((r as Record)['balance'] as Nat).value, decimal_places: icrc1_ledger.decimals)}');
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
                throw Exception('ledger transfer call error: ${CallError.oftheRecord(call_error as Record)}');        
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
                                throw Exception('Bad Fee set on the transfer. expected_fee: ${IcpTokens.oftheRecord((expected_fee_record as Record)['expected_fee']!)}');
                            },
                            'InsufficientFunds': (balance_record) {
                                IcpTokens current_balance = IcpTokens.oftheRecord((balance_record as Record)['balance']!);
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
                throw Exception('ledger transfer call error: ${CallError.oftheRecord(call_error as Record)}');        
            },
        });
        return block_height;    
    }
    
    
    
    
    
    
    
    // ---------------------
    
    // cycles-market methods
    
    Future<BigInt> cm_view_token_lock(Icrc1TokenTradeContract icrc1token_trade_contract) async {
        BigInt token_lock = (c_backwards(
            await this.user.call(
                icrc1token_trade_contract.canister,
                calltype: CallType.query,
                method_name: 'view_token_lock',
                put_bytes: c_forwards([
                    Record.oftheMap({
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
                List<Tokens> rs = await Future.wait([ 
                    check_icrc1_balance(
                        icrc1_ledger_canister_id: tc.icrc1_ledger_canister_id, 
                        owner: tc.token_trade_contract_canister_id,
                        subaccount: principal_as_an_icpsubaccountbytes(this.principal),
                        calltype: CallType.query
                    ),
                    this.cm_view_token_lock(tc)
                ]);
                Tokens token_ledger_balance = rs[0];
                Tokens tokens_in_the_lock = rs[1]; 
                this.cm_trade_contracts[tc]!.trade_contract_token_balance = token_ledger_balance - tokens_in_the_lock;
            }))
        );
    }
    
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
    
    Future<void> fresh_cm_cycles_positions([Icrc1TokenTradeContract? icrc1token_trade_contract]) async {
        List<Icrc1TokenTradeContract> icrc1token_trade_contracts = icrc1token_trade_contract != null ? [icrc1token_trade_contract] : this.cm_trade_contracts.keys.toList();
        await Future.wait(
            icrc1token_trade_contracts.map((tc)=>Future(()async{
                this.cm_trade_contracts[tc]!.logs.cm_cycles_positions.addAll(
                    await cb_download_mechanism(
                        icrc1token_trade_contract: tc,
                        len_so_far: this.cm_trade_contracts[tc]!.logs.cm_cycles_positions.length,
                        download_method_name: 'download_cm_cycles_positions', 
                        function: CMCyclesPosition.oftheRecord,
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
                        function: CMTokenPosition.oftheRecord,
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
                        function: CMCyclesPositionPurchase.oftheRecord,
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
                        function: CMTokenPositionPurchase.oftheRecord,
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
                        function: CMTokenTransferOut.oftheRecord,
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
                        function: CMMessageCyclesPositionPurchasePositorLog.oftheRecord,
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
                        function: CMMessageCyclesPositionPurchasePurchaserLog.oftheRecord,
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
                        function: CMMessageTokenPositionPurchasePositorLog.oftheRecord,
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
                        function: CMMessageTokenPositionPurchasePurchaserLog.oftheRecord,
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
                        function: CMMessageVoidCyclesPositionPositorLog.oftheRecord,
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
                        function: CMMessageVoidTokenPositionPositorLog.oftheRecord,
                    )
                );
            }))   
        );
    }
    
    Future<void> load_cm_data() async {
        await Future.wait([
            this.fresh_cm_trade_contracts_token_balances(),
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
        ]);
    }

    

    
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
                return CreateCyclesPositionSuccess.oftheRecord(create_cycles_position_success as Record);
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
                        throw Exception('cycles-market create_cycles_position call error:\n${CallError.oftheRecord(call_error_record as Record)}');    
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
                return CreateTokenPositionSuccess.oftheRecord(ok_record as Record);
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
                        throw Exception('cycles-market create_icp_position call error:\n${CallError.oftheRecord(call_error_record as Record)}');    
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
                                throw Exception('Error calling the token-ledger for the cycles-market-token-balance.\n${CallError.oftheRecord(call_error_record as Record)}');
                            },
                            'UserTokenBalanceTooLow': (user_token_balance_record) {
                                this.cm_trade_contracts[icrc1token_trade_contract]!.trade_contract_token_balance = ((user_token_balance_record as Record)['user_token_balance'] as Nat).value;
                                throw Exception('The cycles-market-token-balance is too low. The token-balance must be enough to cover the token-position (${q.tokens}) plus the token-ledger-transfer-fees for each possible purchase according to the minimum-purchase (${Tokens(token_quantums: (q.tokens.token_quantums ~/ q.minimum_purchase.token_quantums) * icrc1token_trade_contract.ledger_data.fee, decimal_places: icrc1token_trade_contract.ledger_data.decimals)}). \ncurrent-token-balance: ${Tokens(token_quantums: this.cm_trade_contracts[icrc1token_trade_contract]!.trade_contract_token_balance, decimal_places: icrc1token_trade_contract.ledger_data.decimals)}');
                            },
                            'CyclesMarketIsFull_MaximumRateAndMinimumTokenPositionForABump': (r_ctype) {
                                Record r = r_ctype as Record;
                                throw Exception('The cycles-market token-positions are full. If you create a token-position with a maximum cycles-per-token-rate: ${Cycles.oftheNat(r['maximum_rate_for_a_bump'] as Nat)} and with a minimum token-position: ${Tokens.oftheNat(r['minimum_token_position_for_a_bump'] as Nat, decimal_places: icrc1token_trade_contract.ledger_data.decimals)} then you will bump the most expensive token-position and take its place.');
                            },
                            'MinimumTokenPosition': (tokens) {
                                throw Exception('The minimum tokens for a token-position is: ${Tokens.oftheNat(tokens, decimal_places: icrc1token_trade_contract.ledger_data.decimals)}');
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
                return PurchaseCyclesPositionSuccess.oftheRecord(ok as Record);
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
                        throw Exception('cycles-market purchase_cycles_position call error:\n${CallError.oftheRecord(call_error_record as Record)}');                    
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
                                throw Exception('Error calling the ${icrc1token_trade_contract.ledger_data.symbol}-ledger for the cycles-market-token-balance.\n${CallError.oftheRecord(call_error_record as Record)}');
                            },
                            'UserTokenBalanceTooLow': (user_token_balance_record) {
                                this.cm_trade_contracts[icrc1token_trade_contract]!.trade_contract_token_balance = ((user_token_balance_record as Record)['user_token_balance'] as Nat).value;
                                Tokens cycles_position_purchase_cycles_token_cost = Tokens(
                                    token_quantums: cycles_transform_tokens(purchase_cycles, cycles_position.cycles_per_token_rate),
                                    decimal_places: icrc1token_trade_contract.ledger_data.decimals
                                ); 
                                throw Exception('The user\'s-cycles-market-${icrc1token_trade_contract.ledger_data.symbol}-balance is too low for the purchase. \ncycles-market-${icrc1token_trade_contract.ledger_data.symbol}-balance: ${Tokens(token_quantums: this.cm_trade_contracts[icrc1token_trade_contract]!.trade_contract_token_balance, decimal_places: icrc1token_trade_contract.ledger_data.decimals)}\npurchase_cycles: ${purchase_cycles}\n${icrc1token_trade_contract.ledger_data.symbol}-cost of these cycles in this cycles-position: ${cycles_position_purchase_cycles_token_cost}, ${icrc1token_trade_contract.ledger_data.symbol}-ledger-transfer-fee: ${icrc1token_trade_contract.ledger_data.fee_tokens}');
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
                return PurchaseTokenPositionSuccess.oftheRecord(ok as Record);
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
                        throw Exception('The cycles-balance is too low in the cycles-bank.\ncycles-balance: ${Cycles.oftheNat(r['cycles_balance']!)}\ncycles-market-purchase-position-fee: ${Cycles.oftheNat(r['cycles_market_purchase_position_fee']!)}\ncost for a purchase of the ${purchase_tokens}-${icrc1token_trade_contract.ledger_data.symbol} of the token-position: ${token_position.id} with the cycles_per_token-rate: ${token_position.cycles_per_token_rate} is: ${tokens_transform_cycles(purchase_tokens.token_quantums, token_position.cycles_per_token_rate.cycles)}');
                    },
                    'CyclesMarketPurchaseTokenPositionCallError': (call_error_record) {
                        throw Exception('cycles-market purchase_token_position call error:\n${CallError.oftheRecord(call_error_record as Record)}');                    
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
                                throw Exception('This token-position: ${token_position.id} has ${Tokens.oftheNat((token_position_tokens_record as Record)['token_position_tokens'] as Nat, decimal_places: icrc1token_trade_contract.ledger_data.decimals)}-tokens.');
                            },
                            'TokenPositionMinimumPurchaseIsGreaterThanThePurchaseQuest':(token_position_minimum_purchase_record){
                                throw Exception('File this error: TokenPositionMinimumPurchaseIsGreaterThanThePurchaseQuest\nThe minimum-purchase of this token-position is ${Tokens.oftheNat((token_position_minimum_purchase_record as Record)['token_position_minimum_purchase'] as Nat, decimal_places: icrc1token_trade_contract.ledger_data.decimals)}');
                            }
                        });
                    }
                });
            }
        });
        await this.fresh_cm_token_positions_purchases(icrc1token_trade_contract);
        return purchase_token_position_success;
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
                        throw Exception('cycles-market void_position call_error:\n${CallError.oftheRecord(call_error_record as Record)}');
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
                        throw Exception('cycles_market transfer_token_balance call_error: \n${CallError.oftheRecord(call_error_record as Record)}');
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
                                throw Exception('${icrc1token_trade_contract.ledger_data.symbol}-ledger token-balance call error: \n${CallError.oftheRecord(call_error_record as Record)}');
                            },
                            'UserTokenBalanceTooLow': (user_token_balance_record) {
                                this.cm_trade_contracts[icrc1token_trade_contract]!.trade_contract_token_balance = ((user_token_balance_record as Record)['user_token_balance'] as Nat).value;
                                throw Exception('The cycles-market-${icrc1token_trade_contract.ledger_data.symbol}-balance is too low for this transfer.\n${icrc1token_trade_contract.ledger_data.symbol}-balance: ${Tokens(token_quantums: this.cm_trade_contracts[icrc1token_trade_contract]!.trade_contract_token_balance, decimal_places: icrc1token_trade_contract.ledger_data.decimals)}');
                            },
                            'TokenTransferCallError':(call_error_record) {
                                throw Exception('${icrc1token_trade_contract.ledger_data.symbol}-ledger transfer call error: \n${CallError.oftheRecord(call_error_record as Record)}');
                            },
                            'TokenTransferError': (token_transfer_error){
                                return match_variant<Never>(token_transfer_error as Variant, token_transfer_error_match_map(icrc1token_trade_contract.ledger_data.decimals));
                            }
                        });
                    }                
                });
            }
        });
        this.fresh_cm_token_transfers_out(icrc1token_trade_contract);
        return block_height;
    }



}


Map<String, Never Function(CandidType)> token_transfer_error_match_map({required int token_decimal_places}) {
    'BadFee': (expected_fee_record) {
        throw Exception('Bad Fee set on the transfer. expected_fee: ${Tokens.oftheNat((expected_fee_record as Record)['expected_fee'] as Nat, decimal_places: token_decimal_places)}');
    },
    'InsufficientFunds': (balance_record) {
        // this error does not happen on a cycles-market cm_transfer_token_balance
        Tokens current_balance = Tokens.oftheNat((balance_record as Record)['balance'] as Nat, decimal_places: token_decimal_places);
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



// put into the ic_tools common lib
Future<BigInt> check_icrc1_balance({required Principal icrc1_ledger_canister_id, required Principal owner, Uint8List? subaccount, required CallType calltype}) async {
    BigInt balance = (c_backwards(await Canister(icrc1_ledger_canister_id).call(
        method_name: 'icrc1_balance_of',
        put_bytes: c_forwards([
            Record.oftheMap({
                'owner': owner,
                'subaccount': Option<Blob>(value: subaccount.nullmap((b)=>Blob(b)), value_type: Blob(isTypeStance:true))
            })
        ]),
        calltype: calltype
    )).first as Nat).value;
    return balance;
}



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
    static CyclesBankMetrics oftheRecord(Record r) {
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
                    (c[0] as Record)['trade_contract_canister_id'] as Principal: CMTradeContractLogsLengths.oftheRecord(c)
            },
        );
    }
}



class CMTradeContractLogsLengths {
    CMCallsOutLengths cm_calls_out_lengths;
    CMMessageLogsLengths cm_message_logs_lengths;
    CMTradeContractLogsLengths._({
        required this.cm_calls_out_lengths,
        required this.cm_message_logs_length,
    });
    static CMTradeContractLogsLengths oftheRecord(Record r) {
        CMTradeContractLogsLengths._(
            cm_calls_out_lengths: CMCallsOutLengths.oftheRecord(r['cm_calls_out_lengths'] as Record),
            cm_message_logs_length: CMMessageLogsLengths.oftheRecord(r['cm_message_logs_length'] as Record),    
        );
    }
}

class CMCallsOutLengths {
    BigInt cm_cycles_positions_length;
    BigInt cm_token_positions_length;
    BigInt cm_cycles_positions_purchases_length;
    BigInt cm_token_positions_purchases_length;    
    BigInt cm_token_transfers_out_length;
    CMCallsOutLengths._(
        required this.cm_cycles_positions_length,
        required this.cm_token_positions_length,
        required this.cm_cycles_positions_purchases_length,
        required this.cm_token_positions_purchases_length,   
        required this.cm_token_transfers_out_length,
    );
    static CMCallsOutLengths oftheRecord(Record r) {
        cm_cycles_positions_length: (r['cm_cycles_positions_length'] as Nat64).value,
        cm_token_positions_length: (r['cm_token_positions_length'] as Nat64).value,
        cm_cycles_positions_purchases_length: (r['cm_cycles_positions_purchases_length'] as Nat64).value,
        cm_token_positions_purchases_length: (r['cm_token_positions_purchases_length'] as Nat64).value,   
        cm_token_transfers_out_length: (r['cm_token_transfers_out_length'] as Nat64).value,
    }
}

class CMMessageLogsLengths {
    BigInt cm_message_cycles_position_purchase_positor_logs_length;
    BigInt cm_message_cycles_position_purchase_purchaser_logs_length;
    BigInt cm_message_token_position_purchase_positor_logs_length;
    BigInt cm_message_token_position_purchase_purchaser_logs_length;
    BigInt cm_message_void_cycles_position_positor_logs_length;
    BigInt cm_message_void_token_position_positor_logs_length;
    CMMessageLogsLengths._(
        required this.cm_message_cycles_position_purchase_positor_logs_length,
        required this.cm_message_cycles_position_purchase_purchaser_logs_length,
        required this.cm_message_token_position_purchase_positor_logs_length,
        required this.cm_message_token_position_purchase_purchaser_logs_length,
        required this.cm_message_void_cycles_position_positor_logs_length,
        required this.cm_message_void_token_position_positor_logs_length,
    );    
    static CMMessageLogsLengths oftheRecord(Record r) {
        cm_message_cycles_position_purchase_positor_logs_length: (r['cm_message_cycles_position_purchase_positor_logs_length'] as Nat64).value,
        cm_message_cycles_position_purchase_purchaser_logs_length: (r['cm_message_cycles_position_purchase_purchaser_logs_length'] as Nat64).value,
        cm_message_token_position_purchase_positor_logs_length: (r['cm_message_token_position_purchase_positor_logs_length'] as Nat64).value,
        cm_message_token_position_purchase_purchaser_logs_length: (r['cm_message_token_position_purchase_purchaser_logs_length'] as Nat64).value,
        cm_message_void_cycles_position_positor_logs_length: (r['cm_message_void_cycles_position_positor_logs_length'] as Nat64).value,
        cm_message_void_token_position_positor_logs_length: (r['cm_message_void_token_position_positor_logs_length'] as Nat64).value,
    }
}






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
    
    static CyclesTransferIn oftheRecord(Record r) {
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
    
    static CyclesTransferOut oftheRecord(Record r) {
        Nat? cycles_refunded_nat = r.find_option<Nat>('cycles_refunded');
        Record? opt_cycles_transfer_call_error = r.find_option<Record>('opt_cycles_transfer_call_error');
        return CyclesTransferOut._(
            id: (r['id'] as Nat).value,    
            for_the_canister: r['for_the_canister'] as Principal,    
            cycles_sent: Cycles.oftheNat(r['cycles_sent'] as Nat),    
            cycles_refunded: cycles_refunded_nat != null ? Cycles.oftheNat(cycles_refunded_nat) : null,    
            cycles_transfer_memo: CyclesTransferMemo.oftheVariant(r['cycles_transfer_memo'] as Variant),    
            timestamp_nanos: (r['timestamp_nanos'] as Nat).value,    
            opt_cycles_transfer_call_error: opt_cycles_transfer_call_error != null ? CallError.oftheRecord(opt_cycles_transfer_call_error) : null,
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





// cycles-market classes


class CyclesBankCMTradeContractData {
    
    BigInt trade_contract_token_balance;
    List<Icrc1Transaction> token_ledger_transactions_cache = [];
    CMTradeContractLogs logs;
    
}

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


class CMCyclesPosition {
    final BigInt id;   
    final Cycles cycles;
    final Cycles minimum_purchase;
    final XDRICPRate xdr_permyriad_per_icp_rate;
    final Cycles create_position_fee;
    final BigInt timestamp_nanos; 
    
    CMCyclesPosition._({
        required this.id,   
        required this.cycles,
        required this.minimum_purchase,
        required this.xdr_permyriad_per_icp_rate,
        required this.create_position_fee,
        required this.timestamp_nanos, 
    });
    
    static CMCyclesPosition oftheRecord(Record r) {
        return CMCyclesPosition._(
            id: (r['id'] as Nat).value,
            cycles: Cycles.oftheNat(r['cycles'] as Nat),
            minimum_purchase: Cycles.oftheNat(r['minimum_purchase'] as Nat),
            xdr_permyriad_per_icp_rate: XDRICPRate.oftheXdrPerMyriadPerIcpNat64(r['xdr_permyriad_per_icp_rate'] as Nat64),
            create_position_fee: Cycles(cycles: (r['create_position_fee'] as Nat64).value),
            timestamp_nanos: (r['timestamp_nanos'] as Nat).value,
        );
    }
}


class CMIcpPosition {
    final BigInt id;   
    final IcpTokens icp;
    final IcpTokens minimum_purchase;
    final XDRICPRate xdr_permyriad_per_icp_rate;
    final Cycles create_position_fee;
    final BigInt timestamp_nanos;

    CMIcpPosition._({
        required this.id,   
        required this.icp,
        required this.minimum_purchase,
        required this.xdr_permyriad_per_icp_rate,
        required this.create_position_fee,
        required this.timestamp_nanos
    });
    
    static CMIcpPosition oftheRecord(Record r) {
        return CMIcpPosition._(
            id: (r['id'] as Nat).value,   
            icp: IcpTokens.oftheRecord(r['icp'] as Record),
            minimum_purchase: IcpTokens.oftheRecord(r['minimum_purchase'] as Record),
            xdr_permyriad_per_icp_rate: XDRICPRate.oftheXdrPerMyriadPerIcpNat64(r['xdr_permyriad_per_icp_rate'] as Nat64),
            create_position_fee: Cycles(cycles: (r['create_position_fee'] as Nat64).value),
            timestamp_nanos: (r['timestamp_nanos'] as Nat).value
        );
    }

}


class CMCyclesPositionPurchase {
    final BigInt cycles_position_id;
    final XDRICPRate cycles_position_xdr_permyriad_per_icp_rate;
    final Principal cycles_position_positor;
    final BigInt id;
    final Cycles cycles;
    final Cycles purchase_position_fee;
    final BigInt timestamp_nanos;
    
    CMCyclesPositionPurchase._({
        required this.cycles_position_id,
        required this.cycles_position_xdr_permyriad_per_icp_rate,
        required this.cycles_position_positor,
        required this.id,
        required this.cycles,
        required this.purchase_position_fee,
        required this.timestamp_nanos,
    }); 
    
    static CMCyclesPositionPurchase oftheRecord(Record r) {
        return CMCyclesPositionPurchase._(
            cycles_position_id: (r['cycles_position_id'] as Nat).value,
            cycles_position_xdr_permyriad_per_icp_rate: XDRICPRate.oftheXdrPerMyriadPerIcpNat64(r['cycles_position_xdr_permyriad_per_icp_rate'] as Nat64),
            cycles_position_positor: r['cycles_position_positor'] as Principal,
            id: (r['id'] as Nat).value,
            cycles: Cycles.oftheNat(r['cycles'] as Nat),
            purchase_position_fee: Cycles(cycles: (r['purchase_position_fee'] as Nat64).value),
            timestamp_nanos: (r['timestamp_nanos'] as Nat).value,        
        );
    } 
}

class CMIcpPositionPurchase{
    final BigInt icp_position_id;
    final XDRICPRate icp_position_xdr_permyriad_per_icp_rate;
    final Principal icp_position_positor;
    final BigInt id;
    final IcpTokens icp;
    final Cycles purchase_position_fee;
    final BigInt timestamp_nanos;
    
    CMIcpPositionPurchase._({
        required this.icp_position_id,
        required this.icp_position_xdr_permyriad_per_icp_rate,
        required this.icp_position_positor,
        required this.id,
        required this.icp,
        required this.purchase_position_fee,
        required this.timestamp_nanos,
    });
    
    static CMIcpPositionPurchase oftheRecord(Record r) {
        return CMIcpPositionPurchase._(
            icp_position_id: (r['icp_position_id'] as Nat).value,
            icp_position_xdr_permyriad_per_icp_rate: XDRICPRate.oftheXdrPerMyriadPerIcpNat64(r['icp_position_xdr_permyriad_per_icp_rate'] as Nat64),
            icp_position_positor: r['icp_position_positor'] as Principal,
            id: (r['id'] as Nat).value,
            icp: IcpTokens.oftheRecord(r['icp'] as Record),
            purchase_position_fee: Cycles(cycles: (r['purchase_position_fee'] as Nat64).value),
            timestamp_nanos: (r['timestamp_nanos'] as Nat).value    
        );
    } 
}

class CMIcpTransferOut{
    final IcpTokens icp;
    final IcpTokens icp_fee;
    final String to;
    final BigInt block_height;
    final BigInt timestamp_nanos;
    final Cycles transfer_icp_balance_fee;
    CMIcpTransferOut._({
        required this.icp,
        required this.icp_fee,
        required this.to,
        required this.block_height,
        required this.timestamp_nanos,
        required this.transfer_icp_balance_fee
    });
    static CMIcpTransferOut oftheRecord(Record r) {
        return CMIcpTransferOut._(
            icp: IcpTokens.oftheRecord(r['icp'] as Record),
            icp_fee: IcpTokens.oftheRecord(r['icp_fee'] as Record),
            to: bytesasahexstring((r['to'] as Blob).bytes),
            block_height: (r['block_height'] as Nat).value,
            timestamp_nanos: (r['timestamp_nanos'] as Nat).value,
            transfer_icp_balance_fee: Cycles(cycles: (r['transfer_icp_balance_fee'] as Nat64).value)
        );
    } 
}






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

}


class CreateCyclesPositionSuccess {
    final BigInt position_id;
    CreateCyclesPositionSuccess({
        required this.position_id
    });
    static CreateCyclesPositionSuccess oftheRecord(Record r) {
        return CreateCyclesPositionSuccess(
            position_id: (r['position_id'] as Nat).value
        );
    }
}



class CreateTokenPositionQuest extends Record {
    final Tokens tokens;
    final Tokens minimum_purchase;
    final Cycles cycles_per_token_rate;
    CreateTokenPositionQuest({
        required this.tokens,
        required this.minimum_purchase,
        required this.cycles_per_token_rate
    }) {
        this['tokens']= this.tokens;
        this['minimum_purchase']= this.minimum_purchase;
        this['cycles_per_token_rate']= this.cycles_per_token_rate;
    }
}


class CreateIcpPositionSuccess {
    final BigInt position_id;
    CreateIcpPositionSuccess({
        required this.position_id
    });
    static CreateIcpPositionSuccess oftheRecord(Record r) {
        return CreateIcpPositionSuccess(
            position_id: (r['position_id'] as Nat).value
        );
    }
}


class CyclesBankCMPurchaseCyclesPositionQuest extends Record {
    final CyclesMarketPurchaseCyclesPositionQuest cycles_market_purchase_cycles_position_quest;
    final XDRICPRate cycles_position_xdr_permyriad_per_icp_rate;                                              // for the cycles-bank-log
    final Principal cycles_position_positor;
    CyclesBankCMPurchaseCyclesPositionQuest({
        required this.cycles_market_purchase_cycles_position_quest,
        required this.cycles_position_xdr_permyriad_per_icp_rate,
        required this.cycles_position_positor,
    }) {
        this['cycles_market_purchase_cycles_position_quest'] = this.cycles_market_purchase_cycles_position_quest;
        this['cycles_position_xdr_permyriad_per_icp_rate'] = this.cycles_position_xdr_permyriad_per_icp_rate;
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
    static PurchaseCyclesPositionSuccess oftheRecord(Record r) {
        return PurchaseCyclesPositionSuccess._(
            purchase_id: (r['purchase_id'] as Nat).value
        );
    }
}



class CyclesBankCMPurchaseIcpPositionQuest extends Record {
    final CyclesMarketPurchaseIcpPositionQuest cycles_market_purchase_icp_position_quest;
    final XDRICPRate icp_position_xdr_permyriad_per_icp_rate;
    final Principal icp_position_positor;
    CyclesBankCMPurchaseIcpPositionQuest({
        required this.cycles_market_purchase_icp_position_quest,
        required this.icp_position_xdr_permyriad_per_icp_rate,
        required this.icp_position_positor,
    }) {
        this['cycles_market_purchase_icp_position_quest'] = this.cycles_market_purchase_icp_position_quest;
        this['icp_position_xdr_permyriad_per_icp_rate'] = this.icp_position_xdr_permyriad_per_icp_rate;
        this['icp_position_positor'] = this.icp_position_positor;
    }
}

class CyclesMarketPurchaseIcpPositionQuest extends Record {
    final BigInt icp_position_id;
    final IcpTokens icp;
    CyclesMarketPurchaseIcpPositionQuest({
        required this.icp_position_id,
        required this.icp
    }) {
        this['icp_position_id'] = Nat(this.icp_position_id);
        this['icp'] = this.icp;
    }
}



class PurchaseIcpPositionSuccess {
    final BigInt purchase_id;
    PurchaseIcpPositionSuccess._({
        required this.purchase_id
    });
    static PurchaseIcpPositionSuccess oftheRecord(Record r) {
        return PurchaseIcpPositionSuccess._(
            purchase_id: (r['purchase_id'] as Nat).value
        );
    }
}



class CyclesMarketVoidPositionQuest extends Record {
    BigInt position_id;
    CyclesMarketVoidPositionQuest({
        required this.position_id
    }) {
        this['position_id'] = Nat(this.position_id);
    }
}



class CyclesMarketTransferIcpBalanceQuest extends Record {
    final IcpTokens icp;
    final IcpTokens icp_fee;
    final String to;
    CyclesMarketTransferIcpBalanceQuest({
        required this.icp,
        required this.icp_fee,
        required this.to
    }) {
        this['icp'] = this.icp;
        this['icp_fee'] = this.icp_fee;
        this['to'] = Blob(hexstringasthebytes(this.to));
    }
}



// --------


class CMCyclesPositionPurchasePositorMessageQuest {
    final BigInt cycles_position_id;
    final BigInt purchase_id;
    final Principal purchaser;
    final BigInt purchase_timestamp_nanos;
    final Cycles cycles_purchase;
    final XDRICPRate cycles_position_xdr_permyriad_per_icp_rate;
    final IcpTokens icp_payment;
    final BigInt icp_transfer_block_height;
    final BigInt icp_transfer_timestamp_nanos;
    
    CMCyclesPositionPurchasePositorMessageQuest._({
        required this.cycles_position_id,
        required this.purchase_id,
        required this.purchaser,
        required this.purchase_timestamp_nanos,
        required this.cycles_purchase,
        required this.cycles_position_xdr_permyriad_per_icp_rate,
        required this.icp_payment,
        required this.icp_transfer_block_height,
        required this.icp_transfer_timestamp_nanos,
    });
    static CMCyclesPositionPurchasePositorMessageQuest oftheRecord(Record r) {
        return CMCyclesPositionPurchasePositorMessageQuest._(
            cycles_position_id: (r['cycles_position_id'] as Nat).value,
            purchase_id: (r['purchase_id'] as Nat).value,
            purchaser: (r['purchaser'] as Principal),
            purchase_timestamp_nanos: (r['purchase_timestamp_nanos'] as Nat).value,
            cycles_purchase: Cycles.oftheNat(r['cycles_purchase'] as Nat),
            cycles_position_xdr_permyriad_per_icp_rate: XDRICPRate.oftheXdrPerMyriadPerIcpNat64(r['cycles_position_xdr_permyriad_per_icp_rate'] as Nat64),
            icp_payment: IcpTokens.oftheRecord(r['icp_payment'] as Record),
            icp_transfer_block_height: (r['icp_transfer_block_height'] as Nat64).value,
            icp_transfer_timestamp_nanos: (r['icp_transfer_timestamp_nanos'] as Nat).value,            
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
    static CMMessageCyclesPositionPurchasePositorLog oftheRecord(Record r) {
        return CMMessageCyclesPositionPurchasePositorLog._(
            timestamp_nanos: (r['timestamp_nanos'] as Nat).value,
            cm_message_cycles_position_purchase_positor_quest: CMCyclesPositionPurchasePositorMessageQuest.oftheRecord(r['cm_message_cycles_position_purchase_positor_quest'] as Record)
        );
    }
}



class CMCyclesPositionPurchasePurchaserMessageQuest {
    final BigInt cycles_position_id;
    final Principal cycles_position_positor;
    final XDRICPRate cycles_position_xdr_permyriad_per_icp_rate;
    final BigInt purchase_id;
    final BigInt purchase_timestamp_nanos;
    final IcpTokens icp_payment;
    
    CMCyclesPositionPurchasePurchaserMessageQuest._({
        required this.cycles_position_id,
        required this.cycles_position_positor,
        required this.cycles_position_xdr_permyriad_per_icp_rate,
        required this.purchase_id,
        required this.purchase_timestamp_nanos,
        required this.icp_payment,
    });
    static CMCyclesPositionPurchasePurchaserMessageQuest oftheRecord(Record r) {
        return CMCyclesPositionPurchasePurchaserMessageQuest._(
            cycles_position_id: (r['cycles_position_id'] as Nat).value,
            cycles_position_positor: (r['cycles_position_positor'] as Principal),
            cycles_position_xdr_permyriad_per_icp_rate: XDRICPRate.oftheXdrPerMyriadPerIcpNat64(r['cycles_position_xdr_permyriad_per_icp_rate'] as Nat64),
            purchase_id: (r['purchase_id'] as Nat).value,
            purchase_timestamp_nanos: (r['purchase_timestamp_nanos'] as Nat).value,
            icp_payment: IcpTokens.oftheRecord(r['icp_payment'] as Record),
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
    static CMMessageCyclesPositionPurchasePurchaserLog oftheRecord(Record r) {
        return CMMessageCyclesPositionPurchasePurchaserLog._(
            timestamp_nanos: (r['timestamp_nanos'] as Nat).value,
            cycles_purchase: Cycles.oftheNat(r['cycles_purchase'] as Nat),
            cm_message_cycles_position_purchase_purchaser_quest: CMCyclesPositionPurchasePurchaserMessageQuest.oftheRecord(r['cm_message_cycles_position_purchase_purchaser_quest'] as Record)
        );
    } 
}


class CMIcpPositionPurchasePositorMessageQuest {
    final BigInt icp_position_id;
    final XDRICPRate icp_position_xdr_permyriad_per_icp_rate;
    final Principal purchaser;
    final BigInt purchase_id;
    final IcpTokens icp_purchase;
    final BigInt purchase_timestamp_nanos;
    CMIcpPositionPurchasePositorMessageQuest._({
        required this.icp_position_id,
        required this.icp_position_xdr_permyriad_per_icp_rate,
        required this.purchaser,
        required this.purchase_id,
        required this.icp_purchase,
        required this.purchase_timestamp_nanos,
    });
    static CMIcpPositionPurchasePositorMessageQuest oftheRecord(Record r) {
        return CMIcpPositionPurchasePositorMessageQuest._(
            icp_position_id: (r['icp_position_id'] as Nat).value, 
            icp_position_xdr_permyriad_per_icp_rate: XDRICPRate.oftheXdrPerMyriadPerIcpNat64(r['icp_position_xdr_permyriad_per_icp_rate'] as Nat64),
            purchaser: (r['purchaser'] as Principal),
            purchase_id: (r['purchase_id'] as Nat).value,
            icp_purchase: IcpTokens.oftheRecord(r['icp_purchase'] as Record),
            purchase_timestamp_nanos: (r['purchase_timestamp_nanos'] as Nat).value,            
        );
    }
}


class CMMessageIcpPositionPurchasePositorLog {
    
    final BigInt timestamp_nanos;
    final Cycles cycles_payment;
    final CMIcpPositionPurchasePositorMessageQuest cm_message_icp_position_purchase_positor_quest;
    
    CMMessageIcpPositionPurchasePositorLog._({
        required this.timestamp_nanos,
        required this.cycles_payment,
        required this.cm_message_icp_position_purchase_positor_quest,
    });
    
    static CMMessageIcpPositionPurchasePositorLog oftheRecord(Record r) {
        return CMMessageIcpPositionPurchasePositorLog._(
            timestamp_nanos: (r['timestamp_nanos'] as Nat).value,
            cycles_payment: Cycles.oftheNat(r['cycles_payment'] as Nat),
            cm_message_icp_position_purchase_positor_quest: CMIcpPositionPurchasePositorMessageQuest.oftheRecord(r['cm_message_icp_position_purchase_positor_quest'] as Record),        
        );
    }
}



class CMIcpPositionPurchasePurchaserMessageQuest {
    final BigInt icp_position_id;
    final BigInt purchase_id; 
    final Principal positor;
    final BigInt purchase_timestamp_nanos;
    final Cycles cycles_payment;
    final XDRICPRate icp_position_xdr_permyriad_per_icp_rate;
    final IcpTokens icp_purchase;
    final BigInt icp_transfer_block_height;
    final BigInt icp_transfer_timestamp_nanos;       

    CMIcpPositionPurchasePurchaserMessageQuest._({
        required this.icp_position_id,
        required this.purchase_id,
        required this.positor,
        required this.purchase_timestamp_nanos,
        required this.cycles_payment,
        required this.icp_position_xdr_permyriad_per_icp_rate,
        required this.icp_purchase,
        required this.icp_transfer_block_height,
        required this.icp_transfer_timestamp_nanos,      
    });

    static CMIcpPositionPurchasePurchaserMessageQuest oftheRecord(Record r) {
        return CMIcpPositionPurchasePurchaserMessageQuest._(
            icp_position_id: (r['icp_position_id'] as Nat).value,  
            purchase_id: (r['purchase_id'] as Nat).value,
            positor: (r['positor'] as Principal),
            purchase_timestamp_nanos: (r['purchase_timestamp_nanos'] as Nat).value,
            cycles_payment: Cycles.oftheNat(r['cycles_payment'] as Nat),
            icp_position_xdr_permyriad_per_icp_rate: XDRICPRate.oftheXdrPerMyriadPerIcpNat64(r['icp_position_xdr_permyriad_per_icp_rate'] as Nat64),
            icp_purchase: IcpTokens.oftheRecord(r['icp_purchase'] as Record),
            icp_transfer_block_height: (r['icp_transfer_block_height'] as Nat64).value,
            icp_transfer_timestamp_nanos: (r['icp_transfer_timestamp_nanos'] as Nat).value,        
        );
    }
}

class CMMessageIcpPositionPurchasePurchaserLog {
    final BigInt timestamp_nanos;
    final CMIcpPositionPurchasePurchaserMessageQuest cm_message_icp_position_purchase_purchaser_quest;
    CMMessageIcpPositionPurchasePurchaserLog._({
        required this.timestamp_nanos,
        required this.cm_message_icp_position_purchase_purchaser_quest,
    });
    static CMMessageIcpPositionPurchasePurchaserLog oftheRecord(Record r) {
        return CMMessageIcpPositionPurchasePurchaserLog._(
            timestamp_nanos: (r['timestamp_nanos'] as Nat).value,
            cm_message_icp_position_purchase_purchaser_quest: CMIcpPositionPurchasePurchaserMessageQuest.oftheRecord(r['cm_message_icp_position_purchase_purchaser_quest'] as Record) 
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
    static CMVoidCyclesPositionPositorMessageQuest oftheRecord(Record r) {
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
    static CMMessageVoidCyclesPositionPositorLog oftheRecord(Record r) {
        return CMMessageVoidCyclesPositionPositorLog._(
            timestamp_nanos: (r['timestamp_nanos'] as Nat).value, 
            void_cycles: Cycles.oftheNat(r['void_cycles'] as Nat),
            cm_message_void_cycles_position_positor_quest: CMVoidCyclesPositionPositorMessageQuest.oftheRecord(r['cm_message_void_cycles_position_positor_quest'] as Record),            
        );
    }
}



class CMVoidIcpPositionPositorMessageQuest {
    final BigInt position_id;
    final IcpTokens void_icp;
    final BigInt timestamp_nanos;
    CMVoidIcpPositionPositorMessageQuest._({
        required this.position_id,
        required this.void_icp,
        required this.timestamp_nanos,
    });
    static CMVoidIcpPositionPositorMessageQuest oftheRecord(Record r) {
        return CMVoidIcpPositionPositorMessageQuest._(
            position_id: (r['position_id'] as Nat).value, 
            void_icp: IcpTokens.oftheRecord(r['void_icp'] as Record),
            timestamp_nanos: (r['timestamp_nanos'] as Nat).value,     
        );
    }
}


class CMMessageVoidIcpPositionPositorLog {
    final BigInt timestamp_nanos;
    final CMVoidIcpPositionPositorMessageQuest cm_message_void_icp_position_positor_quest;
    CMMessageVoidIcpPositionPositorLog._({
        required this.timestamp_nanos,
        required this.cm_message_void_icp_position_positor_quest,
    });
    static CMMessageVoidIcpPositionPositorLog oftheRecord(Record r) {
        return CMMessageVoidIcpPositionPositorLog._(
            timestamp_nanos: (r['timestamp_nanos'] as Nat).value,
            cm_message_void_icp_position_positor_quest: CMVoidIcpPositionPositorMessageQuest.oftheRecord(r['cm_message_void_icp_position_positor_quest'] as Record)        
        );
    }
}






