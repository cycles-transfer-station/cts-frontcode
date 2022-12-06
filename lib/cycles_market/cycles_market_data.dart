


import '../config/state.dart';

import 'package:ic_tools/ic_tools.dart';
import 'package:ic_tools/candid.dart';
import 'package:ic_tools/common.dart';



class CyclesMarketData {
    List<CyclesPosition> cycles_positions = [];
    List<IcpPosition> icp_positions = [];
    List<CyclesPositionPurchase> cycles_positions_purchases = [];
    List<IcpPositionPurchase> icp_positions_purchases = [];
    
    CyclesMarketData();
    
    
    Future<void> fresh_cycles_positions() async {
        this.cycles_positions = await cycles_market_download_mechanism(
            download_method_name: 'see_cycles_positions',
            function: CyclesPosition.oftheRecord
        );
    }
    
    Future<void> fresh_icp_positions() async {
        this.icp_positions = await cycles_market_download_mechanism(
            download_method_name: 'see_icp_positions',
            function: IcpPosition.oftheRecord
        );
    }

    Future<void> fresh_cycles_positions_purchases() async {
        this.cycles_positions_purchases = await cycles_market_download_mechanism(
            download_method_name: 'see_cycles_positions_purchases',
            function: CyclesPositionPurchase.oftheRecord
        );
    }

    Future<void> fresh_icp_positions_purchases() async {
        this.icp_positions_purchases = await cycles_market_download_mechanism(
            download_method_name: 'see_icp_positions_purchases',
            function: IcpPositionPurchase.oftheRecord
        );
    }
    
    Future<void> load_data() async {
        await Future.wait([
            this.fresh_cycles_positions(),
            this.fresh_icp_positions(),
            this.fresh_cycles_positions_purchases(),
            this.fresh_icp_positions_purchases(),
        ]);
    }


}


Future<List<T>> cycles_market_download_mechanism<T>({
    required String download_method_name,
    required T Function(Record) function
}) async {
    List<T> list = [];
    for (int i=0; true; i++) {
        Option<Vector> opt_records = (c_backwards(
            await cycles_market.call(
                method_name: download_method_name,
                calltype: CallType.query,
                put_bytes: c_forwards([Record.oftheMap({ 'chunk_i': Nat(BigInt.from(i)) })])
            )
        )[0] as Option).cast_option<Vector>();
        if (opt_records.value != null) {
            list.addAll(opt_records.value!.cast_vector<Record>().map<T>(function));
        } else {
            break;
        }
    }
    return list;
}


abstract class CyclesMarketDataPosition {
    BigInt get id;
    Principal get positor;
    XDRICPRate get xdr_permyriad_per_icp_rate;
    BigInt get timestamp_nanos;
}


class CyclesPosition implements CyclesMarketDataPosition {
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
            xdr_permyriad_per_icp_rate: XDRICPRate.oftheXdrPerMyriadPerIcpNat64(r['xdr_permyriad_per_icp_rate'] as Nat64), 
            timestamp_nanos: (r['timestamp_nanos'] as Nat).value
        );
    }
}

class IcpPosition implements CyclesMarketDataPosition {
    final BigInt id;   
    final Principal positor;
    final IcpTokens icp;
    final IcpTokens minimum_purchase;
    final XDRICPRate xdr_permyriad_per_icp_rate;
    final BigInt timestamp_nanos;
    IcpPosition._({
        required this.id,
        required this.positor,
        required this.icp,
        required this.minimum_purchase,
        required this.xdr_permyriad_per_icp_rate,
        required this.timestamp_nanos
    });
    static IcpPosition oftheRecord(Record r) {
        return IcpPosition._(
            id: (r['id'] as Nat).value,
            positor: r['positor'] as Principal,
            icp: IcpTokens.oftheRecord(r['icp'] as Record),
            minimum_purchase: IcpTokens.oftheRecord(r['minimum_purchase'] as Record),
            xdr_permyriad_per_icp_rate: XDRICPRate.oftheXdrPerMyriadPerIcpNat64(r['xdr_permyriad_per_icp_rate'] as Nat64), 
            timestamp_nanos: (r['timestamp_nanos'] as Nat).value
        );
    }
}


abstract class CyclesMarketDataPositionPurchase {
    BigInt get position_id;
    Principal get position_positor;
    XDRICPRate get position_xdr_permyriad_per_icp_rate;
    BigInt get id;
    Principal get purchaser;
    BigInt get timestamp_nanos;
}

class CyclesPositionPurchase implements CyclesMarketDataPositionPurchase {
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
    final Record icp_payout_data;
    
    BigInt get position_id => cycles_position_id;
    Principal get position_positor => cycles_position_positor; 
    XDRICPRate get position_xdr_permyriad_per_icp_rate => cycles_position_xdr_permyriad_per_icp_rate;
    
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
        required this.icp_payout_data,
    });
    static CyclesPositionPurchase oftheRecord(Record r) {
        return CyclesPositionPurchase._(
            cycles_position_id: (r['cycles_position_id'] as Nat).value,
            cycles_position_positor: (r['cycles_position_positor'] as Principal),
            cycles_position_xdr_permyriad_per_icp_rate: XDRICPRate.oftheXdrPerMyriadPerIcpNat64(r['cycles_position_xdr_permyriad_per_icp_rate'] as Nat64),
            id: (r['id'] as Nat).value,
            purchaser: r['purchaser'] as Principal,
            cycles: Cycles.oftheNat(r['cycles'] as Nat),
            timestamp_nanos: (r['timestamp_nanos'] as Nat).value,
            cycles_payout_lock: (r['cycles_payout_lock'] as Bool).value,
            icp_payout_lock: (r['icp_payout_lock'] as Bool).value,
            cycles_payout_data: (r['cycles_payout_data'] as Record),
            icp_payout_data: (r['icp_payout_data'] as Record),
        );
    }
}


class IcpPositionPurchase implements CyclesMarketDataPositionPurchase {
    final BigInt icp_position_id;
    final Principal icp_position_positor;
    final XDRICPRate icp_position_xdr_permyriad_per_icp_rate;
    final BigInt id;
    final Principal purchaser;
    final IcpTokens icp;
    final BigInt timestamp_nanos;
    final bool cycles_payout_lock;
    final bool icp_payout_lock;
    final Record cycles_payout_data;
    final Record icp_payout_data;
    
    BigInt get position_id => icp_position_id;
    Principal get position_positor => icp_position_positor; 
    XDRICPRate get position_xdr_permyriad_per_icp_rate => icp_position_xdr_permyriad_per_icp_rate;
    
    IcpPositionPurchase._({
        required this.icp_position_id,
        required this.icp_position_positor,
        required this.icp_position_xdr_permyriad_per_icp_rate,
        required this.id,
        required this.purchaser,
        required this.icp,
        required this.timestamp_nanos,
        required this.cycles_payout_lock,
        required this.icp_payout_lock,
        required this.cycles_payout_data,
        required this.icp_payout_data,
    });
    static IcpPositionPurchase oftheRecord(Record r) {
        return IcpPositionPurchase._(
            icp_position_id: (r['icp_position_id'] as Nat).value,
            icp_position_positor: (r['icp_position_positor'] as Principal),
            icp_position_xdr_permyriad_per_icp_rate: XDRICPRate.oftheXdrPerMyriadPerIcpNat64(r['icp_position_xdr_permyriad_per_icp_rate'] as Nat64),
            id: (r['id'] as Nat).value,
            purchaser: r['purchaser'] as Principal,
            icp: IcpTokens.oftheRecord(r['icp'] as Record),
            timestamp_nanos: (r['timestamp_nanos'] as Nat).value,
            cycles_payout_lock: (r['cycles_payout_lock'] as Bool).value,
            icp_payout_lock: (r['icp_payout_lock'] as Bool).value,
            cycles_payout_data: (r['cycles_payout_data'] as Record),
            icp_payout_data: (r['icp_payout_data'] as Record),
        );
    }
}



