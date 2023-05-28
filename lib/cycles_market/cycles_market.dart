


import '../config/state.dart';

import 'package:ic_tools/ic_tools.dart';
import 'package:ic_tools/candid.dart';
import 'package:ic_tools/common.dart';



class CyclesMarketMain {
    
    CyclesMarketMain();

    List<Icrc1TokenTradeContract> icrc1token_trade_contracts = [];
    
    Future<void> fresh_icrc1token_trade_contracts() async {
        List<CandidType> s = await cycles_market.call(
            calltype: CallType.query,
            method_name: 'view_icrc1_token_trade_contracts',  
        );
        Vector<Record> cs = (s.first as Vector).cast_vector<Record>();
        this.icrc1token_trade_contracts = cs.map(Icrc1TokenTradeContract.oftheRecord).toList();
    }

}
    

class Icrc1TokenTradeContract {
    final Principal icrc1_ledger_canister_id;
    final Principal trade_contract_canister_id;
    final Principal? opt_cm_caller;
    Icrc1TokenTradeContract({
        required this.icrc1_ledger_canister_id,
        required this.trade_contract_canister_id,
        required this.opt_cm_caller
    });
    static Icrc1TokenTradeContract oftheRecord(Record r) {
        return Icrc1TokenTradeContract(
            icrc1_ledger_canister_id: r['icrc1_ledger_canister_id'] as Principal,
            trade_contract_canister_id: r['trade_contract_canister_id'] as Principal,
            opt_cm_caller: r['opt_cm_caller'].asOption<PrincipalReference>().value.nullmap((pr)=>pr.principal!);
        );
    }
    
    // ------
    
    List<CyclesPosition> cycles_positions = [];
    List<TokenPosition> token_positions = [];
    List<TradeLog> trade_logs = [];
    
    
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

    Future<void> load_trade_logs() async {
        // START HERE!
    }
    
    

    Future<List<T>> _load_positions_mechanism<T>({
        required String method_name,
        required T Function(Record) function
    }) async {
        List<T> list = [];
        BigInt? start_after_position;
        while (true) {
            Record r = c_backwards(await this.trade_contract_canister_id.call(
                calltype: CallType.query,
                method_name: method_name,
                put_bytes: c_forwards([
                    Record.oftheMap({
                        'opt_start_after_position_id': Option<Nat>(value: start_after_position, value_type: Nat())
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
    final bool cycles_payout_lock;
    final bool token_payout_lock;
    final Record cycles_payout_data;
    final Record token_payout_data;
    
    CyclesPositionPurchase._({
        required this.position_id,
        required this.id,
        required this.positor,
        required this.purchaser,
        required this.tokens,
        required this.cycles,
        required this.cycles_per_token_rate,
        required this.position_kind,
        required this.timestamp_nanos,
        required this.cycles_payout_lock,
        required this.icp_payout_lock,
        required this.cycles_payout_data,
        required this.icp_payout_data,
    });
    static CyclesPositionPurchase oftheRecord(Record r) {
        return CyclesPositionPurchase._(
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
            icp_payout_lock: (r['icp_payout_lock'] as Bool).value,
            cycles_payout_data: (r['cycles_payout_data'] as Record),
            icp_payout_data: (r['icp_payout_data'] as Record),
        );
    }
}


enum PositionKind {
    Cycles,
    Token
}
