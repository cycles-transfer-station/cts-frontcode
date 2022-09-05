


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

    static CyclesPosition oftheRecord(Record r) {
        throw UnimplementedError();
    }
}

class IcpPosition {

    static IcpPosition oftheRecord(Record r) {
        throw UnimplementedError();
    }
}
class CyclesPositionPurchase {

    static CyclesPositionPurchase oftheRecord(Record r) {
        throw UnimplementedError();
    }
}
class IcpPositionPurchase {

    static IcpPositionPurchase oftheRecord(Record r) {
        throw UnimplementedError();
    }
}


/*

#[derive(CandidType, Deserialize)]
struct CyclesPosition {
    id: PositionId,   
    positor: Principal,
    cycles: Cycles,
    minimum_purchase: Cycles,
    xdr_permyriad_per_icp_rate: XdrPerMyriadPerIcp,
    timestamp_nanos: u128,
}

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
