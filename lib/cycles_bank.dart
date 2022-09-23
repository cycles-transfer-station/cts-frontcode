


import 'dart:typed_data';

import 'package:ic_tools/ic_tools.dart';
import 'package:ic_tools/tools.dart';
import 'package:ic_tools/candid.dart';
import 'package:ic_tools/common.dart';

import 'user.dart';
import 'state.dart';
import 'cycles_market.dart';
import 'icp_ledger.dart';

class CyclesBank extends Canister {
    User user;

    CyclesBankMetrics? metrics;
    
    List<CyclesTransferIn> cycles_transfers_in = [];
    List<CyclesTransferOut> cycles_transfers_out = [];
    
    final String cm_icp_id; 
    IcpTokens? cm_icp_balance;
    List<CMCyclesPosition> cm_cycles_positions = [];
    List<CMIcpPosition> cm_icp_positions = [];
    List<CMCyclesPositionPurchase> cm_cycles_positions_purchases = [];
    List<CMIcpPositionPurchase> cm_icp_positions_purchases = [];
    List<CMIcpTransferOut> cm_icp_transfers_out = [];
    
    CyclesBank(
        super.principal,
        this.user,
    ): cm_icp_id = icp_id(cycles_market.principal, subaccount_bytes: principal_as_an_icpsubaccountbytes(principal));
    
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
    

    Future<Iterable<T>> cycles_bank_download_mechanism<T>({
        required int chunk_size, 
        required int len_so_far,
        required int len,
        required String download_method_name,  
        required T Function(Record) function,
    }) async {
        List<T> list = [];
        int total_chunks = (len / chunk_size).toDouble().ceil();
        int start_chunk = (len_so_far / chunk_size).toDouble().floor();
        int start_chunk_position = len_so_far >= chunk_size ? (len_so_far % chunk_size) : len_so_far;
        for (int i=start_chunk; i<total_chunks; i++) {
            Option<Vector<Record>> opt_records = c_backwards(
                await this.user.call(
                    this,
                    method_name: download_method_name,
                    calltype: CallType.query,
                    put_bytes: c_forwards([Nat(BigInt.from(i))])
                )
            )[0] as Option<Vector<Record>>;
            Vector<Record>? records = opt_records.value;
            if (records != null) {
                list.addAll(records.sublist(i==start_chunk ? start_chunk_position : 0).map<T>(function));
            } else {
                break;
            }        
        }
        return list;
    }




    Future<void> fresh_cycles_transfers_in() async {
        await this.fresh_metrics();

        this.cycles_transfers_in.addAll(
            await cycles_bank_download_mechanism(
                chunk_size: this.metrics!.download_cycles_transfers_in_chunk_size.toInt(), 
                len_so_far: this.cycles_transfers_in.length,
                len: this.metrics!.cycles_transfers_in_len.toInt(),
                download_method_name: 'download_cycles_transfers_in', 
                function: CyclesTransferIn.oftheRecord,
            )
        );
    }
   
    Future<void> fresh_cycles_transfers_out() async {
        if (this.metrics == null) { await this.fresh_metrics(); }
        this.cycles_transfers_out.addAll(
            await cycles_bank_download_mechanism(
                chunk_size: this.metrics!.download_cycles_transfers_out_chunk_size.toInt(), 
                len_so_far: this.cycles_transfers_out.length,
                len: this.metrics!.cycles_transfers_out_len.toInt(),
                download_method_name: 'download_cycles_transfers_out', 
                function: CyclesTransferOut.oftheRecord,
            )
        ); 
    }
    
    
    Future<IcpTokens> cm_see_icp_lock() async {
        Variant sponse = c_backwards(
            await this.user.call(
                this,
                calltype: CallType.call,
                method_name: 'cm_see_icp_lock',
                put_bytes: c_forwards([])
            )
        )[0] as Variant;
        IcpTokens icp_lock = match_variant<IcpTokens>(sponse, {
            Ok: (icp_tokens_record) {
                return IcpTokens.oftheRecord(icp_tokens_record as Record);
            },
            Err: (cm_see_icp_lock_error) {
                return match_variant<Never>(cm_see_icp_lock_error as Variant, {
                    'CTSFuelTooLow': (nul) {
                        throw Exception('The CTSFuel is too low in this cycles-bank. topup the CTSFuel.');
                    },
                    'CyclesMarketSeeIcpLockCallError':(call_error_record) {
                        throw Exception('Call error when calling see_icp_lock method on the cycles-market: ${CallError.oftheRecord(call_error_record as Record)}');
                    }
                });
            }
        });      
        return icp_lock;
    }
    Future<void> fresh_cm_icp_balance() async {
        // check icp ledger balance of the cycles-bank cycles-market-[ac]count
        // check the icp_lock in the cycles-market
        IcpTokens icp_ledger_balance = IcpTokens.oftheDouble(await check_icp_balance(this.cm_icp_id));
        IcpTokens icp_in_the_lock = await this.cm_see_icp_lock(); 
        this.cm_icp_balance = icp_ledger_balance - icp_in_the_lock;
    }
    
    
    Future<void> fresh_cm_cycles_positions() async {
        if (this.metrics == null) { await this.fresh_metrics(); }
        this.cm_cycles_positions.addAll(
            await cycles_bank_download_mechanism(
                chunk_size: this.metrics!.download_cm_cycles_positions_chunk_size.toInt(), 
                len_so_far: this.cm_cycles_positions.length,
                len: this.metrics!.cm_cycles_positions_len.toInt(),
                download_method_name: 'download_cm_cycles_positions', 
                function: CMCyclesPosition.oftheRecord,
            )
        ); 
    }
    
    Future<void> fresh_cm_icp_positions() async {
        if (this.metrics == null) { await this.fresh_metrics(); }
        this.cm_icp_positions.addAll(
            await cycles_bank_download_mechanism(
                chunk_size: this.metrics!.download_cm_icp_positions_chunk_size.toInt(), 
                len_so_far: this.cm_icp_positions.length,
                len: this.metrics!.cm_icp_positions_len.toInt(),
                download_method_name: 'download_cm_icp_positions', 
                function: CMIcpPosition.oftheRecord,
            )
        );  
    }
    
    Future<void> fresh_cm_cycles_positions_purchases() async {
        if (this.metrics == null) { await this.fresh_metrics(); }
        this.cm_cycles_positions_purchases.addAll(
            await cycles_bank_download_mechanism(
                chunk_size: this.metrics!.download_cm_cycles_positions_purchases_chunk_size.toInt(), 
                len_so_far: this.cm_cycles_positions_purchases.length,
                len: this.metrics!.cm_cycles_positions_purchases_len.toInt(),
                download_method_name: 'download_cm_cycles_positions_purchases', 
                function: CMCyclesPositionPurchase.oftheRecord,
            )
        );
    }
    
    Future<void> fresh_cm_icp_positions_purchases() async {
        if (this.metrics == null) { await this.fresh_metrics(); }
        this.cm_icp_positions_purchases.addAll(
            await cycles_bank_download_mechanism(
                chunk_size: this.metrics!.download_cm_icp_positions_purchases_chunk_size.toInt(), 
                len_so_far: this.cm_icp_positions_purchases.length,
                len: this.metrics!.cm_icp_positions_purchases_len.toInt(),
                download_method_name: 'download_cm_icp_positions_purchases', 
                function: CMIcpPositionPurchase.oftheRecord,
            )
        ); 
    }
    
    Future<void> fresh_cm_icp_transfers_out() async {
        if (this.metrics == null) { await this.fresh_metrics(); }
        this.cm_icp_transfers_out.addAll(
            await cycles_bank_download_mechanism(
                chunk_size: this.metrics!.download_cm_icp_transfers_out_chunk_size.toInt(), 
                len_so_far: this.cm_icp_transfers_out.length,
                len: this.metrics!.cm_icp_transfers_out_len.toInt(),
                download_method_name: 'download_cm_icp_transfers_out', 
                function: CMIcpTransferOut.oftheRecord,
            )
        ); 
    }
    
    //Future<void> delete_ functionality coming soon
    
    Future<BigInt/*cycles_transfer_id*/> transfer_cycles(UserTransferCyclesQuest q) async {
        if (q.for_the_canister.bytes.length >= 29) {
            throw Exception('Transfer cycles between canisters. Make sure that these cycles are for a canister.');
        }
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
        await this.fresh_cycles_transfers_out();
        return cycles_transfer_out_id;
    }
    
    Future<CreateCyclesPositionSuccess> cm_create_cycles_position(CreateCyclesPositionQuest q) async {
        if (q.minimum_purchase.cycles > q.cycles.cycles) {
            throw Exception('The minimum-purchase of the position must be equal or less than the position.');
        }
        Variant sponse = c_backwards(
            await user.call(
                this,
                method_name: 'cm_create_cycles_position',
                put_bytes: c_forwards([q]),
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
                                throw Exception('The cycles-market cycles-positions are full. If you create a cycles-position with a minimum xdr-icp-rate: ${XDRICPRate.oftheNat64(r['minimum_rate_for_a_bump'] as Nat64)} and with a minimum cycles-position: ${Cycles.oftheNat(r['minimum_cycles_position_for_a_bump']!)} then you will bump the most expensive cycles-position and take its place.');
                            },
                            'MinimumCyclesPosition': (cycles_nat) {
                                throw Exception('The minimum cycles for a cycles-position is: ${Cycles.oftheNat(cycles_nat)}');
                            }
                        });
                    }
                });           
            }
        });   
        this.metrics!.cm_cycles_positions_len = this.metrics!.cm_cycles_positions_len + BigInt.from(1);
        await this.fresh_cm_cycles_positions();
        return create_cycles_position_success;
    }
    
    Future<CreateIcpPositionSuccess> cm_create_icp_position(CreateIcpPositionQuest q) async {
        if (q.minimum_purchase > q.icp) {
            throw Exception('The minimum-purchase of the position must be equal or less than the position.');
        }
        await this.fresh_cm_icp_balance();
        if (this.cm_icp_balance! < q.icp + q.icp ~/ q.minimum_purchase * ICP_LEDGER_TRANSFER_FEE) {
            throw Exception('The cycles-bank\'s cycles-market-icp-balance is too low. The icp-balance must be enough to cover the icp-position + icp-position ~/ icp-position-minimum_purchase * ICP_LEDGER_TRANSFER_FEE[${ICP_LEDGER_TRANSFER_FEE}]\nicp-balance: ${this.cm_icp_balance!}\n');
        }
        Variant sponse = c_backwards(
            await user.call(
                this,
                method_name: 'cm_create_icp_position',
                calltype: CallType.call,
                put_bytes: c_forwards([q])
            )
        )[0] as Variant;
        CreateIcpPositionSuccess create_icp_position_success = match_variant<CreateIcpPositionSuccess>(sponse, {
            Ok: (ok_record) {
                return CreateIcpPositionSuccess.oftheRecord(ok_record as Record);
            },
            Err: (user_cm_create_icp_position_error) {
                return match_variant<Never>(user_cm_create_icp_position_error as Variant, {
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
                    'CyclesMarketCreateIcpPositionCallError': (call_error_record) {
                        throw Exception('cycles-market create_icp_position call error:\n${CallError.oftheRecord(call_error_record as Record)}');    
                    },
                    'CyclesMarketCreateIcpPositionError': (cycles_market_create_icp_position_error) {
                        return match_variant<Never>(cycles_market_create_icp_position_error as Variant, {
                            'MinimumPurchaseMustBeEqualOrLessThanTheIcpPosition': (nul) {
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
                            'CallerIsInTheMiddleOfACreateIcpPositionOrPurchaseCyclesPositionOrTransferIcpBalanceCall': (nul) {
                                throw Exception('The cycles-bank is in the middle of a call for the cycles-market.');    
                            },
                            'CheckUserCyclesMarketIcpLedgerBalanceError':(call_error_record) {
                                throw Exception('Error calling the icp-ledger for the cycles-bank\'s cycles-market-icp-balance.\n${CallError.oftheRecord(call_error_record as Record)}');
                            },
                            'UserIcpBalanceTooLow': (user_icp_balance_record) {
                                this.cm_icp_balance = IcpTokens.oftheRecord((user_icp_balance_record as Record)['user_icp_balance']!);
                                throw Exception('The cycles-bank\'s cycles-market-icp-balance is too low. The icp-balance must be enough to cover the icp-position + icp-position ~/ icp-position-minimum_purchase * ICP_LEDGER_TRANSFER_FEE[${ICP_LEDGER_TRANSFER_FEE}]\nicp-balance: ${this.cm_icp_balance!}\n');
                            },
                            'CyclesMarketIsFull_MaximumRateAndMinimumIcpPositionForABump': (r_ctype) {
                                Record r = r_ctype as Record;
                                throw Exception('The cycles-market icp-positions are full. If you create an icp-position with a maximum xdr-icp-rate: ${XDRICPRate.oftheNat64(r['maximum_rate_for_a_bump']!)} and with a minimum icp-position: ${IcpTokens.oftheRecord(r['minimum_icp_position_for_a_bump']!)} then you will bump the most expensive icp-position and take its place.');
                            },
                            'MinimumIcpPosition': (icptokens_record) {
                                throw Exception('The minimum icp for an icp-position is: ${IcpTokens.oftheRecord(icptokens_record as Record)}');
                            },
                        });
                    }
                });
            }
        });        
        this.metrics!.cm_icp_positions_len = this.metrics!.cm_icp_positions_len + BigInt.from(1);
        await this.fresh_cm_icp_positions();
        return create_icp_position_success;    
    }
    
    
    Future<PurchaseCyclesPositionSuccess> cm_purchase_cycles_position(CyclesPosition cycles_position, Cycles purchase_cycles) async {
        if (cycles_position.minimum_purchase > purchase_cycles) {
            throw Exception('The minimum-purchase of this cycles-position is ${cycles_position.minimum_purchase}');
        }
        if (cycles_position.cycles < purchase_cycles) {
            throw Exception('This cycles-position: ${cycles_position.id} has ${cycles_position.cycles} for the sale.');
        }
        await fresh_cm_icp_balance();
        IcpTokens cycles_position_purchase_cycles_icp_cost = cycles_to_icptokens(purchase_cycles, cycles_position.xdr_permyriad_per_icp_rate); 
        if (this.cm_icp_balance! < cycles_position_purchase_cycles_icp_cost + ICP_LEDGER_TRANSFER_FEE) {
            throw Exception('The cycles-bank\'s cycles-market-icp-balance is too low for the purchase. \ncycles-bank\'s cycles-market-icp-balance: ${this.cm_icp_balance!}\npurchase_cycles: ${purchase_cycles}\nicp-cost of these cycles in this cycles-position: ${cycles_position_purchase_cycles_icp_cost}, icp-ledger-transfer-fee: ${ICP_LEDGER_TRANSFER_FEE}');
        }
        Variant sponse = c_backwards(
            await user.call(
                this,
                method_name: 'cm_purchase_cycles_position',
                calltype: CallType.call,
                put_bytes: c_forwards([
                    CyclesBankCMPurchaseCyclesPositionQuest(
                        cycles_market_purchase_cycles_position_quest: CyclesMarketPurchaseCyclesPositionQuest(
                            cycles_position_id: cycles_position.id,
                            cycles: purchase_cycles,
                        ),
                        cycles_position_xdr_permyriad_per_icp_rate: cycles_position.xdr_permyriad_per_icp_rate,
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
                    'CyclesMarketPurchaseCyclesPositionError': (cycles_market_purchase_cycles_position_error) {
                        return match_variant<Never>(cycles_market_purchase_cycles_position_error as Variant, {
                            'MsgCyclesTooLow': (fee_record) {
                                throw Exception('File this error: \nMsgCyclesTooLow purchase_position_fee: ${Cycles.oftheNat((fee_record as Record)['purchase_position_fee']!)}');
                            },
                            'CyclesMarketIsBusy': (nul) {
                                throw Exception('The cycles-market is busy. try soon.');
                            },
                            'CallerIsInTheMiddleOfACreateIcpPositionOrPurchaseCyclesPositionOrTransferIcpBalanceCall': (nul) {
                                throw Exception('The cycles-bank is in the middle of a call for the cycles-market.');    
                            },
                            'CheckUserCyclesMarketIcpLedgerBalanceError': (call_error_record) {
                                throw Exception('Error calling the icp-ledger for the cycles-bank\'s cycles-market-icp-balance.\n${CallError.oftheRecord(call_error_record as Record)}');
                            },
                            'UserIcpBalanceTooLow': (user_icp_balance_record) {
                                this.cm_icp_balance = IcpTokens.oftheRecord((user_icp_balance_record as Record)['user_icp_balance']!);
                                throw Exception('The cycles-bank\'s cycles-market-icp-balance is too low for the purchase. \ncycles-bank\'s cycles-market-icp-balance: ${this.cm_icp_balance!}\npurchase_cycles: ${purchase_cycles}\nicp-cost of these cycles in this cycles-position: ${cycles_position_purchase_cycles_icp_cost}, icp-ledger-transfer-fee: ${ICP_LEDGER_TRANSFER_FEE}');
                            },
                            'CyclesPositionNotFound':(nul) {
                                throw Exception('The cycles-position is not found. perhaps it has already been purchased.');
                            },
                            'CyclesPositionCyclesIsLessThanThePurchaseQuest': (cycles_position_cycles_record) {
                                // update the cycles-position-cycles
                                
                                throw Exception('This cycles-position: ${cycles_position.id} has ${Cycles.oftheNat((cycles_position_cycles_record as Record)['cycles_position_cycles']! as Nat)} for the sale.\nperhaps some cycles of the cycles-position was purchased.');
                            },
                            'CyclesPositionMinimumPurchaseIsGreaterThanThePurchaseQuest': (cycles_position_minimum_purchase_record) {
                                throw Exception('File this error: CyclesPositionMinimumPurchaseIsGreaterThanThePurchaseQuest\nThe minimum-purchase of this cycles-position is ${Cycles.oftheNat((cycles_position_minimum_purchase_record as Record)['cycles_position_minimum_purchase']!)}');
                            }                               
                        });
                    }
                });
            }
        });
        this.metrics!.cm_cycles_positions_purchases_len = this.metrics!.cm_cycles_positions_purchases_len + BigInt.from(1);
        await this.fresh_cm_cycles_positions_purchases();
        return purchase_cycles_position_success;
    }
    
    Future<PurchaseIcpPositionSuccess> cm_purchase_icp_position(IcpPosition icp_position, IcpTokens purchase_icp) async {
        if (icp_position.minimum_purchase > purchase_icp) {
            throw Exception('The minimum-purchase of this icp-position is ${icp_position.minimum_purchase}');
        }
        if (icp_position.icp < purchase_icp) {
            throw Exception('This icp-position: ${icp_position.id} has ${icp_position.icp} for the sale.');
        }    
        // the cycles-bank checks that the cycles-bank's-cycles_balance is good for this purchase
        Variant sponse = c_backwards(
            await user.call(
                this,
                method_name: 'cm_purchase_icp_position',
                calltype: CallType.call,
                put_bytes: c_forwards([
                    CyclesBankCMPurchaseIcpPositionQuest(
                        cycles_market_purchase_icp_position_quest: CyclesMarketPurchaseIcpPositionQuest(
                            icp_position_id: icp_position.id, 
                            icp: purchase_icp
                        ),
                        icp_position_xdr_permyriad_per_icp_rate: icp_position.xdr_permyriad_per_icp_rate
                    )
                ])
            )
        ).first as Variant;
        PurchaseIcpPositionSuccess purchase_icp_position_success = match_variant<PurchaseIcpPositionSuccess>(sponse, {
            Ok:(ok){
                return PurchaseIcpPositionSuccess.oftheRecord(ok as Record);
            },
            Err: (cycles_bank_cm_purchase_icp_position_error){
                return match_variant<Never>(cycles_bank_cm_purchase_icp_position_error as Variant, {
                    'CTSFuelTooLow': (nul) {
                        throw Exception('The CTSFuel is too low. Topup the CTSFuel in this cycles-bank.');
                    },
                    'MemoryIsFull': (nul) {
                        throw Exception('The memory is full in the cycles-bank. Grow the memory or free some space.');
                    },
                    'CyclesBalanceTooLow': (r_ctype) {
                        Record r = r_ctype as Record;
                        this.metrics!.cycles_balance = Cycles.oftheNat(r['cycles_balance']!);
                        throw Exception('The cycles-balance is too low in the cycles-bank.\ncycles-balance: ${Cycles.oftheNat(r['cycles_balance']!)}\ncycles-market-purchase-position-fee: ${Cycles.oftheNat(r['cycles_market_purchase_position_fee']!)}\ncost for a purchase of the ${purchase_icp}-icp of the icp-position: ${icp_position.id} with the xdr-icp-rate: ${icp_position.xdr_permyriad_per_icp_rate} is: ${icptokens_to_cycles(purchase_icp, icp_position.xdr_permyriad_per_icp_rate)}');
                    },
                    'CyclesMarketPurchaseIcpPositionCallError': (call_error_record) {
                        throw Exception('cycles-market purchase_icp_position call error:\n${CallError.oftheRecord(call_error_record as Record)}');                    
                    },
                    'CyclesMarketPurchaseIcpPositionError': (cycles_market_purchase_icp_position_error) {
                        return match_variant<Never>(cycles_market_purchase_icp_position_error as Variant, {
                            'MsgCyclesTooLow': (fee_record) {
                                throw Exception('File this error: \nMsgCyclesTooLow purchase_position_fee: ${Cycles.oftheNat((fee_record as Record)['purchase_position_fee']!)}');
                            },
                            'CyclesMarketIsBusy': (nul) {
                                throw Exception('The cycles-market is busy. try soon.');
                            },
                            'IcpPositionNotFound': (nul) {
                                throw Exception('The icp-position is not found. perhaps it has already been purchased.');
                            },
                            'IcpPositionIcpIsLessThanThePurchaseQuest': (icp_position_icp_record) {
                                throw Exception('This icp-position: ${icp_position.id} has ${IcpTokens.oftheRecord((icp_position_icp_record as Record)['icp_position_icp']! as Record)} for the sale.\nperhaps some icp of the icp-position was purchased.');
                            },
                            'IcpPositionMinimumPurchaseIsGreaterThanThePurchaseQuest':(icp_position_minimum_purchase_record){
                                throw Exception('File this error: IcpPositionMinimumPurchaseIsGreaterThanThePurchaseQuest\nThe minimum-purchase of this icp-position is ${IcpTokens.oftheRecord((icp_position_minimum_purchase_record as Record)['icp_position_minimum_purchase']!)}');
                            }
                        });
                    }
                });
            }
        });
        this.metrics!.cm_icp_positions_purchases_len = this.metrics!.cm_icp_positions_purchases_len + BigInt.from(1);
        await this.fresh_cm_icp_positions_purchases();
        return purchase_icp_position_success;
    }
    
    
    Future<void> cm_void_position(BigInt position_id) async {
        Variant sponse = c_backwards(
            await user.call(
                this,
                method_name: 'cm_void_position',
                calltype: CallType.call,
                put_bytes: c_forwards([
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
                            'CyclesMarketIsBusy': (nul) {
                                throw Exception('The cycles-market is busy. try soon.');
                            },
                            'PositionNotFound': (nul) {
                                throw Exception('The position is not found. Perhaps it has been purchased.');
                            },
                        });
                    }                    
                });
            }
        });
    }

    Future<BigInt/*block_height*/> cm_transfer_icp_balance(CyclesMarketTransferIcpBalanceQuest q) async {
        Variant sponse = c_backwards(
            await user.call(
                this,
                method_name: 'cm_transfer_icp_balance',
                calltype: CallType.call,
                put_bytes: c_forwards([q])
            )
        ).first as Variant;
        BigInt block_height = match_variant<BigInt>(sponse, {
            Ok: (block_height_nat64) {
                return (block_height_nat64 as Nat64).value;
            },
            Err: (transfer_icp_balance_error) {
                return match_variant<Never>(transfer_icp_balance_error as Variant, {
                    'CTSFuelTooLow': (nul) {
                        throw Exception('The CTSFuel is too low. Topup the CTSFuel in this cycles-bank.');
                    },
                    'MemoryIsFull': (nul) {
                        throw Exception('The memory is full in the cycles-bank. Grow the memory or free some space.');
                    },
                    'CyclesBalanceTooLow': (r_ctype){
                        Record r = r_ctype as Record;
                        this.metrics!.cycles_balance = Cycles.oftheNat(r['cycles_balance'] as Nat);
                        throw Exception('The cycles-balance is too low on this cycles-bank.\ncycles_balance: ${Cycles.oftheNat(r['cycles_balance'] as Nat)}\ncycles_market_transfer_icp_balance_fee: ${Cycles.oftheNat(r['cycles_market_transfer_icp_balance_fee']!)}');
                    },
                    'CyclesMarketTransferIcpBalanceCallError': (call_error_record) {
                        throw Exception('cycles_market transfer_icp_balance call_error: \n${CallError.oftheRecord(call_error_record as Record)}');
                    },
                    'CyclesMarketTransferIcpBalanceError': (cycles_market_transfer_icp_balance_error) {
                        return match_variant<Never>(cycles_market_transfer_icp_balance_error as Variant, {
                            'MsgCyclesTooLow': (r){
                                throw Exception('File this error: MsgCyclesTooLow \n${r}');
                            },
                            'CyclesMarketIsBusy': (nul) {
                                throw Exception('The cycles-market is busy. try soon.');
                            },
                            'CallerIsInTheMiddleOfACreateIcpPositionOrPurchaseCyclesPositionOrTransferIcpBalanceCall': (nul){
                                throw Exception('The cycles-bank is in the middle of a call for the cycles-market.');
                            },
                            'CheckUserCyclesMarketIcpLedgerBalanceCallError': (call_error_record) {
                                throw Exception('Icp-ledger balance call error: \n${CallError.oftheRecord(call_error_record as Record)}');
                            },
                            'UserIcpBalanceTooLow': (r) {
                                this.cm_icp_balance = IcpTokens.oftheRecord((r as Record)['user_icp_balance']!);
                                throw Exception('The cycles-bank\'s cycles-market-icp-balance is too low for this transfer.\nicp_balance: ${this.cm_icp_balance}');
                            },
                            'IcpTransferCallError':(call_error_record) {
                                throw Exception('Icp-ledger transfer call error: \n${CallError.oftheRecord(call_error_record as Record)}');
                            },
                            'IcpTransferError': (icp_transfer_error){
                                return match_variant<Never>(icp_transfer_error as Variant, this.user.icp_transfer_error_match_map);
                            }
                        });
                    }                
                });
            }
        });
        this.metrics!.cm_icp_transfers_out_len = this.metrics!.cm_icp_transfers_out_len + BigInt.from(1);
        await this.fresh_cm_icp_transfers_out();
        return block_height;
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
                    'CyclesBalanceTooLow': (cycles_balance_record) { 
                        this.metrics!.cycles_balance = Cycles.oftheNat((cycles_balance_record as Record)['cycles_balance']!);
                        throw Exception('The cycles_balance is too low.');
                    }
                });
            }
        });    
        await this.fresh_metrics();
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
                        throw Exception('The minimum days that the lifetime of this cycles-bank can lengthen is ${((nat as Nat).value - this.metrics!.lifetime_termination_timestamp_seconds)/BigInt.from(60)/60/24}');
                    },
                    'CyclesBalanceTooLow': (r_ctype){
                        Record r = r_ctype as Record;
                        this.metrics!.cycles_balance = Cycles.oftheNat(r['cycles_balance']!);
                        throw Exception('The cycles_balance in the cycles-bank is too low.\ncost to lengthen the lifetime for ${ (q.set_lifetime_termination_timestamp_seconds - this.metrics!.lifetime_termination_timestamp_seconds)/BigInt.from(60)/60/24 }-days: ${Cycles.oftheNat(r['lengthen_cost_cycles']!)}\ncycles_balance: ${this.metrics!.cycles_balance}');
                    },
                    'CBSMCallError': (call_error_record) {
                        throw Exception('cbsm call error: ${CallError.oftheRecord(call_error_record as Record)}');
                    }   
                });
            }
        });
        await this.fresh_metrics();
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
                        throw Exception('The minimum new storage size is: ${((r_c as Record)['minimum_new_storage_size_mib'] as Nat).value} MiB');
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
        await this.fresh_metrics();
    }

    
    
}





typedef CTSFuel = Cycles;







class CyclesBankMetrics {
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
            cycles_balance: Cycles.oftheNat(r['cycles_balance'] as Nat),
            ctsfuel_balance: CTSFuel.oftheNat(r['ctsfuel_balance'] as Nat),
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
            cycles: Cycles.oftheNat(r['cycles'] as Nat),
            cycles_transfer_memo: CyclesTransferMemo.oftheVariant(r['cycles_transfer_memo'] as Variant),
            timestamp_nanos: (r['timestamp_nanos'] as Nat).value,
        );
    }
}


class CyclesTransferOut {
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
            fee_paid: Cycles.oftheNat(r['fee_paid'] as Nat64)
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
            xdr_permyriad_per_icp_rate: XDRICPRate.oftheNat64(r['xdr_permyriad_per_icp_rate'] as Nat64),
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
            xdr_permyriad_per_icp_rate: XDRICPRate.oftheNat64(r['xdr_permyriad_per_icp_rate'] as Nat64),
            create_position_fee: Cycles(cycles: (r['create_position_fee'] as Nat64).value),
            timestamp_nanos: (r['timestamp_nanos'] as Nat).value
        );
    }

}


class CMCyclesPositionPurchase {
    final BigInt cycles_position_id;
    final XDRICPRate cycles_position_xdr_permyriad_per_icp_rate;
    final BigInt id;
    final Cycles cycles;
    final Cycles purchase_position_fee;
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
            cycles_position_xdr_permyriad_per_icp_rate: XDRICPRate.oftheNat64(r['cycles_position_xdr_permyriad_per_icp_rate'] as Nat64),
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
    final BigInt id;
    final IcpTokens icp;
    final Cycles purchase_position_fee;
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
            icp_position_xdr_permyriad_per_icp_rate: XDRICPRate.oftheNat64(r['icp_position_xdr_permyriad_per_icp_rate'] as Nat64),
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
    final XDRICPRate xdr_icp_rate;
    CreateCyclesPositionQuest({
        required this.cycles,
        required this.minimum_purchase,
        required this.xdr_icp_rate
    }) {
        this['cycles']= this.cycles;
        this['minimum_purchase']= this.minimum_purchase;
        this['xdr_permyriad_per_icp_rate']= this.xdr_icp_rate;
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



class CreateIcpPositionQuest extends Record {
    final IcpTokens icp;
    final IcpTokens minimum_purchase;
    final XDRICPRate xdr_icp_rate;
    CreateIcpPositionQuest({
        required this.icp,
        required this.minimum_purchase,
        required this.xdr_icp_rate
    }) {
        this['icp']= this.icp;
        this['minimum_purchase']= this.minimum_purchase;
        this['xdr_permyriad_per_icp_rate']= this.xdr_icp_rate;
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
    CyclesBankCMPurchaseCyclesPositionQuest({
        required this.cycles_market_purchase_cycles_position_quest,
        required this.cycles_position_xdr_permyriad_per_icp_rate,
    }) {
        this['cycles_market_purchase_cycles_position_quest'] = this.cycles_market_purchase_cycles_position_quest;
        this['cycles_position_xdr_permyriad_per_icp_rate'] = this.cycles_position_xdr_permyriad_per_icp_rate;
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
    CyclesBankCMPurchaseIcpPositionQuest({
        required this.cycles_market_purchase_icp_position_quest,
        required this.icp_position_xdr_permyriad_per_icp_rate
    }) {
        this['cycles_market_purchase_icp_position_quest'] = this.cycles_market_purchase_icp_position_quest;
        this['icp_position_xdr_permyriad_per_icp_rate'] = this.icp_position_xdr_permyriad_per_icp_rate;
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


