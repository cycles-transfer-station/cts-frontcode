







class CyclesMarket extends Canister {
    
    List<CyclesPosition> = cycles_positions;
    List<IcpPosition> = icp_positions;
    List<CyclesPositionPurchase> cycles_positions_purchases;
    List<IcpPositionPurchase> = icp_positions_purchases;
    
    
    CyclesMarket(super.principal);
    
    
    Future<void> download_cycles_positions(int chunk_i) async {
    
    }
    
    Future<void> download_icp_positions(int chunk_i) async {
    
    }

    Future<void> download_cycles_positions_purchases(int chunk_i) async {
    
    }

    Future<void> download_icp_positions_purchases(int chunk_i) async {
    
    }


}




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
