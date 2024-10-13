import 'package:flutter/material.dart';
import 'package:ic_tools/ic_tools.dart';
import 'package:ic_tools/candid.dart' show c_forwards_one, c_backwards_one, Record, Vector, Nat;
import 'package:ic_tools/common.dart';

import '../config/state_bind.dart';
import '../bank/scaffold_body.dart';
import '../config/state.dart';
import '../config/urls.dart';
import '../tools/tools.dart';

class FutureAndLog {
    Future<void> future;
    Icrc1Transaction? log;
    String? error;
    FutureAndLog(this.future, this.log, this.error);
}


class ViewBankIcrc3LogScaffoldBody extends StatefulWidget {
    ViewBankIcrc3LogScaffoldBody({Key? key}) : super(key: key);
    static ViewBankIcrc3LogScaffoldBody create({Key? key}) => ViewBankIcrc3LogScaffoldBody(key: key);
    State createState() => ViewBankIcrc3LogScaffoldBodyState();
}
class ViewBankIcrc3LogScaffoldBodyState extends State<ViewBankIcrc3LogScaffoldBody> {
    Map<Canister, Map<BigInt, FutureAndLog>> cache = {};
    
    @override
    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
        
        // for now we only support the cts-cycles-bank
        if (state.current_url.variables['token_ledger_id'] != CYCLES_BANK_LEDGER.ledger.principal.text) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
                state.current_url = CustomUrl('void');
                MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
            });
            return Text('');
        }
        
        Canister ledger_of_the_url = Canister(Principal.text(state.current_url.variables['token_ledger_id']!));
        BigInt block_id_of_the_url = BigInt.parse(state.current_url.variables['block_id']!);
        
        if (cache[ledger_of_the_url] == null) {
            cache[ledger_of_the_url] = {};
        }
        if (cache[ledger_of_the_url]![block_id_of_the_url] == null) {
            cache[ledger_of_the_url]![block_id_of_the_url] = FutureAndLog(
                Future(()async{
                    // we don't follow any callbacks here bc for now we only support the cts-cycles-bank and for now the cts-cycles-bank doesn't use archives yet.
                    // when changing to support any icrc-1/3-ledger, make it follow callbacks when needed. 
                    // also make sure to support icrc-2 approve blocks and transfer-from account 
                    Record get_blocks_sponse = c_backwards_one(await ledger_of_the_url.call(
                        method_name: 'icrc3_get_blocks',
                        calltype: CallType.query,
                        put_bytes: c_forwards_one(Vector.of_the_list<Record>([
                            Record.of_the_map({
                                'start': Nat(block_id_of_the_url),
                                'length': Nat(BigInt.one),
                            })
                        ]))
                    )) as Record;
                    
                    Vector<Record> blocks = (get_blocks_sponse['blocks'] as Vector).cast_vector<Record>();
                    
                    if (blocks.isEmpty) {
                        throw Exception('Error, ledger did not return the requested block');
                    }
                                    
                    Icrc1Transaction t = Icrc1Transaction.of_the_icrc3_record(blocks.first);
                    
                    if (t.block != block_id_of_the_url) {
                        throw Exception('Error, ledger did not return the requested block');
                    }
                    
                    cache[ledger_of_the_url]![block_id_of_the_url]!.log = t;
                }).then((_x){
                    setState((){});
                }).catchError((err) {
                    cache[ledger_of_the_url]![block_id_of_the_url]!.error = err.toString();
                    setState((){});
                }),
                null,
                null,
            );
        }
        
        return Align(
            alignment: Alignment.center,
            child: cache[ledger_of_the_url]![block_id_of_the_url]!.log == null 
                ? Text(cache[ledger_of_the_url]![block_id_of_the_url]!.error != null ? etext(cache[ledger_of_the_url]![block_id_of_the_url]!.error!) : 'Loading block $block_id_of_the_url') 
                : Container(
                    height: 400,
                    child: Icrc1TransactionCard(
                        CYCLES_BANK_LEDGER,
                        cache[ledger_of_the_url]![block_id_of_the_url]!.log!
                    )
                )
        );
    }
}
