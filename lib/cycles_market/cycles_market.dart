import 'dart:math';
import 'dart:typed_data';

import '../config/state.dart';

import 'package:ic_tools/ic_tools.dart';
import 'package:ic_tools/candid.dart';
import 'package:ic_tools/common.dart';
import 'package:ic_tools/tools.dart';
import 'package:ic_tools_web/ic_tools_web.dart' show NullMap;

const int TRADE_LOG_STABLE_MEMORY_SERIALIZE_SIZE = 157; 


class CyclesMarketMain {
    
    CyclesMarketMain();

    List<Icrc1TokenTradeContract> icrc1token_trade_contracts = [];
    
    Future<void> fresh_icrc1token_trade_contracts() async {
        List<CandidType> s = c_backwards(await cycles_market.call(
            calltype: CallType.query,
            method_name: 'view_icrc1_token_trade_contracts',  
        ));
        Vector<Record> cs = (s.first as Vector).cast_vector<Record>();
        this.icrc1token_trade_contracts = await Future.wait(cs.map(Icrc1TokenTradeContract.oftheRecord));
    }

}
    

class Icrc1TokenTradeContract extends Record {
    final Principal icrc1_ledger_canister_id;
    final Principal trade_contract_canister_id;
    final Principal? opt_cm_caller;
    
    final Icrc1Ledger ledger_data;
    
    Icrc1TokenTradeContract({
        required this.icrc1_ledger_canister_id,
        required this.trade_contract_canister_id,
        required this.opt_cm_caller,
        required this.ledger_data,
    }) {
        this['icrc1_ledger_canister_id'] = this.icrc1_ledger_canister_id; 
        this['trade_contract_canister_id'] = this.trade_contract_canister_id;
        this['opt_cm_caller'] = Option(value: this.opt_cm_caller, value_type: PrincipalReference(isTypeStance:true));
    }
    static Future<Icrc1TokenTradeContract> oftheRecord(Record r) async {
        Principal icrc1_ledger_canister_id = r['icrc1_ledger_canister_id'] as Principal; 
        // call ledger for the fee and decimals
        Icrc1Ledger ledger_data = await Icrc1Ledger.load(icrc1_ledger_canister_id);        
        return Icrc1TokenTradeContract(
            icrc1_ledger_canister_id: icrc1_ledger_canister_id,
            trade_contract_canister_id: r['trade_contract_canister_id'] as Principal,
            opt_cm_caller: r.find_option<PrincipalReference>('opt_cm_caller').nullmap((pr)=>pr.principal!),
            ledger_data: ledger_data
        );
    }
    
    Canister get canister => Canister(this.trade_contract_canister_id);
    
    // ------
    
    List<CyclesPosition> cycles_positions = [];
    List<TokenPosition> token_positions = [];
    
    Future<void> load_cycles_positions() async {
        this.cycles_positions = await _load_positions_mechanism(
            method_name: 'view_cycles_positions',
            function: CyclesPosition.oftheRecord
        );
    }
    
    Future<void> load_token_positions() async {
        this.token_positions = await _load_positions_mechanism(
            method_name: 'view_token_positions',
            function: TokenPosition.oftheRecord
        );
    }
    
    Future<void> load_positions() async {
        await Future.wait([
            this.load_cycles_positions(),
            this.load_token_positions(),
        ]);
    }

    Future<List<T>> _load_positions_mechanism<T extends Icrc1TokenTradeContractPosition>({
        required String method_name,
        required T Function(Record) function
    }) async {
        List<T> list = [];
        BigInt? start_after_position;
        while (true) {
            Record r = c_backwards(await Canister(this.trade_contract_canister_id).call(
                calltype: CallType.query,
                method_name: method_name,
                put_bytes: c_forwards([
                    Record.oftheMap({
                        'opt_start_after_position_id': Option<Nat>(value: start_after_position.nullmap((n)=>Nat(n)), value_type: Nat())
                    })
                ])
            )).first as Record;
            Vector<Record> positions = (r['positions'] as Vector).cast_vector<Record>();
            if (positions.length == 0) {
                break;
            }
            list.addAll(positions.map<T>(function));
            if ((r['is_last_chunk'] as Bool).value == true) {
                break;
            }
            start_after_position = list.last.id;
        }
        return list;
    }
    
    // ----------------------
    
    List<TradeLog> trade_logs = [];
    Future<void>? load_trade_logs_future;
    
    
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
        // take into the count logs that are saved in this class
        // call to make sure to get new logs but stop when logs catch up with what we have by the last time.
        // as of now the function overwrites any logs saved
        // 
        
        
        List<StorageCanister> storage_canisters = [];
        
        BigInt last_known_trade_log_id = this.trade_logs.isNotEmpty ? this.trade_logs.last.id : BigInt.from(-1);
        List<TradeLog> gather_trade_logs = [];
        
        // call trade_contract_canister_id
        BigInt? opt_start_before_id;
        while (true) {
            Record s = c_backwards(await Canister(this.trade_contract_canister_id).call(
                calltype: CallType.query,
                method_name: 'view_trade_logs',
                put_bytes: c_forwards([
                    Record.oftheMap({
                        'opt_start_before_id': Option<Nat>(value: opt_start_before_id.nullmap((n)=>Nat(n)), value_type: Nat()),
                    })
                ]),
            )).first as Record;
            
            //BigInt latest_trade_log_id = (s['trade_logs_len'] as Nat).value - BigInt.from(1);
            
            storage_canisters = ((s['storage_canisters'] as Vector).cast_vector<Record>()).map(StorageCanister.oftheRecord).toList();
            
            Uint8List logs = (s['logs'] as Blob).bytes;
            
            if (logs.length == 0) {
                break;
            }
            
            gather_trade_logs = [
                ...logs.chunks(TRADE_LOG_STABLE_MEMORY_SERIALIZE_SIZE).map(TradeLog.oftheStableMemorySerialization),
                ...gather_trade_logs
            ];
            
            if (gather_trade_logs.first.id <= last_known_trade_log_id) {
                this.trade_logs.addAll(
                    gather_trade_logs.skipWhile((l)=> l.id <= last_known_trade_log_id)
                );
                return;
            }
                        
            if (
                storage_canisters.isNotEmpty 
                && storage_canisters.last.first_log_id + storage_canisters.last.length == gather_trade_logs.first.id
            ) {
                break; // :move-on for the querying of the storage-canisters.
            }
            
            opt_start_before_id = gather_trade_logs.first.id;
            
        }
        
        // call the storage canisters
        const int quest_for_the_logs_general_chunk_length = (1024*1024 + 1024*512) ~/ TRADE_LOG_STABLE_MEMORY_SERIALIZE_SIZE; 

        for (StorageCanister storage_canister in storage_canisters.reversed) {

            int checkpoint_length = storage_canister.length.toInt();
            while (true) {
                int quest_length = min(quest_for_the_logs_general_chunk_length, checkpoint_length);
                BigInt start_at_id = (storage_canister.first_log_id + BigInt.from(checkpoint_length)) - BigInt.from(quest_length);
                
                Record s = c_backwards(await Canister(storage_canister.canister_id).call(
                    calltype: CallType.query,
                    method_name: storage_canister.view_trade_logs_method_name,
                    put_bytes: c_forwards([
                        Record.oftheMap({
                            'start_id': Nat(start_at_id),
                            'length': Nat(BigInt.from(quest_length)),
                        })
                    ])
                )).first as Record;
                
                Uint8List logs = (s['logs'] as Blob).bytes;
                
                gather_trade_logs = [
                    ...logs.chunks(TRADE_LOG_STABLE_MEMORY_SERIALIZE_SIZE).map(TradeLog.oftheStableMemorySerialization), 
                    ...gather_trade_logs
                ];
                
                if (gather_trade_logs.first.id <= last_known_trade_log_id) {
                    this.trade_logs.addAll(
                        gather_trade_logs.skipWhile((l)=> l.id <= last_known_trade_log_id)
                    );
                    return;
                }
                
                checkpoint_length -= quest_length;
                
                if (start_at_id == storage_canister.first_log_id /*checkpoint_length == 0*/) {
                    break;
                }
            
            }
            
        }
        
        // only happens on the first load
        this.trade_logs = gather_trade_logs; 
        
    }
    
    // --------
    
    Future<void> load_positions_and_trade_logs() async {
        await Future.wait([
            this.load_positions(),
            this.load_trade_logs(),
        ]);
    }
    
    
}


class StorageCanister {
    final BigInt first_log_id;
    final BigInt length;
    final int log_size;
    final Principal canister_id;
    final String view_trade_logs_method_name;
    StorageCanister._({
        required this.first_log_id,
        required this.length,
        required this.log_size,
        required this.canister_id,
        required this.view_trade_logs_method_name,
    });
    static StorageCanister oftheRecord(Record r) {
        FunctionReference callback = r['callback'] as FunctionReference;
        return StorageCanister._(
            first_log_id: (r['first_log_id'] as Nat).value,
            length: (r['length'] as Nat).value,
            log_size: (r['log_size'] as Nat32).value,
            canister_id: Principal.oftheBytes(callback.service!.id!.bytes),
            view_trade_logs_method_name: callback.method_name!.value
        );
    }
}




abstract class Icrc1TokenTradeContractPosition {
    BigInt get id;
    Principal get positor;
    BigInt get cycles_per_token_rate;
    BigInt get timestamp_nanos;
}


class CyclesPosition implements Icrc1TokenTradeContractPosition {
    final BigInt id;   
    final Principal positor;
    final Cycles cycles;
    final Cycles minimum_purchase;
    final BigInt cycles_per_token_rate;
    final BigInt timestamp_nanos;
    CyclesPosition._({
        required this.id,   
        required this.positor,
        required this.cycles,
        required this.minimum_purchase,
        required this.cycles_per_token_rate,
        required this.timestamp_nanos,
    });
    static CyclesPosition oftheRecord(Record r) {
        return CyclesPosition._(
            id: (r['id'] as Nat).value,
            positor: r['positor'] as Principal,
            cycles: Cycles.oftheNat(r['cycles'] as Nat),
            minimum_purchase: Cycles.oftheNat(r['minimum_purchase'] as Nat),
            cycles_per_token_rate: (r['cycles_per_token_rate'] as Nat).value, 
            timestamp_nanos: (r['timestamp_nanos'] as Nat).value
        );
    }
}


class TokenPosition implements Icrc1TokenTradeContractPosition {
    final BigInt id;   
    final Principal positor;
    final BigInt tokens;
    final BigInt minimum_purchase;
    final BigInt cycles_per_token_rate;
    final BigInt timestamp_nanos;
    TokenPosition._({
        required this.id,
        required this.positor,
        required this.tokens,
        required this.minimum_purchase,
        required this.cycles_per_token_rate,
        required this.timestamp_nanos
    });
    static TokenPosition oftheRecord(Record r) {
        return TokenPosition._(
            id: (r['id'] as Nat).value,
            positor: r['positor'] as Principal,
            tokens: (r['tokens'] as Nat).value,
            minimum_purchase: (r['minimum_purchase'] as Nat).value,
            cycles_per_token_rate: (r['cycles_per_token_rate'] as Nat).value, 
            timestamp_nanos: (r['timestamp_nanos'] as Nat).value
        );
    }
}



class TradeLog {

    final BigInt position_id;
    final BigInt id;
    final Principal positor;
    final Principal purchaser;
    final BigInt tokens;
    final Cycles cycles;
    final BigInt cycles_per_token_rate;
    final PositionKind position_kind;
    final BigInt timestamp_nanos;
    final bool? cycles_payout_lock;
    final bool? token_payout_lock;
    final Record? cycles_payout_data;
    final Record? token_payout_data;
    
    TradeLog._({
        required this.position_id,
        required this.id,
        required this.positor,
        required this.purchaser,
        required this.tokens,
        required this.cycles,
        required this.cycles_per_token_rate,
        required this.position_kind,
        required this.timestamp_nanos,
        this.cycles_payout_lock,
        this.token_payout_lock,
        this.cycles_payout_data,
        this.token_payout_data,
    });
    static TradeLog oftheRecord(Record r) {
        return TradeLog._(
            position_id: (r['position_id'] as Nat).value,
            id: (r['id'] as Nat).value,
            positor: (r['positor'] as Principal),
            purchaser: r['purchaser'] as Principal,
            tokens: (r['tokens'] as Nat).value,
            cycles: Cycles.oftheNat(r['cycles'] as Nat),
            cycles_per_token_rate: (r['cycles_per_token_rate'] as Nat).value,
            position_kind: (r['position_kind'] as Variant).containsKey(PositionKind.Cycles.name) ? PositionKind.Cycles : PositionKind.Token,
            timestamp_nanos: (r['timestamp_nanos'] as Nat).value,
            cycles_payout_lock: (r['cycles_payout_lock'] as Bool).value,
            token_payout_lock: (r['token_payout_lock'] as Bool).value,
            cycles_payout_data: (r['cycles_payout_data'] as Record),
            token_payout_data: (r['token_payout_data'] as Record),
        );
    }
    static TradeLog oftheStableMemorySerialization(Uint8List bytes) {
        return TradeLog._(
            position_id: u128_of_the_be_bytes(bytes.getRange(0, 16)),
            id: u128_of_the_be_bytes(bytes.getRange(16, 32)),
            positor: principal_of_the_30_bytes(bytes.getRange(32, 62)),
            purchaser: principal_of_the_30_bytes(bytes.getRange(62, 92)),
            tokens: u128_of_the_be_bytes(bytes.getRange(92, 108)),
            cycles: Cycles(cycles: u128_of_the_be_bytes(bytes.getRange(108, 124))),
            cycles_per_token_rate: u128_of_the_be_bytes(bytes.getRange(124, 140)),
            position_kind: bytes[140] == 0 ? PositionKind.Cycles : PositionKind.Token,
            timestamp_nanos: u128_of_the_be_bytes(bytes.getRange(141, 157)),
        );
    }
}


enum PositionKind {
    Cycles,
    Token
}

// helpers

Principal principal_of_the_30_bytes(Iterable<int> b) {
    List<int> blist = b.toList();
    return Principal.oftheBytes(Uint8List.fromList(blist.getRange(1, blist[0] + 1).toList()));
}

BigInt u128_of_the_be_bytes(Iterable<int> bytes) {
    return BigInt.parse(bytes_as_the_bitstring(bytes), radix: 2);
}

String bytes_as_the_bitstring(Iterable<int> bytes) {
    String bitstring = '';
    for (int byte in bytes) {
        String byte_bitstring = byte.toRadixString(2);
        while (byte_bitstring.length < 8) { byte_bitstring = '0' + byte_bitstring; }
        bitstring = bitstring + byte_bitstring;
    }
    return bitstring;
}



extension Chunks<T extends List> on T {
    List<T> chunks(int chunk_size) {
        var b_len = this.length;
        List<T> chunks = [];
        for(int i = 0; i < b_len; i += chunk_size) {    
            chunks.add(this.sublist(i,min(i+chunk_size, b_len)) as T);
        }
        return chunks;
    }
} 
