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
                                            child: Text(state.cm_main.icrc1token_trade_contracts[i].ledger_data.symbol + '/CYCLES', style: TextStyle(fontSize: 22)), 
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
            Future.wait([
                state.cm_main.icrc1token_trade_contracts[widget.cm_main_icrc1token_trade_contracts_i].load_data(),
                if (state.user != null && state.user!.bank != null) ...[
                    state.user!.bank!.load_cm_data(state.cm_main.trade_contracts[widget.cm_main_icrc1token_trade_contracts_i]),
                    state.user!.bank!.fresh_metrics(),
                    state.user!.bank!.fresh_icrc1_balances(state.cm_main.trade_contracts[widget.cm_main_icrc1token_trade_contracts_i].ledger_data),
                    state.user!.bank!.fresh_icrc1_transactions(state.cm_main.trade_contracts[widget.cm_main_icrc1token_trade_contracts_i].ledger_data),
                ]
            ])
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
                                child: MarketTrades(cm_main_trade_contracts_i: widget.cm_main_icrc1token_trade_contracts_i) 
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
                                    padding: EdgeInsets.all(27),
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
    int cm_main_trade_contracts_i;
    MarketTrades({required this.cm_main_trade_contracts_i}) : super(key: ValueKey('CyclesMarketTradeContractTradePage MarketTrades cm_main_trade_contracts_i ${cm_main_trade_contracts_i}'));
    State createState() => MarketTradesState();
}
class MarketTradesState extends State<MarketTrades> {
    
    String timestamp_format(DateTime t) {
        const Map<int, String> month_map = {
            DateTime.january: 'January',
            DateTime.february: 'February',
            DateTime.march: 'March',
            DateTime.april: 'April',
            DateTime.may: 'May',
            DateTime.june: 'June',
            DateTime.july: 'July',
            DateTime.august: 'August',
            DateTime.september: 'September',
            DateTime.october: 'October',
            DateTime.november: 'November',
            DateTime.december: 'December',
        };
        DateTime now = DateTime.now();
        String? daydata = t.isBefore(DateTime(now.year, now.month, now.day)) ? '${t.month}-${t.day}-${t.year}' : null;
        String fmt = '${t.hour}:${t.minute}:${t.second}';
        if (daydata != null){
            fmt = fmt + '\n$daydata';
        }
        return fmt;
    }
    
    late CustomState state;
    late MainStateBindScope<CustomState> main_state_bind_scope;
    
    late final ScrollController _controller;
    bool loading = false;
    bool reached_the_begining = false;
    
    BigInt? get_earliest_known_trade_id() {
        if (state.cm_main.trade_contracts[widget.cm_main_trade_contracts_i].latest_trades.length >= 1) {
            return state.cm_main.trade_contracts[widget.cm_main_trade_contracts_i].latest_trades.first.id; 
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
                    await state.cm_main.trade_contracts[widget.cm_main_trade_contracts_i].load_trades_back_chunk();
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
                            
        return SingleChildScrollView(scrollDirection: Axis.horizontal, child: Container(
            constraints: BoxConstraints(
                maxHeight: 400,
                maxWidth: 700
            ),
            //decoration: BoxDecoration(border: Border.all()),
            child: DataTable2(
                headingTextStyle: DefaultTextStyle.of(context).style.copyWith(fontFamily: 'CourierNewBold', fontSize: 17),                      
                dataTextStyle: DefaultTextStyle.of(context).style.copyWith(fontFamily: 'CourierNew', fontSize: 17),
                isHorizontalScrollBarVisible: false,
                scrollController: _controller,
                showBottomBorder: true,
                columns: <DataColumn>[
                    DataColumn(label: Text('${state.cm_main.trade_contracts[widget.cm_main_trade_contracts_i].ledger_data.symbol}')),
                    DataColumn(label: Text('RATE')),
                    DataColumn(label: Text('CYCLES')),
                    DataColumn(label: Text('TIME'))
                ],
                rows: [
                    for (TradeItem trade in state.cm_main.trade_contracts[widget.cm_main_trade_contracts_i].latest_trades.reversed) 
                        DataRow(
                            cells: [
                                DataCell(show_tokens_with_symbol(trade.quantity, state.cm_main.trade_contracts[widget.cm_main_trade_contracts_i].ledger_data.symbol, show_token_symbol_in_main: false)),
                                DataCell(Text('${trade.rate}')),
                                DataCell(show_tokens_with_symbol(tokens_transform_cycles(trade.quantity.quantums, trade.rate), cycles_symbol, show_token_symbol_in_main: false)),
                                DataCell(Text('${timestamp_format(datetime_of_the_nanos(trade.time_nanos))}', style: TextStyle(fontSize: timestamp_format_font_size)))
                            ]
                        ),
                ]
            )
        ));
    }
}


class PositionBook extends StatelessWidget {
    int cm_main_icrc1token_trade_contracts_i;    
    PositionBook({required this.cm_main_icrc1token_trade_contracts_i}) : super(key: ValueKey('CyclesMarketTradeContractTradePage PositionBook cm_main_icrc1token_trade_contracts_i ${cm_main_icrc1token_trade_contracts_i}'));
    
    ScrollController sell_positions_scroll_controller = ScrollController();
    
    late CustomState state;
    late MainStateBindScope<CustomState> main_state_bind_scope;
    
    Widget build(BuildContext context) {
        state = MainStateBind.get_state<CustomState>(context);
        main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
        
        CyclesPerTokenRate latest_trade_rate = 
            state.cm_main.icrc1token_trade_contracts[cm_main_icrc1token_trade_contracts_i].latest_trades.length >= 1 
            ?
            state.cm_main.icrc1token_trade_contracts[cm_main_icrc1token_trade_contracts_i].latest_trades.last.rate
            : 
            CyclesPerTokenRate(cycles_per_token_quantum_rate: BigInt.from(0), token_decimal_places: state.cm_main.icrc1token_trade_contracts[cm_main_icrc1token_trade_contracts_i].ledger_data.decimals);
        
        List<DataColumn> header_columns = <DataColumn>[                                 
            DataColumn(label: Text('${state.cm_main.trade_contracts[cm_main_icrc1token_trade_contracts_i].ledger_data.symbol}')),
            DataColumn(label:Text('RATE')),
            DataColumn(label:  Text('CYCLES'))
        ];
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
            if (sell_positions_scroll_controller.hasClients) { // need this check for when there are 0 sell-positions.
                sell_positions_scroll_controller.jumpTo(sell_positions_scroll_controller.position.maxScrollExtent);
            }
        });
        
        List<DataRow> sell_positions_rows = create_position_book_data_rows(state.cm_main.icrc1token_trade_contracts[cm_main_icrc1token_trade_contracts_i].sell_position_book, PositionKind.Token); 
        
        double sell_positions_dataRowHeight = DataTableTheme.of(context).dataRowMinHeight ?? kMinInteractiveDimension; // the default for the DataTable2
        
        return Container(
            constraints: BoxConstraints(maxHeight: 400, maxWidth: 400),
            child: Column(
                children: [
                    ConstrainedBox(
                        constraints: BoxConstraints(maxHeight:  DataTableTheme.of(context).headingRowHeight ?? 56.0),
                        child: DataTable2(
                            headingTextStyle: DefaultTextStyle.of(context).style.copyWith(fontFamily: 'CourierNewBold', fontSize: 17),                      
                            columns: header_columns,
                            rows: [],
                        ),
                    ),
                    Flexible(
                        child: Align(
                            alignment: Alignment.bottomCenter,
                            child: LayoutBuilder(
                                builder: (BuildContext context, BoxConstraints constraints) {
                            //      height: constraints.maxHeight,
                            //      width: constraints.maxWidth
                                    return ConstrainedBox(
                                        constraints: BoxConstraints(maxHeight: min(sell_positions_rows.length * sell_positions_dataRowHeight, constraints.maxHeight)),
                                        child: DataTable2(
                                            dataTextStyle: DefaultTextStyle.of(context).style.copyWith(fontFamily: 'CourierNew', fontSize: 17),
                                            scrollController: sell_positions_scroll_controller,
                                            headingRowHeight: 0,                         
                                            dataRowHeight: sell_positions_dataRowHeight,   
                                            showBottomBorder: true,
                                            columns: header_columns,
                                            rows: sell_positions_rows,
                                        )
                                    );
                                }
                            )
                        )
                    ),    
                    Center(
                        child: Container(
                            padding: EdgeInsets.symmetric(vertical: 11),
                            child: Text('${latest_trade_rate}', style: TextStyle(fontSize: 19, fontFamily: 'CourierNewBold'))
                        )
                    ),
                    Flexible(child: DataTable2(
                        headingRowHeight: 0,
                        dataTextStyle: DefaultTextStyle.of(context).style.copyWith(fontFamily: 'CourierNew', fontSize: 17),
                        showBottomBorder: true,
                        columns: header_columns,
                        rows: create_position_book_data_rows(state.cm_main.icrc1token_trade_contracts[cm_main_icrc1token_trade_contracts_i].buy_position_book, PositionKind.Cycles)
                    )),
                ]
            )
        );
    }
    
    DataRow create_position_book_data_row(BigInt quantity, CyclesPerTokenRate rate, PositionKind kind) {
        late Cycles cycles_quantity; 
        late Tokens tokens_quantity; 
        switch (kind) {
            case PositionKind.Cycles: 
                cycles_quantity = Cycles(cycles: quantity);
                tokens_quantity = Tokens(quantums: cycles_transform_tokens(cycles_quantity, rate), decimal_places: rate.token_decimal_places);
            case PositionKind.Token: 
                tokens_quantity = Tokens(quantums: quantity, decimal_places: rate.token_decimal_places);
                cycles_quantity = tokens_transform_cycles(tokens_quantity.quantums, rate);
        }
        return DataRow(
            cells: [
                DataCell(show_tokens_with_symbol(tokens_quantity, state.cm_main.trade_contracts[cm_main_icrc1token_trade_contracts_i].ledger_data.symbol, show_token_symbol_in_main: false)),
                DataCell(Text('${rate}', style: TextStyle(color: kind == PositionKind.Cycles ? green : red, fontFamily:'CourierNewBold' ))),
                DataCell(show_tokens_with_symbol(cycles_quantity, cycles_symbol, show_token_symbol_in_main: false))
            ]
        );
    }
    
    List<DataRow> create_position_book_data_rows(List<PositionBookItem> positions, PositionKind position_kind) {
        positions = positions..sort((a,b){return b.rate.cycles_per_token_quantum_rate.compareTo(a.rate.cycles_per_token_quantum_rate);}); 
        
        if (positions.length == 0) { return <DataRow>[]; }
        
        List<DataRow> datarows = [];

        BigInt quantity = BigInt.from(0); 
        CyclesPerTokenRate rate = positions.first.rate;
        
        bool is_buy_positions = position_kind == PositionKind.Cycles; 
        
        for (PositionBookItem position in positions) {    
            if (position.rate.cycles_per_token_quantum_rate == rate.cycles_per_token_quantum_rate) {
                quantity += position.quantity;
            } else {
                datarows.add(create_position_book_data_row(quantity, rate, position_kind));
                quantity = position.quantity; 
                rate = position.rate;
            }
        }
        // for the last positon
        datarows.add(create_position_book_data_row(quantity, rate, position_kind));
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
                                    
                                    late BigInt position_id;
                                    try {
                                        if (widget.position_kind == PositionKind.Cycles) {
                                            position_id = await state.user!.bank!.cm_trade_cycles(
                                                state.cm_main.icrc1token_trade_contracts[widget.cm_main_icrc1token_trade_contracts_i],
                                                TradeCyclesQuest(
                                                    cycles: Cycles(cycles: trade_amount.quantums),
                                                    cycles_per_token_rate: cycles_per_token_rate,
                                                )
                                            );
                                        } else {
                                            position_id = await state.user!.bank!.cm_trade_tokens(
                                                state.cm_main.icrc1token_trade_contracts[widget.cm_main_icrc1token_trade_contracts_i],
                                                TradeTokensQuest(
                                                    tokens: trade_amount,
                                                    cycles_per_token_rate: cycles_per_token_rate
                                                )
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
                                            state.user!.bank!.load_cm_data(state.cm_main.icrc1token_trade_contracts[widget.cm_main_icrc1token_trade_contracts_i]),
                                            state.user!.bank!.fresh_metrics(),
                                            state.user!.bank!.fresh_icrc1_balances(state.cm_main.trade_contracts[widget.cm_main_icrc1token_trade_contracts_i].ledger_data),
                                            state.user!.bank!.fresh_icrc1_transactions(state.cm_main.trade_contracts[widget.cm_main_icrc1token_trade_contracts_i].ledger_data),
                                            state.cm_main.icrc1token_trade_contracts[widget.cm_main_icrc1token_trade_contracts_i].load_data()
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
                
        return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
                constraints: BoxConstraints(maxHeight: 505, maxWidth: 909),
                child: PaginatedDataTable2(
                    minWidth: 500,
                    renderEmptyRowsInTheEnd: false,
                    dividerThickness: 1,
                    headingTextStyle: DefaultTextStyle.of(context).style.copyWith(fontFamily: 'CourierNewBold', fontSize: 17),                      
                    dataTextStyle: DefaultTextStyle.of(context).style.copyWith(fontFamily: 'CourierNew', fontSize: 17),
                    rowsPerPage: 8,
                    columnSpacing: 13,
                    smRatio: 0.45,
                    lmRatio: 1.6,
                    columns: [
                        /*
                        DataColumn2(
                            label: Text('TYPE'),
                            //numeric: false,
                            //size: ColumnSize.M,
                            fixedWidth: 50.0,
                        ),
                        */
                        
                        DataColumn2(
                            label: Text('ID'), 
                            //numeric: true,
                            size: ColumnSize.S,
                        ),
                        /*
                        DataColumn2( // maybe put in the dropdown data section onTap ?
                            label: Text('creation-time'), 
                            //numeric: true,
                            size: ColumnSize.L,
                        ),
                        */
                        DataColumn2(
                            label: Text('POSITION'), 
                            //numeric: true,
                            size: ColumnSize.M,
                            tooltip: 'ORIGINAL-POSIT'
                        ),
                        DataColumn2(
                            label: Text('RATE'), 
                            //numeric: true,
                            size: ColumnSize.S,
                            tooltip: 'CYCLES PER ${state.cm_main.icrc1token_trade_contracts[widget.cm_main_icrc1token_trade_contracts_i].ledger_data.symbol}'
                        ),
                        DataColumn2(
                            label: Text('TRADES'), 
                            //numeric: true,
                            size: ColumnSize.L,
                            tooltip: ''
                        ),
                        /*
                        DataColumn2(
                            label: Text('FILL-RATE'), 
                            //numeric: true,
                            size: ColumnSize.S,
                            tooltip: 'The weighted-average of the rates of the trades of this position/order so far.'
                        ),
                        */
                        DataColumn2(
                            label: Text('CURRENT-POSITION'), 
                            //numeric: true,
                            size: ColumnSize.M,
                            tooltip: 'The current amount of the position/order if this position is open.'
                        ),
                        /*
                        DataColumn2(
                            label: Text('payouts-fees-sum'), 
                            //numeric: true,
                            size: ColumnSize.M,
                        ),
                        */
                    ],
                    source: UserCMLogsDataTableSource(
                        cm_main_icrc1token_trade_contracts_i: widget.cm_main_icrc1token_trade_contracts_i,
                        context: context,  
                    ),
                ),    
            )
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


DataRow datarow_of_the_user_position_log(BuildContext context, int cm_main_trade_contracts_i, PositionLog pl) {

    CustomState state = MainStateBind.get_state<CustomState>(context);
    MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
            
    Icrc1Ledger ledger_data = state.cm_main.trade_contracts[cm_main_trade_contracts_i].ledger_data;
    String token_symbol = ledger_data.symbol;
    int token_decimal_places = ledger_data.decimals;
    
    Tokens? fill_tokens;
    Cycles? fill_cycles;
    
    BigInt position_purchases_sum_quantity = pl.quest.quantity - pl.mainder_position_quantity;
    Widget position_purchases_sum_widget = pl.position_kind == PositionKind.Cycles 
        ? 
        show_tokens_with_symbol(Cycles(cycles: position_purchases_sum_quantity), cycles_symbol) 
        : 
        show_tokens_with_symbol(Tokens(quantums: position_purchases_sum_quantity, decimal_places: token_decimal_places), token_symbol);
    
    Widget fill_widget = pl.position_kind == PositionKind.Cycles 
        ? 
        show_tokens_with_symbol(Tokens(quantums: pl.fill_quantity, decimal_places: token_decimal_places), token_symbol) 
        : 
        show_tokens_with_symbol(Cycles(cycles: pl.fill_quantity), cycles_symbol);
    
    Widget position_quantity = 
        pl.position_kind == PositionKind.Cycles 
        ? 
        show_tokens_with_symbol(Cycles(cycles: pl.quest.quantity), cycles_symbol)
        : 
        show_tokens_with_symbol(Tokens(quantums: pl.quest.quantity, decimal_places: token_decimal_places), token_symbol);
    
    Widget trades_quantities_widget = Row(children: [position_purchases_sum_widget, Text(' <> '), fill_widget]);
    
    Widget current_position_widget = 
        pl.position_termination != null 
        ? 
        Container(
            child: Text(switch (pl.position_termination!.cause) {
                PositionTerminationCause.Fill => 'DONE',
                PositionTerminationCause.Bump => 'BUMP',
                PositionTerminationCause.TimePass => 'TIMEOUT',
                PositionTerminationCause.UserCallVoidPosition => 'CANCELLED',   
            })
        ) 
        :
        Row(
            children: [
                pl.position_kind == PositionKind.Cycles
                ? 
                show_tokens_with_symbol(Cycles(cycles: pl.mainder_position_quantity), cycles_symbol)
                : 
                show_tokens_with_symbol(Tokens(quantums: pl.mainder_position_quantity, decimal_places: token_decimal_places), token_symbol)        
                ,
                //SizedBox(width: 11),
                Spacer(),
                OutlineButton(
                    child: Text('CANCEL', style: TextStyle(fontSize: 11, fontFamily: 'CourierNew')),
                    on_press_complete: () async {
                            state.loading_text = 'closing position ${pl.id} ...';
                            state.is_loading = true;
                            MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                            
                            try {
                                await state.user!.bank!.cm_void_position(state.cm_main.trade_contracts[cm_main_trade_contracts_i], pl.id);
                            } catch(e,s) {
                                //print(e);
                                //print(s);
                                await showDialog(
                                    context: state.context,
                                    barrierDismissible: false,
                                    builder: (BuildContext context) {
                                        return AlertDialog(
                                            title: Text('cancel position error'),
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
                            
                            state.loading_text = 'cancel position success.\nposition-id: ${pl.id}\nloading positions ...';
                            main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);
                            
                            Future success_dialog = showDialog(
                                context: state.context,
                                builder: (BuildContext context) {
                                    return AlertDialog(
                                        title: Text('cancel position success!'),
                                        content: Text('position-id: ${pl.id}'),
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
                                    state.user!.bank!.load_cm_data(state.cm_main.trade_contracts[cm_main_trade_contracts_i]),
                                    state.user!.bank!.fresh_metrics(),
                                    state.user!.bank!.fresh_icrc1_balances(state.cm_main.trade_contracts[cm_main_trade_contracts_i].ledger_data),
                                    state.user!.bank!.fresh_icrc1_transactions(state.cm_main.trade_contracts[cm_main_trade_contracts_i].ledger_data),
                                    state.cm_main.trade_contracts[cm_main_trade_contracts_i].load_data()
                                ]);
                            } catch(e) {
                                await showDialog(
                                    context: state.context,
                                    builder: (BuildContext context) {
                                        return AlertDialog(
                                            title: Text('Error when loading current positions:'),
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
                )
            ]
        );
    
        
    return DataRow2(
        onTap: () async {
            await showDialog(
                context: context, // state.context?. 
                builder: (BuildContext context) {
                    return PositionDialog(
                        cm_main_trade_contracts_i: cm_main_trade_contracts_i, 
                        pl: pl,
                        position_quantity: position_quantity,
                        position_purchases_sum_quantity: position_purchases_sum_quantity,
                        trades_quantities_widget: trades_quantities_widget,
                        current_position_widget: current_position_widget,
                    );
                }                
            );
        },
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
            DataCell(Text(pl.id.toString())),
            //DataCell(Text('${position_log_timestamp_format(datetime_of_the_nanos(pl.creation_timestamp_nanos))}')),
            DataCell(position_quantity),
            DataCell(Text('${pl.quest.cycles_per_token_rate.toString()/*.replaceFirst('T', '')*/}')),
            DataCell(
                trades_quantities_widget
            ),
            //DataCell(Text('${pl.fill_average_rate.toString().replaceFirst('T', '')}')),
            DataCell(
                current_position_widget
            ),            
            //DataCell(Text('${pl.position_kind == PositionKind.Cycles ? Tokens(quantums: pl.payouts_fees_sum, decimal_places: token_decimal_places) : Cycles(cycles: pl.payouts_fees_sum)}')), 
            
        ]
    );
            
    
}

class PositionDialog extends StatefulWidget {
    final int cm_main_trade_contracts_i;
    PositionLog pl;
    Widget position_quantity;
    BigInt position_purchases_sum_quantity;
    Widget trades_quantities_widget;
    Widget current_position_widget;
    PositionDialog({
        required this.cm_main_trade_contracts_i, 
        required this.pl,
        required this.position_quantity,
        required this.position_purchases_sum_quantity,
        required this.trades_quantities_widget,
        required this.current_position_widget,
    }) : super(key: ValueKey('PositionDialog pl-id: ${pl.id} cm_main_trade_contracts_i: ${cm_main_trade_contracts_i}'));
    State createState() => PositionDialogState();
}
class PositionDialogState extends State<PositionDialog> {
    
    Future<void>? load_cm_user_position_trade_logs_future;    
    
    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
        
        if (load_cm_user_position_trade_logs_future == null && state.user!.bank!.cm_trade_contracts[state.cm_main.trade_contracts[widget.cm_main_trade_contracts_i]]!.user_positions_trade_logs[widget.pl.id] == null) {
            load_cm_user_position_trade_logs_future = state.user!.bank!.load_cm_user_position_trade_logs(state.cm_main.trade_contracts[widget.cm_main_trade_contracts_i], widget.pl.id); 
        }
        
        Icrc1Ledger ledger_data = state.cm_main.trade_contracts[widget.cm_main_trade_contracts_i].ledger_data;
        String token_symbol = ledger_data.symbol;
        int token_decimal_places = ledger_data.decimals;
        
        PositionLog pl = widget.pl;
        
        return Dialog(
            child: Container(
                constraints: BoxConstraints(maxWidth: 505),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        ScaffoldBodyHeader(Row(
                            mainAxisSize: MainAxisSize.max, 
                            children: [
                                Flexible(flex:1, fit: FlexFit.tight, child: Container(
                                    width: double.infinity, 
                                    child: Align(
                                        alignment: Alignment.topLeft, 
                                        child: Container(
                                            //padding: EdgeInsets.all(3),
                                            child: IconButton(icon: Icon(Icons.close), iconSize: 11, onPressed: ()=>Navigator.of(context).pop()),/*OutlineButton(
                                                child: Center(child: Text('x', style: TextStyle(fontFamily: 'CourierNew'))),
                                                on_press_complete: () => Navigator.of(context).pop(),
                                            )*/
                                        ) 
                                    )
                                )),
                                Flexible(flex: 11, fit: FlexFit.tight, child: Center(
                                    child: Column(
                                        children: [
                                            Text('POSITION-LOG', style: TextStyle(fontSize: 17))
                                        ]
                                    )
                                )),
                                Flexible(flex: 1,  fit: FlexFit.tight, child: Container(width: double.infinity, child: Text(''))),
                            ]
                        )),
                        Flexible(fit: FlexFit.loose, child: ScrollConfigurationWithTheMouse(
                            SingleChildScrollView(
                                scrollDirection: Axis.horizontal, 
                                child: SingleChildScrollView(
                                    scrollDirection: Axis.vertical,
                                    child: Container(
                                        padding: EdgeInsets.all(27),
                                        child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: <Widget>[
                                                //Text('POSITION-LOG', style: TextStyle(fontSize: 23)),
                                                //SizedBox(height: 21),
                                                DataTable(
                                                    headingRowHeight: 0,
                                                    dataTextStyle: DefaultTextStyle.of(context).style.copyWith(fontFamily: 'CourierNew', fontSize: 14),
                                                    columns: [
                                                        DataColumn(label: Text('')),
                                                        DataColumn(label: Text('')),
                                                    ],
                                                    rows: [
                                                        DataRow(cells: [
                                                            DataCell(Text('ID:',/* style: TextStyle(fontFamily: 'CourierNewBold')*/)),
                                                            DataCell(Text('${pl.id}')),
                                                        ]),
                                                        DataRow(cells: [
                                                            DataCell(Text('TIMESTAMP:', /*style: TextStyle(fontFamily: 'CourierNewBold')*/)),
                                                            DataCell(Text('${position_log_timestamp_format(datetime_of_the_nanos(pl.creation_timestamp_nanos))}', style: TextStyle(fontSize: timestamp_format_font_size))),
                                                        ]),
                                                        DataRow(cells: [
                                                            DataCell(Text('POSITION:', /*style: TextStyle(fontFamily: 'CourierNewBold')*/)),
                                                            DataCell(widget.position_quantity),
                                                        ]),
                                                        DataRow(cells: [
                                                            DataCell(Text('RATE:', /*style: TextStyle(fontFamily: 'CourierNewBold')*/)),
                                                            DataCell(Text(pl.quest.cycles_per_token_rate.toString())),
                                                        ]),
                                                        DataRow(cells: [
                                                            DataCell(Text('FILL-PERCENTAGE:', /*style: TextStyle(fontFamily: 'CourierNewBold')*/)),
                                                            DataCell(
                                                                Builder(
                                                                    builder: (BuildContext context) {
                                                                        double percentage_fill = widget.position_purchases_sum_quantity.toDouble() / (pl.quest.quantity / BigInt.from(100));
                                                                        return Text('${percentage_fill.toStringAsFixed(0)}%');
                                                                    }
                                                                )
                                                            ),
                                                        ]),
                                                        DataRow(cells: [
                                                            DataCell(Text('TRADES:', /*style: TextStyle(fontFamily: 'CourierNewBold')*/)),
                                                            DataCell(widget.trades_quantities_widget),
                                                        ]),
                                                        DataRow(cells: [
                                                            DataCell(Text('FILL-AVERAGE-RATE:', /*style: TextStyle(fontFamily: 'CourierNewBold')*/)),
                                                            DataCell(Text('${pl.fill_average_rate}')),
                                                        ]),
                                                        DataRow(cells: [
                                                            DataCell(Text('CTS-PAYOUT-FEES:',/* style: TextStyle(fontFamily: 'CourierNewBold')*/)),
                                                            DataCell(
                                                                pl.position_kind == PositionKind.Cycles 
                                                                ? 
                                                                show_tokens_with_symbol(Tokens(quantums: pl.payouts_fees_sum, decimal_places: token_decimal_places), token_symbol)
                                                                : 
                                                                show_tokens_with_symbol(Cycles(cycles: pl.payouts_fees_sum), cycles_symbol)                                                        
                                                            )
                                                        ]),
                                                        if (pl.position_kind == PositionKind.Cycles) DataRow(cells: [
                                                            DataCell(Text('${token_symbol}-LEDGER-FEES:',/* style: TextStyle(fontFamily: 'CourierNewBold')*/)),
                                                            DataCell(
                                                                FutureBuilder(
                                                                    future: load_cm_user_position_trade_logs_future,
                                                                    builder: (BuildContext context, AsyncSnapshot snapshot) {
                                                                        CustomState state = MainStateBind.get_state<CustomState>(context);
                                                                        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
                                                                        BigInt trades_token_payouts_ledger_fees_sum =
                                                                            (state.user!.bank!.cm_trade_contracts[state.cm_main.trade_contracts[widget.cm_main_trade_contracts_i]]!
                                                                                .user_positions_trade_logs[widget.pl.id].nullmap((m)=>m.values) ?? [])
                                                                                .fold(BigInt.from(0), (BigInt value, TradeLogAndPayoutStatus l)=> value + l.tl.tokens_payout_ledger_transfer_fee);
                                                                        return switch (snapshot.connectionState) {
                                                                            ConnectionState.none || ConnectionState.done => show_tokens_with_symbol(
                                                                                Tokens(quantums: trades_token_payouts_ledger_fees_sum, decimal_places: token_decimal_places), 
                                                                                token_symbol
                                                                            ),
                                                                            _ => Center(child: Text('loading ...'))
                                                                        };
                                                                    }
                                                                )
                                                            ),
                                                        ]),
                                                        /*
                                                        DataRow(cells: [
                                                            DataCell(Text('PAYOUTS:', style: TextStyle(fontFamily: 'CourierNewBold'))),
                                                            DataCell(
                                                                pl.position_kind == PositionKind.Cycles 
                                                                ? 
                                                                FutureBuilder(
                                                                    future: load_cm_user_position_trade_logs_future,                                                                
                                                                    builder: (BuildContext context, AsyncSnapshot snapshot) {
                                                                        CustomState state = MainStateBind.get_state<CustomState>(context);
                                                                        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
                                                                        BigInt trades_token_payouts_ledger_fees_sum =
                                                                            state.user!.bank!.cm_trade_contracts[state.cm_main.trade_contracts[widget.cm_main_trade_contracts_i]]!
                                                                                .user_positions_trade_logs[widget.pl.id].nullmap((m)=>m.values) ?? []
                                                                                .fold(BigInt.from(0), (BigInt value, TradeLog tl)=> value + tl.tokens_payout_ledger_transfer_fee);
                                                                        return switch (snapshot.connectionState) {
                                                                            ConnectionState.none || ConnectionState.done => 
                                                                            show_tokens_with_symbol(Tokens(quantums: pl.fill_quantity - pl.payouts_fees_sum - trades_token_payouts_ledger_fees_sum, decimal_places: token_decimal_places), token_symbol)
                                                                
                                                                            show_tokens_with_symbol(
                                                                                Tokens(quantums: , decimal_places: token_decimal_places), 
                                                                                token_symbol
                                                                            ),
                                                                            _ => Center(child: Text('loading ...'))
                                                                        };
                                                                    }
                                                                )
                                                                :
                                                                show_tokens_with_symbol(Cycles(cycles: pl.fill_quantity - pl.payouts_fees_sum), cycles_symbol)
                                                                                                                        
                                                            )
                                                        ]),
                                                        */
                                                        DataRow(cells: [
                                                            DataCell(Text('CURRENT-POSITION:', /*style: TextStyle(fontFamily: 'CourierNewBold')*/)),
                                                            DataCell(widget.current_position_widget),
                                                        ]),
                                                        
                                                        
                                                    ]
                                                ),
                                                SizedBox(height: 17),
                                                OutlineButton(
                                                    child: Text('VIEW TRADES', style: TextStyle(fontFamily: 'CourierNew', fontSize: 14)),
                                                    on_press_complete: () async {
                                                        await showDialog(
                                                            context: context, 
                                                            builder: (BuildContext context) { 
                                                                return Dialog(
                                                                    child: ViewTradesForASpecificUserPosition(pl, cm_main_trade_contracts_i: widget.cm_main_trade_contracts_i, load_cm_user_position_trade_logs_future: load_cm_user_position_trade_logs_future),
                                                                );
                                                            }
                                                        );
                                                    } 
                                                ),
                                            ],
                                        ),
                                    )
                                )
                            )
                        ))
                    ]
                )
            )
        );
    }
}        

/*
    
}
*/
String cycles_symbol = 'CYCLES';

Tooltip show_tokens_with_symbol(Tokens tokens, String token_symbol, {bool show_token_symbol_in_main = true}) {
    Tokens tokens_round = tokens.round_decimal_places(2);
    Tokens tokens_for_the_main_show = tokens_round.quantums == BigInt.from(0) ? tokens : tokens_round; 
    return Tooltip(
        richMessage: TextSpan(
            style: TextStyle(fontFamily: 'ChakraPetchBold', fontSize: 17),
            children: <TextSpan>[
                TextSpan(text: tokens.toString()),
                TextSpan(text: '-$token_symbol', style: TextStyle(fontSize: 11)),
            ],
        ),
        child: Text.rich(
            TextSpan(
                children: <TextSpan>[
                    TextSpan(text: tokens_for_the_main_show.toString()),
                    if (show_token_symbol_in_main) TextSpan(text: '-$token_symbol', style: TextStyle(fontSize: 11)),
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
        return datarow_of_the_user_position_log(context, cm_main_icrc1token_trade_contracts_i, pl);
        
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
                (k)=>datarow_of_the_user_position_log(
                    context,
                    cm_main_icrc1token_trade_contracts_i, 
                    state.user!.bank!.cm_trade_contracts[state.cm_main.icrc1token_trade_contracts[cm_main_icrc1token_trade_contracts_i]]!
                        .current_user_positions[k]!,
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
                (k)=>datarow_of_the_user_position_log(
                    context,
                    cm_main_icrc1token_trade_contracts_i, 
                    state.user!.bank!.cm_trade_contracts[state.cm_main.icrc1token_trade_contracts[cm_main_icrc1token_trade_contracts_i]]!
                        .current_user_positions[k]!,
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

const double timestamp_format_font_size = 13;

class ViewTradesForASpecificUserPosition extends StatefulWidget {
    PositionLog pl;
    int cm_main_trade_contracts_i;
    Future<void>? load_cm_user_position_trade_logs_future;    
    ViewTradesForASpecificUserPosition(this.pl, {required this.cm_main_trade_contracts_i, required this.load_cm_user_position_trade_logs_future}) : super(key: ValueKey('ViewTradesForASpecificUserPosition: ${pl.id} cm_main_trade_contracts_i: ${cm_main_trade_contracts_i}'));
    State createState() => ViewTradesForASpecificUserPositionState();
}
class ViewTradesForASpecificUserPositionState extends State<ViewTradesForASpecificUserPosition> {
    
    late final ScrollController scrollcontroller;
        
    void initState() {        
        scrollcontroller = ScrollController();
        //scrollcontroller.addListener(_handle_controller_scroll);
        super.initState();
    }
    void dispose() {
        //scrollcontroller.removeListener(_handle_controller_scroll);
        scrollcontroller.dispose();
        super.dispose();
    }
    
    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
                
        int token_decimal_places = state.cm_main.trade_contracts[widget.cm_main_trade_contracts_i].ledger_data.decimals;
        String token_symbol = state.cm_main.trade_contracts[widget.cm_main_trade_contracts_i].ledger_data.symbol;
        
        double width = 850;
        
        return Container(
            padding: EdgeInsets.all(13),
            constraints: BoxConstraints(maxWidth: width),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                    //Text('TRADES', style: TextStyle(fontSize: 21)),
                    ScaffoldBodyHeader(Row(
                        mainAxisSize: MainAxisSize.max, 
                        children: [
                            Flexible(flex:1, fit: FlexFit.tight, child: Container(
                                width: double.infinity, 
                                child: Align(
                                    alignment: Alignment.topLeft, 
                                    child: Container(
                                        //padding: EdgeInsets.all(3),
                                        child: IconButton(icon: Icon(Icons.close), iconSize: 11, onPressed: ()=>Navigator.of(context).pop()),/*OutlineButton(
                                            child: Center(child: Text('x', style: TextStyle(fontFamily: 'CourierNew'))),
                                            on_press_complete: () => Navigator.of(context).pop(),
                                        )*/
                                    ) 
                                )
                            )),
                            Flexible(flex: 11, fit: FlexFit.tight, child: Center(
                                child: Column(
                                    children: [
                                        Text('POSITION-${widget.pl.id} TRADES', style: TextStyle(fontSize: 17))
                                    ]
                                )
                            )),
                            Flexible(flex: 1,  fit: FlexFit.tight, child: Container(width: double.infinity, child: Text(''))),
                        ]
                    )),
                    Flexible(fit: FlexFit.loose, child: ScrollConfigurationWithTheMouse(/*SingleChildScrollView(
                        scrollDirection: Axis.horizontal, 
                        child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: */FutureBuilder(
                            future: widget.load_cm_user_position_trade_logs_future,
                            builder: (BuildContext context, AsyncSnapshot snapshot) {
                                double dataRowHeight = DataTableTheme.of(context).dataRowMinHeight ?? kMinInteractiveDimension; // the default for the DataTable2
                                return switch (snapshot.connectionState) {
                                    ConnectionState.none || ConnectionState.done => LayoutBuilder(
                                        builder: (BuildContext context, BoxConstraints constraints) {
                                            Iterable<TradeLogAndPayoutStatus> rows = state.user!.bank!.cm_trade_contracts[state.cm_main.trade_contracts[widget.cm_main_trade_contracts_i]]!.user_positions_trade_logs[widget.pl.id].nullmap((m)=>m.values) ?? [];
                                            double headingRowHeight = DataTableTheme.of(context).headingRowHeight ?? 56.0;
                                            return SingleChildScrollView(scrollDirection: Axis.horizontal, child: Container(
                                                constraints: BoxConstraints(maxHeight: min(headingRowHeight + rows.length * dataRowHeight, constraints.maxHeight)),
                                                width: width,
                                                child: DataTable2(
                                                    headingTextStyle: DefaultTextStyle.of(context).style.copyWith(fontFamily: 'CourierNewBold', fontSize: 17),                      
                                                    dataTextStyle: DefaultTextStyle.of(context).style.copyWith(fontFamily: 'CourierNew', fontSize: 17),
                                                    isHorizontalScrollBarVisible: false,
                                                    scrollController: scrollcontroller,
                                                    showBottomBorder: true,
                                                    smRatio: 0.57,
                                                    lmRatio: 1.3,
                                                    columns: <DataColumn>[
                                                        DataColumn2(label: Text('ID'), size: ColumnSize.S),
                                                        DataColumn2(label: Text('TIMESTAMP'), size: ColumnSize.M),
                                                        DataColumn2(label: Text('TRADE'), size: ColumnSize.L),
                                                        DataColumn2(label: Text('RATE'), size: ColumnSize.S),
                                                        DataColumn2(label: Text('PAYOUT'), size: ColumnSize.S),
                                                    ],
                                                    rows: [
                                                        for (TradeLogAndPayoutStatus l in rows)
                                                            DataRow(cells: [
                                                                DataCell(Text('${l.tl.id}')),
                                                                DataCell(Text('${position_log_timestamp_format(datetime_of_the_nanos(l.tl.timestamp_nanos))}', style: TextStyle(fontSize: timestamp_format_font_size))),
                                                                DataCell(Builder(builder: (BuildContext context) {
                                                                    List<Widget> trade_mounts = [
                                                                        show_tokens_with_symbol(l.tl.cycles, cycles_symbol),
                                                                        show_tokens_with_symbol(Tokens(quantums: l.tl.tokens, decimal_places: token_decimal_places), token_symbol)                                                
                                                                    ];
                                                                    if (widget.pl.position_kind == PositionKind.Token) {
                                                                        trade_mounts = trade_mounts.reversed.toList(); 
                                                                    } 
                                                                    return Row(children: [trade_mounts[0], Text(' <> '), trade_mounts[1]]);
                                                                })),
                                                                DataCell(Text('${l.tl.cycles_per_token_rate.toString()}')),
                                                                DataCell(Text((widget.pl.position_kind == PositionKind.Cycles ? l.tokens_payout_complete : l.cycles_payout_complete) ? 'DONE' : 'PENDING')),
                                                                /*
                                                                DataCell(
                                                                    widget.pl.position_kind == PositionKind.Cycles
                                                                    ?
                                                                    show_tokens_with_symbol(Tokens(quantums: tl.tokens_payout_fee, decimal_places: token_decimal_places), token_symbol)
                                                                    : 
                                                                    show_tokens_with_symbol(tl.cycles_payout_fee, cycles_symbol)
                                                                ),
                                                                */
                                                            ])
                                                    ]
                                                )
                                            ));
                                        }
                                    ),
                                    _ => Center(child: Text('loading the trades for this position'))
                                };
                            }
                        )
                    ))
                ]
            )
        );
    }   
}



