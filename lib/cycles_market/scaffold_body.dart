import 'dart:ui' as dart_ui;
import 'dart:math';
import 'dart:html' show window;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'package:ic_tools/tools.dart';
import 'package:ic_tools/common.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:contentsize_tabbarview/contentsize_tabbarview.dart';

import '../config/state.dart';
import '../config/state_bind.dart';
import '../config/urls.dart';
import './cycles_market.dart';
import '../bank/forms.dart';
import '../tools/widgets.dart';
import '../tools/tools.dart';
import '../tools/ii_login.dart';
import '../user.dart';
import './candles.dart';



class CyclesMarketScaffoldBody extends StatefulWidget {
    const CyclesMarketScaffoldBody({Key? key}) : super(key: key);
    static CyclesMarketScaffoldBody create({Key? key}) => CyclesMarketScaffoldBody(key: key);
    State<CyclesMarketScaffoldBody> createState() => CyclesMarketScaffoldBodyState();
}
class CyclesMarketScaffoldBodyState extends State<CyclesMarketScaffoldBody> {    

    bool stop_scroll = false; 
    
    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        //MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
        
        if (state.first_show_scaffold == false) {
            return const Text(''); // is never shown to the user. it is for when the router is loading the first-state of tcs or bank or ledgers and want to put the pages into the navigator but not build the ui for the pages.
        }
        
        double scaffold_body_header_max_width = 1300;
        /*
        List<Widget> column_children = [];
        
        column_children.addAll([

            SizedBox(
                height: 10,   
            ),
            Container(
                width: width,
                child: Container(
                    margin: EdgeInsets.all(13),
                    child: Align(
                        alignment: Alignment.centerLeft,
                        child: CyclesMarketTokenSelector(),
                    )
                )
            ),
            CyclesMarketTradeContractTradePage(
                cm_main_icrc1token_trade_contracts_i: state.cm_main_icrc1token_trade_contracts_i,
                stop_scroll: (bool b) => setState((){ stop_scroll = b; }),
            )
        ]);
        */

        return Center(
            child: Container(
                child: Column(
                    children: [
                        Container(
                            constraints: BoxConstraints(maxWidth: scaffold_body_header_max_width),
                            child: ScaffoldBodyHeader(
                                /*Container(
                                    decoration: BoxDecoration(
                                        color: blue,
                                        borderRadius: BorderRadius.circular(20),
                                    ),
                                    child:*/ Container(
                                        //margin: EdgeInsets.all(13),
                                        child: Text('CYCLES-MARKET', style: TextStyle(fontSize: 19)),
                                    )
                                //)
                            )
                        ),
                        Expanded(
                            child: Stack(
                                children: [
                                    ListView(
                                        padding: EdgeInsets.all(0),
                                        physics: stop_scroll ? NeverScrollableScrollPhysics() : null,
                                        addAutomaticKeepAlives: true,
                                        children: [
                                            Column(
                                                children: [
                                                    CyclesMarketTradeContractTradePage(
                                                        cm_main_icrc1token_trade_contracts_i: state.cm_main_icrc1token_trade_contracts_i,
                                                        stop_scroll: (bool b) => setState((){ stop_scroll = b; }),
                                                    ),
                                                ]
                                            )
                                        ]
                                    ),
                                    Center(
                                        child: Column(
                                            children: [
                                                SizedBox(
                                                    height: 10,
                                                ),
                                                Container(
                                                    width: scaffold_body_header_max_width,
                                                    margin: EdgeInsets.all(13),
                                                    child: Align(
                                                        alignment: Alignment.centerLeft,
                                                        child: CyclesMarketTokenSelector(),
                                                    )
                                                ),
                                            ]
                                        )
                                    )
                                ]
                            )
                        )
                    ]
                )
            )
        );
    }
    
}



class CyclesMarketTokenSelector extends StatefulWidget {
    CyclesMarketTokenSelector({super.key});
    State<CyclesMarketTokenSelector> createState() => CyclesMarketTokenSelectorState();
}
class CyclesMarketTokenSelectorState extends State<CyclesMarketTokenSelector> {

    late TextEditingController text_controller;
    late FocusNode focus_node;

    late CustomState state; // need for the focus_node listener
    late MainStateBindScope<CustomState> main_state_bind_scope;

    void initState() {
        super.initState();
        text_controller = TextEditingController();
        focus_node = FocusNode(
            debugLabel: 'market token selector', 
            canRequestFocus: switch (defaultTargetPlatform) {
                TargetPlatform.android || TargetPlatform.iOS => false,
                _ => true,
            }
        );
        focus_node.addListener(focus_node_listener);
    }
    void dispose() {
        text_controller.dispose();
        focus_node.removeListener(focus_node_listener);
        focus_node.dispose();
        super.dispose();
    }

    void focus_node_listener() {
        // if go away from focus, set the text back to the current token symbol in case someone left something else in the text field.
        if (focus_node.hasPrimaryFocus == false) {
            print('setting token selector text back to the current token symbol');
            text_controller.text = state.cm_main.trade_contracts[state.cm_main_icrc1token_trade_contracts_i].ledger_data.symbol;
        }
    }

    Widget build(BuildContext context) {
        state = MainStateBind.get_state<CustomState>(context);
        main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);

        return CardWithBorder(
            child: DropdownMenu<int>(
                menuStyle: MenuStyle(
                    side: WidgetStatePropertyAll(BorderSide.none),
                ),
                controller: text_controller,
                focusNode: focus_node,
                enableSearch: true,
                enableFilter: false, // we want the user to always be able to know that there are many tokens. the search already moves the highlighted selection so no need for this flag.
                textStyle: DefaultTextStyle.of(context).style.copyWith(fontFamily: 'CourierNewBold', fontSize: 22),
                dropdownMenuEntries: <DropdownMenuEntry<int>>[
                    for (int i = 0; i < state.cm_main.icrc1token_trade_contracts.length; i++)
                        DropdownMenuEntry<int>(
                            label: state.cm_main.icrc1token_trade_contracts[i].ledger_data.symbol,
                            value: i,
                            style: ButtonStyle(textStyle: WidgetStatePropertyAll(TextStyle(fontFamily: 'CourierNewBold', fontSize: 22)))
                        ),
                ],
                initialSelection: state.cm_main_icrc1token_trade_contracts_i,
                onSelected: (int? select_i) {
                    if (select_i is int) {
                        if (select_i != state.cm_main_icrc1token_trade_contracts_i) {
                            change_url_into_cm_market(select_i, context);
                        } else {
                            setState((){});
                        }
                    }
                }
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
                if (state.user != null) ...[
                    state.user!.load_cm_data([state.cm_main.trade_contracts[widget.cm_main_icrc1token_trade_contracts_i]]),
                    state.user!.fresh_icrc1_balances([state.cm_main.trade_contracts[widget.cm_main_icrc1token_trade_contracts_i].ledger_data, CYCLES_BANK_LEDGER]),
                    //state.user!.fresh_icrc1_transactions([state.cm_main.trade_contracts[widget.cm_main_icrc1token_trade_contracts_i].ledger_data, CYCLES_BANK_LEDGER]),
                ]
            ])
            .then((x){
                if (this.mounted) {     // this function can run when this widget is no longer in the widget tree. make sure to call setState only if this widget is still in the widget tree.  
                    setState((){});
                }
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
        
        const double tb_padding_market_trades_and_position_book = 11;
        const double runSpacing = 13;
        const double wrap_spacing = runSpacing * 2;

        return Container(
            child: Column(
                children: [ 
                    //temp
                    /*
                    for (Candle candle in state.cm_main.trade_contracts[widget.cm_main_icrc1token_trade_contracts_i].candles)
                        Text('time: ${candle.time_nanos}, open: ${candle.open_rate}, high: ${candle.high_rate}, low: ${candle.low_rate}, close: ${candle.close_rate}, volume: ${candle.volume_tokens}'),
                    */
                    LayoutBuilder(
                        builder: (BuildContext context, BoxConstraints constraints) {
                            double sbheight = 23;
                            if (constraints.maxWidth < 983) { // wonderful
                                sbheight += 80;
                            }
                            return SizedBox(
                                height: sbheight,
                            );
                        }
                    ),
                    VolumeStats(cm_main_trade_contracts_i: widget.cm_main_icrc1token_trade_contracts_i),
                    SizedBox(height: runSpacing*2),
                    Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.start,
                        runSpacing: runSpacing,
                        spacing: wrap_spacing,
                        children: [
                            CreatePositionWidget(cm_main_icrc1token_trade_contracts_i: widget.cm_main_icrc1token_trade_contracts_i),
                            CandlesChart(cm_main_trade_contracts_i: widget.cm_main_icrc1token_trade_contracts_i),
                        ]
                    ),
                    SizedBox(height: runSpacing),
                    Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: wrap_spacing,
                        runSpacing: runSpacing,
                        children: [
                            Container(
                                padding: EdgeInsets.symmetric(vertical: tb_padding_market_trades_and_position_book),
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
                                padding: EdgeInsets.symmetric(vertical: tb_padding_market_trades_and_position_book),
                                child: PositionBook(cm_main_icrc1token_trade_contracts_i: widget.cm_main_icrc1token_trade_contracts_i)
                            ),  
                        ]
                    ),
                    if (state.user != null) ...[
                        SizedBox(height: runSpacing),
                        Container(
                            child: UserCMLogs(cm_main_icrc1token_trade_contracts_i: widget.cm_main_icrc1token_trade_contracts_i)
                        ), 
                    ],
                    SizedBox(height: 13),
                ]
            )
        );   
    }
    
}

class VolumeStats extends StatelessWidget {
    int cm_main_trade_contracts_i;
    VolumeStats({super.key, required this.cm_main_trade_contracts_i});
    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        //MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
        
        Icrc1TokenTradeContract tc = state.cm_main.trade_contracts[this.cm_main_trade_contracts_i];
        ViewVolumeStatsSponse volume_stats = tc.volume_stats!;
        
        const double row_height = 32;
        
        return CardWithBorder(
            child: Container(
                margin: EdgeInsets.symmetric(vertical: 13),
                height: row_height*2,
                child: ListView(
                    shrinkWrap: true,
                    scrollDirection: Axis.horizontal,
                    children: [
                        DividerTheme(
                            data: DividerTheme.of(context).copyWith(color: const Color(0xFFFFFF)),
                            child: DataTable(
                                headingRowHeight: row_height,
                                dataRowMaxHeight: row_height,
                                dataRowMinHeight: row_height,
                                headingTextStyle: TextStyle(fontSize: 17, fontFamily: 'CourierNewBold'),
                                dataTextStyle: TextStyle(fontSize: 17, fontFamily: 'CourierNew'),
                                dividerThickness: 0,                                                        // renders 1px for some reason, https://github.com/flutter/flutter/issues/132214
                                //border: TableBorder.all(width: 1),
                                columns: [
                                    DataColumn(label: Text('VOLUME')),
                                    DataColumn(label: Text('24-HOUR')),
                                    DataColumn(label: Text('7-DAY')),
                                    DataColumn(label: Text('30-DAY')),
                                    DataColumn(label: Text('TOTAL')),
                                ],
                                rows: [
                                    /*
                                    DataRow(
                                        cells: [
                                            DataCell(Text('CYCLES:')),
                                            DataCell(show_tokens_with_symbol(Cycles(cycles: volume_stats.volume_cycles.volume_24_hour), cycles_symbol)),
                                            DataCell(show_tokens_with_symbol(Cycles(cycles: volume_stats.volume_cycles.volume_7_day), cycles_symbol)),
                                            DataCell(show_tokens_with_symbol(Cycles(cycles: volume_stats.volume_cycles.volume_30_day), cycles_symbol)),
                                            DataCell(show_tokens_with_symbol(Cycles(cycles: volume_stats.volume_cycles.volume_sum), cycles_symbol)),
                                        ]
                                    ),
                                    */
                                     // maybe on hover ask if user wants to view the token volume in token-units
                                    DataRow(
                                        cells: [
                                            DataCell(Text('${tc.ledger_data.symbol}:')),
                                            DataCell(show_tokens_with_symbol(Tokens(quantums: volume_stats.volume_tokens.volume_24_hour, decimal_places: tc.ledger_data.decimals), tc.ledger_data.symbol)),
                                            DataCell(show_tokens_with_symbol(Tokens(quantums: volume_stats.volume_tokens.volume_7_day, decimal_places: tc.ledger_data.decimals), tc.ledger_data.symbol)),
                                            DataCell(show_tokens_with_symbol(Tokens(quantums: volume_stats.volume_tokens.volume_30_day, decimal_places: tc.ledger_data.decimals), tc.ledger_data.symbol)),
                                            DataCell(show_tokens_with_symbol(Tokens(quantums: volume_stats.volume_tokens.volume_sum, decimal_places: tc.ledger_data.decimals), tc.ledger_data.symbol)),
                                        ]
                                    ),

                                ]
                            )
                        )
                    ]
                )
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
        && _controller.position.maxScrollExtent - _controller.offset < 50) { 
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
                            
        return CardWithBorder(
            child: Container(
                margin: EdgeInsets.symmetric(vertical: 13),
                child: Column(
                    children: [
                        Text('LATEST TRADES'),
                        SingleChildScrollView(scrollDirection: Axis.horizontal, child: Container(
                            margin: EdgeInsets.symmetric(horizontal: 17),
                            constraints: BoxConstraints(
                                maxHeight: 400,
                                maxWidth: 700
                            ),
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
                        ))
                    ]
                )
            )
        );
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
        
        return CardWithBorder(
            child: Container(
                margin: EdgeInsets.all(13),
                child: Column(
                    children: [
                        Text('POSITION BOOK'),
                        Container(
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
                                            child: Text(
                                                '${
                                                    state.cm_main.trade_contracts[cm_main_icrc1token_trade_contracts_i].compute_weight_average_rate_of_the_current_positions()
                                                }',
                                                style: TextStyle(fontSize: 19, fontFamily: 'CourierNewBold')
                                            )
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
                        )
                    ]
                )
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


const Color green = /*Color(0xFF4B6D3C);*/Color(0xFF45635E);//const Color(0xFF26a69a);
const Color red = /*Color(0xFF6D3C4B);*/Color(0xFF63454A);//const Color(0xFFef5350);



class CreatePositionWidget extends StatelessWidget {
    final int cm_main_icrc1token_trade_contracts_i;
    CreatePositionWidget({super.key, required this.cm_main_icrc1token_trade_contracts_i});
    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
        
        final String token_symbol = state.cm_main.icrc1token_trade_contracts[this.cm_main_icrc1token_trade_contracts_i].ledger_data.symbol;
        
        
        return CardWithBorder(child: Container(
            margin: EdgeInsets.all(13),
            width: 300,
            /*
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(20),
            ),*/
            child: DefaultTabController(
                length: 2,
                child: Column(
                    mainAxisSize: MainAxisSize.min, 
                    children: [
                        Text('TRADE'),
                        Container(
                            child: TabBar(
                                tabs: [
                                    Tab(text: 'CYCLES'),
                                    Tab(text: '${token_symbol}'),
                                ],
                            )
                        ),
                        Container(
                            child: ContentSizeTabBarView(
                                children: [
                                    CreatePositionForm(position_kind: PositionKind.Cycles, cm_main_icrc1token_trade_contracts_i: cm_main_icrc1token_trade_contracts_i),
                                    CreatePositionForm(position_kind: PositionKind.Token, cm_main_icrc1token_trade_contracts_i: cm_main_icrc1token_trade_contracts_i),
                                ],
                            ),
                        ),
                    ]
                )
            )
        ));
        
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
    late TextEditingController quantity_text_controller;
    late TextEditingController rate_text_controller;
    
    late Tokens trade_amount;
    late CyclesPerTokenRate cycles_per_token_rate;
    
    // for the text-controller-listeners
    late CustomState state;
    late MainStateBindScope<CustomState> main_state_bind_scope;    
    
    CyclesPerTokenRate? current_written_rate;
    
    @override
    void initState() {
        super.initState();
        quantity_text_controller = TextEditingController();
        rate_text_controller = TextEditingController();
        rate_text_controller.addListener((){
            CyclesPerTokenRate? valid_input;
            try {
                valid_input = CyclesPerTokenRate.oftheTCyclesDoubleString(rate_text_controller.text.trim(), token_decimal_places: state.cm_main.trade_contracts[widget.cm_main_icrc1token_trade_contracts_i].ledger_data.decimals);
            } catch(e) {}
            if (valid_input != null) {
                current_written_rate = valid_input;
            } else {
                current_written_rate = null;
            }
            setState((){});
        });
        
    }
    @override
    void dispose() {
        quantity_text_controller.dispose();    
        rate_text_controller.dispose();
        super.dispose();
    }
    
    Widget build(BuildContext context) {
        state = MainStateBind.get_state<CustomState>(context);
        main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);

        final String buy_or_sell = widget.position_kind == PositionKind.Cycles ? 'BUY' : 'SELL';
        final Icrc1Ledger ledger_data = state.cm_main.icrc1token_trade_contracts[widget.cm_main_icrc1token_trade_contracts_i].ledger_data;
        final int token_decimal_places = ledger_data.decimals;        
        final String token_symbol = ledger_data.symbol;
        
        final int first_field_decimal_places = widget.position_kind == PositionKind.Cycles ? Cycles.T_CYCLES_DECIMAL_PLACES : token_decimal_places;
        
        late final String max_quantity;
        if (state.user != null) {
            switch (widget.position_kind) {
                case PositionKind.Cycles:
                    max_quantity = Cycles(cycles: state.user!.icrc1_balances_cache[CYCLES_BANK_LEDGER]!).toString().replaceFirst('T', '');
                case PositionKind.Token:
                    max_quantity = Tokens(quantums: state.user!.icrc1_balances_cache[ledger_data]!, decimal_places: token_decimal_places).toString();    
            }
        }
        
        List<Widget> cycles_balance_and_token_balance = [
            Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text(
                    'CYCLES-BALANCE: ${state.user != null ? Cycles(cycles: state.user!.icrc1_balances_cache[CYCLES_BANK_LEDGER]!) : '_'}', 
                    style: TextStyle(fontFamily: 'CourierNew', fontSize: 14)
                ),
            ),
            Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text(
                    '${ledger_data.symbol}-BALANCE: ${state.user != null ? Tokens(quantums: state.user!.icrc1_balances_cache[ledger_data]!, decimal_places: ledger_data.decimals) : '_'}', 
                    style: TextStyle(fontFamily: 'CourierNew', fontSize: 14)
                ),
            ),
        ];
        
        Tokens quantity_ledger_fee = widget.position_kind == PositionKind.Token ? Tokens(quantums: ledger_data.fee, decimal_places: token_decimal_places) : Cycles(cycles: CYCLES_BANK_LEDGER.fee);
        Tokens ledger_fees_now = quantity_ledger_fee.add_quantums(quantity_ledger_fee.quantums); // two ledger fees to create a position 
        
        return Form(
            key: form_key,
            child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                    TextFormField(
                        controller: quantity_text_controller,
                        style: TextStyle(fontFamily: 'CourierNewBold'),
                        decoration: InputDecoration(
                            labelText: widget.position_kind == PositionKind.Cycles ? 'TCYCLES' : '$token_symbol',
                            suffix: TextButton(
                                child: Text('MAX', style: TextStyle(fontFamily: 'CourierNew')),
                                onPressed: () {
                                    if (state.user != null) {
                                        quantity_text_controller.value = TextEditingValue(text: max_quantity, selection: TextSelection.collapsed(offset: max_quantity.length));
                                    }
                                }
                            )
                        ),
                        onSaved: (String? value) { trade_amount = Tokens.of_the_double_string(value!, decimal_places: first_field_decimal_places); },
                        validator: (String? v) {
                            final String? tokens_validator_result = tokens_validator(token_decimal_places: first_field_decimal_places)(v);
                            if (tokens_validator_result != null) {
                                return tokens_validator_result;
                            }
                            final BigInt try_trade_quantums = Tokens.of_the_double_string(v!, decimal_places: first_field_decimal_places).quantums;
                            final BigInt user_balance_quantums = switch (widget.position_kind) {
                                PositionKind.Cycles => state.user!.icrc1_balances_cache[CYCLES_BANK_LEDGER]!,
                                PositionKind.Token => state.user!.icrc1_balances_cache[ledger_data]!,
                            };
                            if (try_trade_quantums > user_balance_quantums) {
                                return 'Your balance is too low for this amount.';
                            }
                            Tokens minimum_quantity = Tokens(quantums: quantity_ledger_fee.quantums * BigInt.from(10) + BigInt.from(10000) + ledger_fees_now.quantums, decimal_places: quantity_ledger_fee.decimal_places); 
                            if (try_trade_quantums < minimum_quantity.quantums) {
                                return 'Minimum ${minimum_quantity}';
                            }
                            return null;
                        }
                    ),
                    TextFormField(
                        controller: rate_text_controller,     
                        style: TextStyle(fontFamily: 'CourierNewBold'),
                        decoration: InputDecoration(
                            labelText: 'RATE (TCYCLES per 1-${token_symbol})',
                            //suffixText: current_written_rate != null && state.cycles_per_one_usd != null ? ' ≈ ${Tokens(quantums: cycles_transform_tokens(Cycles(cycles: current_written_rate!.cycles_per_token_quantum_rate*(BigInt.from(10).pow(token_decimal_places))), state.cycles_per_one_usd!), decimal_places: 2)}-USD' : null,
                            suffixStyle: TextStyle(fontFamily: 'CourierNew'),
                        ),
                        onSaved: (String? value) { cycles_per_token_rate = CyclesPerTokenRate.oftheTCyclesDoubleString(value!, token_decimal_places: token_decimal_places); },
                        validator: cycles_per_token_rate_validator(token_decimal_places: token_decimal_places)                    
                    ),
                    SizedBox(height:6),
                    if (widget.position_kind == PositionKind.Cycles) ...cycles_balance_and_token_balance
                    else ...(cycles_balance_and_token_balance.reversed.toList()),
                    Container(
                        width: double.infinity,
                        padding: EdgeInsets.fromLTRB(0, 7, 0,7),
                        child: FilledButton.tonal(
                            child: Text('TRADE ${widget.position_kind == PositionKind.Cycles ? 'CYCLES' : token_symbol} for ${widget.position_kind == PositionKind.Cycles ? token_symbol : 'CYCLES'}'),
                            onPressed: () async {
                                if (state.user == null) {
                                    
                                    await showDialog(
                                        context: context,
                                        barrierDismissible: true,
                                        builder: (BuildContext context) {
                                            return AlertDialog(
                                                title: Text('LOG-IN', style: TextStyle(fontFamily: 'CourierNewBold')),
                                                contentPadding: EdgeInsets.fromLTRB(0,16,0,0),
                                                content: Container(
                                                    height: 130,
                                                    child: Center(
                                                        child: IILoginButton(do_before: (){ Navigator.of(context).pop(); }),
                                                    ),
                                                ),
                                                actions: [
                                                    TextButton(
                                                        child: Text('CANCEL',  textAlign: TextAlign.end),
                                                        onPressed: () {
                                                            Navigator.of(context).pop();
                                                        }
                                                    ),
                                                ]
                                            );
                                        }
                                    );
                                    return;
                                }
                                
                                if (form_key.currentState!.validate()==true) {
                                    
                                    form_key.currentState!.save();
                                    
                                    // update trade_amount if not enough balance for position-creation-fees
                                    final BigInt user_balance_quantums = switch (widget.position_kind) {
                                        PositionKind.Cycles => state.user!.icrc1_balances_cache[CYCLES_BANK_LEDGER]!,
                                        PositionKind.Token => state.user!.icrc1_balances_cache[ledger_data]!,
                                    };
                                    // form field validator already makes sure that the user has enough balance for the amount and that the position is for at least the minimum position quantity + ledger_fees_now
                                    if (trade_amount.quantums + ledger_fees_now.quantums > user_balance_quantums) {
                                        trade_amount = Tokens(quantums: user_balance_quantums - ledger_fees_now.quantums, decimal_places: trade_amount.decimal_places);
                                    } 
                                    
                                    // show confirmation dialog
                                    late final bool confirm;
                                    await showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (BuildContext context) {
                                            
                                            Tokens trade_for_mount = widget.position_kind == PositionKind.Cycles ? Tokens(quantums: cycles_transform_tokens(Cycles(cycles: trade_amount.quantums), cycles_per_token_rate), decimal_places: token_decimal_places) : tokens_transform_cycles(trade_amount.quantums, cycles_per_token_rate);
                                            String trade_for_mount_suffix = '${widget.position_kind == PositionKind.Cycles ? ('-' + token_symbol) : ('-CYCLES')}';                                            
                                            
                                            BigInt trade_payout_fees_if_fill_quantums 
                                                = widget.position_kind == PositionKind.Cycles ?
                                                cycles_transform_tokens(Cycles(cycles: tokens_transform_cycles(trade_for_mount.quantums, cycles_per_token_rate).quantums ~/ BigInt.from(10000) * BigInt.from(50)), cycles_per_token_rate) // fee is always calculated in the cycles-form. 
                                                : trade_for_mount.quantums ~/ BigInt.from(10000) * BigInt.from(50); 
                                            Tokens trade_payout_fees_if_fill = widget.position_kind == PositionKind.Cycles ? Tokens(quantums: trade_payout_fees_if_fill_quantums, decimal_places: token_decimal_places) : Cycles(cycles: trade_payout_fees_if_fill_quantums);
                                            
                                            String ledger_fees_now_suffix = '${widget.position_kind == PositionKind.Cycles ? ('-CYCLES') : ('-' + token_symbol)}';                                            
                                            
                                            return AlertDialog(
                                                title: Text('CONFIRM', style: TextStyle(fontFamily: 'CourierNewBold')),
                                                contentPadding: EdgeInsets.fromLTRB(0,16,0,0),
                                                content: SingleChildScrollView(
                                                    child: SingleChildScrollView(
                                                        scrollDirection: Axis.horizontal,
                                                        child: Container(
                                                            constraints: BoxConstraints(
                                                                minWidth: 550,
                                                            ),    
                                                            padding: EdgeInsets.fromLTRB(24,0,24,24),
                                                            child: Column(
                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                children: [
                                                                    Text('TRADE ${widget.position_kind == PositionKind.Cycles ? 'CYCLES' : token_symbol} for ${widget.position_kind == PositionKind.Cycles ? token_symbol : 'CYCLES'}', style: TextStyle(fontFamily: 'CourierNew', fontSize: 19)),
                                                                    Column(
                                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                                        children: [
                                                                            SizedBox(
                                                                                height: 13,
                                                                            ),    
                                                                            DividerTheme(
                                                                                data: DividerTheme.of(context).copyWith(color: const Color(0xFFFFFF)),
                                                                                child: DataTable(
                                                                                    headingRowHeight: 0,
                                                                                    dataTextStyle: TextStyle(fontFamily: 'CourierNew', fontSize: 17), 
                                                                                    dividerThickness: 0,
                                                                                    columns: [
                                                                                        DataColumn(
                                                                                            label: Text('')
                                                                                        ),
                                                                                        DataColumn(
                                                                                            label: Text('')
                                                                                        ),
                                                                                    ],
                                                                                    rows: [
                                                                                        DataRow(
                                                                                            cells: [
                                                                                                DataCell(Text(
                                                                                                    'Trade:' 
                                                                                                )),
                                                                                                DataCell(Text(
                                                                                                    '${trade_amount}${widget.position_kind == PositionKind.Cycles ? 'T' : ''}-${widget.position_kind == PositionKind.Cycles ? 'CYCLES' : token_symbol}'
                                                                                                )),
                                                                                            ]
                                                                                        ),
                                                                                        DataRow(
                                                                                            cells: [
                                                                                                DataCell(Text(
                                                                                                    'Rate:' 
                                                                                                )),
                                                                                                DataCell(Builder(
                                                                                                    builder: (BuildContext context) {
                                                                                                        String text = /*'1-${token_symbol} = */'${cycles_per_token_rate}-CYCLES per 1-${token_symbol}'; 
                                                                                                        /*if (state.cycles_per_one_usd != null) {
                                                                                                            text += ' ≈ \$${Tokens(quantums: cycles_transform_tokens(Cycles(cycles: cycles_per_token_rate.cycles_per_token_quantum_rate * Tokens(quantums: BigInt.zero, decimal_places: token_decimal_places).dividable_by), state.cycles_per_one_usd!), decimal_places: 2)}-USD';
                                                                                                        }*/
                                                                                                        return Text(text);
                                                                                                    }
                                                                                                )),
                                                                                            ]
                                                                                        ),
                                                                                        DataRow(
                                                                                            cells: [
                                                                                                DataCell(Text(
                                                                                                    'Ledger fees:' 
                                                                                                )),
                                                                                                DataCell(Text(
                                                                                                    '${ledger_fees_now}${ledger_fees_now_suffix}'
                                                                                                )),
                                                                                            ]
                                                                                        ),
                                                                                        DataRow(
                                                                                            cells: [
                                                                                                DataCell(Text(
                                                                                                    'Total cost:'
                                                                                                )),
                                                                                                DataCell(Text(
                                                                                                    '${ledger_fees_now.add_quantums(trade_amount.quantums)}${ledger_fees_now_suffix}'
                                                                                                ))
                                                                                            ]
                                                                                        ),
                                                                                        /*
                                                                                        DataRow(
                                                                                            cells: [
                                                                                                DataCell(Text('If the position fills')),
                                                                                                DataCell(Text(''))
                                                                                            ]
                                                                                        ),
                                                                                        */
                                                                                        DataRow(
                                                                                            cells: [
                                                                                                DataCell(Text(
                                                                                                    'Position fill:'
                                                                                                )),
                                                                                                DataCell(Text(
                                                                                                    '${trade_for_mount}${trade_for_mount_suffix}'                                                                       
                                                                                                ))
                                                                                            ]
                                                                                        ),
                                                                                        DataRow(
                                                                                            cells: [
                                                                                                DataCell(Text(
                                                                                                    'Position fill fee:'
                                                                                                )),
                                                                                                DataCell(Text(
                                                                                                    '${trade_payout_fees_if_fill}${trade_for_mount_suffix}'                                                                       
                                                                                                ))
                                                                                            ]
                                                                                        ),
                                                                                        DataRow(
                                                                                            cells: [
                                                                                                DataCell(Text(
                                                                                                    'Position fill payout:'
                                                                                                )),
                                                                                                DataCell(Text(
                                                                                                    '${trade_for_mount.add_quantums(-trade_payout_fees_if_fill.quantums)}${trade_for_mount_suffix}'
                                                                                                ))
                                                                                            ]
                                                                                        ),
                                                                                        DataRow(
                                                                                            cells: [
                                                                                                DataCell(Text(
                                                                                                    'Payout ledger fee:'
                                                                                                )),
                                                                                                DataCell(Text(
                                                                                                    '${widget.position_kind == PositionKind.Token ? '${Cycles(cycles: CYCLES_BANK_LEDGER.fee)}-${cycles_symbol}' : '${Tokens(quantums: ledger_data.fee, decimal_places: token_decimal_places)}-${token_symbol}'}'                                                                       
                                                                                                ))
                                                                                            ]
                                                                                        )
                                                                                    ]
                                                                                ),
                                                                            ),
                                                                            SizedBox(height: 13),
                                                                            
                                                                        ]
                                                                    ),
                                                                ]
                                                            )
                                                        )
                                                    )
                                                ),
                                                actions: [
                                                    TextButton(
                                                        child: Text('CANCEL',  textAlign: TextAlign.end),
                                                        onPressed: () {
                                                            confirm = false;
                                                            Navigator.of(context).pop();
                                                        }
                                                    ),
                                                    TextButton(
                                                        child: Text('OK',  textAlign: TextAlign.end),
                                                        onPressed: () {
                                                            confirm = true;
                                                            Navigator.of(context).pop();
                                                        }
                                                    ),
                                                ]
                                            );
                                        }
                                    );
                                    if (confirm == false) {
                                        return;
                                    }
                                    
                                    
                                    
                                    state.loading_text = 'Creating Position';
                                    state.is_loading = true;
                                    MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                                    
                                    late BigInt position_id;
                                    try {
                                        if (widget.position_kind == PositionKind.Cycles) {
                                            position_id = await state.user!.cm_trade_cycles(
                                                state.cm_main.icrc1token_trade_contracts[widget.cm_main_icrc1token_trade_contracts_i],
                                                TradeCyclesQuest(
                                                    cycles: Cycles(cycles: trade_amount.quantums),
                                                    cycles_per_token_rate: cycles_per_token_rate,
                                                    posit_transfer_ledger_fee: CYCLES_BANK_LEDGER.fee,
                                                )
                                            );
                                        } else {
                                            position_id = await state.user!.cm_trade_tokens(
                                                state.cm_main.icrc1token_trade_contracts[widget.cm_main_icrc1token_trade_contracts_i],
                                                TradeTokensQuest(
                                                    tokens: trade_amount,
                                                    cycles_per_token_rate: cycles_per_token_rate,
                                                    posit_transfer_ledger_fee: state.cm_main.trade_contracts[widget.cm_main_icrc1token_trade_contracts_i].ledger_data.fee,
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
                                                    title: Text('Create Position Error:'),
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
                                    quantity_text_controller.clear();
                                    rate_text_controller.clear();
                                    state.loading_text = 'Create position is success. \nPosition-ID: ${position_id}\nloading token balance and position data ...';
                                    main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);
                                    
                                    Future success_dialog = showDialog(
                                        context: state.context,
                                        builder: (BuildContext context) {
                                            return AlertDialog(
                                                title: Text('Create Position Success!'),
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
                                            state.user!.load_cm_data([state.cm_main.icrc1token_trade_contracts[widget.cm_main_icrc1token_trade_contracts_i]]),
                                            state.user!.fresh_icrc1_balances([state.cm_main.trade_contracts[widget.cm_main_icrc1token_trade_contracts_i].ledger_data, CYCLES_BANK_LEDGER]),
                                            /*too slow*///state.user!.fresh_icrc1_transactions([state.cm_main.trade_contracts[widget.cm_main_icrc1token_trade_contracts_i].ledger_data, CYCLES_BANK_LEDGER]),
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
                
        return CardWithBorder(
            child: Container(
                margin: EdgeInsets.symmetric(vertical: 13),
                child: Column(
                    children: [
                        Text('LOGS'),
                        SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Container(
                                margin: EdgeInsets.symmetric(horizontal: 17),
                                constraints: BoxConstraints(maxHeight: 505, maxWidth: 909),
                                child: PaginatedDataTable2(
                                    wrapInCard: false,
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
                                        DataColumn2(
                                            label: Text('ID'),
                                            size: ColumnSize.S,
                                        ),
                                        DataColumn2(
                                            label: Text('POSITION'),
                                            size: ColumnSize.M,
                                            tooltip: 'ORIGINAL-POSIT'
                                        ),
                                        DataColumn2(
                                            label: Text('RATE'),
                                            size: ColumnSize.S,
                                            tooltip: 'CYCLES PER ${state.cm_main.icrc1token_trade_contracts[widget.cm_main_icrc1token_trade_contracts_i].ledger_data.symbol}'
                                        ),
                                        DataColumn2(
                                            label: Text('TRADES'),
                                            size: ColumnSize.L,
                                            tooltip: ''
                                        ),
                                        DataColumn2(
                                            label: Text('CURRENT-POSITION'),
                                            size: ColumnSize.M,
                                            tooltip: 'The current amount of the position/order if this position is open.'
                                        ),
                                    ],
                                    source: UserCMLogsDataTableSource(
                                        cm_main_icrc1token_trade_contracts_i: widget.cm_main_icrc1token_trade_contracts_i,
                                        context: context,
                                    ),
                                ),
                            )
                        )
                    ]
                )
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




Widget create_trades_quantities_widget(PositionLog pl, Icrc1Ledger token_ledger_data) {
    Widget position_purchases_sum_widget = pl.position_kind == PositionKind.Cycles
        ?
        show_tokens_with_symbol(Cycles(cycles: pl.position_purchases_sum_quantity()), cycles_symbol)
        :
        show_tokens_with_symbol(Tokens(quantums: pl.position_purchases_sum_quantity(), decimal_places: token_ledger_data.decimals), token_ledger_data.symbol);

    Widget fill_widget = pl.position_kind == PositionKind.Cycles
        ?
        show_tokens_with_symbol(Tokens(quantums: pl.fill_quantity, decimal_places: token_ledger_data.decimals), token_ledger_data.symbol)
        :
        show_tokens_with_symbol(Cycles(cycles: pl.fill_quantity), cycles_symbol);

    Widget trades_quantities_widget = Row(children: [position_purchases_sum_widget, Text(' <> '), fill_widget]);

    return trades_quantities_widget;
}

Widget create_position_quantity_widget(PositionLog pl, Icrc1Ledger token_ledger_data) {
    return
        pl.position_kind == PositionKind.Cycles
        ?
        show_tokens_with_symbol(Cycles(cycles: pl.quest.quantity), cycles_symbol)
        :
        show_tokens_with_symbol(Tokens(quantums: pl.quest.quantity, decimal_places: token_ledger_data.decimals), token_ledger_data.symbol);
}

Widget create_current_position_widget(PositionLog pl, Icrc1Ledger token_ledger_data, BuildContext context, int cm_main_trade_contracts_i) {

    CustomState state = MainStateBind.get_state<CustomState>(context);
    MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);

    return
    pl.position_termination != null
    ?
    Container(
        child: Text(switch (pl.position_termination!.cause) {
            PositionTerminationCause.Fill => 'COMPLETE',
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
            show_tokens_with_symbol(Tokens(quantums: pl.mainder_position_quantity, decimal_places: token_ledger_data.decimals), token_ledger_data.symbol)
            ,
            //SizedBox(width: 11),
            Spacer(),
            Container(height: 22, width: 55, child: OutlineButton(
                child: Text('CANCEL', style: TextStyle(fontSize: 11, fontFamily: 'CourierNew')),
                on_press_complete: () async {
                    state.loading_text = 'closing position ${pl.id} ...';
                    state.is_loading = true;
                    MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);

                    try {
                        await state.user!.cm_void_position(state.cm_main.trade_contracts[cm_main_trade_contracts_i], pl.id);
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
                            state.user!.load_cm_data([state.cm_main.trade_contracts[cm_main_trade_contracts_i]]),
                            state.user!.fresh_icrc1_balances([state.cm_main.trade_contracts[cm_main_trade_contracts_i].ledger_data, CYCLES_BANK_LEDGER]),
                            /*too slow*///state.user!.fresh_icrc1_transactions([state.cm_main.trade_contracts[cm_main_trade_contracts_i].ledger_data, CYCLES_BANK_LEDGER]),
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
            ))
        ]
    );
}

DataRow datarow_of_the_user_position_log(BuildContext context, int cm_main_trade_contracts_i, PositionLogAndVoidPositionPayoutStatus plavpps) {
    PositionLog pl = plavpps.pl;
    
    CustomState state = MainStateBind.get_state<CustomState>(context);
            
    Icrc1Ledger ledger_data = state.cm_main.trade_contracts[cm_main_trade_contracts_i].ledger_data;

    Widget trades_quantities_widget = create_trades_quantities_widget(pl, ledger_data);
    
    Widget position_quantity_widget = create_position_quantity_widget(pl, ledger_data);
    
    Widget current_position_widget = create_current_position_widget(pl, ledger_data, context, cm_main_trade_contracts_i);

    return DataRow2(
        onTap: () async {
            await showDialog(
                context: context, // state.context?. 
                builder: (BuildContext context) {
                    return PositionDialog(
                        cm_main_trade_contracts_i: cm_main_trade_contracts_i, 
                        pl_id: pl.id,
                    );
                }                
            );
        },
        cells: <DataCell>[
            DataCell(Text(pl.id.toString())),
            //DataCell(Text('${position_log_timestamp_format(datetime_of_the_nanos(pl.creation_timestamp_nanos))}')),
            DataCell(position_quantity_widget),
            DataCell(Text('${pl.quest.cycles_per_token_rate.toString()/*.replaceFirst('T', '')*/}')),
            DataCell(
                trades_quantities_widget
            ),
            DataCell(
                current_position_widget
            ),
        ]
    );
            
    
}

class HeaderWithACloseButton extends StatelessWidget {
    Widget child;
    HeaderWithACloseButton({required this.child});
    Widget build(BuildContext context) {
        return ScaffoldBodyHeader(Row(
            mainAxisSize: MainAxisSize.max, 
            children: [
                Flexible(flex:1, fit: FlexFit.tight, child: Container(
                    width: double.infinity, 
                    child: Align(
                        alignment: Alignment.topLeft, 
                        child: Container(
                            child: IconButton(icon: Icon(Icons.close), iconSize: 11, onPressed: ()=>Navigator.of(context).pop()),
                        ) 
                    )
                )),
                Flexible(flex: 11, fit: FlexFit.tight, child: Center(
                    child: child,
                )),
                Flexible(flex: 1,  fit: FlexFit.tight, child: Container(width: double.infinity, child: Text(''))),
            ]
        ));
    }
}                  
 
 
 class KeyValueDataTable extends StatelessWidget {
     List<(Widget key, Widget value)> items;
     KeyValueDataTable({required this.items});
     Widget build(BuildContext context) {
         return DataTable(
            headingRowHeight: 0,
            dataTextStyle: DefaultTextStyle.of(context).style.copyWith(fontFamily: 'CourierNew', fontSize: 14),
            columns: [
                DataColumn(label: Text('')),
                DataColumn(label: Text('')),
            ],
            rows: [
                for (var (Widget k, Widget v) in this.items)
                    DataRow(cells: [
                        DataCell(k),
                        DataCell(v),
                    ]),
            ]
        );
    }
}
 

class PositionDialog extends StatefulWidget {
    final int cm_main_trade_contracts_i;
    final BigInt pl_id;
    PositionDialog({
        required this.cm_main_trade_contracts_i,
        required this.pl_id,
    }) : super(key: ValueKey('PositionDialog pl-id: ${pl_id} cm_main_trade_contracts_i: ${cm_main_trade_contracts_i}'));
    State createState() => PositionDialogState();
}
class PositionDialogState extends State<PositionDialog> {
    
    Future<void>? load_cm_user_position_trade_logs_future;    
    
    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
        
        if (load_cm_user_position_trade_logs_future == null && state.user!.cm_trade_contracts[state.cm_main.trade_contracts[widget.cm_main_trade_contracts_i]]!.user_positions_trade_logs[widget.pl_id] == null) {
            load_cm_user_position_trade_logs_future = state.user!.load_cm_user_position_trade_logs(state.cm_main.trade_contracts[widget.cm_main_trade_contracts_i], widget.pl_id);
        }
        
        Icrc1Ledger ledger_data = state.cm_main.trade_contracts[widget.cm_main_trade_contracts_i].ledger_data;
        String token_symbol = ledger_data.symbol;
        int token_decimal_places = ledger_data.decimals;
        
        // find plavpps in this build method because after a position-cancellation, the position needs to re-fresh on the set-state with the new-values.
        PositionLogAndVoidPositionPayoutStatus plavpps = find_plavpps_of_id(widget.pl_id, state, widget.cm_main_trade_contracts_i);
        PositionLog pl = plavpps.pl;

        return Dialog(
            child: Container(
                constraints: BoxConstraints(maxWidth: 555),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        HeaderWithACloseButton(
                            child: Column(
                                children: [
                                    Text('POSITION-LOG', style: TextStyle(fontSize: 17))
                                ]
                            )
                        ),
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
                                                KeyValueDataTable(
                                                    items: [
                                                        (
                                                            Text('ID:'),
                                                            Text('${pl.id}')
                                                        ),
                                                        (
                                                            Text('TIMESTAMP:'),
                                                            Text('${position_log_timestamp_format(datetime_of_the_nanos(pl.creation_timestamp_nanos))}', style: TextStyle(fontSize: timestamp_format_font_size)),
                                                        ),
                                                        (
                                                            Text('POSITION:'),
                                                            create_position_quantity_widget(pl, ledger_data),
                                                        ),
                                                        (
                                                            Text('RATE:', /*style: TextStyle(fontFamily: 'CourierNewBold')*/),
                                                            Text(pl.quest.cycles_per_token_rate.toString()),
                                                        ),
                                                        (
                                                            Text('FILL-PERCENTAGE:', /*style: TextStyle(fontFamily: 'CourierNewBold')*/),
                                                            Builder(
                                                                builder: (BuildContext context) {
                                                                    double percentage_fill = pl.position_purchases_sum_quantity().toDouble() / (pl.quest.quantity / BigInt.from(100));
                                                                    return Text('${percentage_fill.toStringAsFixed(0)}%');
                                                                }
                                                            )
                                                        ),
                                                        (
                                                            Text('TRADES:', /*style: TextStyle(fontFamily: 'CourierNewBold')*/),
                                                            create_trades_quantities_widget(pl, ledger_data),
                                                        ),
                                                        (
                                                            Text('FILL-AVERAGE-RATE:', /*style: TextStyle(fontFamily: 'CourierNewBold')*/),
                                                            Text('${pl.fill_average_rate}'),
                                                        ),
                                                        (
                                                            Text('CTS-FEES:',/* style: TextStyle(fontFamily: 'CourierNewBold')*/),
                                                            pl.position_kind == PositionKind.Cycles 
                                                            ? 
                                                            show_tokens_with_symbol(Tokens(quantums: pl.payouts_fees_sum, decimal_places: token_decimal_places), token_symbol)
                                                            : 
                                                            show_tokens_with_symbol(Cycles(cycles: pl.payouts_fees_sum), cycles_symbol)     
                                                        ),
                                                        (
                                                            Text('${pl.position_kind == PositionKind.Cycles ? token_symbol : 'CYCLES'}-PAYOUT-LEDGER-FEES:'),
                                                            FutureBuilder(
                                                                future: load_cm_user_position_trade_logs_future,
                                                                builder: (BuildContext context, AsyncSnapshot snapshot) {
                                                                    CustomState state = MainStateBind.get_state<CustomState>(context);
                                                                    MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
                                                                    BigInt trades_payouts_ledger_fees_sum =
                                                                        (state.user!.cm_trade_contracts[state.cm_main.trade_contracts[widget.cm_main_trade_contracts_i]]!
                                                                            .user_positions_trade_logs[pl.id].nullmap((m)=>m.values) ?? [])
                                                                            .fold(BigInt.from(0), (BigInt value, TradeLogAndPayoutStatus l)=> value + (pl.position_kind == PositionKind.Cycles ? l.tl.tokens_payout_ledger_transfer_fee : l.tl.cycles_payout_ledger_transfer_fee));
                                                                    return switch (snapshot.connectionState) {
                                                                        ConnectionState.none || ConnectionState.done => 
                                                                            pl.position_kind == PositionKind.Cycles 
                                                                            ? show_tokens_with_symbol(
                                                                                Tokens(quantums: trades_payouts_ledger_fees_sum, decimal_places: token_decimal_places), 
                                                                                token_symbol
                                                                            )
                                                                            : show_tokens_with_symbol(
                                                                                Cycles(cycles: trades_payouts_ledger_fees_sum), 
                                                                                cycles_symbol
                                                                            ),
                                                                        _ => Center(child: Text('loading ...'))
                                                                    };
                                                                }
                                                            )
                                                        ),
                                                        (
                                                            Text('PAYOUTS-SUM:'),
                                                            FutureBuilder(
                                                                future: load_cm_user_position_trade_logs_future,                                                                
                                                                builder: (BuildContext context, AsyncSnapshot snapshot) {
                                                                    CustomState state = MainStateBind.get_state<CustomState>(context);
                                                                    MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
                                                                    
                                                                    Widget loading_widget = Center(child: Text('loading ...'));
                                                                    
                                                                    switch (snapshot.connectionState) {
                                                                        case ConnectionState.none || ConnectionState.done: 
                                                                            Iterable<TradeLogAndPayoutStatus> tlaps_list = 
                                                                                (state.user!.cm_trade_contracts[state.cm_main.trade_contracts[widget.cm_main_trade_contracts_i]]!
                                                                                .user_positions_trade_logs[pl.id].nullmap((m)=>m.values) ?? []);
                                                                            bool is_pending =
                                                                                tlaps_list.map(
                                                                                    pl.position_kind == PositionKind.Cycles 
                                                                                    ? (tlaps)=>tlaps.tokens_payout_complete
                                                                                    : (tlaps)=>tlaps.cycles_payout_complete
                                                                                ).contains(false);
                                                                            if (is_pending) {
                                                                                return loading_widget;
                                                                            }
                                                                            if (pl.position_kind == PositionKind.Cycles) {
                                                                                BigInt final_tokens_payout = tlaps_list.fold(
                                                                                    BigInt.zero,
                                                                                    (v, l) {
                                                                                        return v + l.tl.tokens - l.tl.tokens_payout_fee - l.tl.tokens_payout_ledger_transfer_fee;
                                                                                    }
                                                                                );
                                                                                return show_tokens_with_symbol(Tokens(quantums: final_tokens_payout, decimal_places: token_decimal_places), token_symbol, round_main_show: false);
                                                                            } else {
                                                                                Cycles final_cycles_payout = tlaps_list.fold(
                                                                                    Cycles(cycles: BigInt.zero),
                                                                                    (v, l) {
                                                                                        return v + l.tl.cycles - l.tl.cycles_payout_fee - Cycles(cycles: l.tl.cycles_payout_ledger_transfer_fee);
                                                                                    }
                                                                                );
                                                                                return show_tokens_with_symbol(final_cycles_payout, cycles_symbol, round_main_show: false);
                                                                            }
                                                                        default:
                                                                            return loading_widget;
                                                                    }
                                                                }
                                                            )      
                                                        ),
                                                        (
                                                            Text('CURRENT-POSITION:'),
                                                            create_current_position_widget(pl, ledger_data, context, widget.cm_main_trade_contracts_i),
                                                        ),
                                                        if (pl.position_termination != null) ...[
                                                            (
                                                                Text('POSITION-LEFTOVER:'),
                                                                pl.position_kind == PositionKind.Cycles
                                                                ? show_tokens_with_symbol(
                                                                    Cycles(cycles: pl.mainder_position_quantity),
                                                                    cycles_symbol,
                                                                )
                                                                : show_tokens_with_symbol(
                                                                    Tokens(quantums: pl.mainder_position_quantity, decimal_places: token_decimal_places),
                                                                    token_symbol,
                                                                ),
                                                            ),
                                                            if (pl.void_position_payout_dust_collection && pl.mainder_position_quantity != BigInt.zero) (
                                                                Text('LEFTOVER-DUST-COLLECTION:'),
                                                                Text('true'),
                                                            ),
                                                            if (pl.void_position_payout_dust_collection == false) ...[
                                                                (
                                                                    Text('LEFTOVER-TRANSFER-STATUS:'),
                                                                    Text(plavpps.void_position_payout_complete ? 'COMPLETE' : 'PENDING')
                                                                ),
                                                                if (plavpps.void_position_payout_complete) ...[
                                                                    (
                                                                        Text('LEFTOVER-TRANSFER-LEDGER-FEE:'),
                                                                        pl.position_kind == PositionKind.Token 
                                                                        ? show_tokens_with_symbol(
                                                                            Tokens(quantums: pl.void_position_payout_ledger_transfer_fee, decimal_places: token_decimal_places),
                                                                            token_symbol
                                                                        )
                                                                        : show_tokens_with_symbol(
                                                                            Cycles(cycles: pl.void_position_payout_ledger_transfer_fee),
                                                                            cycles_symbol
                                                                        )
                                                                    ),
                                                                    (
                                                                        Text('LEFTOVER-TRANSFER:'),
                                                                        pl.position_kind == PositionKind.Token 
                                                                        ? show_tokens_with_symbol(
                                                                            Tokens(quantums: pl.mainder_position_quantity - pl.void_position_payout_ledger_transfer_fee, decimal_places: token_decimal_places),
                                                                            token_symbol,
                                                                            round_main_show: false,
                                                                        )
                                                                        : show_tokens_with_symbol(
                                                                            Cycles(cycles: pl.mainder_position_quantity - pl.void_position_payout_ledger_transfer_fee),
                                                                            cycles_symbol,
                                                                            round_main_show: false,
                                                                        )
                                                                    )
                                                                ]
                                                            ]
                                                        ]
                                                    ]
                                                ),
                                                SizedBox(height: 17),
                                                OutlineButton(
                                                    child: Container(
                                                        padding: EdgeInsets.symmetric(horizontal: 9),
                                                        child: Text('VIEW TRADES', style: TextStyle(fontFamily: 'CourierNew', fontSize: 14)),
                                                    ),
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

    

class TradeLogDialog extends StatelessWidget {
    PositionLog pl;
    TradeLogAndPayoutStatus tlaps;
    int cm_main_trade_contracts_i;
    Widget trade_widget;
    Widget payout_status_widget;
    Widget timestamp_widget;
                                                                
    TradeLogDialog({
        required this.pl,
        required this.cm_main_trade_contracts_i, 
        required this.tlaps,
        required this.trade_widget,
        required this.payout_status_widget,
        required this.timestamp_widget,
    }) : super(key: ValueKey('TradeLogDialog tl-id: ${tlaps.tl.id} pl-id: ${pl.id} cm_main_trade_contracts_i: ${cm_main_trade_contracts_i}'));
    
    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
                
        Icrc1Ledger ledger_data = state.cm_main.trade_contracts[cm_main_trade_contracts_i].ledger_data;
        String token_symbol = ledger_data.symbol;
        int token_decimal_places = ledger_data.decimals;
        
        TradeLog tl = tlaps.tl;
        
        return Dialog(
            child: Container(
                constraints: BoxConstraints(maxWidth: 505),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        HeaderWithACloseButton(
                            child: Column(
                                children: [
                                    Text('TRADE-LOG', style: TextStyle(fontSize: 17))
                                ]
                            )
                        ),
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
                                                KeyValueDataTable(
                                                    items: [
                                                        (
                                                            Text('POSITION-ID:'),
                                                            Text('${pl.id}')
                                                        ),
                                                        (
                                                            Text('TRADE-ID:'),
                                                            Text('${tl.id}'),    
                                                        ),
                                                        (
                                                            Text('TIMESTAMP:'),
                                                            Text('${position_log_timestamp_format(datetime_of_the_nanos(tl.timestamp_nanos))}', style: TextStyle(fontSize: timestamp_format_font_size)),
                                                        ),
                                                        (
                                                            Text('TRADE'),
                                                            trade_widget
                                                        ),
                                                        (
                                                            Text('TRADE-RATE:'),
                                                            Text('${tl.cycles_per_token_rate}'),
                                                        ),
                                                        (
                                                            Text('CTS-PAYOUT-FEE:'),
                                                            pl.position_kind == PositionKind.Cycles 
                                                            ? 
                                                            show_tokens_with_symbol(Tokens(quantums: tl.tokens_payout_fee, decimal_places: token_decimal_places), token_symbol)
                                                            : 
                                                            show_tokens_with_symbol(tl.cycles_payout_fee, cycles_symbol)     
                                                        ),
                                                        (
                                                            Text('${pl.position_kind == PositionKind.Cycles ? token_symbol : 'CYCLES'}-PAYOUT-LEDGER-FEE:'),
                                                            pl.position_kind == PositionKind.Cycles
                                                            ?
                                                            show_tokens_with_symbol(Tokens(quantums: tl.tokens_payout_ledger_transfer_fee, decimal_places: token_decimal_places), token_symbol)
                                                            :
                                                            show_tokens_with_symbol(Cycles(cycles: tl.cycles_payout_ledger_transfer_fee), cycles_symbol)
                                                        ),
                                                        if (
                                                            (pl.position_kind == PositionKind.Cycles && tlaps.tokens_payout_complete && tl.token_payout_dust_collection) 
                                                            || 
                                                            (pl.position_kind == PositionKind.Token && tlaps.cycles_payout_complete && tl.cycles_payout_dust_collection)
                                                        ) (                                                        
                                                            Text('DUST-COLLECTION:'),
                                                            Text('true')
                                                        ),
                                                        (
                                                            Text('PAYOUT:'),
                                                            pl.position_kind == PositionKind.Cycles 
                                                            ? 
                                                            show_tokens_with_symbol(
                                                                Tokens(quantums: tl.tokens - tl.tokens_payout_fee - tl.tokens_payout_ledger_transfer_fee, decimal_places: token_decimal_places), 
                                                                token_symbol
                                                            )
                                                            : 
                                                            show_tokens_with_symbol(
                                                                tl.cycles - tl.cycles_payout_fee - Cycles(cycles: tl.cycles_payout_ledger_transfer_fee),
                                                                cycles_symbol
                                                            )
                                                        )
                                                    ]
                                                ),
                                                //SizedBox(height: 17),
                                                
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

Tooltip show_tokens_with_symbol(Tokens tokens, String token_symbol, {bool show_token_symbol_in_main = true, bool round_main_show = true}) {
    Tokens tokens_round = tokens.round_decimal_places(3);
    Tokens possible_round_up = tokens.add_quantums(BigInt.from(pow(10, tokens.decimal_places-3))).round_decimal_places(0); 
    if (possible_round_up.quantums > tokens_round.quantums) {
        tokens_round = possible_round_up;
    }
    Tokens tokens_for_the_main_show = round_main_show ? (tokens_round.quantums == BigInt.from(0) ? tokens : tokens_round) : tokens;
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

// will throw if non existant id.
PositionLogAndVoidPositionPayoutStatus find_plavpps_of_id(BigInt plid, CustomState state, int cm_main_trade_contracts_i) {
    PositionLogAndVoidPositionPayoutStatus? plavpps = state.user!.cm_trade_contracts[state.cm_main.trade_contracts[cm_main_trade_contracts_i]]!.current_user_positions[plid].nullmap((pl)=>PositionLogAndVoidPositionPayoutStatus(pl, false));
    if (plavpps == null) {
        plavpps = state.user!.cm_trade_contracts[state.cm_main.trade_contracts[cm_main_trade_contracts_i]]!
        .user_void_positions_pending[plid];
    }
    if (plavpps == null) {
        plavpps = PositionLogAndVoidPositionPayoutStatus(
            state.user!.cm_trade_contracts[state.cm_main.icrc1token_trade_contracts[cm_main_trade_contracts_i]]!
            .user_positions_storage[plid]!,
            true,
        );
    }
    return plavpps;
}


class UserCMLogsDataTableSource extends DataTableSource {
    int cm_main_icrc1token_trade_contracts_i;
    BuildContext context;
    late CustomState state;
    UserCMLogsDataTableSource({required this.cm_main_icrc1token_trade_contracts_i, required this.context}) {
        state = MainStateBind.get_state<CustomState>(context);
    }
    
    int get rowCount => state.user!.cm_trade_contracts[state.cm_main.icrc1token_trade_contracts[cm_main_icrc1token_trade_contracts_i]]!
        .user_positions_storage.length;
    
    bool get isRowCountApproximate => false;    
    
    DataRow? getRow(int i) {
        Iterable<BigInt> user_positions_storage_keys = 
            state.user!.cm_trade_contracts[state.cm_main.icrc1token_trade_contracts[cm_main_icrc1token_trade_contracts_i]]!
            .user_positions_storage.keys;
        BigInt plid = user_positions_storage_keys.elementAt(user_positions_storage_keys.length - 1 - i);
        PositionLogAndVoidPositionPayoutStatus plavpps = find_plavpps_of_id(plid, state, cm_main_icrc1token_trade_contracts_i);
        return datarow_of_the_user_position_log(context, cm_main_icrc1token_trade_contracts_i, plavpps);
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
                    HeaderWithACloseButton(
                        child: Column(
                            children: [
                                Text('POSITION-${widget.pl.id} TRADES', style: TextStyle(fontSize: 17))
                            ]
                        )
                    ),
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
                                            Iterable<TradeLogAndPayoutStatus> tlaps_list = state.user!.cm_trade_contracts[state.cm_main.trade_contracts[widget.cm_main_trade_contracts_i]]!.user_positions_trade_logs[widget.pl.id].nullmap((m)=>m.values) ?? [];
                                            double headingRowHeight = DataTableTheme.of(context).headingRowHeight ?? 56.0;
                                            
                                            List<DataRow2> data_rows = [];
                                            for (TradeLogAndPayoutStatus l in tlaps_list) {
                                                
                                                Widget trade_widget = Builder(builder: (BuildContext context) {
                                                    List<Widget> trade_mounts = [
                                                        show_tokens_with_symbol(l.tl.cycles, cycles_symbol),
                                                        show_tokens_with_symbol(Tokens(quantums: l.tl.tokens, decimal_places: token_decimal_places), token_symbol)                                                
                                                    ];
                                                    if (widget.pl.position_kind == PositionKind.Token) {
                                                        trade_mounts = trade_mounts.reversed.toList(); 
                                                    } 
                                                    return Row(children: [trade_mounts[0], Text(' <> '), trade_mounts[1]]);
                                                });
                                                Widget payout_status_widget = Text((widget.pl.position_kind == PositionKind.Cycles ? l.tokens_payout_complete : l.cycles_payout_complete) ? 'COMPLETE' : 'PENDING');
                                                Widget timestamp_widget = Text('${position_log_timestamp_format(datetime_of_the_nanos(l.tl.timestamp_nanos))}', style: TextStyle(fontSize: timestamp_format_font_size));
                                                
                                                data_rows.add(DataRow2(
                                                    onTap: () async {
                                                        await showDialog(
                                                            context: context,
                                                            builder: (BuildContext context) {
                                                                return TradeLogDialog(
                                                                    pl: widget.pl,
                                                                    tlaps: l, 
                                                                    cm_main_trade_contracts_i: widget.cm_main_trade_contracts_i,
                                                                    trade_widget: trade_widget,
                                                                    payout_status_widget: payout_status_widget,
                                                                    timestamp_widget: timestamp_widget,
                                                                ); 
                                                            }
                                                        );
                                                    },
                                                    cells: [
                                                        DataCell(Text('${l.tl.id}')),
                                                        DataCell(timestamp_widget),
                                                        DataCell(trade_widget),
                                                        DataCell(Text('${l.tl.cycles_per_token_rate.toString()}')),
                                                        DataCell(payout_status_widget),
                                                    ]
                                                ));
                                            } 
                                            
                                            return SingleChildScrollView(scrollDirection: Axis.horizontal, child: Container(
                                                constraints: BoxConstraints(maxHeight: min(headingRowHeight + tlaps_list.length * dataRowHeight, constraints.maxHeight)),
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
                                                    rows: data_rows,
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




List<Future> generate_possible_cm_page_first_load_futures(int cm_main_trade_contracts_i, CustomState state) {
    List<Future> wait_futures = [];
    if (state.cm_main.trade_contracts[cm_main_trade_contracts_i].first_load_data == null) { // state.cm_main.trade_contracts[i] will not be null, because the setNewRoutePath waits till the loadfirststate which loads the view_tcs. so it can only be a cycles_market current url when the loadfirststate is done.
        state.cm_main.trade_contracts[cm_main_trade_contracts_i].first_load_data = state.cm_main.trade_contracts[cm_main_trade_contracts_i].load_data();                
        wait_futures.add(state.cm_main.trade_contracts[cm_main_trade_contracts_i].first_load_data!);
        //print('cm ${state.cm_main.trade_contracts[cm_main_trade_contracts_i].ledger_data.symbol} first load_data');
    }
    if (state.user != null) {
        if (state.user!.first_load_tcs.containsKey(state.cm_main.trade_contracts[cm_main_trade_contracts_i]) == false) {
            state.user!.first_load_tcs[state.cm_main.trade_contracts[cm_main_trade_contracts_i]] = state.user!.load_cm_data([state.cm_main.trade_contracts[cm_main_trade_contracts_i]]);
            wait_futures.add(state.user!.first_load_tcs[state.cm_main.trade_contracts[cm_main_trade_contracts_i]]!);
            //print('cm ${state.cm_main.trade_contracts[cm_main_trade_contracts_i].ledger_data.symbol} user first load_cm_data');
        }
        if (state.user!.first_load_icrc1ledgers_balances.containsKey(state.cm_main.trade_contracts[cm_main_trade_contracts_i].ledger_data) == false) {
            state.user!.first_load_icrc1ledgers_balances[state.cm_main.trade_contracts[cm_main_trade_contracts_i].ledger_data] = state.user!.fresh_icrc1_balances([state.cm_main.trade_contracts[cm_main_trade_contracts_i].ledger_data]); 
            wait_futures.add(state.user!.first_load_icrc1ledgers_balances[state.cm_main.trade_contracts[cm_main_trade_contracts_i].ledger_data]!);
            //print('cm ${state.cm_main.trade_contracts[cm_main_trade_contracts_i].ledger_data.symbol} user load balance');
        }
        if (state.user!.first_load_icrc1ledgers_balances.containsKey(CYCLES_BANK_LEDGER) == false) {
            state.user!.first_load_icrc1ledgers_balances[CYCLES_BANK_LEDGER] = state.user!.fresh_icrc1_balances([CYCLES_BANK_LEDGER]); 
            wait_futures.add(state.user!.first_load_icrc1ledgers_balances[CYCLES_BANK_LEDGER]!);
            //print('cm ${'CYCLES'} user load balance');
        }
    }
    return wait_futures;
}

void change_url_into_cm_market(int cm_main_trade_contracts_i, BuildContext context) {
    CustomState state = MainStateBind.get_state<CustomState>(context);
    MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
    
    List<Future> wait_futures = generate_possible_cm_page_first_load_futures(cm_main_trade_contracts_i, state);
    
    Function d = () {
        state.cm_main_icrc1token_trade_contracts_i = cm_main_trade_contracts_i;
        state.current_url = CustomUrl(
            'cycles_market', 
            variables: {
                'token_ledger_id': state.cm_main.icrc1token_trade_contracts[cm_main_trade_contracts_i].ledger_data.ledger.principal.text
            }
        );
        main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);
    };
    
    if (wait_futures.isNotEmpty) {
        state.loading_text = 'loading ${state.cm_main.trade_contracts[cm_main_trade_contracts_i].ledger_data.symbol} market ...';
        state.is_loading = true;
        state.show_loading_page_transition_completer = Completer();
        wait_futures.add(state.show_loading_page_transition_completer.future);
        main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);
        Future.wait(wait_futures).then((_x){
            state.is_loading = false;
            d();
        });
    } else {
        d();
    }
}
