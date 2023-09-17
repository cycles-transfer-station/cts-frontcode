import 'dart:ui' as dart_ui;

import 'package:flutter/material.dart';

import 'package:ic_tools/tools.dart';
import 'package:ic_tools/common.dart';
import 'package:data_table_2/data_table_2.dart';

import '../config/state.dart';
import '../config/state_bind.dart';
import '../config/pages.dart';
import '../config/urls.dart';
import './cycles_market.dart';
import './chart.dart';
import './forms.dart';
import './cards.dart';
import '../cycles_bank/cycles_bank.dart';
import '../cycles_bank/forms.dart';
import '../main.dart';
import '../tools/widgets.dart';
import '../tools/ii_login.dart';
import '../tools/tools.dart';



// check the stop scroll functionality 



class CyclesMarketScaffoldBody extends StatefulWidget {
    CyclesMarketScaffoldBody({Key? key}) : super(key: key);
    static CyclesMarketScaffoldBody create({Key? key}) => CyclesMarketScaffoldBody(key: key);
    State<CyclesMarketScaffoldBody> createState() => CyclesMarketScaffoldBodyState();
}
class CyclesMarketScaffoldBodyState extends State<CyclesMarketScaffoldBody> {    

    bool stop_scroll = false; 
    
    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
    
        // set the state.cm_main_icrc1token_trade_contracts_i
        int cm_main_icrc1token_trade_contracts_index_where_current_url_token_ledger_symbol_matches_token_trade_contract_ledger_data_symbol 
            = state.cm_main.icrc1token_trade_contracts.indexWhere((tc)=>tc.ledger_data.symbol == state.current_url.variables['token_ledger_symbol']!);
        
        if (cm_main_icrc1token_trade_contracts_index_where_current_url_token_ledger_symbol_matches_token_trade_contract_ledger_data_symbol < 0) {
            state.current_url = CustomUrl('void');
            MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
        } else {
            state.cm_main_icrc1token_trade_contracts_i = cm_main_icrc1token_trade_contracts_index_where_current_url_token_ledger_symbol_matches_token_trade_contract_ledger_data_symbol;
        }
        
        
        
        
        List<Widget> column_children = [];
        
        column_children.addAll([
            SizedBox(
                height: 10,   
            ),
            Container(
                width: 900,
                child: Container(
                    margin: EdgeInsets.all(13),
                    child: Align(
                        alignment: Alignment.centerLeft,
                        child: DropdownButton<int>(
                            //decoration: InputDecoration(
                            //    labelText: 'Token'//state.user!.cycles_bank!.current_icrc1_ledger.symbol,
                            //),
                            underline: Container(
                                height: 0,
                                color: Colors.deepPurpleAccent,
                            ),
                            //isExpanded: false,
                            items: [
                                for (int i = 0; i < state.cm_main.icrc1token_trade_contracts.length; i++)                 
                                    DropdownMenuItem<int>(
                                        child: Container(
                                            padding: EdgeInsets.all(8),
                                            child: Text(state.cm_main.icrc1token_trade_contracts[i].ledger_data.symbol + ' / TCYCLES', style: TextStyle(fontSize: 22)), 
                                        ),
                                        value: i
                                    ),
                            ],
                            value: state.cm_main_icrc1token_trade_contracts_i,
                            onChanged: (int? select_i) { 
                                if (select_i is int) {
                                    if (select_i != state.cm_main_icrc1token_trade_contracts_i) { 
                                        state.current_url = CustomUrl(
                                            'cycles_market', 
                                            variables: {
                                                'token_ledger_symbol': state.cm_main.icrc1token_trade_contracts[select_i].ledger_data.symbol
                                            }
                                        );
                                        MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                                    }
                                }
                            }
                        )
                    )
                )
            ),
            CyclesMarketTradeContractTradePage(
                cm_main_icrc1token_trade_contracts_i: state.cm_main_icrc1token_trade_contracts_i,
                stop_scroll: (bool b) => setState((){ stop_scroll = b; }),
            )
        ]);
        
        return Center(
            child: Container(
                //constraints: BoxConstraints(maxWidth: 900),
                child: Column(
                    children: [
                        Container(
                            constraints: BoxConstraints(maxWidth: 900),
                            child: ScaffoldBodyHeader(Text('CYCLES-MARKET', style: TextStyle(fontSize: 19))),
                        ),
                        Expanded(
                            child: ListView(
                                padding: EdgeInsets.all(0),
                                physics: stop_scroll ? NeverScrollableScrollPhysics() : null,
                                children: [
                                    Column(
                                        children: column_children 
                                    )
                                ],
                                addAutomaticKeepAlives: true
                            )
                        )
                    ]
                )
            )
        );
    }
    
}


class CyclesMarketTradeContractTradePage extends StatefulWidget {
    int cm_main_icrc1token_trade_contracts_i;
    void Function(bool) stop_scroll;
    CyclesMarketTradeContractTradePage({
        required this.cm_main_icrc1token_trade_contracts_i,
        required this.stop_scroll
    }) : super(key: ValueKey<String>('CyclesMarketTradeContractTradePage cm_main_icrc1token_trade_contracts_i ${cm_main_icrc1token_trade_contracts_i}'));
    State<CyclesMarketTradeContractTradePage> createState() => CyclesMarketTradeContractTradePageState();
}
class CyclesMarketTradeContractTradePageState extends State<CyclesMarketTradeContractTradePage> {
    
    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
        
        
        return Container(
            child: Column(
                children: [ 
                    Wrap(
                        children: [
                            Container(
                                child: MarketTrades(cm_main_icrc1token_trade_contracts_i: widget.cm_main_icrc1token_trade_contracts_i) 
                            ),
                            MouseRegion(
                                child: Container(
                                    child: Chart(
                                        cm_main_icrc1token_trade_contracts_i: widget.cm_main_icrc1token_trade_contracts_i,
                                        key: ValueKey('CyclesMarketTradeContractTradePage Candlestick-Chart cm_main_icrc1token_trade_contracts_i ${widget.cm_main_icrc1token_trade_contracts_i}')
                                    ),
                                    constraints: BoxConstraints(maxHeight: 500, maxWidth: 900, minWidth: 300)
                                ),
                                onEnter: (event) {
                                    widget.stop_scroll(true);
                                },
                                onExit: (event) {
                                    widget.stop_scroll(false);
                                }
                            ),
                            Container(
                                child: PositionBook(cm_main_icrc1token_trade_contracts_i: widget.cm_main_icrc1token_trade_contracts_i)
                            ),  
                        ]
                    ),
                    if (state.user != null && state.user!.bank != null) Wrap(
                        children: [
                            Container(
                                child: CreatePositionWidget(cm_main_icrc1token_trade_contracts_i: widget.cm_main_icrc1token_trade_contracts_i)
                            )
                        ]
                    )
                ]
            )
        );
        
        
    }
    
}





class MarketTrades extends StatelessWidget {
    int cm_main_icrc1token_trade_contracts_i;
    MarketTrades({required this.cm_main_icrc1token_trade_contracts_i}) : super(key: ValueKey('CyclesMarketTradeContractTradePage MarketTrades cm_main_icrc1token_trade_contracts_i ${cm_main_icrc1token_trade_contracts_i}'));
    
    
    String timestamp_format(DateTime t) {
        return '${t.hour}:${t.minute}:${t.second}';
    }
    
    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
    
        return Container(
            padding: EdgeInsets.fromLTRB(10,17,10,17),
            constraints: BoxConstraints(
                maxHeight: 400,
                maxWidth: 400
            ),
            //decoration: BoxDecoration(border: Border.all()),
            child: DataTable2(
                //headingRowHeight: 0,
                showBottomBorder: true,
                columns: <DataColumn>[
                    DataColumn(label: Text('Quantity')),
                    DataColumn(label: Text('Rate')),
                    DataColumn(label: Text('Time'))
                ],
                rows: [
                    for (TradeItem trade in state.cm_main.icrc1token_trade_contracts[cm_main_icrc1token_trade_contracts_i].latest_trades.reversed) 
                        DataRow(
                            cells: [
                                DataCell(Text('${trade.quantity}')),
                                DataCell(Text('${trade.rate}', style: TextStyle(color: trade.kind == PositionKind.Cycles ? red : green /*when to make red or green?*/))),
                                DataCell(Text('${timestamp_format(datetime_of_the_nanos(trade.time_nanos))}'))
                            ]
                        ),
                ]
            )
        );
    }
}


class PositionBook extends StatelessWidget {
    int cm_main_icrc1token_trade_contracts_i;    
    PositionBook({required this.cm_main_icrc1token_trade_contracts_i}) : super(key: ValueKey('CyclesMarketTradeContractTradePage PositionBook cm_main_icrc1token_trade_contracts_i ${cm_main_icrc1token_trade_contracts_i}'));
    
    List<DataRow> create_position_book_data_rows(List<PositionBookItem> positions, PositionKind position_kind) {
        positions = positions..sort((a,b){return b.rate.cycles_per_token_quantum_rate.compareTo(a.rate.cycles_per_token_quantum_rate);}); 
        
        if (positions.length == 0) { return <DataRow>[]; }
        
        List<DataRow> datarows = [];

        Tokens quantity = Tokens(quantums: BigInt.from(0), decimal_places: positions.first.quantity.decimal_places); 
        CyclesPerTokenRate rate = positions.first.rate;
        
        bool is_buy_positions = position_kind == PositionKind.Cycles; 
        
        for (PositionBookItem position in positions) {    
            if (position.rate.cycles_per_token_quantum_rate == rate.cycles_per_token_quantum_rate) {
                quantity = Tokens(quantums: quantity.quantums + position.quantity.quantums, decimal_places: quantity.decimal_places);
            } else {
                datarows.add(
                    DataRow(
                        cells: [
                            DataCell(Text('${quantity}')),
                            DataCell(Text('${rate}', style: TextStyle(color: is_buy_positions ? green : red ))),
                            DataCell(Text('${tokens_transform_cycles(quantity.quantums, rate)}'))
                        ]
                    )
                );
                quantity = position.quantity; 
                rate = position.rate;
            }
        }
        // for the last positon
        datarows.add(
            DataRow(
                cells: [
                    DataCell(Text('${quantity}')),
                    DataCell(Text('${rate}', style: TextStyle(color: is_buy_positions ? green : red ))),
                    DataCell(Text('${tokens_transform_cycles(quantity.quantums, rate)}'))
                ]
            )
        );
        return datarows;
    }
    
    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
        
        return Container(
            constraints: BoxConstraints(maxHeight: 540, maxWidth: 400),
            child: Column(
                children: [
                    Flexible(
                        flex: 2,
                        child: DataTable2(
                            reverse: true,
                            showBottomBorder: true,
                            columns: <DataColumn>[
                                DataColumn(label: Text('Quantity')),
                                DataColumn(label:Text('Rate')),
                                DataColumn(label:  Text('Total'))
                            ],
                            rows: create_position_book_data_rows(state.cm_main.icrc1token_trade_contracts[cm_main_icrc1token_trade_contracts_i].sell_position_book, PositionKind.Token)
                        )    
                    ),
                    Text('middle widget, current/latest trade price'),
                    Flexible(
                        flex: 2,
                        child: DataTable2(
                            headingRowHeight: 0,
                            showBottomBorder: true,
                            columns: <DataColumn>[                                 
                                DataColumn(label: Text('Quantity')),
                                DataColumn(label:Text('Rate')),
                                DataColumn(label:  Text('Total'))
                            ],
                            rows: create_position_book_data_rows(state.cm_main.icrc1token_trade_contracts[cm_main_icrc1token_trade_contracts_i].buy_position_book, PositionKind.Cycles)
                        )
                    ),
                ]
            )
        );
    }
}


const Color green = const Color(0xFF26a69a);
const Color red = const Color(0xFFef5350);



class CreatePositionWidget extends StatelessWidget {
    final int cm_main_icrc1token_trade_contracts_i;
    CreatePositionWidget({super.key, required this.cm_main_icrc1token_trade_contracts_i});
    Widget build(BuildContext context) {
        
        return Container(
            //height: 300,
            width: 300,
            child: DefaultTabController(
                length: 2,
                child: Column(
                    children: [
                        Container(
                            //height: 50,
                            child: TabBar(
                                tabs: [
                                    Tab(text: 'BUY'),
                                    Tab(text: 'SELL'),
                                ],
                            )
                        ),
                        Container(
                            height: 300,
                            //width: 300,
                            child: TabBarView(
                                children: [
                                    CreatePositionForm(position_kind: PositionKind.Cycles, cm_main_icrc1token_trade_contracts_i: cm_main_icrc1token_trade_contracts_i),
                                    CreatePositionForm(position_kind: PositionKind.Token, cm_main_icrc1token_trade_contracts_i: cm_main_icrc1token_trade_contracts_i),
                                ],
                            ),
                        ),
                    ]
                )
            )
        );
        
    }
    
}



class CreatePositionForm extends StatefulWidget {
    final int cm_main_icrc1token_trade_contracts_i;
    final PositionKind position_kind;
    CreatePositionForm({super.key, required this.position_kind, required this.cm_main_icrc1token_trade_contracts_i});
    State<CreatePositionForm> createState() => CreatePositionFormState();
}
class CreatePositionFormState extends State<CreatePositionForm> {
    GlobalKey<FormState> form_key = GlobalKey<FormState>();
    
    late Tokens amount_tokens;
    late CyclesPerTokenRate cycles_per_token_rate;
    
    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);

        final String buy_or_sell = widget.position_kind == PositionKind.Cycles ? 'BUY' : 'SELL';
        final int token_decimal_places = state.cm_main.icrc1token_trade_contracts[widget.cm_main_icrc1token_trade_contracts_i].ledger_data.decimals;        
        final String token_symbol = state.cm_main.icrc1token_trade_contracts[widget.cm_main_icrc1token_trade_contracts_i].ledger_data.symbol;
        
        return Form(
            key: form_key,
            child: Column(
                children: <Widget>[
                    TextFormField(
                        decoration: InputDecoration(
                            labelText: '$token_symbol:',
                        ),
                        onSaved: (String? value) { amount_tokens = Tokens.of_the_double_string(value!, decimal_places: token_decimal_places); },
                        validator: tokens_validator(token_decimal_places: token_decimal_places)
                    ),
                    TextFormField(
                        decoration: InputDecoration(
                            labelText: 'rate:',
                        ),
                        onSaved: (String? value) { cycles_per_token_rate = CyclesPerTokenRate.oftheTCyclesDoubleString(value!, token_decimal_places: token_decimal_places); },
                        validator: cycles_per_token_rate_validator(token_decimal_places: token_decimal_places)
                    ),
                    Container(
                        width: double.infinity,
                        padding: EdgeInsets.fromLTRB(7, 17, 7,7),
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: blue),
                            child: Text('${buy_or_sell} ${token_symbol}'),
                            onPressed: () async {
                                if (form_key.currentState!.validate()==true) {
                                    
                                    form_key.currentState!.save();
                                    
                                    state.loading_text = 'creating ${buy_or_sell} position';
                                    state.is_loading = true;
                                    MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                                    
                                    MatchTokensQuest match_tokens_quest = MatchTokensQuest(
                                        tokens: amount_tokens,
                                        cycles_per_token_rate: cycles_per_token_rate,
                                    );
                                    
                                    late BigInt position_id;
                                    
                                    try {
                                        if (widget.position_kind == PositionKind.Cycles) {
                                            position_id = await state.user!.bank!.cm_buy_tokens(
                                                state.cm_main.icrc1token_trade_contracts[widget.cm_main_icrc1token_trade_contracts_i],
                                                match_tokens_quest
                                            );
                                        } else {
                                            position_id = await state.user!.bank!.cm_sell_tokens(
                                                state.cm_main.icrc1token_trade_contracts[widget.cm_main_icrc1token_trade_contracts_i],
                                                match_tokens_quest
                                            );
                                        }
                                    } catch(e,s) {
                                        //print(e);
                                        //print(s);
                                        
                                        await showDialog(
                                            context: state.context,
                                            builder: (BuildContext context) {
                                                return AlertDialog(
                                                    title: Text('$buy_or_sell $token_symbol error:'),
                                                    content: Text('${etext(e)}'),
                                                    actions: <Widget>[
                                                        TextButton(
                                                            onPressed: () => Navigator.pop(context),
                                                            child: const Text('OK'),
                                                        ),
                                                    ]
                                                );
                                            }   
                                        );                                    
                                        state.is_loading = false;
                                        main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);                                                                    
                                        return;
                                    }
                                    
                                    form_key.currentState!.reset();
                                    state.loading_text = '$buy_or_sell $token_symbol is success. \nposition-id: ${position_id}\nloading token balance and position data ...';
                                    main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);
                                    
                                    Future success_dialog = showDialog(
                                        context: state.context,
                                        builder: (BuildContext context) {
                                            return AlertDialog(
                                                title: Text('$buy_or_sell $token_symbol success!'),
                                                content: Text('Position-ID: ${position_id}'),
                                                actions: <Widget>[
                                                    TextButton(
                                                        onPressed: () => Navigator.pop(context),
                                                        child: const Text('OK'),
                                                    ),
                                                ]
                                            );
                                        }   
                                    ); 
                                    
                                    try {
                                        await Future.wait([
                                            state.user!.bank!.fresh_cm_trade_contracts_token_balances(state.cm_main.icrc1token_trade_contracts[widget.cm_main_icrc1token_trade_contracts_i]),
                                            state.user!.bank!.fresh_metrics(),
                                            state.cm_main.icrc1token_trade_contracts[widget.cm_main_icrc1token_trade_contracts_i].load_positions_and_trades()
                                        ]);
                                    } catch(e) {
                                        await showDialog(
                                            context: state.context,
                                            builder: (BuildContext context) {
                                                return AlertDialog(
                                                    title: Text('Error when loading the token balance and the position data:'),
                                                    content: Text('${etext(e)}'),
                                                    actions: <Widget>[
                                                        TextButton(
                                                            onPressed: () => Navigator.pop(context),
                                                            child: const Text('OK'),
                                                        ),
                                                    ]
                                                );
                                            }   
                                        );                                    
                                    }
                                
                                    await success_dialog;
                                    
                                    state.is_loading = false;
                                    main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);   
                                }
                            }
                        )
                    )
                ]
            )
        );               
    }
}




/*
class UserCMLogs extends StatefulWidget {
    UserCMLogs({super.key});
    State createState() => UserCMLogsState();
}
class UserCMLogsState extends State<UserCMLogs> {
    
    
    Widget build(BuildContext context) {
        return Container(
            child: AsyncPaginatedDataTable2(
                showBottomBorder: true,
                columns: [
                    DataColumn2(
                        label: Text('status'), // open or closed 
                        numeric: true,
                    )
                    DataColumn2(
                        label: Text('position-id'), 
                        numeric: true,
                    ),
                    DataColumn2( // maybe put in the dropdown data section onTap ?
                        label: Text('creation-time'), 
                        numeric: true,
                    ),
                    DataColumn2(
                        label: Text('original-position-tokens'), 
                        numeric: true,
                    ),
                    DataColumn2(
                        label: Text('original-position-rate'), 
                        numeric: true,
                    ),
                    DataColumn2(
                        label: Text('filled'), 
                        numeric: true,
                    ),
                    DataColumn2(
                        label: Text('filled average rate'), 
                        numeric: true,
                    ),
                    DataColumn2(
                        label: Text('current-position-tokens'), 
                        numeric: true,
                    ),
                ],
                source: CustomAsyncDataTableSource(),
                 
            )
        );    
    }
}


class CustomAsyncDataTableSource extends AsyncDataTableSource {
    
    Future<AsyncRowsResponse> getRows(int start, int end) async {
        
        // each row is a position. // onTap shows more about each trade? maybe a two line row without the onTap
        DataRow2(
            cells: [
                DataCell(Text('')),
                DataCell(Text('')),
                DataCell(Text('')),
                DataCell(Text('')),
                DataCell(Text('')),
                DataCell(Text('')),
                DataCell(Text('')),
                DataCell(Text('')),
            ],
            onTap: () {
                
            }
        )
        
        return AsyncRowsResponse(
            , /*total_rows:*/
            , /*rows:*/ 
            
        )
    }


}

*/













/*



class CyclesMarketScaffoldBody extends StatelessWidget {
    CyclesMarketScaffoldBody({Key? key}) : super(key: key);
    static CyclesMarketScaffoldBody create({Key? key}) => CyclesMarketScaffoldBody(key: key);
    
    final ScrollController user_cycles_positions_scroll_controller = ScrollController();
    final ScrollController user_icp_positions_scroll_controller = ScrollController();    
    final ScrollController user_cycles_positions_purchases_scroll_controller = ScrollController();
    final ScrollController user_icp_positions_purchases_scroll_controller = ScrollController();    
    final ScrollController cycles_positions_scroll_controller = ScrollController();
    final ScrollController icp_positions_scroll_controller = ScrollController();    
    final ScrollController cycles_positions_purchases_scroll_controller = ScrollController();
    final ScrollController icp_positions_purchases_scroll_controller = ScrollController();    
    
    
    
    @override
    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
        
         
        List<Widget> column_children = [];
                
        column_children.add(
            SizedBox(
                height: 21
            )
        );
        
        if (state.user == null) {
            column_children.addAll([
                Container(padding: EdgeInsets.all(17), child: OutlineButton(
                    button_text: 'ii login',
                    on_press_complete: () async { await ii_login(context); }
                ))       
            ]);
        } else if (state.user!.cycles_bank == null) {
            column_children.addAll([
                Container(
                    width: double.infinity,
                    height: 55,
                    constraints: BoxConstraints(maxWidth: 550),
                    padding: EdgeInsets.fromLTRB(11,0,11,17),
                    child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: blue),
                        child: Text('CREATE MEMBERSHIP', style: TextStyle(fontSize: 21)),
                        onPressed: () async {  
                            state.current_url = CustomUrl('cycles_bank');
                            main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);
                        }
                    )
                )
            ]);
        } else if (state.user != null && state.user!.cycles_bank != null) {
            column_children.addAll([
                Center(
                    child: Padding(
                        padding: EdgeInsets.all(17),
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: blue),
                            child: Text('LOAD CYCLES-MARKET DATA', style: TextStyle(fontSize:11)),
                            onPressed: () async {
                                state.loading_text = 'loading cycles-market data ...';
                                state.is_loading = true;
                                MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                                try {
                                    await Future.wait([
                                        state.cycles_market_data.load_data(),
                                        state.user!.cycles_bank!.fresh_metrics(),
                                        state.user!.cycles_bank!.load_cm_data()
                                    ]);
                                } catch(e) {
                                    await showDialog(
                                        context: state.context,
                                        builder: (BuildContext context) {
                                            return AlertDialog(
                                                title: Text('Error when loading the cycles-market data:'),
                                                content: Text('${e}'),
                                                actions: <Widget>[
                                                    TextButton(
                                                        onPressed: () => Navigator.pop(context),
                                                        child: const Text('OK'),
                                                    ),
                                                ]
                                            );
                                        }   
                                    );                                    
                                }
                                state.is_loading = false;
                                main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);
                            }
                        )
                    ),
                ),
                SizedBox(
                    width: 3,
                    height: 17
                ),
                Wrap(
                    children: [
                        Container(
                            padding: EdgeInsets.fromLTRB(0,0,0,17),
                            constraints: BoxConstraints(maxWidth: 350, minWidth: 250),
                            child: Column(
                                children: [
                                    Container(
                                        padding: EdgeInsets.fromLTRB(17,5,17,5),
                                        child: Column(
                                            children: [
                                                Center(
                                                    child: SelectableText('CYCLES-BANK-ID: ', style: TextStyle(fontSize: 13)),
                                                ),
                                                SizedBox(
                                                    height: 27,
                                                    child: Center(
                                                        child: SelectableText('${state.user!.cycles_bank!.principal.text}', style: TextStyle(fontSize: 11)),
                                                    ),
                                                ),
                                                Container(
                                                    padding: EdgeInsets.fromLTRB(10,7,10,3),
                                                    child: Text('CYCLES: ${state.user!.cycles_bank!.metrics != null ? state.user!.cycles_bank!.metrics!.cycles_balance : 'unknown'}', style: TextStyle(fontSize:17)),                   
                                                )
                                            ]
                                        )
                                    )
                                ]
                            ) 
                        ),
                        Container(
                            padding: EdgeInsets.fromLTRB(0,0,0,17),
                            constraints: BoxConstraints(maxWidth: 350, minWidth: 250),
                            child: Column(
                                children: [
                                    Container(
                                        padding: EdgeInsets.fromLTRB(17,5,17,5),
                                        child: Column(
                                            children: [
                                                Center(
                                                    child: SelectableText('CYCLES-BANK\'S CYCLES-MARKET ICP-ID: ', style: TextStyle(fontSize: 13)),
                                                ),
                                                SizedBox(
                                                    height: 27,
                                                    child: Center(
                                                        child: SelectableText('${state.user!.cycles_bank!.cm_icp_id}', style: TextStyle(fontSize: 11)),
                                                    ),
                                                ),
                                                Container(
                                                    padding: EdgeInsets.fromLTRB(10,7,10,3),
                                                    child: Text('ICP: ${state.user!.cycles_bank!.cm_icp_balance != null ? state.user!.cycles_bank!.cm_icp_balance! : 'unknown'}', style: TextStyle(fontSize:17)),                   
                                                )
                                            ]
                                        )
                                    ),
                                    /*
                                    Padding(
                                        padding: EdgeInsets.all(7),
                                        child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(backgroundColor: blue),
                                            child: Text('LOAD CM ICP BALANCE', style: TextStyle(fontSize:11)),
                                            onPressed: () async {
                                                state.loading_text = 'loading cycles-bank\'s cycles-market icp balance ...';
                                                state.is_loading = true;
                                                MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                                                try {
                                                    await state.user!.cycles_bank!.fresh_cm_icp_balance();
                                                } catch(e) {
                                                    await showDialog(
                                                        context: state.context,
                                                        builder: (BuildContext context) {
                                                            return AlertDialog(
                                                                title: Text('Error when loading the cycles-bank\'s cycles-market icp balance:'),
                                                                content: Text('${e}'),
                                                                actions: <Widget>[
                                                                    TextButton(
                                                                        onPressed: () => Navigator.pop(context),
                                                                        child: const Text('OK'),
                                                                    ),
                                                                ]
                                                            );
                                                        }   
                                                    );                                    
                                                }
                                                state.is_loading = false;
                                                main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);
                                            }
                                        )
                                    ),   
                                    */
                                    Padding(
                                        padding: EdgeInsets.all(7),
                                        child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(backgroundColor: blue),
                                            child: Text('WITHDRAW CM ICP BALANCE', style: TextStyle(fontSize:11)),
                                            onPressed: () async {
                                                await showDialog(
                                                    context: context,
                                                    builder: (BuildContext context) {
                                                        return AlertDialog(
                                                            title: Center(child: Text('Withdraw cycles-market icp-balance')),
                                                            content: Container(
                                                                padding: EdgeInsets.all(0),
                                                                child: CyclesBankCMTransferIcpForm(key: ValueKey('CyclesMarketScaffoldBody CyclesBankCMTransferIcpForm'))
                                                            ),
                                                            //actions: <Widget>[]
                                                        );
                                                    }   
                                                );
                                            }
                                        )
                                    ),   
                                    
                                ]
                            ) 
                        )
                    ]
                ),
                SizedBox(
                    width: 1,
                    height: 15
                ),
                Container(
                    padding: EdgeInsets.fromLTRB(10,17,10,17),
                    child: DataTable(
                        headingRowHeight: 0,
                        showBottomBorder: true,
                        columns: <DataColumn>[
                            DataColumn(
                                label: Expanded(
                                    child: Text(
                                        '',
                                    ),
                                ),
                            ),
                            DataColumn(
                                label: Expanded(
                                    child: Text(
                                        '',
                                    )
                                )
                            )
                        ],
                        rows: [
                            DataRow(
                                cells: [
                                    DataCell(Text('CREATE POSITION FEE: ')),
                                    DataCell(Text('0.05-TCycles')),
                                ]
                            ),
                            DataRow(
                                cells: [
                                    DataCell(Text('PURCHASE POSITION FEE: ')),
                                    DataCell(Text('0.05-TCycles')),
                                ]
                            )                            

                            
                        ]
                    )
                ),
                SizedBox(
                    height: 17,
                    width: 1    
                ),
                Wrap(
                    children: [
                        Container(
                            padding: EdgeInsets.all(11),
                            constraints: BoxConstraints(maxWidth: 350, minWidth: 250),
                            child: CyclesBankCMCreateCyclesPositionForm(key: ValueKey('CyclesBankScoffoldBody CyclesBankCMCreateCyclesPositionForm')),
                        ),
                        Container(
                            padding: EdgeInsets.all(11),
                            constraints: BoxConstraints(maxWidth: 350, minWidth: 250),
                            child: CyclesBankCMCreateIcpPositionForm(key: ValueKey('CyclesBankScoffoldBody CyclesBankCMCreateIcpPositionForm')),
                        )
                    ]
                ),
                Padding(
                    padding: EdgeInsets.all(13),
                    child: Divider(
                        height: 13.0,   
                        thickness: 4.0,
                        indent: 17.0,
                        endIndent: 17.0,
                        //color: 
                    ),
                ),    
            ]);
            
        }    
        
        List<CyclesPosition> cycles_positions = state.cycles_market_data.cycles_positions.reversed.toList();
        List<IcpPosition> icp_positions = state.cycles_market_data.icp_positions.reversed.toList();
        List<CyclesPositionPurchase> cycles_positions_purchases = state.cycles_market_data.cycles_positions_purchases.reversed.toList();
        List<IcpPositionPurchase> icp_positions_purchases = state.cycles_market_data.icp_positions_purchases.reversed.toList();
        
        
        if (state.user != null && state.user!.cycles_bank != null) {
            cycles_positions = cycles_positions.where((CyclesPosition cp)=>cp.positor.text != state.user!.cycles_bank!.principal.text).toList();
            icp_positions = icp_positions.where((IcpPosition ip)=>ip.positor.text != state.user!.cycles_bank!.principal.text).toList();
        }        
        
        if (state.user == null || state.user!.cycles_bank == null) {
            column_children.add(
                Padding(
                    padding: EdgeInsets.all(7),
                    child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: blue),
                        child: Text('LOAD CYCLES-MARKET DATA', style: TextStyle(fontSize:11)),
                        onPressed: () async {
                            state.loading_text = 'loading cycles-market data ...';
                            state.is_loading = true;
                            MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                            try {
                                await Future.wait([
                                    state.cycles_market_data.load_data()
                                ]);
                            } catch(e) {
                                await showDialog(
                                    context: state.context,
                                    builder: (BuildContext context) {
                                        return AlertDialog(
                                            title: Text('Error when loading the cycles-market positions:'),
                                            content: Text('${e}'),
                                            actions: <Widget>[
                                                TextButton(
                                                    onPressed: () => Navigator.pop(context),
                                                    child: const Text('OK'),
                                                ),
                                            ]
                                        );
                                    }   
                                );                                    
                            }
                            state.is_loading = false;
                            main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);
                        }
                    )
                )
            );
        }
        
        if (cycles_positions.length > 0) {
            column_children.addAll([
                Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(11,0,0,0),
                    child: Text('CYCLES-POSITIONS', style: TextStyle(fontSize: 17)),
                ),
                LimitedBox(
                    maxHeight: 407,
                    child: Container(
                        constraints: BoxConstraints(),
                        //padding: EdgeInsets.all(17),
                        child: ScrollConfiguration(
                            behavior: ScrollConfiguration.of(context).copyWith(dragDevices: ScrollConfiguration.of(context).dragDevices.toSet()..add(dart_ui.PointerDeviceKind.mouse), ),
                            child: Scrollbar(
                                controller: cycles_positions_scroll_controller,
                                child: ListView.builder(
                                    controller: cycles_positions_scroll_controller,
                                    key: UniqueKey(), //ValueKey('cm cycles-positions'),
                                    scrollDirection: Axis.horizontal,
                                    reverse: false,
                                    shrinkWrap: false,
                                    padding: EdgeInsets.all(7),
                                    itemBuilder: (BuildContext context, int i) {
                                        return CyclesPositionListItem(cycles_positions[i]);
                                    },
                                    itemCount: cycles_positions.length,
                                    addAutomaticKeepAlives: true,
                                    addRepaintBoundaries: true,
                                    addSemanticIndexes: true,
                                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
                                    clipBehavior: Clip.hardEdge
                                )
                            )
                        )
                    )
                )
            ]);
        }
        if (icp_positions.length > 0) {
            column_children.addAll([
                Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(11,0,0,0),
                    child: Text('ICP-POSITIONS', style: TextStyle(fontSize: 17)),
                ),
                LimitedBox(
                    maxHeight: 407,
                    child: Container(
                        constraints: BoxConstraints(),
                        //padding: EdgeInsets.all(17),
                        child: ScrollConfiguration(
                            behavior: ScrollConfiguration.of(context).copyWith(dragDevices: ScrollConfiguration.of(context).dragDevices.toSet()..add(dart_ui.PointerDeviceKind.mouse), ),
                            child: Scrollbar(
                                controller: icp_positions_scroll_controller,
                                child: ListView.builder(
                                    controller: icp_positions_scroll_controller,
                                    key: UniqueKey(), //ValueKey('cm icp-positions'),
                                    scrollDirection: Axis.horizontal,
                                    reverse: false,
                                    shrinkWrap: false,
                                    padding: EdgeInsets.all(7),
                                    itemBuilder: (BuildContext context, int i) {
                                        return IcpPositionListItem(icp_positions[i]);
                                    },
                                    itemCount: icp_positions.length,
                                    addAutomaticKeepAlives: true,
                                    addRepaintBoundaries: true,
                                    addSemanticIndexes: true,
                                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
                                    clipBehavior: Clip.hardEdge
                                )
                            )
                        )
                    )
                )
            ]);
        }
        if (cycles_positions_purchases.length > 0) {
            column_children.addAll([
                Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(11,0,0,0),
                    child: Text('CYCLES-POSITIONS-PURCHASES', style: TextStyle(fontSize: 17)),
                ),
                LimitedBox(
                    maxHeight: 390,
                    child: Container(
                        constraints: BoxConstraints(),
                        //padding: EdgeInsets.all(17),
                        child: ScrollConfiguration(
                            behavior: ScrollConfiguration.of(context).copyWith(dragDevices: ScrollConfiguration.of(context).dragDevices.toSet()..add(dart_ui.PointerDeviceKind.mouse), ),
                            child: Scrollbar(
                                controller: cycles_positions_purchases_scroll_controller,
                                child: ListView.builder(
                                    controller: cycles_positions_purchases_scroll_controller,
                                    key: UniqueKey(), //ValueKey('cm cycles-positions-purchases'),
                                    scrollDirection: Axis.horizontal,
                                    reverse: false,
                                    shrinkWrap: false,
                                    padding: EdgeInsets.all(7),
                                    itemBuilder: (BuildContext context, int i) {
                                        return CyclesPositionPurchaseListItem(cycles_positions_purchases[i]);
                                    },
                                    itemCount: cycles_positions_purchases.length,
                                    addAutomaticKeepAlives: true,
                                    addRepaintBoundaries: true,
                                    addSemanticIndexes: true,
                                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
                                    clipBehavior: Clip.hardEdge
                                )
                            )
                        )
                    )
                )
            ]);
        }
        if (icp_positions_purchases.length > 0) {
            column_children.addAll([
                Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(11,0,0,0),
                    child: Text('ICP-POSITIONS-PURCHASES', style: TextStyle(fontSize: 17)),
                ),
                LimitedBox(
                    maxHeight: 390,
                    child: Container(
                        constraints: BoxConstraints(),
                        //padding: EdgeInsets.all(17),
                        child: ScrollConfiguration(
                            behavior: ScrollConfiguration.of(context).copyWith(dragDevices: ScrollConfiguration.of(context).dragDevices.toSet()..add(dart_ui.PointerDeviceKind.mouse), ),
                            child: Scrollbar(
                                controller: icp_positions_purchases_scroll_controller,
                                child: ListView.builder(
                                    controller: icp_positions_purchases_scroll_controller,
                                    key: UniqueKey(), //ValueKey('cm icp-positions-purchases'),
                                    scrollDirection: Axis.horizontal,
                                    reverse: false,
                                    shrinkWrap: false,
                                    padding: EdgeInsets.all(7),
                                    itemBuilder: (BuildContext context, int i) {
                                        return IcpPositionPurchaseListItem(icp_positions_purchases[i]);
                                    },
                                    itemCount: icp_positions_purchases.length,
                                    addAutomaticKeepAlives: true,
                                    addRepaintBoundaries: true,
                                    addSemanticIndexes: true,
                                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
                                    clipBehavior: Clip.hardEdge
                                )
                            )
                        )
                    )
                )
            ]);
        }
        
            
        if (state.user != null && state.user!.cycles_bank != null) {    
            
            
            final bool Function(CyclesMarketDataPosition) is_position_by_the_user = (CyclesMarketDataPosition cmdp) {
                return aresamebytes(cmdp.positor.bytes, state.user!.cycles_bank!.principal.bytes);
            };
            
            Map<BigInt, CyclesPosition> current_user_cycles_positions = Map.fromIterable(
                state.cycles_market_data.cycles_positions.where(is_position_by_the_user).toList(),
                key: (cp) => cp.id,
                value: (cp) => cp
            );
        
            Map<BigInt, IcpPosition> current_user_icp_positions = Map.fromIterable(
                state.cycles_market_data.icp_positions.where(is_position_by_the_user).toList(),
                key: (ip) => ip.id,
                value: (ip) => ip
            );
                
            List<CMCyclesPosition> cycles_bank_cm_cycles_positions_logs = state.user!.cycles_bank!.cm_cycles_positions.reversed.toList();
                //..sort((CMCyclesPosition cm_cp1, CMCyclesPosition cm_cp2)=>cm_cp1.id.compareTo(cm_cp2.id))
                //..reversed.toList();
                
            List<CMIcpPosition> cycles_bank_cm_icp_positions_logs = state.user!.cycles_bank!.cm_icp_positions.reversed.toList();
                //..sort((CMIcpPosition cm_ip1, CMIcpPosition cm_ip2)=>cm_ip1.id.compareTo(cm_ip2.id))
                //..reversed.toList();
                
            Map<BigInt, List<CMMessageCyclesPositionPurchasePositorLog>> user_cycles_positions_ids_map_cm_message_cycles_position_purchase_positor_logs = {};
            
            Map<BigInt, List<CMMessageIcpPositionPurchasePositorLog>> user_icp_positions_ids_map_cm_message_icp_position_purchase_positor_logs = {};
            
            for (CMCyclesPosition cm_cycles_position in cycles_bank_cm_cycles_positions_logs) {
                user_cycles_positions_ids_map_cm_message_cycles_position_purchase_positor_logs[cm_cycles_position.id] = 
                    state.user!.cycles_bank!.cm_message_cycles_position_purchase_positor_logs
                        .where((CMMessageCyclesPositionPurchasePositorLog l) => cm_cycles_position.id == l.cm_message_cycles_position_purchase_positor_quest.cycles_position_id)
                        .toList()
                        ..sort((CMMessageCyclesPositionPurchasePositorLog l1, CMMessageCyclesPositionPurchasePositorLog l2) => l1.cm_message_cycles_position_purchase_positor_quest.purchase_id.compareTo(l2.cm_message_cycles_position_purchase_positor_quest.purchase_id));
            }

            for (CMIcpPosition cm_icp_position in cycles_bank_cm_icp_positions_logs) {
                user_icp_positions_ids_map_cm_message_icp_position_purchase_positor_logs[cm_icp_position.id] = 
                    state.user!.cycles_bank!.cm_message_icp_position_purchase_positor_logs
                        .where((CMMessageIcpPositionPurchasePositorLog l) => cm_icp_position.id == l.cm_message_icp_position_purchase_positor_quest.icp_position_id)
                        .toList()
                        ..sort((CMMessageIcpPositionPurchasePositorLog l1, CMMessageIcpPositionPurchasePositorLog l2) => l1.cm_message_icp_position_purchase_positor_quest.purchase_id.compareTo(l2.cm_message_icp_position_purchase_positor_quest.purchase_id));
            }
            
            
            if (cycles_bank_cm_cycles_positions_logs.length > 0) {
                column_children.addAll([
                    Container(
                        width: double.infinity,
                        padding: EdgeInsets.fromLTRB(11,0,0,0),
                        child: Text('USER-CYCLES-POSITIONS', style: TextStyle(fontSize: 17)),
                    ),
                    LimitedBox(
                        maxHeight: 390,
                        child: Container(
                            constraints: BoxConstraints(),
                            //padding: EdgeInsets.all(17),
                            child: ScrollConfiguration(
                                behavior: ScrollConfiguration.of(context).copyWith(dragDevices: ScrollConfiguration.of(context).dragDevices.toSet()..add(dart_ui.PointerDeviceKind.mouse), ),
                                child: Scrollbar(
                                    controller: user_cycles_positions_scroll_controller,
                                    child: ListView.builder(
                                        controller: user_cycles_positions_scroll_controller,
                                        key: UniqueKey(), //ValueKey('cm user-cycles-positions'),
                                        scrollDirection: Axis.horizontal,
                                        reverse: false,
                                        shrinkWrap: false,
                                        padding: EdgeInsets.all(7),
                                        itemBuilder: (BuildContext context, int i) {
                                            CMCyclesPosition cm_cycles_position = cycles_bank_cm_cycles_positions_logs[i];
                                            List<CMMessageCyclesPositionPurchasePositorLog> purchases = user_cycles_positions_ids_map_cm_message_cycles_position_purchase_positor_logs[cm_cycles_position.id]!;  
                                            Cycles? current_position;
                                            if (current_user_cycles_positions[cm_cycles_position.id] is CyclesPosition) {
                                                current_position = (current_user_cycles_positions[cm_cycles_position.id] as CyclesPosition).cycles;
                                            }
                                            CMMessageVoidCyclesPositionPositorLog? cm_message_void_cycles_position_positor_log;
                                            Iterable<CMMessageVoidCyclesPositionPositorLog> cm_message_void_cycles_position_positor_logs_with_the_cm_cycles_position_id = 
                                                state.user!.cycles_bank!.cm_message_void_cycles_position_positor_logs
                                                    .where((CMMessageVoidCyclesPositionPositorLog l) => cm_cycles_position.id == l.cm_message_void_cycles_position_positor_quest.position_id);
                                            if (cm_message_void_cycles_position_positor_logs_with_the_cm_cycles_position_id.length > 0) {
                                                cm_message_void_cycles_position_positor_log = cm_message_void_cycles_position_positor_logs_with_the_cm_cycles_position_id.first;
                                            }
                                            return UserCyclesPositionListItem(
                                                cm_cycles_position: cm_cycles_position,
                                                purchases: purchases,
                                                current_position: current_position,             
                                                cm_message_void_cycles_position_positor_log: cm_message_void_cycles_position_positor_log,
                                            );
                                        },
                                        itemCount: cycles_bank_cm_cycles_positions_logs.length,
                                        addAutomaticKeepAlives: true,
                                        addRepaintBoundaries: true,
                                        addSemanticIndexes: true,
                                        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
                                        clipBehavior: Clip.hardEdge
                                    )
                                )
                            )                   
                        )
                    )
                ]);
            }
            
            if (cycles_bank_cm_icp_positions_logs.length > 0) {
                column_children.addAll([
                    Container(
                        width: double.infinity,
                        padding: EdgeInsets.fromLTRB(11,0,0,0),
                        child: Text('USER-ICP-POSITIONS', style: TextStyle(fontSize: 17)),
                    ),
                    LimitedBox(
                        maxHeight: 390,
                        child: Container(
                            constraints: BoxConstraints(),
                            //padding: EdgeInsets.all(17),
                            child: ScrollConfiguration(
                                behavior: ScrollConfiguration.of(context).copyWith(dragDevices: ScrollConfiguration.of(context).dragDevices.toSet()..add(dart_ui.PointerDeviceKind.mouse), ),
                                child: Scrollbar(
                                    controller: user_icp_positions_scroll_controller,
                                    child: ListView.builder(
                                        controller: user_icp_positions_scroll_controller,
                                        key: UniqueKey(), //ValueKey('cm user-icp-positions'),
                                        scrollDirection: Axis.horizontal,
                                        reverse: false,
                                        shrinkWrap: false,
                                        padding: EdgeInsets.all(7),
                                        itemBuilder: (BuildContext context, int i) {
                                            CMIcpPosition cm_icp_position = cycles_bank_cm_icp_positions_logs[i];
                                            List<CMMessageIcpPositionPurchasePositorLog> purchases = user_icp_positions_ids_map_cm_message_icp_position_purchase_positor_logs[cm_icp_position.id]!;  
                                            IcpTokens? current_position;
                                            if (current_user_icp_positions[cm_icp_position.id] is IcpPosition) {
                                                current_position = (current_user_icp_positions[cm_icp_position.id] as IcpPosition).icp;
                                            }
                                            CMMessageVoidIcpPositionPositorLog? cm_message_void_icp_position_positor_log;
                                            Iterable<CMMessageVoidIcpPositionPositorLog> cm_message_void_icp_position_positor_logs_with_the_cm_icp_position_id = 
                                                state.user!.cycles_bank!.cm_message_void_icp_position_positor_logs
                                                    .where((CMMessageVoidIcpPositionPositorLog l) => cm_icp_position.id == l.cm_message_void_icp_position_positor_quest.position_id);
                                            if (cm_message_void_icp_position_positor_logs_with_the_cm_icp_position_id.length > 0) {
                                                cm_message_void_icp_position_positor_log = cm_message_void_icp_position_positor_logs_with_the_cm_icp_position_id.first;
                                            }
                                            return UserIcpPositionListItem(
                                                cm_icp_position: cm_icp_position,
                                                purchases: purchases,
                                                current_position: current_position,             
                                                cm_message_void_icp_position_positor_log: cm_message_void_icp_position_positor_log,
                                            );
                                        },
                                        itemCount: cycles_bank_cm_icp_positions_logs.length,
                                        addAutomaticKeepAlives: true,
                                        addRepaintBoundaries: true,
                                        addSemanticIndexes: true,
                                        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
                                        clipBehavior: Clip.hardEdge
                                    )
                                )
                            )                
                        )
                    )
                ]);
            }
            
            if (state.user!.cycles_bank!.cm_cycles_positions_purchases.length > 0) {
                
                List<CMCyclesPositionPurchase> cycles_bank_cm_cycles_positions_purchases = state.user!.cycles_bank!.cm_cycles_positions_purchases.reversed.toList();
            
                column_children.addAll([
                    Container(
                        width: double.infinity,
                        padding: EdgeInsets.fromLTRB(11,0,0,0),
                        child: Text('USER-CYCLES-POSITIONS-PURCHASES', style: TextStyle(fontSize: 17)),
                    ),
                    LimitedBox(
                        maxHeight: 390,
                        child: Container(
                            constraints: BoxConstraints(),
                            //padding: EdgeInsets.all(17),
                            child: ScrollConfiguration(
                                behavior: ScrollConfiguration.of(context).copyWith(dragDevices: ScrollConfiguration.of(context).dragDevices.toSet()..add(dart_ui.PointerDeviceKind.mouse), ),
                                child: Scrollbar(
                                    controller: user_cycles_positions_purchases_scroll_controller,
                                    child: ListView.builder(
                                        controller: user_cycles_positions_purchases_scroll_controller,
                                        key: UniqueKey(), //ValueKey('cm user-cycles-positions-purchases'),
                                        scrollDirection: Axis.horizontal,
                                        reverse: false,
                                        shrinkWrap: false,
                                        padding: EdgeInsets.all(7),
                                        itemBuilder: (BuildContext context, int i) {
                                            CMCyclesPositionPurchase cm_cycles_position_purchase = cycles_bank_cm_cycles_positions_purchases[i];
                                            CMMessageCyclesPositionPurchasePurchaserLog? cm_message_cycles_position_purchase_purchaser_log;
                                            try {
                                                cm_message_cycles_position_purchase_purchaser_log = 
                                                    state.user!.cycles_bank!.cm_message_cycles_position_purchase_purchaser_logs
                                                    .where((CMMessageCyclesPositionPurchasePurchaserLog cm_message_cycles_position_purchase_purchaser_log)=>cm_message_cycles_position_purchase_purchaser_log.cm_message_cycles_position_purchase_purchaser_quest.purchase_id == cm_cycles_position_purchase.id).first;
                                            } catch(e) {
                                                
                                            }
                                            return UserCyclesPositionPurchaseListItem(
                                                cm_cycles_position_purchase: cm_cycles_position_purchase,
                                                cm_message_cycles_position_purchase_purchaser_log: cm_message_cycles_position_purchase_purchaser_log
                                            );
                                        },
                                        itemCount: cycles_bank_cm_cycles_positions_purchases.length,
                                        addAutomaticKeepAlives: true,
                                        addRepaintBoundaries: true,
                                        addSemanticIndexes: true,
                                        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
                                        clipBehavior: Clip.hardEdge
                                    )
                                )
                            )
                        )
                    )
                ]);
            } 
            
            if (state.user!.cycles_bank!.cm_icp_positions_purchases.length > 0) {
                
                List<CMIcpPositionPurchase> cycles_bank_cm_icp_positions_purchases = state.user!.cycles_bank!.cm_icp_positions_purchases.reversed.toList();
            
                column_children.addAll([
                    Container(
                        width: double.infinity,
                        padding: EdgeInsets.fromLTRB(11,0,0,0),
                        child: Text('USER-ICP-POSITIONS-PURCHASES', style: TextStyle(fontSize: 17)),
                    ),
                    LimitedBox(
                        maxHeight: 390,
                        child: Container(
                            constraints: BoxConstraints(),
                            //padding: EdgeInsets.all(17),
                            child: ScrollConfiguration(
                                behavior: ScrollConfiguration.of(context).copyWith(dragDevices: ScrollConfiguration.of(context).dragDevices.toSet()..add(dart_ui.PointerDeviceKind.mouse), ),
                                child: Scrollbar(
                                    controller: user_icp_positions_purchases_scroll_controller,
                                    child: ListView.builder(
                                        controller: user_icp_positions_purchases_scroll_controller,
                                        key: UniqueKey(), //ValueKey('cm user-icp-positions-purchases'),
                                        scrollDirection: Axis.horizontal,
                                        reverse: false,
                                        shrinkWrap: false,
                                        padding: EdgeInsets.all(7),
                                        itemBuilder: (BuildContext context, int i) {
                                            CMIcpPositionPurchase cm_icp_position_purchase = cycles_bank_cm_icp_positions_purchases[i];
                                            CMMessageIcpPositionPurchasePurchaserLog? cm_message_icp_position_purchase_purchaser_log;
                                            try {
                                                cm_message_icp_position_purchase_purchaser_log = 
                                                    state.user!.cycles_bank!.cm_message_icp_position_purchase_purchaser_logs
                                                    .where((CMMessageIcpPositionPurchasePurchaserLog cm_message_icp_position_purchase_purchaser_log)=>cm_message_icp_position_purchase_purchaser_log.cm_message_icp_position_purchase_purchaser_quest.purchase_id == cm_icp_position_purchase.id).first;
                                            } catch(e) {
                                                
                                            }
                                            return UserIcpPositionPurchaseListItem(
                                                cm_icp_position_purchase: cm_icp_position_purchase,
                                                cm_message_icp_position_purchase_purchaser_log: cm_message_icp_position_purchase_purchaser_log
                                            );
                                        },
                                        itemCount: cycles_bank_cm_icp_positions_purchases.length,
                                        addAutomaticKeepAlives: true,
                                        addRepaintBoundaries: true,
                                        addSemanticIndexes: true,
                                        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
                                        clipBehavior: Clip.hardEdge
                                    )
                                )
                            )
                        )
                    )
                ]);
            }    
        }
        
        
        return Center(
            child: Container(
                constraints: BoxConstraints(maxWidth: 900),
                child: Column(
                    children: [
                        ScaffoldBodyHeader(Text('CYCLES-MARKET', style: TextStyle(fontSize: 19))),
                        Expanded(
                            child: ListView(
                                padding: EdgeInsets.all(0),
                                children: [
                                    Column(
                                        children: column_children 
                                    )
                                ],
                                addAutomaticKeepAlives: true
                            )
                        )
                    ]
                )
            )
        );
        
        
        //return Center(child: Text('Construction ...'));
    }
}
*/

