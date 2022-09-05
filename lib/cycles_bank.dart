


import 'dart:typed_data';

import 'package:ic_tools/ic_tools.dart';
import 'package:ic_tools/tools.dart';
import 'package:ic_tools/candid.dart';
import 'package:ic_tools/common.dart' as common;

import 'user.dart';
import 'state.dart';

import 'icp_ledger.dart';

class CyclesBank extends Canister {
    User user;

    CyclesBankMetrics? metrics;
    
    List<CyclesTransferIn> cycles_transfers_in = [];
    List<CyclesTransferOut> cycles_transfers_out = [];
    
    List<CMCyclesPosition> cm_cycles_positions = [];
    List<CMIcpPosition> cm_icp_positions = [];
    List<CMCyclesPositionPurchase> cm_cycles_positions_purchases = [];
    List<CMIcpPositionPurchase> cm_icp_positions_purchases = [];
    List<CMIcpTransferOut> cm_icp_transfers_out = [];
    
    CyclesBank(
        super.principal,
        this.user,
    );
    
    Future<void> fresh_metrics() async {
        Record metrics_record = c_backwards(
            await this.user.call(
                this,
                method_name: 'metrics',
                calltype: CallType.call,
                put_bytes: c_forwards([])
            )
        )[0] as Record;
        this.metrics = CyclesBankMetrics.oftheRecord(metrics_record);
    }
    
    

    Future<void> fresh_cycles_transfers_in() async {
        if (this.metrics == null) { await this.fresh_metrics(); }
        
        this.cycles_transfers_in.addAll(
            await cts_download_mechanism(
                chunk_size: this.metrics!.download_cycles_transfers_in_chunk_size.toInt(), 
                len_so_far: this.cycles_transfers_in.length,
                len: this.metrics!.cycles_transfers_in_len.toInt(),
                download_method_name: 'download_cycles_transfers_in', 
                caller: user.caller,
                legations: user.legations,
                canister: this,
                function: CyclesTransferIn.oftheRecord,
            )
        );
    }
   
    Future<void> fresh_cycles_transfers_out() async {
        if (this.metrics == null) { await this.fresh_metrics(); }
        this.cycles_transfers_out.addAll(
            await cts_download_mechanism(
                chunk_size: this.metrics!.download_cycles_transfers_out_chunk_size.toInt(), 
                len_so_far: this.cycles_transfers_out.length,
                len: this.metrics!.cycles_transfers_out_len.toInt(),
                download_method_name: 'download_cycles_transfers_out', 
                caller: user.caller,
                legations: user.legations,
                canister: this,
                function: CyclesTransferOut.oftheRecord,
            )
        ); 
    }
    
    
    
    
    
    Future<void> fresh_cm_cycles_positions() async {
        if (this.metrics == null) { await this.fresh_metrics(); }
        this.cm_cycles_positions.addAll(
            await cts_download_mechanism(
                chunk_size: this.metrics!.download_cm_cycles_positions_chunk_size.toInt(), 
                len_so_far: this.cm_cycles_positions.length,
                len: this.metrics!.cm_cycles_positions_len.toInt(),
                download_method_name: 'download_cm_cycles_positions', 
                caller: user.caller,
                legations: user.legations,
                canister: this,
                function: CMCyclesPosition.oftheRecord,
            )
        ); 
    }
    
    Future<void> fresh_cm_icp_positions() async {
        if (this.metrics == null) { await this.fresh_metrics(); }
        this.cm_icp_positions.addAll(
            await cts_download_mechanism(
                chunk_size: this.metrics!.download_cm_icp_positions_chunk_size.toInt(), 
                len_so_far: this.cm_icp_positions.length,
                len: this.metrics!.cm_icp_positions_len.toInt(),
                download_method_name: 'download_cm_icp_positions', 
                caller: user.caller,
                legations: user.legations,
                canister: this,
                function: CMIcpPosition.oftheRecord,
            )
        );  
    }
    
    Future<void> fresh_cm_cycles_positions_purchases() async {
        if (this.metrics == null) { await this.fresh_metrics(); }
        this.cm_cycles_positions_purchases.addAll(
            await cts_download_mechanism(
                chunk_size: this.metrics!.download_cm_cycles_positions_purchases_chunk_size.toInt(), 
                len_so_far: this.cm_cycles_positions_purchases.length,
                len: this.metrics!.cm_cycles_positions_purchases_len.toInt(),
                download_method_name: 'download_cm_cycles_positions_purchases', 
                caller: user.caller,
                legations: user.legations,
                canister: this,
                function: CMCyclesPositionPurchase.oftheRecord,
            )
        );
    }
    
    Future<void> fresh_cm_icp_positions_purchases() async {
        if (this.metrics == null) { await this.fresh_metrics(); }
        this.cm_icp_positions_purchases.addAll(
            await cts_download_mechanism(
                chunk_size: this.metrics!.download_cm_icp_positions_purchases_chunk_size.toInt(), 
                len_so_far: this.cm_icp_positions_purchases.length,
                len: this.metrics!.cm_icp_positions_purchases_len.toInt(),
                download_method_name: 'download_cm_icp_positions_purchases', 
                caller: user.caller,
                legations: user.legations,
                canister: this,
                function: CMIcpPositionPurchase.oftheRecord,
            )
        ); 
    }
    
    Future<void> fresh_cm_icp_transfers_out() async {
        if (this.metrics == null) { await this.fresh_metrics(); }
        this.cm_icp_transfers_out.addAll(
            await cts_download_mechanism(
                chunk_size: this.metrics!.download_cm_icp_transfers_out_chunk_size.toInt(), 
                len_so_far: this.cm_icp_transfers_out.length,
                len: this.metrics!.cm_icp_transfers_out_len.toInt(),
                download_method_name: 'download_cm_icp_transfers_out', 
                caller: user.caller,
                legations: user.legations,
                canister: this,
                function: CMIcpTransferOut.oftheRecord,
            )
        ); 
    }
}







typedef CTSFuel = Cycles;


class CyclesBankMetrics {
    Cycles cycles_balance;
    CTSFuel user_canister_ctsfuel_balance;
    BigInt storage_size_mib;
    BigInt lifetime_termination_timestamp_seconds;
    Vector<Principal> cycles_transferrer_canisters;
    Principal user_id;
    BigInt user_canister_creation_timestamp_nanos;
    BigInt storage_usage;
    BigInt cycles_transfers_id_counter;
    BigInt cycles_transfers_in_len;
    BigInt cycles_transfers_out_len;
    BigInt download_cycles_transfers_in_chunk_size;
    BigInt download_cycles_transfers_out_chunk_size;
    BigInt cm_cycles_positions_len;
    BigInt cm_icp_positions_len;
    BigInt cm_cycles_positions_purchases_len;
    BigInt cm_icp_positions_purchases_len;
    BigInt cm_icp_transfers_out_len;
    BigInt download_cm_cycles_positions_chunk_size;
    BigInt download_cm_icp_positions_chunk_size;
    BigInt download_cm_cycles_positions_purchases_chunk_size;
    BigInt download_cm_icp_positions_purchases_chunk_size;
    BigInt download_cm_icp_transfers_out_chunk_size;
    CyclesBankMetrics._({
        required this.cycles_balance,
        required this.user_canister_ctsfuel_balance,
        required this.storage_size_mib,
        required this.lifetime_termination_timestamp_seconds,
        required this.cycles_transferrer_canisters,
        required this.user_id,
        required this.user_canister_creation_timestamp_nanos,
        required this.storage_usage,
        required this.cycles_transfers_id_counter,
        required this.cycles_transfers_in_len,
        required this.cycles_transfers_out_len,
        required this.download_cycles_transfers_in_chunk_size,
        required this.download_cycles_transfers_out_chunk_size,
        required this.cm_cycles_positions_len,
        required this.cm_icp_positions_len,
        required this.cm_cycles_positions_purchases_len,
        required this.cm_icp_positions_purchases_len,
        required this.cm_icp_transfers_out_len,
        required this.download_cm_cycles_positions_chunk_size,
        required this.download_cm_icp_positions_chunk_size,
        required this.download_cm_cycles_positions_purchases_chunk_size,
        required this.download_cm_icp_positions_purchases_chunk_size,
        required this.download_cm_icp_transfers_out_chunk_size
    });
    static CyclesBankMetrics oftheRecord(Record r) {
        return CyclesBankMetrics._(
            cycles_balance: (r['cycles_balance'] as Nat).value,
            user_canister_ctsfuel_balance: (r['user_canister_ctsfuel_balance'] as Nat).value,
            storage_size_mib: (r['storage_size_mib'] as Nat).value,
            lifetime_termination_timestamp_seconds: (r['lifetime_termination_timestamp_seconds'] as Nat).value,
            cycles_transferrer_canisters: (r['cycles_transferrer_canisters'] as Vector<Principal>), 
            user_id: (r['user_id'] as Principal),
            user_canister_creation_timestamp_nanos: (r['user_canister_creation_timestamp_nanos'] as Nat).value,
            storage_usage: (r['storage_usage'] as Nat).value,
            cycles_transfers_id_counter: (r['cycles_transfers_id_counter'] as Nat).value,
            cycles_transfers_in_len: (r['cycles_transfers_in_len'] as Nat).value,
            cycles_transfers_out_len: (r['cycles_transfers_out_len'] as Nat).value,
            download_cycles_transfers_in_chunk_size: (r['download_cycles_transfers_in_chunk_size'] as Nat).value,
            download_cycles_transfers_out_chunk_size: (r['download_cycles_transfers_out_chunk_size'] as Nat).value,
            cm_cycles_positions_len: (r['cm_cycles_positions_len'] as Nat).value,
            cm_icp_positions_len: (r['cm_icp_positions_len'] as Nat).value,
            cm_cycles_positions_purchases_len: (r['cm_cycles_positions_purchases_len'] as Nat).value,
            cm_icp_positions_purchases_len: (r['cm_icp_positions_purchases_len'] as Nat).value,
            cm_icp_transfers_out_len: (r['cm_icp_transfers_out_len'] as Nat).value,
            download_cm_cycles_positions_chunk_size: (r['download_cm_cycles_positions_chunk_size'] as Nat).value,
            download_cm_icp_positions_chunk_size: (r['download_cm_icp_positions_chunk_size'] as Nat).value,
            download_cm_cycles_positions_purchases_chunk_size: (r['download_cm_cycles_positions_purchases_chunk_size'] as Nat).value,
            download_cm_icp_positions_purchases_chunk_size: (r['download_cm_icp_positions_purchases_chunk_size'] as Nat).value,
            download_cm_icp_transfers_out_chunk_size: (r['download_cm_icp_transfers_out_chunk_size'] as Nat).value
        );
    }
}




class CyclesTransferIn {
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
            cycles: (r['cycles'] as Nat).value,
            cycles_transfer_memo: CyclesTransferMemo.oftheVariant(r['cycles_transfer_memo'] as Variant),
            timestamp_nanos: (r['timestamp_nanos'] as Nat).value,
        );
    }
}


class CyclesTransferOut {
    final BigInt id;
    final Principal for_the_canister;
    final BigInt cycles_sent;
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
            cycles_sent: (r['cycles_sent'] as Nat).value,    
            cycles_refunded: cycles_refunded_nat != null ? cycles_refunded_nat.value : null,    
            cycles_transfer_memo: CyclesTransferMemo.oftheVariant(r['cycles_transfer_memo'] as Variant),    
            timestamp_nanos: (r['timestamp_nanos'] as Nat).value,    
            opt_cycles_transfer_call_error: opt_cycles_transfer_call_error != null ? CallError.oftheRecord(opt_cycles_transfer_call_error) : null,
            fee_paid: (r['fee_paid'] as Nat64).value
        );
    }
}


class CMCyclesPosition {
    final BigInt id;   
    final Cycles cycles;
    final Cycles minimum_purchase;
    final BigInt xdr_permyriad_per_icp_rate;
    final BigInt create_position_fee;
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
            cycles: (r['cycles'] as Nat).value,
            minimum_purchase: (r['minimum_purchase'] as Nat).value,
            xdr_permyriad_per_icp_rate: (r['xdr_permyriad_per_icp_rate'] as Nat64).value,
            create_position_fee: (r['create_position_fee'] as Nat64).value,
            timestamp_nanos: (r['timestamp_nanos'] as Nat).value,
        );
    }
}


class CMIcpPosition {
    final BigInt id;   
    final IcpTokens icp;
    final IcpTokens minimum_purchase;
    final BigInt xdr_permyriad_per_icp_rate;
    final BigInt create_position_fee;
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
            xdr_permyriad_per_icp_rate: (r['xdr_permyriad_per_icp_rate'] as Nat64).value,
            create_position_fee: (r['create_position_fee'] as Nat64).value,
            timestamp_nanos: (r['timestamp_nanos'] as Nat).value
        );
    }

}


class CMCyclesPositionPurchase {
    final BigInt cycles_position_id;
    final BigInt cycles_position_xdr_permyriad_per_icp_rate;
    final BigInt id;
    final Cycles cycles;
    final BigInt purchase_position_fee;
    final BigInt timestamp_nanos;
    
    CMCyclesPositionPurchase._({
        required this.cycles_position_id,
        required this.cycles_position_xdr_permyriad_per_icp_rate,
        required this.id,
        required this.cycles,
        required this.purchase_position_fee,
        required this.timestamp_nanos,
    }); 
    
    static CMCyclesPositionPurchase oftheRecord(Record r) {
        return CMCyclesPositionPurchase._(
            cycles_position_id: (r['cycles_position_id'] as Nat).value,
            cycles_position_xdr_permyriad_per_icp_rate: (r['cycles_position_xdr_permyriad_per_icp_rate'] as Nat64).value,
            id: (r['id'] as Nat).value,
            cycles: (r['cycles'] as Nat).value,
            purchase_position_fee: (r['purchase_position_fee'] as Nat64).value,
            timestamp_nanos: (r['timestamp_nanos'] as Nat).value,        
        );
    } 
}

class CMIcpPositionPurchase{
    final BigInt icp_position_id;
    final BigInt icp_position_xdr_permyriad_per_icp_rate;
    final BigInt id;
    final IcpTokens icp;
    final BigInt purchase_position_fee;
    final BigInt timestamp_nanos;
    
    CMIcpPositionPurchase._({
        required this.icp_position_id,
        required this.icp_position_xdr_permyriad_per_icp_rate,
        required this.id,
        required this.icp,
        required this.purchase_position_fee,
        required this.timestamp_nanos,
    });
    
    static CMIcpPositionPurchase oftheRecord(Record r) {
        return CMIcpPositionPurchase._(
            icp_position_id: (r['icp_position_id'] as Nat).value,
            icp_position_xdr_permyriad_per_icp_rate: (r['icp_position_xdr_permyriad_per_icp_rate'] as Nat64).value,
            id: (r['id'] as Nat).value,
            icp: IcpTokens.oftheRecord(r['icp'] as Record),
            purchase_position_fee: (r['purchase_position_fee'] as Nat64).value,
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
    final BigInt transfer_icp_balance_fee;
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
            transfer_icp_balance_fee: (r['transfer_icp_balance_fee'] as Nat64).value
        );
    } 
}


// ----------------------------


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
        this['cycles'] = Nat(this.cycles);
        this['cycles_transfer_memo'] = this.cycles_transfer_memo;
    }
}

/*

#[derive(CandidType, Deserialize)]
pub enum UserTransferCyclesError {
    CTSFuelTooLow,
    MemoryIsFull,
    InvalidCyclesTransferMemoSize{max_size_bytes: u128},
    InvalidTransferCyclesAmount{ minimum_user_transfer_cycles: Cycles },
    CyclesBalanceTooLow { cycles_balance: Cycles, cycles_transferrer_transfer_cycles_fee: Cycles },
    CyclesTransferrerTransferCyclesError(cycles_transferrer::TransferCyclesError),
    CyclesTransferrerTransferCyclesCallError((u32, String))
}


// --------------------

 #[derive(CandidType, Deserialize)]
    pub struct CreateCyclesPositionQuest {
        pub cycles: Cycles,
        pub minimum_purchase: Cycles,
        pub xdr_permyriad_per_icp_rate: XdrPerMyriadPerIcp,
        
    }


#[derive(CandidType, Deserialize)]
pub enum UserCMCreateCyclesPositionError {
    CTSFuelTooLow,
    MemoryIsFull,
    CyclesBalanceTooLow{ cycles_balance: Cycles, cycles_market_create_position_fee: Cycles },
    CyclesMarketCreateCyclesPositionCallError((u32, String)),
    CyclesMarketCreateCyclesPositionError(cycles_market::CreateCyclesPositionError)
}

#[derive(CandidType, Deserialize)]
    pub enum CreateCyclesPositionError{
        MinimumPurchaseMustBeEqualOrLessThanTheCyclesPosition,
        MsgCyclesTooLow{ create_position_fee: Cycles },
        CyclesMarketIsBusy,
        CyclesMarketIsFull,
        CyclesMarketIsFull_MinimumRateAndMinimumCyclesPositionForABump{ minimum_rate_for_a_bump: XdrPerMyriadPerIcp, minimum_cycles_position_for_a_bump: Cycles },
        MinimumCyclesPosition(Cycles)   
    }

#[derive(CandidType, Deserialize)]
    pub struct CreateCyclesPositionSuccess {
        pub position_id: PositionId,
    }





#[derive(CandidType, Deserialize)]
    pub struct CreateIcpPositionQuest {
        pub icp: IcpTokens,
        pub minimum_purchase: IcpTokens,
        pub xdr_permyriad_per_icp_rate: XdrPerMyriadPerIcp,
    }
    
    
    
#[derive(CandidType, Deserialize)]
pub enum UserCMCreateIcpPositionError {
    CTSFuelTooLow,
    MemoryIsFull,
    CyclesBalanceTooLow{ cycles_balance: Cycles, cycles_market_create_position_fee: Cycles },
    CyclesMarketCreateIcpPositionCallError((u32, String)),
    CyclesMarketCreateIcpPositionError(cycles_market::CreateIcpPositionError)
}

    #[derive(CandidType, Deserialize)]
    pub enum CreateIcpPositionError {
        MinimumPurchaseMustBeEqualOrLessThanTheIcpPosition,
        MsgCyclesTooLow{ create_position_fee: Cycles },
        CyclesMarketIsFull,
        CyclesMarketIsBusy,
        CallerIsInTheMiddleOfACreateIcpPositionOrPurchaseCyclesPositionOrTransferIcpBalanceCall,
        CheckUserCyclesMarketIcpLedgerBalanceError((u32, String)),
        UserIcpBalanceTooLow{ user_icp_balance: IcpTokens },
        CyclesMarketIsFull_MaximumRateAndMinimumIcpPositionForABump{ maximum_rate_for_a_bump: XdrPerMyriadPerIcp, minimum_icp_position_for_a_bump: IcpTokens },
        MinimumIcpPosition(IcpTokens),
    }

    #[derive(CandidType, Deserialize)]
    pub struct CreateIcpPositionSuccess {
        pub position_id: PositionId
    }


#[derive(CandidType, Deserialize)]
pub struct UserCMPurchaseCyclesPositionQuest {
    cycles_market_purchase_cycles_position_quest: cycles_market::PurchaseCyclesPositionQuest,
    cycles_position_xdr_permyriad_per_icp_rate: XdrPerMyriadPerIcp // for the user_canister-log
}
#[derive(CandidType, Deserialize)]
    pub struct PurchaseCyclesPositionQuest {
        pub cycles_position_id: PositionId,
        pub cycles: Cycles
    }

#[derive(CandidType, Deserialize)]
pub enum UserCMPurchaseCyclesPositionError {
    CTSFuelTooLow,
    MemoryIsFull,
    CyclesBalanceTooLow{ cycles_balance: Cycles, cycles_market_purchase_position_fee: Cycles },
    CyclesMarketPurchaseCyclesPositionCallError((u32, String)),
    CyclesMarketPurchaseCyclesPositionError(cycles_market::PurchaseCyclesPositionError)
}


    #[derive(CandidType, Deserialize)]
    pub enum PurchaseCyclesPositionError {
        MsgCyclesTooLow{ purchase_position_fee: Cycles },
        CyclesMarketIsBusy,
        CallerIsInTheMiddleOfACreateIcpPositionOrPurchaseCyclesPositionOrTransferIcpBalanceCall,
        CheckUserCyclesMarketIcpLedgerBalanceError((u32, String)),
        UserIcpBalanceTooLow{ user_icp_balance: IcpTokens },
        CyclesPositionNotFound,
        CyclesPositionCyclesIsLessThanThePurchaseQuest{ cycles_position_cycles: Cycles },
        CyclesPositionMinimumPurchaseIsGreaterThanThePurchaseQuest{ cycles_position_minimum_purchase: Cycles },
    }

    #[derive(CandidType, Deserialize)]
    pub struct PurchaseCyclesPositionSuccess {
        pub purchase_id: PurchaseId,
    }



#[derive(CandidType, Deserialize)]
pub struct UserCMPurchaseIcpPositionQuest {
    cycles_market_purchase_icp_position_quest: cycles_market::PurchaseIcpPositionQuest,
    icp_position_xdr_permyriad_per_icp_rate: XdrPerMyriadPerIcp // for the user_canister-log
}
#[derive(CandidType, Deserialize)]
    pub struct PurchaseIcpPositionQuest {
        pub icp_position_id: PositionId,
        pub icp: IcpTokens
    }
#[derive(CandidType, Deserialize)]
pub enum UserCMPurchaseIcpPositionError {
    CTSFuelTooLow,
    MemoryIsFull,
    CyclesBalanceTooLow{ cycles_balance: Cycles, cycles_market_purchase_position_fee: Cycles },
    CyclesMarketPurchaseIcpPositionCallError((u32, String)),
    CyclesMarketPurchaseIcpPositionError(cycles_market::PurchaseIcpPositionError)
}


    #[derive(CandidType, Deserialize)]
    pub enum PurchaseIcpPositionError {
        MsgCyclesTooLow{ purchase_position_fee: Cycles },
        CyclesMarketIsBusy,
        IcpPositionNotFound,
        IcpPositionIcpIsLessThanThePurchaseQuest{ icp_position_icp: IcpTokens },
        IcpPositionMinimumPurchaseIsGreaterThanThePurchaseQuest{ icp_position_minimum_purchase: IcpTokens }
    }

    #[derive(CandidType, Deserialize)]
    pub struct PurchaseIcpPositionSuccess {
        pub purchase_id: PurchaseId
    }


#[derive(CandidType, Deserialize)]
    pub struct VoidPositionQuest {
        pub position_id: PositionId
    }
    
#[derive(CandidType, Deserialize)]
pub enum UserCMVoidPositionError {
    CTSFuelTooLow,
    CyclesMarketVoidPositionCallError((u32, String)),
    CyclesMarketVoidPositionError(cycles_market::VoidPositionError)
}

    #[derive(CandidType, Deserialize)]
    pub enum VoidPositionError {
        WrongCaller,
        CyclesMarketIsBusy,
        PositionNotFound,
    }

#[derive(CandidType, Deserialize)]
pub enum UserCMSeeIcpLockError {
    CTSFuelTooLow,
    CyclesMarketSeeIcpLockCallError((u32, String)),
}


#[derive(CandidType, Deserialize)]
    pub struct TransferIcpBalanceQuest {
        pub icp: IcpTokens,
        pub icp_fee: IcpTokens,
        pub to: IcpId
    }
    
    
#[derive(CandidType, Deserialize)]
pub enum UserCMTransferIcpBalanceError {
    CTSFuelTooLow,
    MemoryIsFull,
    CyclesBalanceTooLow{ cycles_balance: Cycles, cycles_market_transfer_icp_balance_fee: Cycles },
    CyclesMarketTransferIcpBalanceCallError((u32, String)),
    CyclesMarketTransferIcpBalanceError(cycles_market::TransferIcpBalanceError)
}
    #[derive(CandidType, Deserialize)]
    pub enum TransferIcpBalanceError {
        MsgCyclesTooLow{ transfer_icp_balance_fee: Cycles },
        CyclesMarketIsBusy,
        CallerIsInTheMiddleOfACreateIcpPositionOrPurchaseCyclesPositionOrTransferIcpBalanceCall,
        CheckUserCyclesMarketIcpLedgerBalanceCallError((u32, String)),
        UserIcpBalanceTooLow{ user_icp_balance: IcpTokens },
        IcpTransferCallError((u32, String)),
        IcpTransferError(IcpTransferError)
    }


*/
