import 'dart:ui' as dart_ui;
import 'dart:math';
import 'dart:html' show window;
import 'dart:async';

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
    
    late CustomState state;
    late MainStateBindScope<CustomState> main_state_bind_scope;
    
    late Timer timer;
    void initState() {
        timer = Timer.periodic(Duration(seconds: 30), (timer) {
            state.cm_main.icrc1token_trade_contracts[widget.cm_main_icrc1token_trade_contracts_i].load_positions_and_trades()
            .then((x){
                setState((){});
            });
        });
        super.initState();
    }
    void dispose() {
        timer.cancel();
        super.dispose();
    }
    
    Widget build(BuildContext context) {
        state = MainStateBind.get_state<CustomState>(context);
        main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
        
        const double lr_padding_market_trades_and_position_book = 37;
        const double tb_padding_market_trades_and_position_book = 11;
        
        return Container(
            child: Column(
                children: [ 
                    Wrap(
                        children: [
                            Container(
                                padding: EdgeInsets.symmetric(horizontal: lr_padding_market_trades_and_position_book, vertical: tb_padding_market_trades_and_position_book),
                                child: MarketTrades(cm_main_icrc1token_trade_contracts_i: widget.cm_main_icrc1token_trade_contracts_i) 
                            ),
                            /*
                            MouseRegion(
                                child: Container(
                                    child: Chart(
                                        cm_main_icrc1token_trade_contracts_i: widget.cm_main_icrc1token_trade_contracts_i,
                                        key: ValueKey('CyclesMarketTradeContractTradePage Candlestick-Chart cm_main_icrc1token_trade_contracts_i ${widget.cm_main_icrc1token_trade_contracts_i}')
                                    ),
                                    constraints: BoxConstraints(maxHeight: 450, maxWidth: 800, minWidth: 300),
                                    padding: EdgeInsets.symmetric(horizontal: 73),
                                ),
                                onEnter: (event) {
                                    widget.stop_scroll(true);
                                },
                                onExit: (event) {
                                    widget.stop_scroll(false);
                                }
                            ),
                            */
                            Container(
                                padding: EdgeInsets.symmetric(horizontal: lr_padding_market_trades_and_position_book, vertical: tb_padding_market_trades_and_position_book),
                                child: PositionBook(cm_main_icrc1token_trade_contracts_i: widget.cm_main_icrc1token_trade_contracts_i)
                            ),  
                        ]
                    ),
                    if (state.user != null && state.user!.bank != null) ...[
                        SizedBox(height: 71),
                        Wrap(
                            children: [
                                Container(
                                    child: Center(
                                        child: CreatePositionWidget(cm_main_icrc1token_trade_contracts_i: widget.cm_main_icrc1token_trade_contracts_i)
                                    )    
                                ),
                                Container(
                                    child: Center(
                                        child: UserCMLogs(cm_main_icrc1token_trade_contracts_i: widget.cm_main_icrc1token_trade_contracts_i)
                                    )
                                )
                            ]
                        ),
                    ]
                ]
            )
        );
        
        
    }
    
}




class MarketTrades extends StatefulWidget {
    int cm_main_icrc1token_trade_contracts_i;
    MarketTrades({required this.cm_main_icrc1token_trade_contracts_i}) : super(key: ValueKey('CyclesMarketTradeContractTradePage MarketTrades cm_main_icrc1token_trade_contracts_i ${cm_main_icrc1token_trade_contracts_i}'));
    State createState() => MarketTradesState();
}
class MarketTradesState extends State<MarketTrades> {
    
    String timestamp_format(DateTime t) {
        return '${t.hour}:${t.minute}:${t.second}';
    }
    
    late CustomState state;
    late MainStateBindScope<CustomState> main_state_bind_scope;
    
    late final ScrollController _controller;
    bool loading = false;
    bool reached_the_begining = false;
    
    BigInt? get_earliest_known_trade_id() {
        if (state.cm_main.icrc1token_trade_contracts[widget.cm_main_icrc1token_trade_contracts_i].latest_trades.length >= 1) {
            return state.cm_main.icrc1token_trade_contracts[widget.cm_main_icrc1token_trade_contracts_i].latest_trades.first.id; 
        } else {
            return null;
        }
    }
    void _handle_controller_scroll() {
        if (reached_the_begining == false 
        && loading == false
        && _controller.position.maxScrollExtent - _controller.offset < 200) { 
            loading = true;
            Future(()async{
                BigInt? earliest_known_trade_id_before_load = get_earliest_known_trade_id();
                try {
                    await state.cm_main.icrc1token_trade_contracts[widget.cm_main_icrc1token_trade_contracts_i].load_trades_back_chunk();
                } catch(e) {
                    window.alert('failed to load earlier market trades');
                    return;
                }
                BigInt? earliest_known_trade_id_after_load = get_earliest_known_trade_id();
                if (earliest_known_trade_id_before_load == earliest_known_trade_id_after_load
                || earliest_known_trade_id_after_load == BigInt.from(0)) {
                    reached_the_begining = true;   
                }
                loading = false;
                setState((){});
            })
            .then((_x){});
        }
    }
        
    void initState() {
        _controller = ScrollController();
        _controller.addListener(_handle_controller_scroll);
        super.initState();
    }
    void dispose() {
        _controller.removeListener(_handle_controller_scroll);
        _controller.dispose();
        super.dispose();
    }
    
    Widget build(BuildContext context) {
        state = MainStateBind.get_state<CustomState>(context);
        main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
        
        if (get_earliest_known_trade_id() == BigInt.from(0)) {
            reached_the_begining = true;
        }
                            
        return Container(
            constraints: BoxConstraints(
                maxHeight: 400,
                maxWidth: 400
            ),
            //decoration: BoxDecoration(border: Border.all()),
            child: DataTable2(
                isHorizontalScrollBarVisible: false,
                scrollController: _controller,
                showBottomBorder: true,
                columns: <DataColumn>[
                    DataColumn(label: Text('Quantity')),
                    DataColumn(label: Text('Rate')),
                    DataColumn(label: Text('Time'))
                ],
                rows: [
                    for (TradeItem trade in state.cm_main.icrc1token_trade_contracts[widget.cm_main_icrc1token_trade_contracts_i].latest_trades.reversed) 
                        DataRow(
                            cells: [
                                DataCell(Text('${trade.quantity}')),
                                DataCell(Text('${trade.rate}')),
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
    
    ScrollController sell_positions_scroll_controller = ScrollController();
    
    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
        
        CyclesPerTokenRate latest_trade_rate = 
            state.cm_main.icrc1token_trade_contracts[cm_main_icrc1token_trade_contracts_i].latest_trades.length >= 1 
            ?
            state.cm_main.icrc1token_trade_contracts[cm_main_icrc1token_trade_contracts_i].latest_trades.last.rate
            : 
            CyclesPerTokenRate(cycles_per_token_quantum_rate: BigInt.from(0), token_decimal_places: state.cm_main.icrc1token_trade_contracts[cm_main_icrc1token_trade_contracts_i].ledger_data.decimals);
        
        List<DataColumn> header_columns = <DataColumn>[                                 
            DataColumn(label: Text('Quantity')),
            DataColumn(label:Text('Rate')),
            DataColumn(label:  Text('Total'))
        ];
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
            sell_positions_scroll_controller.jumpTo(sell_positions_scroll_controller.position.maxScrollExtent);
        });
        
        return Container(
            constraints: BoxConstraints(maxHeight: 400, maxWidth: 400),
            child: Column(
                children: [
                    DataTable(
                        columns: header_columns,
                        rows: [],
                    ),
                    Flexible(child: DataTable2(
                        scrollController: sell_positions_scroll_controller,
                        headingRowHeight: 0,                            
                        showBottomBorder: true,
                        columns: header_columns,
                        rows: create_position_book_data_rows(state.cm_main.icrc1token_trade_contracts[cm_main_icrc1token_trade_contracts_i].sell_position_book, PositionKind.Token)
                    )),    
                    Center(
                        child: Container(
                            padding: EdgeInsets.symmetric(vertical: 11),
                            child: Text('${latest_trade_rate}', style: TextStyle(fontSize: 17))
                        )
                    ),
                    Flexible(child: DataTable2(
                        headingRowHeight: 0,
                        showBottomBorder: true,
                        columns: header_columns,
                        rows: create_position_book_data_rows(state.cm_main.icrc1token_trade_contracts[cm_main_icrc1token_trade_contracts_i].buy_position_book, PositionKind.Cycles)
                    )),
                ]
            )
        );
    }
    
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
}


const Color green = const Color(0xFF26a69a);
const Color red = const Color(0xFFef5350);



class CreatePositionWidget extends StatelessWidget {
    final int cm_main_icrc1token_trade_contracts_i;
    CreatePositionWidget({super.key, required this.cm_main_icrc1token_trade_contracts_i});
    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
        
        final String token_symbol = state.cm_main.icrc1token_trade_contracts[this.cm_main_icrc1token_trade_contracts_i].ledger_data.symbol;
        
        
        return Container(
            padding: EdgeInsets.fromLTRB(0,0,0,0),
            //height: 300,
            width: 300,
            child: DefaultTabController(
                length: 2,
                child: Column(
                    children: [
                        Container(child:Center(child:Text('TRADE'))),
                        Container(
                            //height: 50,
                            child: TabBar(
                                tabs: [
                                    Tab(text: 'CYCLES'),
                                    Tab(text: '${token_symbol}'),
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
    
    late Tokens trade_amount;
    late CyclesPerTokenRate cycles_per_token_rate;
    
    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);

        final String buy_or_sell = widget.position_kind == PositionKind.Cycles ? 'BUY' : 'SELL';
        final int token_decimal_places = state.cm_main.icrc1token_trade_contracts[widget.cm_main_icrc1token_trade_contracts_i].ledger_data.decimals;        
        final String token_symbol = state.cm_main.icrc1token_trade_contracts[widget.cm_main_icrc1token_trade_contracts_i].ledger_data.symbol;
        
        int first_field_decimal_places = widget.position_kind == PositionKind.Cycles ? Cycles.T_CYCLES_DECIMAL_PLACES : token_decimal_places;
        
        return Form(
            key: form_key,
            child: Column(
                children: <Widget>[
                    TextFormField(
                        decoration: InputDecoration(
                            labelText: widget.position_kind == PositionKind.Cycles ? 'TCYCLES' : '$token_symbol:',
                        ),
                        onSaved: (String? value) { trade_amount = Tokens.of_the_double_string(value!, decimal_places: first_field_decimal_places); },
                        validator: tokens_validator(token_decimal_places: first_field_decimal_places)
                    ),
                    TextFormField(
                        decoration: InputDecoration(
                            labelText: 'TRADE RATE (TCYCLES per ${token_symbol}):',
                        ),
                        onSaved: (String? value) { cycles_per_token_rate = CyclesPerTokenRate.oftheTCyclesDoubleString(value!, token_decimal_places: token_decimal_places); },
                        validator: cycles_per_token_rate_validator(token_decimal_places: token_decimal_places)
                    ),
                    Container(
                        width: double.infinity,
                        padding: EdgeInsets.fromLTRB(0, 17, 0,7),
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: blue),
                            child: Text('TRADE ${widget.position_kind == PositionKind.Cycles ? 'CYCLES' : token_symbol} for ${widget.position_kind == PositionKind.Cycles ? token_symbol : 'CYCLES'}'),
                            onPressed: () async {
                                if (form_key.currentState!.validate()==true) {
                                    
                                    form_key.currentState!.save();
                                    
                                    state.loading_text = 'creating ${buy_or_sell} position';
                                    state.is_loading = true;
                                    MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                                    
                                    
                                    Tokens match_tokens = 
                                        widget.position_kind == PositionKind.Cycles 
                                        ? Tokens(quantums: trade_amount.quantums ~/ cycles_per_token_rate.cycles_per_token_quantum_rate, decimal_places: token_decimal_places) 
                                        : trade_amount;
                                    MatchTokensQuest match_tokens_quest = MatchTokensQuest(
                                        tokens: match_tokens,
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
                                            state.user!.bank!.load_cm_user_positions(state.cm_main.icrc1token_trade_contracts[widget.cm_main_icrc1token_trade_contracts_i]),
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





class UserCMLogs extends StatefulWidget {
    UserCMLogs({super.key, required this.cm_main_icrc1token_trade_contracts_i});
    int cm_main_icrc1token_trade_contracts_i;
    State createState() => UserCMLogsState();
}
class UserCMLogsState extends State<UserCMLogs> {
    
    
    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
                
        return Container(
                constraints: BoxConstraints(maxHeight: 500, maxWidth: 800),
                child: PaginatedDataTable2(
                    //headingRowHeight: 00,
                    //dataRowHeight: 300,
                    minWidth: 500,
                    renderEmptyRowsInTheEnd: false,
                    dividerThickness: 1,
                    headingTextStyle: DefaultTextStyle.of(context).style.copyWith(fontFamily: 'ChakraPetch', fontSize: 17),                      
                    dataTextStyle: DefaultTextStyle.of(context).style.copyWith(fontFamily: 'ChakraPetch', fontSize: 17),
                    rowsPerPage: 8,
                    columnSpacing: 13,
                    columns: [
                        /*
                        DataColumn2(
                            label: Text('TYPE'),
                            numeric: false,
                            //size: ColumnSize.M,
                            fixedWidth: 50.0,
                        ),
                        */
                        /*
                        DataColumn2(
                            label: Text('id'), 
                            numeric: true,
                            size: ColumnSize.S,
                        ),
                        */
                        /*
                        DataColumn2( // maybe put in the dropdown data section onTap ?
                            label: Text('creation-time'), 
                            numeric: true,
                            size: ColumnSize.L,
                        ),
                        */
                        DataColumn2(
                            label: Text('POSITION'), 
                            numeric: true,
                            size: ColumnSize.M,
                            tooltip: 'original-position'
                        ),
                        DataColumn2(
                            label: Text('RATE'), 
                            numeric: true,
                            size: ColumnSize.S,
                            tooltip: 'original-position cycles per token rate'
                        ),
                        DataColumn2(
                            label: Text('FILL'), 
                            numeric: true,
                            size: ColumnSize.M,
                            tooltip: 'Amount of the position/order that is filled'
                        ),
                        /*
                        DataColumn2(
                            label: Text('FILL-RATE'), 
                            numeric: true,
                            size: ColumnSize.S,
                            tooltip: 'The weighted-average of the rates of the trades of this position/order so far.'
                        ),
                        */
                        DataColumn2(
                            label: Text('CURRENT-POSITION'), 
                            numeric: true,
                            size: ColumnSize.M,
                            tooltip: 'The current amount of the position/order if this position is open.'
                        ),
                        /*
                        DataColumn2(
                            label: Text('payouts-fees-sum'), 
                            numeric: true,
                            size: ColumnSize.M,
                        ),
                        */
                    ],
                    source: UserCMLogsDataTableSource(
                        cm_main_icrc1token_trade_contracts_i: widget.cm_main_icrc1token_trade_contracts_i,
                        context: context,  
                    ),
                ),    
            
        );    
    }
}


String position_log_timestamp_format(DateTime t) {
    DateTime now = DateTime.now();
    String s = '${t.hour}:${t.minute}:${t.second}';
    if ((now.year, now.month, now.day) != (t.year, t.month, t.day)) {
        s = s + ' ${t.month}/${t.day}/${t.year}';
    } 
    return s;
}
DataRow datarow_of_the_user_position_log(BuildContext context, PositionLog pl, String token_symbol) {
    int token_decimal_places = pl.match_tokens_quest.tokens.decimal_places;
    return DataRow2(
        onTap: () {},
        cells: <DataCell>[
             /*
             DataCell(
                Text(pl.position_kind == PositionKind.Cycles ? 'BUY' : 'SELL'), /*+ '-' + (pl.position_termination == null ? 'OPEN' : 'CLOSED')*/
                /*
                {bool placeholder = false, 
                bool showEditIcon = false, 
                GestureTapCallback? onTap, 
                GestureLongPressCallback? onLongPress, 
                GestureTapDownCallback? onTapDown, 
                GestureTapCallback? onDoubleTap, 
                GestureTapCancelCallback? onTapCancel}) 
                */
            ),
            */
            //DataCell(Text(pl.id.toString())),
            //DataCell(Text('${position_log_timestamp_format(datetime_of_the_nanos(pl.creation_timestamp_nanos))}')),
            DataCell(
                pl.position_kind == PositionKind.Cycles 
                ? 
                show_tokens_with_symbol(context, tokens_transform_cycles(pl.match_tokens_quest.tokens.quantums, pl.match_tokens_quest.cycles_per_token_rate), cycles_symbol)
                : 
                show_tokens_with_symbol(context, pl.match_tokens_quest.tokens, token_symbol)
            ),
            DataCell(Text('${pl.match_tokens_quest.cycles_per_token_rate.toString().replaceFirst('T', '')}')),
            DataCell(
                pl.position_kind == PositionKind.Cycles 
                ? 
                show_tokens_with_symbol(context, Tokens(quantums: pl.fill_quantity, decimal_places: token_decimal_places), token_symbol) 
                : 
                show_tokens_with_symbol(context, Cycles(cycles: pl.fill_quantity), cycles_symbol)
            ),
            //DataCell(Text('${pl.fill_average_rate.toString().replaceFirst('T', '')}')),
            DataCell(
                pl.position_termination != null 
                ? 
                Text('') 
                :
                pl.position_kind == PositionKind.Cycles 
                ? 
                show_tokens_with_symbol(context, Cycles(cycles: pl.mainder_position_quantity), cycles_symbol) 
                : 
                show_tokens_with_symbol(context, Tokens(quantums: pl.mainder_position_quantity, decimal_places: token_decimal_places), token_symbol)
            ),            
            //DataCell(Text('${pl.position_kind == PositionKind.Cycles ? Tokens(quantums: pl.payouts_fees_sum, decimal_places: token_decimal_places) : Cycles(cycles: pl.payouts_fees_sum)}')), 
            
        ]
    );
    
}

String cycles_symbol = 'TCYCLES';

Tooltip show_tokens_with_symbol(BuildContext context, Tokens tokens, String token_symbol) {
    Tokens tokens_round = tokens.round_decimal_places(2);
    Tokens tokens_for_the_main_show = tokens_round.quantums == BigInt.from(0) ? tokens : tokens_round; 
    return Tooltip(
        richMessage: TextSpan(
            style: TextStyle(fontFamily: 'ChakraPetchBold', fontSize: 17),
            children: <TextSpan>[
                TextSpan(text: tokens.toString().replaceFirst('T', '')),
                //TextSpan(text: '-$token_symbol', style: TextStyle(fontSize: 9)),
            ],
        ),
        child: Text.rich(
            TextSpan(
                children: <TextSpan>[
                    TextSpan(text: tokens_for_the_main_show.toString().replaceFirst('T', '')),
                    TextSpan(text: '-$token_symbol', style: TextStyle(fontSize: 11)),
                ],
            )
        )
    );
}


class UserCMLogsDataTableSource extends DataTableSource {
    int cm_main_icrc1token_trade_contracts_i;
    BuildContext context;
    late CustomState state;
    UserCMLogsDataTableSource({required this.cm_main_icrc1token_trade_contracts_i, required this.context}) {
        state = MainStateBind.get_state<CustomState>(context);
    }
    
    int get rowCount => state.user!.bank!.cm_trade_contracts[state.cm_main.icrc1token_trade_contracts[cm_main_icrc1token_trade_contracts_i]]!
        .user_positions_storage.length;
    
    bool get isRowCountApproximate => false;    
    
    DataRow? getRow(int i) {
        Iterable<BigInt> user_positions_storage_keys = 
            state.user!.bank!.cm_trade_contracts[state.cm_main.icrc1token_trade_contracts[cm_main_icrc1token_trade_contracts_i]]!
            .user_positions_storage.keys;
        BigInt plid = user_positions_storage_keys.elementAt(user_positions_storage_keys.length - 1 - i);
        PositionLog? pl = state.user!.bank!.cm_trade_contracts[state.cm_main.icrc1token_trade_contracts[cm_main_icrc1token_trade_contracts_i]]!
            .current_user_positions[plid];
        if (pl == null) {
            pl = state.user!.bank!.cm_trade_contracts[state.cm_main.icrc1token_trade_contracts[cm_main_icrc1token_trade_contracts_i]]!
                .user_positions_storage[plid]!;
        }
        return datarow_of_the_user_position_log(context, pl!, state.cm_main.icrc1token_trade_contracts[cm_main_icrc1token_trade_contracts_i]!.ledger_data.symbol);
        
    }
    Future<AsyncRowsResponse> getRows(int start_i, int count) async {
        // each row is a position. // onTap shows more about each trade? maybe a two line row without the onTap
        
        List<DataRow> rows = [];
        
        int current_user_positions_length = state.user!.bank!.cm_trade_contracts[state.cm_main.icrc1token_trade_contracts[cm_main_icrc1token_trade_contracts_i]]!.current_user_positions.length; 
        if (start_i < current_user_positions_length) {
            Iterable<BigInt> map_keys = state.user!.bank!.cm_trade_contracts[state.cm_main.icrc1token_trade_contracts[cm_main_icrc1token_trade_contracts_i]]!
            .current_user_positions.keys;
            Iterable<BigInt> keys_show = map_keys.take(map_keys.length - start_i).skip(max(0, map_keys.length - start_i - count).toInt()).toList().reversed;
            rows.addAll(keys_show.map(
                (k)=>datarow_of_the_user_position_log(context, state.user!.bank!.cm_trade_contracts[state.cm_main.icrc1token_trade_contracts[cm_main_icrc1token_trade_contracts_i]]!
                    .current_user_positions[k]!, 
                    state.cm_main.icrc1token_trade_contracts[cm_main_icrc1token_trade_contracts_i]!.ledger_data.symbol
                )
            ));
        }
        if (rows.length < count) {
            Iterable<BigInt> map_keys = state.user!.bank!.cm_trade_contracts[state.cm_main.icrc1token_trade_contracts[cm_main_icrc1token_trade_contracts_i]]!
            .user_positions_storage.keys;
            Iterable<BigInt> keys_show = map_keys
                .skipWhile((k)=>state.user!.bank!.cm_trade_contracts[state.cm_main.icrc1token_trade_contracts[cm_main_icrc1token_trade_contracts_i]]!.current_user_positions.containsKey(k))
                .take(map_keys.length - max(0, start_i - current_user_positions_length))
                .skip(max(0, map_keys.length - max(0, start_i - current_user_positions_length).toInt() - count - rows.length).toInt()).toList().reversed;
            rows.addAll(keys_show.map(
                (k)=>datarow_of_the_user_position_log(context, state.user!.bank!.cm_trade_contracts[state.cm_main.icrc1token_trade_contracts[cm_main_icrc1token_trade_contracts_i]]!
                    .current_user_positions[k]!,
                    state.cm_main.icrc1token_trade_contracts[cm_main_icrc1token_trade_contracts_i]!.ledger_data.symbol
                )
            ));
        }
        
        return AsyncRowsResponse(
            state.user!.bank!.cm_trade_contracts[state.cm_main.icrc1token_trade_contracts[cm_main_icrc1token_trade_contracts_i]]!
            .user_positions_storage.length,
            rows,
        );
    }
    
    int get selectedRowCount => 0;


}















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

