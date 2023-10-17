import 'dart:math';
import 'dart:typed_data';
import 'dart:async';

import '../config/state.dart';
import '../tools/tools.dart';
import 'package:ic_tools/ic_tools.dart';
import 'package:ic_tools/candid.dart';
import 'package:ic_tools/common.dart';
import 'package:ic_tools/tools.dart';

const int TRADE_LOG_STABLE_MEMORY_SERIALIZE_SIZE = 157; 


class CyclesMarketMain {
    
    CyclesMarketMain();

    List<Icrc1TokenTradeContract> icrc1token_trade_contracts = [];
    List<Icrc1TokenTradeContract> get trade_contracts => this.icrc1token_trade_contracts;
    Future<void> fresh_icrc1token_trade_contracts() async {
        Vector<Record> s = (c_backwards_one(await cycles_market.call(
            calltype: CallType.query,
            method_name: 'view_icrc1_token_trade_contracts',  
        )) as Vector).cast_vector<Record>();
        this.icrc1token_trade_contracts = await Future.wait(s.map((t)=>Icrc1TokenTradeContract.of_the_record(t[0] as Record)));
    }

}
    

class Icrc1TokenTradeContract extends Record {
    final Principal icrc1_ledger_canister_id;
    final Principal trade_contract_canister_id;
    
    final Icrc1Ledger ledger_data;
    
    Icrc1TokenTradeContract({
        required this.icrc1_ledger_canister_id,
        required this.trade_contract_canister_id,
        required this.ledger_data,
    }) {
        this['icrc1_ledger_canister_id'] = this.icrc1_ledger_canister_id; 
        this['trade_contract_canister_id'] = this.trade_contract_canister_id;
    }
    static Future<Icrc1TokenTradeContract> of_the_record(Record r) async {
        Principal icrc1_ledger_canister_id = r['icrc1_ledger_canister_id'] as Principal; 
        // call ledger for the fee and decimals
        Icrc1Ledger ledger_data = await Icrc1Ledger.load(icrc1_ledger_canister_id);        
        return Icrc1TokenTradeContract(
            icrc1_ledger_canister_id: icrc1_ledger_canister_id,
            trade_contract_canister_id: r['trade_contract_canister_id'] as Principal,
            ledger_data: ledger_data
        );
    }
    
    Canister get canister => Canister(this.trade_contract_canister_id);
    
   
    
    
    Future<void> load_positions_and_trades() async {
        await Future.wait([
            this.load_position_book(),
            this.check_new_trades(),
        ]);
    }
    
    
    
    List<PositionBookItem> buy_position_book = [];
    List<PositionBookItem> sell_position_book = [];
    
    Future<void> load_position_book() async {
        await Future.wait([
            Future(()async{
                this.buy_position_book = await load_position_book_(PositionKind.Cycles);        
            }),
            Future(()async{
                this.sell_position_book = await load_position_book_(PositionKind.Token);
            }),            
        ]);
    }
          
    Future<List<PositionBookItem>> load_position_book_(PositionKind kind) async {
        
        List<PositionBookItem> gather = [];
        while (true) {
            ViewPositionBookSponse sponse = ViewPositionBookSponse.of_the_record(c_backwards_one(await this.canister.call(
                calltype: CallType.query,
                method_name: switch (kind) { 
                    PositionKind.Cycles => 'view_cycles_position_book',
                    PositionKind.Token => 'view_tokens_position_book',
                },
                put_bytes: c_forwards([
                    Record.of_the_map({
                        'opt_start_greater_than_rate': Option<Nat>(value: gather.isEmpty ? null : gather.last.rate, value_type: Nat()),
                    })
                ]),
            )) as Record, token_decimal_places: this.ledger_data.decimals);
            
            gather.addAll(sponse.positions_quantities);
            
            if (sponse.is_last_chunk == true) {
                break;
            }
        }
        
        return gather; 
    }
    
    
    List<TradeItem> latest_trades = [];
    
    
    
    Future<void> check_new_trades() async {
        List<TradeItem> gather = [];
        bool catch_up_complete = false;            
        await for (Principal c_id in latest_trades_canisters_generator()) {
            while (true) {
                ViewTradesSponse sponse = await cm_view_latest_trades_(c_id, gather.isEmpty ? null : gather.first.id);
                gather = [
                    ...sponse.trades_data,  
                    ...gather
                ];
                if (this.latest_trades.isNotEmpty && gather.first.id <= this.latest_trades.last.id) {
                    gather = gather.skipWhile((e)=>e.id <= this.latest_trades.last.id).toList();
                    catch_up_complete = true;
                    break;
                }   
                if (this.latest_trades.isEmpty && gather.length >= 500) {
                    catch_up_complete = true;
                    break;
                }  
                if (sponse.is_last_chunk_on_this_canister == true) {
                    break;
                }
            }
            if (catch_up_complete) {
                break;
            }
        }
        this.latest_trades.addAll(gather);
    }
    
    List<StorageCanister> trades_scs_cache = [];
    
    Future<void> load_trades_back_chunk() async {
        if (this.latest_trades.isEmpty) {
            await this.check_new_trades();
            return;
        }
        if (this.latest_trades.first.id == BigInt.from(0)) {
            return;
        }
        Principal? call_canister_id;
        if (trades_scs_cache.isEmpty || trades_scs_cache.last.first_log_id + trades_scs_cache.last.length < this.latest_trades.first.id) {
            trades_scs_cache = await this.view_trades_storage_canisters();
        }
        for (StorageCanister sc in trades_scs_cache) {
            if (this.latest_trades.first.id > sc.first_log_id && this.latest_trades.first.id <= sc.first_log_id + sc.length) {
                call_canister_id = sc.canister_id;
            }
        }
        if (call_canister_id == null) {
            call_canister_id = this.trade_contract_canister_id;
        }
        ViewTradesSponse sponse = await cm_view_latest_trades_(call_canister_id, this.latest_trades.first.id);
        this.latest_trades = [
            ...sponse.trades_data,
            ...this.latest_trades
        ];
    }
    
    Stream<Principal> latest_trades_canisters_generator() async* {
        yield this.trade_contract_canister_id;
        List<StorageCanister> trades_scs = await this.view_trades_storage_canisters();
        print('trades-storage-canisters: $trades_scs');
        trades_scs_cache = trades_scs;
        for (StorageCanister sc in trades_scs.reversed) {
            yield sc.canister_id;
        } 
    }
    
    Future<ViewTradesSponse> cm_view_latest_trades_(Principal c_id, [BigInt? opt_start_before_id]) async {
        return ViewTradesSponse.of_the_record(c_backwards_one(await Canister(c_id).call(
            calltype: CallType.query,
            method_name: 'view_latest_trades',
            put_bytes: c_forwards([
                Record.of_the_map({
                    'opt_start_before_id': Option<Nat>(value: opt_start_before_id.nullmap((id)=>Nat(id)), value_type: Nat()),
                })
            ]),            
        )) as Record, token_decimal_places: this.ledger_data.decimals);
    }
        
    
    Future<List<StorageCanister>> view_positions_storage_canisters() async {
        return (c_backwards_one(await this.canister.call(
            method_name: 'view_positions_storage_canisters',
            calltype: CallType.query,
        )) as Vector).cast_vector<Record>().map<StorageCanister>((r) => StorageCanister.of_the_record(r)).toList();
    }
    
    Future<List<StorageCanister>> view_trades_storage_canisters() async {
        return (c_backwards_one(await this.canister.call(
            method_name: 'view_trades_storage_canisters',
            calltype: CallType.query,
        )) as Vector).cast_vector<Record>().map<StorageCanister>((r) => StorageCanister.of_the_record(r)).toList();
    }
}



typedef PositionBookItem = ({CyclesPerTokenRate rate, BigInt quantity}); 


class ViewPositionBookSponse {
        
    final List<PositionBookItem> positions_quantities; 
    final bool is_last_chunk;
    ViewPositionBookSponse._({
        required this.positions_quantities,
        required this.is_last_chunk,
    });
    static ViewPositionBookSponse of_the_record(Record r, {required int token_decimal_places}) {
        return ViewPositionBookSponse._(
            positions_quantities: (r['positions_quantities'] as Vector).cast_vector<Record>()
                .map((item){
                    return (
                        rate: CyclesPerTokenRate(
                            cycles_per_token_quantum_rate: (item[0] as Nat).value,
                            token_decimal_places: token_decimal_places,
                        ),
                        quantity: (item[1] as Nat).value,
                    );
                }).toList(),
            is_last_chunk: (r['is_last_chunk'] as Bool).value,
        );
    }
}

typedef TradeItem = ({BigInt id, Tokens quantity, CyclesPerTokenRate rate, BigInt time_nanos, PositionKind kind});

class ViewTradesSponse {
        
    final List<TradeItem> trades_data; 
    final bool is_last_chunk_on_this_canister;

    ViewTradesSponse._({
        required this.trades_data,
        required this.is_last_chunk_on_this_canister,
    });
    static ViewTradesSponse of_the_record(Record r, {required int token_decimal_places}) {
        return ViewTradesSponse._(
            trades_data: (r['trades_data'] as Vector).cast_vector<Record>()
                .map((item){
                    return (
                        id: (item[0] as Nat).value,
                        quantity: Tokens(quantums: (item[1] as Nat).value, decimal_places: token_decimal_places),
                        rate: CyclesPerTokenRate(
                            cycles_per_token_quantum_rate: (item[2] as Nat).value,
                            token_decimal_places: token_decimal_places,
                        ),
                        time_nanos: (item[3] as Nat64).value,
                        kind: match_variant(item[4] as Variant, { for (var k in PositionKind.values) k.name: (n)=>k })
                    );
                }).toList(),
            is_last_chunk_on_this_canister: (r['is_last_chunk_on_this_canister'] as Bool).value,
        );
    }
}

enum PositionTerminationCause {
    Fill, // the position is fill[ed]. position.amount < minimum_token_match()
    Bump, // the position got bumped
    TimePass, // expired
    UserCallVoidPosition, // t
}

class PositionTerminationData {
    BigInt timestamp_nanos;
    PositionTerminationCause cause;
    PositionTerminationData._({
        required this.timestamp_nanos,
        required this.cause, 
    });
}


class PositionLog {
    final BigInt id;
    Principal positor;
    CreatePositionQuestLog quest;
    PositionKind position_kind;
    BigInt mainder_position_quantity; // if cycles position this is: Cycles, if Token position this is: Tokens.
    BigInt fill_quantity; // if mainder_position_quantity is: Cycles, this is: Tokens. if mainder_position_quantity is: Tokens, this is Cycles.
    CyclesPerTokenRate fill_average_rate;
    BigInt payouts_fees_sum; // // if cycles-position this is: Tokens, if token-position this is: Cycles.
    BigInt creation_timestamp_nanos;
    PositionTerminationData? position_termination;
    
    //BigInt trade_log_ids
    
    PositionLog._({
        required this.id,
        required this.positor,
        required this.quest,
        required this.position_kind,
        required this.mainder_position_quantity, // if cycles position this is: Cycles, if Token position this is: Tokens.
        required this.fill_quantity, // if mainder_position_quantity is: Cycles, this is: Tokens. if mainder_position_quantity is: Tokens, this is Cycles.
        required this.fill_average_rate,
        required this.payouts_fees_sum, // // if cycles-position this is: Tokens, if token-position this is: Cycles.
        required this.creation_timestamp_nanos,
        required this.position_termination,
    });
    
    static int STABLE_MEMORY_SERIALIZE_SIZE = 163;
    
    static PositionLog oftheStableMemorySerialization(Uint8List bytes, {required int token_decimal_places}) {
        PositionTerminationData? termination;
        if (bytes[153] == 1) {
            termination = PositionTerminationData._(
                timestamp_nanos: bigint_of_the_be_bytes(bytes.getRange(154, 162)),
                cause: switch (bytes[162]) {
                    0 => PositionTerminationCause.Fill,
                    1 => PositionTerminationCause.Bump,
                    2 => PositionTerminationCause.TimePass,
                    3 => PositionTerminationCause.UserCallVoidPosition,
                    _ => throw Exception('unknown PositionTerminationCause serialization.')
                }
            );
        }
        return PositionLog._(
            id: u128_of_the_be_bytes(bytes.getRange(2, 18)),
            positor: principal_of_the_30_bytes(bytes.getRange(18, 48)),
            quest: CreatePositionQuestLog(
                quantity: u128_of_the_be_bytes(bytes.getRange(48, 64)),
                cycles_per_token_rate: CyclesPerTokenRate(cycles_per_token_quantum_rate: u128_of_the_be_bytes(bytes.getRange(64, 80)), token_decimal_places:token_decimal_places),
            ),
            position_kind: bytes[80] == 0 ? PositionKind.Cycles : PositionKind.Token,
            mainder_position_quantity: u128_of_the_be_bytes(bytes.getRange(81, 97)), // if cycles position this is: Cycles, if Token position this is: Tokens.
            fill_quantity: u128_of_the_be_bytes(bytes.getRange(97, 113)), // if mainder_position_quantity is: Cycles, this is: Tokens. if mainder_position_quantity is: Tokens, this is Cycles.
            fill_average_rate: CyclesPerTokenRate(
                cycles_per_token_quantum_rate: u128_of_the_be_bytes(bytes.getRange(113, 129)),
                token_decimal_places:token_decimal_places,
            ),
            payouts_fees_sum: u128_of_the_be_bytes(bytes.getRange(129, 145)), // // if cycles-position this is: Tokens, if token-position this is: Cycles.
            creation_timestamp_nanos: bigint_of_the_be_bytes(bytes.getRange(145, 153)),
            position_termination: termination,
        );
    }
}










class StorageCanister {
    final BigInt first_log_id;
    final BigInt length;
    final int log_size;
    final Principal canister_id;
    StorageCanister._({
        required this.first_log_id,
        required this.length,
        required this.log_size,
        required this.canister_id,
    });
    static StorageCanister of_the_record(Record r) {
        return StorageCanister._(
            first_log_id: (r['first_log_id'] as Nat).value,
            length: (r['length'] as Nat).value,
            log_size: (r['log_size'] as Nat32).value,
            canister_id: r['canister_id'] as Principal,
        );
    }
    String toString() => 'StorageCanister: $canister_id';
}




abstract class Icrc1TokenTradeContractPosition {
    BigInt get id;
    Principal get positor;
    TradeQuest get quest;
    CyclesPerTokenRate get cycles_per_token_rate => this.quest.cycles_per_token_rate;
    BigInt get timestamp_nanos;
    
    Cycles get cycles_quantity;
    BigInt get tokens_quantity;
}


class CyclesPosition implements Icrc1TokenTradeContractPosition {
    final BigInt id;   
    final Principal positor;
    final TradeCyclesQuest quest;
    final Cycles current_position_cycles;
    final BigInt purchases_rates_times_cycles_quantities_sum;
    final Tokens tokens_payouts_fees_sum;
    final BigInt timestamp_nanos;
    
    Cycles get cycles_quantity => this.current_position_cycles;
    BigInt get tokens_quantity => cycles_transform_tokens(this.current_position_cycles, this.quest.cycles_per_token_rate);
    CyclesPerTokenRate get cycles_per_token_rate => quest.cycles_per_token_rate;
    
    CyclesPosition._({
        required this.id,   
        required this.positor,
        required this.quest,
        required this.current_position_cycles,
        required this.purchases_rates_times_cycles_quantities_sum,
        required this.tokens_payouts_fees_sum,
        required this.timestamp_nanos,
    });
    static CyclesPosition of_the_record(Record r, {required int token_decimal_places}) {
        return CyclesPosition._(
            id: (r['id'] as Nat).value,
            positor: r['positor'] as Principal,
            quest: TradeCyclesQuest.of_the_record(r['quest'] as Record, token_decimal_places: token_decimal_places),
            current_position_cycles: Cycles.oftheNat(r['current_position_cycles'] as Nat),
            purchases_rates_times_cycles_quantities_sum: (r['purchases_rates_times_cycles_quantities_sum'] as Nat).value, 
            tokens_payouts_fees_sum: Tokens(quantums: (r['tokens_payouts_fees_sum'] as Nat).value, decimal_places: token_decimal_places),
            timestamp_nanos: (r['timestamp_nanos'] as Nat).value
        );
    }
}


class TokenPosition implements Icrc1TokenTradeContractPosition {
    final BigInt id;   
    final Principal positor;
    final TradeTokensQuest quest;    
    final Tokens current_position_tokens;
    final BigInt purchases_rates_times_token_quantities_sum;
    final Cycles cycles_payouts_fees_sum;
    final BigInt timestamp_nanos;
    
    Cycles get cycles_quantity => tokens_transform_cycles(this.current_position_tokens.quantums, this.quest.cycles_per_token_rate);
    BigInt get tokens_quantity => this.current_position_tokens.quantums;
    CyclesPerTokenRate get cycles_per_token_rate => quest.cycles_per_token_rate;
    
    TokenPosition._({
        required this.id,
        required this.positor,
        required this.quest,
        required this.current_position_tokens,
        required this.purchases_rates_times_token_quantities_sum,
        required this.cycles_payouts_fees_sum,
        required this.timestamp_nanos,
    });
    static TokenPosition of_the_record(Record r, {required int token_decimal_places}) {
        return TokenPosition._(
            id: (r['id'] as Nat).value,
            positor: r['positor'] as Principal,
            quest: TradeTokensQuest.of_the_record(r['quest'] as Record, token_decimal_places: token_decimal_places),            
            current_position_tokens: Tokens(quantums: (r['current_position_tokens'] as Nat).value, decimal_places: token_decimal_places),
            purchases_rates_times_token_quantities_sum: (r['purchases_rates_times_token_quantities_sum'] as Nat).value, 
            cycles_payouts_fees_sum: Cycles.oftheNat(r['cycles_payouts_fees_sum'] as Nat),
            timestamp_nanos: (r['timestamp_nanos'] as Nat).value
        );
    }
}


abstract class TradeQuest {
    CyclesPerTokenRate get cycles_per_token_rate;
}

class TradeCyclesQuest extends Record implements TradeQuest {
    final Cycles cycles;
    final CyclesPerTokenRate cycles_per_token_rate;
    TradeCyclesQuest({
        required this.cycles,
        required this.cycles_per_token_rate,
    }) {
        this['cycles'] = this.cycles;
        this['cycles_per_token_rate'] = this.cycles_per_token_rate;
    }
    static TradeCyclesQuest of_the_record(Record r, {required int token_decimal_places}) {
        return TradeCyclesQuest(
            cycles: Cycles.oftheNat(r['cycles'] as Nat),
            cycles_per_token_rate: CyclesPerTokenRate(
                cycles_per_token_quantum_rate: (r['cycles_per_token_rate'] as Nat).value,
                token_decimal_places: token_decimal_places
            )
        );
    }
}
class TradeTokensQuest extends Record implements TradeQuest {
    final Tokens tokens;
    final CyclesPerTokenRate cycles_per_token_rate;
    TradeTokensQuest({
        required this.tokens,
        required this.cycles_per_token_rate,
    }) {
        this['tokens'] = this.tokens;
        this['cycles_per_token_rate'] = this.cycles_per_token_rate;
    }
    static TradeTokensQuest of_the_record(Record r, {required int token_decimal_places}) {
        return TradeTokensQuest(
            tokens: Tokens(quantums: (r['tokens'] as Nat).value, decimal_places: token_decimal_places),
            cycles_per_token_rate: CyclesPerTokenRate(
                cycles_per_token_quantum_rate: (r['cycles_per_token_rate'] as Nat).value,
                token_decimal_places: token_decimal_places
            )
        );
    }
}


class CreatePositionQuestLog {
    final BigInt quantity;
    final CyclesPerTokenRate cycles_per_token_rate;
    CreatePositionQuestLog({
        required this.quantity,
        required this.cycles_per_token_rate,
    });
    /*
    static CreatePositionQuestLog of_the_record(Record r, {required int token_decimal_places}) {
        return CreatePositionQuestLog(
            quantity: (r['quantity'] as Nat).value,
            cycles_per_token_rate: CyclesPerTokenRate(
                cycles_per_token_quantum_rate: (r['cycles_per_token_rate'] as Nat).value,
                token_decimal_places: token_decimal_places
            )
        );
    } 
    */
}


DateTime datetime_of_the_nanos(BigInt nanos) => DateTime.fromMillisecondsSinceEpoch(milliseconds_of_the_nanos(nanos).toInt());

class TradeLog {

    final BigInt position_id;
    final BigInt id;
    final Principal positor;
    final Principal purchaser;
    final BigInt tokens;
    final Cycles cycles;
    final CyclesPerTokenRate cycles_per_token_rate;
    final PositionKind position_kind;
    final BigInt timestamp_nanos;
    /*
    final BigInt tokens_payout_fee;
    final BigInt tokens_payout_ledger_transfer_fees_sum;
    final Cycles cycles_payout_fee;
    */
    final bool? cycles_payout_lock;
    final bool? token_payout_lock;
    final Record? cycles_payout_data;
    final Record? token_payout_data;
    
    DateTime datetime() => datetime_of_the_nanos(timestamp_nanos);
    
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
    static TradeLog of_the_record(Record r, {required int token_decimal_places}) {
        return TradeLog._(
            position_id: (r['position_id'] as Nat).value,
            id: (r['id'] as Nat).value,
            positor: (r['positor'] as Principal),
            purchaser: r['purchaser'] as Principal,
            tokens: (r['tokens'] as Nat).value,
            cycles: Cycles.oftheNat(r['cycles'] as Nat),
            cycles_per_token_rate: CyclesPerTokenRate(cycles_per_token_quantum_rate: (r['cycles_per_token_rate'] as Nat).value, token_decimal_places: token_decimal_places),
            position_kind: (r['position_kind'] as Variant).containsKey(PositionKind.Cycles.name) ? PositionKind.Cycles : PositionKind.Token,
            timestamp_nanos: (r['timestamp_nanos'] as Nat).value,
            cycles_payout_lock: (r['cycles_payout_lock'] as Bool).value,
            token_payout_lock: (r['token_payout_lock'] as Bool).value,
            cycles_payout_data: (r['cycles_payout_data'] as Record),
            token_payout_data: (r['token_payout_data'] as Record),
        );
    }
    static TradeLog oftheStableMemorySerialization(Uint8List bytes, {required int token_decimal_places}) {
        return TradeLog._(
            position_id: u128_of_the_be_bytes(bytes.getRange(0, 16)),
            id: u128_of_the_be_bytes(bytes.getRange(16, 32)),
            positor: principal_of_the_30_bytes(bytes.getRange(32, 62)),
            purchaser: principal_of_the_30_bytes(bytes.getRange(62, 92)),
            tokens: u128_of_the_be_bytes(bytes.getRange(92, 108)),
            cycles: Cycles(cycles: u128_of_the_be_bytes(bytes.getRange(108, 124))),
            cycles_per_token_rate: CyclesPerTokenRate(cycles_per_token_quantum_rate: u128_of_the_be_bytes(bytes.getRange(124, 140)), token_decimal_places: token_decimal_places),
            position_kind: bytes[140] == 0 ? PositionKind.Cycles : PositionKind.Token,
            timestamp_nanos: u128_of_the_be_bytes(bytes.getRange(141, 157)),
        );
    }
}


enum PositionKind {
    Cycles,
    Token
}

