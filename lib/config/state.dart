import 'dart:typed_data';
import 'dart:convert';
import 'dart:math';
import 'dart:html' show window, CryptoKey, Event;
import 'dart:js_util';
import 'dart:async';


import 'package:js/js.dart';
import 'package:js/js_util.dart';

import 'package:ic_tools/ic_tools.dart';
import 'package:ic_tools/tools.dart';
import 'package:ic_tools/candid.dart' show
    c_backwards,
    c_forwards,
    c_forwards_one,
    c_backwards_one,
    CandidType,
    Nat,
    Int,
    Nat64,
    Option,
    Vector,
    Blob,
    Record,
    Variant,
    Nat8,
    Nat32,
    Bool,
    match_variant,
    candid_text_hash
    ;
import 'package:ic_tools/candid.dart' as candid;
import 'package:ic_tools/common.dart' show IcpTokens, Icrc1Ledger, Icrc1Ledgers, Icrc1Account, Tokens, Ok, Err;
import 'package:ic_tools/common.dart' as common;
import 'package:ic_tools/common_web.dart';

import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';
import 'package:cbor/simple.dart' as cbor_simple;
import 'package:data_table_2/data_table_2.dart';


import 'urls.dart';
import '../cycles_market/cycles_market.dart';
import '../user.dart';
import '../transfer_icp/icp_ledger.dart';
import '../tests/test.dart' as t;




late final Canister cts;
late final Canister cycles_market;
late final Canister bank;


late final String cts_main_icp_id;

const String em3jm = 'em3jm-bqaaa-aaaar-qabxa-cai';

const String x3ncx = 'x3ncx-liaaa-aaaam-qbcfa-cai';

final bool is_on_local = window.location.hostname!.contains('localhost') || window.location.hostname!.contains('127.0.0.1');


class CustomState {

    CustomState() {
        
        if (window.location.hostname!.contains(em3jm) || window.location.hostname!.contains('cycles-transfer-station.com')) {
            cts = Canister(Principal.text(em3jm));
            cycles_market = Canister(Principal.text('el2py-miaaa-aaaar-qabxq-cai'));
            bank = Canister(Principal.text('wwikr-gqaaa-aaaar-qacva-cai'));
        } else if (window.location.hostname!.contains(x3ncx)) {
            cts = Canister(Principal.text(x3ncx)); 
            cycles_market = Canister(Principal.text('x4med-gqaaa-aaaam-qbcfq-cai'));
            bank = Canister(Principal.text('ul6ir-xiaaa-aaaam-qbcna-cai'));
        } else if (is_on_local) {
            /// local replica 
            ic_base_url = Uri.parse('http://127.0.0.1:8080');
            fetch_root_key().then((_x){});
            cts = Canister(Principal.bytes(Uint8List.fromList(utf8.encode('cts_local_'))));
            cycles_market = Canister(Principal.bytes(Uint8List.fromList(utf8.encode('cm_local__'))));
            bank = Canister(Principal.bytes(Uint8List.fromList(utf8.encode('bank_local'))));
        } else {
            throw Exception('unknown stance');
        }
        
        
        cts_main_icp_id = common.icp_id(cts.principal);
        
        print('CTS-MAIN: ${cts.principal.text}.');
        
        dataTableShowLogs = false; // for the data_table_2 package
        
        current_icrc1_ledger = CYCLES_BANK_LEDGER; // set here cause can only use CYCLES_BANK_LEDGER after bank-variable is set.
        known_icrc1_ledgers = [CYCLES_BANK_LEDGER];
        
    }    
    
    
    bool first_show_scaffold = false;

    CustomUrl current_url = CustomUrl('welcome');
    
    String loading_text = 'loading ...';
    bool is_loading = true; // state starts loading. the router sets the is_loading=false and calls tifyListeners() on a successfull completion of the load_first_state function. 
    
    Completer show_loading_page_transition_completer = Completer();
    
    late BuildContext _scontext; 
    
    void set context(BuildContext c) { this._scontext = c; }
    BuildContext get context => this._scontext;
        
    CyclesPerTokenRateWithATimestamp? cmc_cycles_per_icp_rate_with_a_timestamp;
    CyclesPerTokenRate get cmc_cycles_per_icp_rate => this.cmc_cycles_per_icp_rate_with_a_timestamp!.cycles_per_token_rate;
    
    CyclesMarketMain cm_main = CyclesMarketMain();
    
    int cm_main_icrc1token_trade_contracts_i = 0;
    
    User? user;
    
    late Icrc1Ledger current_icrc1_ledger; // for the selection of the bank-page-token // late cause bank is set in the constructor; 
    late List<Icrc1Ledger> known_icrc1_ledgers;// late cause bank is set in the constructor;

    Future<void> loadfirststate() async { 
        print('load first state');
        
        Future cycles_market_main_fresh_icrc1token_trade_contracts_future = Future(()async{
            await this.cm_main.fresh_icrc1token_trade_contracts();
            this.known_icrc1_ledgers.addAll(this.cm_main.trade_contracts.map((tc)=>tc.ledger_data));
        });
        
        await Future.wait([
            this.fresh_xdr_icp_rate(),
            cycles_market_main_fresh_icrc1token_trade_contracts_future,
            Future(()async{ 
                await this.load_state_of_the_browser_storage();
                if (this.user != null) {
                    print('load user');
                    await cycles_market_main_fresh_icrc1token_trade_contracts_future;
                    this.user!.fresh_known_cm_trade_contracts_of_the_cm_main();
                    
                    // get back cm escrow funds
                    Future.wait(this.cm_main.trade_contracts.map((tc)=>Future(()async{
                        await this.user!.fresh_cm_trade_contracts_balances([tc]);
                        if (this.user!.cm_trade_contracts[tc]!.trade_contract_token_balance > tc.ledger_data.fee) {
                            try{
                                await this.user!.cm_transfer_balance(
                                    tc,
                                    CyclesMarketTransferBalanceQuest(                                
                                        amount: this.user!.cm_trade_contracts[tc]!.trade_contract_token_balance - tc.ledger_data.fee,
                                        ledger_transfer_fee: tc.ledger_data.fee,
                                        to: Icrc1Account(owner: this.user!.principal),
                                    ),
                                    PositionKind.Token
                                );
                            } catch(cm_transfer_balance_error) {
                                print('Error transfer cm token balance:\n${cm_transfer_balance_error}');
                            }
                        } 
                        if (this.user!.cm_trade_contracts[tc]!.trade_contract_cycles_balance > CYCLES_BANK_LEDGER.fee) {
                            try{
                                await this.user!.cm_transfer_balance(
                                    tc,
                                    CyclesMarketTransferBalanceQuest(                                
                                        amount: this.user!.cm_trade_contracts[tc]!.trade_contract_cycles_balance - CYCLES_BANK_LEDGER.fee,
                                        ledger_transfer_fee: CYCLES_BANK_LEDGER.fee,
                                        to: Icrc1Account(owner: this.user!.principal),
                                    ),
                                    PositionKind.Cycles
                                );
                            } catch(cm_transfer_balance_error) {
                                print('Error transfer cm cycles balance:\n${cm_transfer_balance_error}');
                            }
                        }
                    }))).then((_x){});
                    
                    // makes sure that the loads are set in the first_load_-maps so that the router does not load them again.
                    this.user!.first_load_icrc1ledgers_balances[CYCLES_BANK_LEDGER] = this.user!.fresh_icrc1_balances([CYCLES_BANK_LEDGER]);
                    this.user!.first_load_icrc1ledgers_balances[Icrc1Ledgers.ICP] = this.user!.fresh_icrc1_balances([Icrc1Ledgers.ICP]);
                    this.user!.first_load_icrc1ledgers_transactions[CYCLES_BANK_LEDGER] = this.user!.fresh_icrc1_transactions([CYCLES_BANK_LEDGER]);
                    this.user!.first_load_icrc1ledgers_transactions[Icrc1Ledgers.ICP] = this.user!.fresh_icrc1_transactions([Icrc1Ledgers.ICP]);
                    await Future.wait([
                        this.user!.first_load_icrc1ledgers_balances[CYCLES_BANK_LEDGER]!,
                        this.user!.first_load_icrc1ledgers_balances[Icrc1Ledgers.ICP]!,
                        this.user!.first_load_icrc1ledgers_transactions[CYCLES_BANK_LEDGER]!,
                        this.user!.first_load_icrc1ledgers_transactions[Icrc1Ledgers.ICP]!,
                        this.user!.fresh_bank_user_subaccount_icp_balance(),
                    ]);
                    
                } 
            }),
        ]);
    }

    
    Future<void> fresh_xdr_icp_rate() async {
        // call the cmc
        //query call with the certification-data
        
        Uint8List sponse = await common.SYSTEM_CANISTERS.cycles_mint.call(
            calltype: CallType.query,
            method_name: 'get_icp_xdr_conversion_rate',
        );
        List<CandidType> cs = c_backwards(sponse);
        Record rc = cs[0] as Record;
        Uint8List certificate_bytes = (rc['certificate'] as Blob).bytes;
        Map certificate = cbor_simple.cbor.decode(certificate_bytes) as Map;
        await verify_certificate(certificate);
        BigInt btime = leb128.decodeUnsigned(lookup_path_value_in_an_ic_certificate_tree(certificate['tree'], _pathbytes(['time']))!);
        if (btime < get_current_time_nanoseconds() - BigInt.from(30*1000000000)) { throw Exception('time is too old on the certificate'); }
        Uint8List certified_data = lookup_path_value_in_an_ic_certificate_tree(certificate['tree'], _pathbytes(['canister', common.SYSTEM_CANISTERS.cycles_mint.principal.bytes, 'certified_data']))!;
        List canister_hash_tree = cbor_simple.cbor.decode((rc['hash_tree'] as Blob).bytes) as List;
        Uint8List treeroothash = construct_ic_system_state_tree_root_hash(canister_hash_tree);
        if (!aresamebytes(certified_data, treeroothash)) { throw Exception('certified data doesn\'t match the tree'); }
        Record certified_icpxdrrate = c_backwards(lookup_path_value_in_an_ic_certificate_tree(canister_hash_tree, _pathbytes(["ICP_XDR_CONVERSION_RATE"]))!)[0] as Record;
        //Record r = rc['data'] as Record;
        //print(r['xdr_permyriad_per_icp']);
        //print(r['timestamp_seconds']);
        Nat64 certified_xdr_permyriad_per_icp = certified_icpxdrrate['xdr_permyriad_per_icp'] as Nat64;
        Nat64 certified_timestamp_seconds = certified_icpxdrrate['timestamp_seconds'] as Nat64;

        this.cmc_cycles_per_icp_rate_with_a_timestamp = CyclesPerTokenRateWithATimestamp(
            cycles_per_token_rate: CyclesPerTokenRate(cycles_per_token_quantum_rate: certified_xdr_permyriad_per_icp.value, token_decimal_places: Icrc1Ledgers.ICP.decimals),
            timestamp_seconds: certified_timestamp_seconds.value 
        );        
    }

    
    Future<void> save_state_in_the_browser_storage() async {
        if (this.user != null) {
            await this.user!.caller.indexdb_save();
        }
    }
    
    Future<void> load_state_of_the_browser_storage() async {
    
        IICaller? ii_caller = await IICaller.indexdb_load();
        
        if (ii_caller != null) {
            User user_of_the_idb = User(
                state: this,
                caller: ii_caller
            );    
            if (user_of_the_idb.expiration_timestamp_nanoseconds == null) {
                this.user = user_of_the_idb;
            } else if (get_current_time_nanoseconds() < user_of_the_idb.expiration_timestamp_nanoseconds! - BigInt.from(1000000000*60*10)) {
                // temporary condition for the first 30 days of the CTS. Take away at mid february.
                if (user_of_the_idb.expiration_timestamp_nanoseconds! >= BigInt.parse('1703759039499000000') + BigInt.from(Duration(days: 31).inMicroseconds * 1000)) {
                    this.user = user_of_the_idb;
                }
            }
            
        }

    }
    
}






Uint8List principal_as_an_icpsubaccountbytes(Principal principal) {
    List<int> bytes = []; // an icp subaccount is 32 bytes
    bytes.add(principal.bytes.length);
    bytes.addAll(principal.bytes);
    while (bytes.length < 32) { bytes.add(0); }
    return Uint8List.fromList(bytes);
}



Icrc1Ledger CYCLES_BANK_LEDGER = Icrc1Ledger(
    ledger: bank, 
    symbol: 'CYCLES', 
    name: 'CYCLES', 
    decimals: 12, 
    fee: BigInt.parse('10000000000'), 
); 





/*
class Cycles extends Nat {
    BigInt get cycles => super.value;
    
    String toString() {
        BigInt tcycles = this.cycles ~/ Cycles.T_CYCLES_DIVIDABLE_BY;
        BigInt cycles_less_than_1T = this.cycles % Cycles.T_CYCLES_DIVIDABLE_BY;
        String decimal_places = '';
        if (cycles_less_than_1T != BigInt.from(0)) {
            decimal_places = cycles_less_than_1T.toRadixString(10);
            while (decimal_places.length < 12) {
                decimal_places = '0${decimal_places}';
            }
            while (decimal_places[decimal_places.length-1] == '0') {
                decimal_places = decimal_places.substring(0, decimal_places.length-1);    
            }
            decimal_places = '.${decimal_places}';
        }
        String s = '${tcycles}${decimal_places}T';
        return s;
    }
    
    Cycles({required BigInt cycles}) : super(cycles);
    
    static Cycles oftheNat(CandidType nat) {
        return Cycles(
            cycles: (nat as Nat).value
        );
    }
    
    static BigInt T_CYCLES_DIVIDABLE_BY = BigInt.from(pow(10, Cycles.T_CYCLES_DECIMAL_PLACES));
    static int T_CYCLES_DECIMAL_PLACES = 12;    
    static Cycles oftheTCyclesDoubleString(String tcycles_string) {
        tcycles_string = tcycles_string.trim();
        if (tcycles_string == '') {
            throw Exception('must be a number');
        }
        List<String> tcycles_string_split = tcycles_string.split('.');
        if (tcycles_string_split.length > 2) {
            throw Exception('invalid number.');
        } 
        BigInt tcycles = BigInt.parse(tcycles_string_split[0]);
        BigInt cycles_less_than_1T = BigInt.from(0);        
        if (tcycles_string_split.length == 2) {
            String decimal_places = tcycles_string_split[1];        
            if (decimal_places.length > Cycles.T_CYCLES_DECIMAL_PLACES) {
                throw Exception('Max ${Cycles.T_CYCLES_DECIMAL_PLACES} decimal places for the TCycles');
            }
            while (decimal_places.length < Cycles.T_CYCLES_DECIMAL_PLACES) {
                decimal_places = '${decimal_places}0';
            }
            cycles_less_than_1T = BigInt.parse(decimal_places);
        }
        Cycles cycles = Cycles(cycles: (tcycles * Cycles.T_CYCLES_DIVIDABLE_BY) + cycles_less_than_1T);
        return cycles;
    }
*/
// TCycles
class Cycles extends Tokens {
    BigInt get cycles => super.quantums;
    
    String toString() {
        String s = super.toString();
        if (this.cycles != BigInt.from(0)) { s = s + 'T'; } 
        return s;
    }
    
    Cycles round_decimal_places(int round_decimal_places) {
        return Cycles(cycles: super.round_decimal_places(round_decimal_places).quantums);
    }
    
    Cycles add_quantums(BigInt add_quantums) {
        return Cycles(cycles: super.add_quantums(add_quantums).quantums);
    }
    
    Cycles({required BigInt cycles}) : super(quantums: cycles, decimal_places: T_CYCLES_DECIMAL_PLACES);
    
    static Cycles of_the_nat(CandidType nat) => Cycles.oftheNat(nat);
    
    static Cycles oftheNat(CandidType nat) {
        return Cycles(
            cycles: (nat as Nat).value
        );
    }
    
    static BigInt T_CYCLES_DIVIDABLE_BY = BigInt.from(pow(10, Cycles.T_CYCLES_DECIMAL_PLACES));
    static int T_CYCLES_DECIMAL_PLACES = 12;    
    
    static Cycles oftheTCyclesDoubleString(String tcycles_string) => Cycles(cycles: Tokens.of_the_double_string(tcycles_string, decimal_places: Cycles.T_CYCLES_DECIMAL_PLACES).quantums);
                    
    Cycles operator + (Cycles t) {
        return Cycles(cycles: this.cycles + t.cycles);
    }    
    Cycles operator - (Cycles t) {
        return Cycles(cycles: this.cycles - t.cycles);
    } 
    Cycles operator * (Cycles t) {
        return Cycles(cycles: this.cycles * t.cycles);
    } 
    Cycles operator ~/ (Cycles t) {
        return Cycles(cycles: this.cycles ~/ t.cycles);
    } 
    bool operator > (Cycles t) {
        return this.cycles > t.cycles;
    } 
    bool operator < (Cycles t) {
        return this.cycles < t.cycles;
    } 
    bool operator >= (Cycles t) {
        return this.cycles >= t.cycles;
    } 
    bool operator <= (Cycles t) {
        return this.cycles <= t.cycles;
    } 
    
    @override
    bool operator ==(covariant Cycles other) => other is Cycles && other.cycles == this.cycles;
    
} 


Cycles tokens_transform_cycles(BigInt token_quantums, Cycles cycles_per_token) {
    return Cycles(cycles: token_quantums * cycles_per_token.cycles);
}

BigInt cycles_transform_tokens(Cycles cycles, Cycles cycles_per_token) {
    return cycles.cycles ~/ cycles_per_token.cycles;
}



/*
final BigInt CYCLES_PER_XDR = Cycles.T_CYCLES_DIVIDABLE_BY;

Cycles icptokens_to_cycles(IcpTokens icpts, XDRICPRate xdr_icp_rate) {
    return Cycles(cycles: 
        icpts.e8s 
        * xdr_icp_rate.xdr_permyriad_per_icp 
        * CYCLES_PER_XDR 
        ~/ (IcpTokens.DIVIDABLE_BY * XDRICPRate.DIVIDABLE_BY)
    );
}

IcpTokens cycles_to_icptokens(Cycles cycles, XDRICPRate xdr_icp_rate) {
    return IcpTokens(e8s:
        cycles.cycles
        * (IcpTokens.DIVIDABLE_BY * XDRICPRate.DIVIDABLE_BY)
        ~/ CYCLES_PER_XDR
        ~/ xdr_icp_rate.xdr_permyriad_per_icp    
    );
}

XDRICPRate xdr_per_icp_rate_of_a_cycles_and_icp(Cycles cycles, IcpTokens icpts) {
    return XDRICPRate(xdr_permyriad_per_icp: cycles.cycles ~/ icpts.e8s);
}
*/









class CyclesPerTokenRate extends Cycles {
    final int token_decimal_places;
    CyclesPerTokenRate({required BigInt cycles_per_token_quantum_rate, required this.token_decimal_places}) : super(cycles: cycles_per_token_quantum_rate);
    BigInt get cycles_per_token_quantum_rate => super.cycles;
    static CyclesPerTokenRate oftheTCyclesDoubleString(String tcycles_string, {required int token_decimal_places}) {
        Tokens ts = Tokens.of_the_double_string(tcycles_string, decimal_places: Cycles.T_CYCLES_DECIMAL_PLACES - token_decimal_places); // makes sure the right number of decimal places
        return CyclesPerTokenRate(
            cycles_per_token_quantum_rate: ts.quantums,
            token_decimal_places: token_decimal_places
        );
    }
    String toString() => Cycles(cycles: this.cycles_per_token_quantum_rate * BigInt.from(pow(10, this.token_decimal_places))).toString();
    
    
    
    
    // operators
    _check_same_token_decimal_places(CyclesPerTokenRate a, CyclesPerTokenRate b) {
        if (a.token_decimal_places != b.token_decimal_places) {
            throw Exception('Cannot perform operation on a CyclesPerTokenRate with a different token_decimal_places.');
        }
    }
    CyclesPerTokenRate operator + (covariant CyclesPerTokenRate t) {
        _check_same_token_decimal_places(this, t);
        return CyclesPerTokenRate(
            cycles_per_token_quantum_rate: this.cycles_per_token_quantum_rate + t.cycles_per_token_quantum_rate,
            token_decimal_places: this.token_decimal_places // we checked that they both have the same token_decimal_places.
        );
    }    
    CyclesPerTokenRate operator - (covariant CyclesPerTokenRate t) {
        _check_same_token_decimal_places(this, t);
        return CyclesPerTokenRate(
            cycles_per_token_quantum_rate: this.cycles_per_token_quantum_rate - t.cycles_per_token_quantum_rate,
            token_decimal_places: this.token_decimal_places // we checked that they both have the same token_decimal_places.
        );
    } 
    CyclesPerTokenRate operator * (covariant CyclesPerTokenRate t) {
        _check_same_token_decimal_places(this, t);
        return CyclesPerTokenRate(
            cycles_per_token_quantum_rate: this.cycles_per_token_quantum_rate * t.cycles_per_token_quantum_rate,
            token_decimal_places: this.token_decimal_places // we checked that they both have the same token_decimal_places.
        );
    } 
    CyclesPerTokenRate operator ~/ (covariant CyclesPerTokenRate t) {
        _check_same_token_decimal_places(this, t);
        return CyclesPerTokenRate(
            cycles_per_token_quantum_rate: this.cycles_per_token_quantum_rate ~/ t.cycles_per_token_quantum_rate,
            token_decimal_places: this.token_decimal_places // we checked that they both have the same token_decimal_places.
        );
    } 
    bool operator > (covariant CyclesPerTokenRate t) {
        _check_same_token_decimal_places(this, t);
        return this.cycles_per_token_quantum_rate > t.cycles_per_token_quantum_rate;
    } 
    bool operator < (covariant CyclesPerTokenRate t) {
        _check_same_token_decimal_places(this, t);
        return this.cycles_per_token_quantum_rate < t.cycles_per_token_quantum_rate;
    } 
    bool operator >= (covariant CyclesPerTokenRate t) {
        _check_same_token_decimal_places(this, t);
        return this.cycles_per_token_quantum_rate >= t.cycles_per_token_quantum_rate;
    } 
    bool operator <= (covariant CyclesPerTokenRate t) {
        _check_same_token_decimal_places(this, t);
        return this.cycles_per_token_quantum_rate <= t.cycles_per_token_quantum_rate;
    } 
       
}

class CyclesPerTokenRateWithATimestamp {
    final CyclesPerTokenRate cycles_per_token_rate;
    final BigInt timestamp_seconds;
    CyclesPerTokenRateWithATimestamp({required this.cycles_per_token_rate, required this.timestamp_seconds});
}

class IcpTokensWithATimestamp {
    final IcpTokens icp;
    final BigInt timestamp_nanos;
    IcpTokensWithATimestamp({required this.icp, BigInt? opt_timestamp_nanos}) : timestamp_nanos = opt_timestamp_nanos==null ? get_current_time_nanoseconds() : opt_timestamp_nanos;
}

/*

class XDRICPRateWithATimestamp {
    final XDRICPRate xdr_icp_rate;
    final BigInt timestamp_seconds;
    XDRICPRateWithATimestamp({required this.xdr_icp_rate, required this.timestamp_seconds});
}



class XDRICPRate extends Nat64 {
    BigInt get xdr_permyriad_per_icp => super.value;
    
    XDRICPRate({required BigInt xdr_permyriad_per_icp}): super(xdr_permyriad_per_icp);
    
    static XDRICPRate oftheXdrPerMyriadPerIcpNat64(CandidType nat64) {
        return XDRICPRate(
            xdr_permyriad_per_icp: (nat64 as Nat64).value
        );
    }
    static XDRICPRate oftheDoubleString(String xdr_per_icp_string) {
        xdr_per_icp_string = xdr_per_icp_string.trim();
        if (xdr_per_icp_string == '') {
            throw Exception('must be a number');
        }
        List<String> xdr_per_icp_string_split = xdr_per_icp_string.split('.');
        if (xdr_per_icp_string_split.length > 2) {
            throw Exception('invalid number.');
        }
        BigInt xdr_per_icp = BigInt.parse(xdr_per_icp_string_split[0]);
        BigInt xdr_per_icp_less_than_1 = BigInt.from(0);
        if (xdr_per_icp_string_split.length == 2) {
            String decimal_places = xdr_per_icp_string_split[1];        
            if (decimal_places.length > XDRICPRate.DECIMAL_PLACES) {
                throw Exception('Max ${XDRICPRate.DECIMAL_PLACES} decimal places for the XDR/ICP rate');
            }
            while (decimal_places.length < XDRICPRate.DECIMAL_PLACES) {
                decimal_places = '${decimal_places}0';
            }
            xdr_per_icp_less_than_1 = BigInt.parse(decimal_places);
        }
        XDRICPRate xdricprate = XDRICPRate(xdr_permyriad_per_icp: (xdr_per_icp * XDRICPRate.DIVIDABLE_BY) + xdr_per_icp_less_than_1);
        return xdricprate;
    }
    String toString() {
        return '${this.xdr_permyriad_per_icp/XDRICPRate.DIVIDABLE_BY}';
    }
    
    static int DECIMAL_PLACES = 4;
    static BigInt DIVIDABLE_BY = BigInt.from(pow(10, XDRICPRate.DECIMAL_PLACES));
}
*/



class CallError {
    final int error_code;
    final String error_message;
    CallError({required this.error_code, required this.error_message});
    
    static CallError of_the_record(Record r) {
        return CallError(
            error_code: (r[0] as Nat32).value,
            error_message: (r[1] as candid.Text).value
        );
    }
    
    String toString() {
        return 'error_code: ${this.error_code}, error_message: ${this.error_message}';
    }
}







class CyclesTransferMemo extends Variant {
    CyclesTransferMemo._();
    
    static CyclesTransferMemo blob(Blob blob) {
        CyclesTransferMemo ctm = CyclesTransferMemo._();
        ctm['Blob'] = blob;
        return ctm;
    }
    static CyclesTransferMemo text(candid.Text text) {
        CyclesTransferMemo ctm = CyclesTransferMemo._();
        ctm['Text'] = text;
        return ctm;
    }
    static CyclesTransferMemo nat(Nat nat) {
        CyclesTransferMemo ctm = CyclesTransferMemo._();
        ctm['Nat'] = nat;
        return ctm;
    }
    static CyclesTransferMemo int_(Int int_) {
        CyclesTransferMemo ctm = CyclesTransferMemo._();
        ctm['Int'] = int_;
        return ctm;
    }
    static CyclesTransferMemo oftheVariant(Variant ctmvariant) {
        match_variant<void>(ctmvariant, {
            'Blob': (c) { if (c is! Blob) { throw Exception('CyclesTransferMemo Blob must be with the value of the Blob.'); } },
            'Text': (c) { if (c is! candid.Text) { throw Exception('CyclesTransferMemo Text must be with the value of the Text.'); } },
            'Nat': (c) { if (c is! Nat) { throw Exception('CyclesTransferMemo Nat must be with the value of the Nat.'); } },
            'Int': (c) { if (c is! Int) { throw Exception('CyclesTransferMemo Int must be with the value of the Int.'); } } 
        });
        CyclesTransferMemo ctm = CyclesTransferMemo._();
        ctm[ctmvariant.keys.first] = ctmvariant.values.first;
        return ctm;
    }
    
    String toString() {
        if (this.keys.first == candid_text_hash('Text')) {
            return '${(this.values.first as candid.Text).value}';
        }
        if (this.keys.first == candid_text_hash('Blob')) {
            return '${bytesasahexstring((this.values.first as Blob).bytes)}';
        }
        if (this.keys.first == candid_text_hash('Nat')) {
            return '${(this.values.first as Nat).value}';
        }
        if (this.keys.first == candid_text_hash('Int')) {
            return '${(this.values.first as Int).value}';
        }
        throw Exception('');
    }
    
}


DateTime datetime_of_the_nanoseconds(BigInt nanoseconds) {
    return DateTime.fromMillisecondsSinceEpoch((nanoseconds ~/ BigInt.from(1000000)).toInt());
}







class Icrc1Transaction {
    final BigInt block;
    final Icrc1TransactionKind icrc1_transaction_kind;
    final BigInt tokens;
    final Icrc1Account? to;  // null on a burn
    final Icrc1Account? from; // null on a mint
    final BigInt? created_at_time_nanos; 
    final BigInt timestamp_nanos; 
    final Uint8List? memo; // max 32 bytes
    final BigInt? fee; // null on a mint or a burn
    Icrc1Transaction({
        required this.block,
        required this.icrc1_transaction_kind,
        required this.tokens,
        required this.to,
        required this.from,
        required this.created_at_time_nanos,
        required this.timestamp_nanos,
        required this.memo,
        required this.fee,
    });
    static Icrc1Transaction of_the_record(Record tr) {
        Record tk = tr['transaction'] as Record;
        String kind = (tk['kind'] as candid.Text).value;
        Record t = tk.find_option<Record>(kind)!;
        return Icrc1Transaction(
            block: (tr['id'] as Nat).value,
            icrc1_transaction_kind: Icrc1TransactionKind.values.byName(kind),
            tokens: (t['amount'] as Nat).value, 
            to: t.find_option<Record>('to').nullmap(Icrc1Account.of_the_record), 
            from: t.find_option<Record>('from').nullmap(Icrc1Account.of_the_record),
            created_at_time_nanos: t.find_option<Nat64>('created_at_time').nullmap((n)=>n.value), 
            timestamp_nanos: (tk['timestamp'] as Nat64).value,
            memo: t.find_option<Vector>('memo').nullmap((v)=>Blob.of_the_vector_nat8(v.cast_vector<Nat8>()).bytes),
            fee: t.find_option<Nat>('fee').nullmap((m)=>m.value)
        );
    }
    String toString() {
        return '$block';
    }
}


enum Icrc1TransactionKind {
    mint,
    burn,
    transfer
}



// ------------------------------------------------------------





List<Uint8List> _pathbytes(List<dynamic> path) {
    // a path is a list of labels, see the ic-spec. 
    // this function converts string labels to utf8 blobs in a new-list for the convenience. 
    List<dynamic> pathb = [];
    for (int i=0;i<path.length;i++) { 
        pathb.add(path[i]);
        if (pathb[i] is String) {
            pathb[i] = utf8.encode(pathb[i]);    
        }
    }
    return List.castFrom<dynamic, Uint8List>(pathb);
}






































