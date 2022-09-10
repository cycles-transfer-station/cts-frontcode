


import 'state.dart';
import 'package:ic_tools/ic_tools.dart';
import 'package:ic_tools/candid.dart';



class CyclesMarketData {
    List<CyclesPosition> cycles_positions = [];
    List<IcpPosition> icp_positions = [];
    List<CyclesPositionPurchase> cycles_positions_purchases = [];
    List<IcpPositionPurchase> icp_positions_purchases = [];
    
    CyclesMarketData();
    
    
    Future<void> fresh_cycles_positions() async {
        this.cycles_positions = await cycles_market_download_mechanism(
            download_method_name: 'download_cycles_positions',
            function: CyclesPosition.oftheRecord
        );
    }
    
    Future<void> fresh_icp_positions() async {
        this.icp_positions = await cycles_market_download_mechanism(
            download_method_name: 'download_icp_positions',
            function: IcpPosition.oftheRecord
        );
    }

    Future<void> fresh_cycles_positions_purchases() async {
        this.cycles_positions_purchases = await cycles_market_download_mechanism(
            download_method_name: 'download_cycles_positions_purchases',
            function: CyclesPositionPurchase.oftheRecord
        );
    }

    Future<void> fresh_icp_positions_purchases() async {
        this.icp_positions_purchases = await cycles_market_download_mechanism(
            download_method_name: 'download_icp_positions_purchases',
            function: IcpPositionPurchase.oftheRecord
        );
    }


}


Future<List<T>> cycles_market_download_mechanism<T>({
    required String download_method_name,
    required T Function(Record) function
}) async {
    List<T> list = [];
    for (int i=0; true; i++) {
        Option<Vector<Record>> opt_records = c_backwards(
            await cycles_market.call(
                method_name: download_method_name,
                calltype: CallType.query,
                put_bytes: c_forwards([Record.oftheMap({ 'chunk_i': Nat(BigInt.from(i)) })])
            )
        )[0] as Option<Vector<Record>>;
        Vector<Record>? records = opt_records.value;
        if (records != null) {
            list.addAll(records.map<T>(function));
        } else {
            break;
        }
    }
    return list;
}


class CyclesPosition {
    final BigInt id;   
    final Principal positor;
    final Cycles cycles;
    final Cycles minimum_purchase;
    final XDRICPRate xdr_permyriad_per_icp_rate;
    final BigInt timestamp_nanos;
    CyclesPosition._({
        required this.id,   
        required this.positor,
        required this.cycles,
        required this.minimum_purchase,
        required this.xdr_permyriad_per_icp_rate,
        required this.timestamp_nanos,
    });
    static CyclesPosition oftheRecord(Record r) {
        return CyclesPosition._(
            id: (r['id'] as Nat).value,
            positor: r['positor'] as Principal,
            cycles: Cycles.oftheNat(r['cycles'] as Nat),
            minimum_purchase: Cycles.oftheNat(r['minimum_purchase'] as Nat),
            xdr_permyriad_per_icp_rate: XDRICPRate.oftheNat64(r['xdr_permyriad_per_icp_rate'] as Nat64), 
            timestamp_nanos: (r['timestamp_nanos'] as Nat).value
        );
    }
}

class IcpPosition {

    static IcpPosition oftheRecord(Record r) {
        throw UnimplementedError();
    }
}
class CyclesPositionPurchase {
    final BigInt cycles_position_id;
    final Principal cycles_position_positor;
    final XDRICPRate cycles_position_xdr_permyriad_per_icp_rate;
    final BigInt id;
    final Principal purchaser;
    final Cycles cycles;
    final BigInt timestamp_nanos;
    final bool cycles_payout_lock;
    final bool icp_payout_lock;
    final Record cycles_payout_data;
    final bool icp_payout;
    CyclesPositionPurchase._({
        required this.cycles_position_id,
        required this.cycles_position_positor,
        required this.cycles_position_xdr_permyriad_per_icp_rate,
        required this.id,
        required this.purchaser,
        required this.cycles,
        required this.timestamp_nanos,
        required this.cycles_payout_lock,
        required this.icp_payout_lock,
        required this.cycles_payout_data,
        required this.icp_payout,
    });
    static CyclesPositionPurchase oftheRecord(Record r) {
        return CyclesPositionPurchase._(
            cycles_position_id: (r['cycles_position_id'] as Nat).value,
            cycles_position_positor: (r['cycles_position_positor'] as Principal),
            cycles_position_xdr_permyriad_per_icp_rate: XDRICPRate.oftheNat64(r['cycles_position_xdr_permyriad_per_icp_rate'] as Nat64),
            id: (r['id'] as Nat).value,
            purchaser: r['purchaser'] as Principal,
            cycles: Cycles.oftheNat(r['cycles'] as Nat),
            timestamp_nanos: (r['timestamp_nanos'] as Nat).value,
            cycles_payout_lock: (r['cycles_payout_lock'] as Bool).value,
            icp_payout_lock: (r['icp_payout_lock'] as Bool).value,
            cycles_payout_data: (r['cycles_payout_data'] as Record),
            icp_payout: (r['icp_payout'] as Bool).value,
        );
    }
}


class IcpPositionPurchase {

    static IcpPositionPurchase oftheRecord(Record r) {
        throw UnimplementedError();
    }
}


/*


#[derive(CandidType, Deserialize)]
struct IcpPosition {
    id: PositionId,   
    positor: Principal,
    icp: IcpTokens,
    minimum_purchase: IcpTokens,
    xdr_permyriad_per_icp_rate: XdrPerMyriadPerIcp,
    timestamp_nanos: u128,
}


#[derive(CandidType, Deserialize)]
struct CyclesPositionPurchase {
    cycles_position_id: PositionId,
    cycles_position_positor: Principal,
    cycles_position_xdr_permyriad_per_icp_rate: XdrPerMyriadPerIcp,
    id: PurchaseId,
    purchaser: Principal,
    cycles: Cycles,
    timestamp_nanos: u128,
    cycles_payout_lock: bool,
    icp_payout_lock: bool,
    cycles_payout_data: CyclesPayoutData,
    icp_payout: bool
}

#[derive(CandidType, Deserialize)]
struct IcpPositionPurchase {
    icp_position_id: PositionId,
    icp_position_positor: Principal,
    icp_position_xdr_permyriad_per_icp_rate: XdrPerMyriadPerIcp,
    id: PurchaseId,
    purchaser: Principal,
    icp: IcpTokens,
    timestamp_nanos: u128,
    cycles_payout_lock: bool,
    icp_payout_lock: bool,
    cycles_payout_data: CyclesPayoutData,
    icp_payout: bool
}



*/
