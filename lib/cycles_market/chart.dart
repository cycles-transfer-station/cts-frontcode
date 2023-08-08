import 'dart:math';

import 'package:flutter/material.dart';
import 'package:candlesticks/candlesticks.dart';
//import './mock_data.dart';
import './cycles_market.dart';
import '../config/state.dart';
import '../config/state_bind.dart';



abstract class CandleTimeDurationType {
    Duration get duration;
    DateTime closest_interval(DateTime t);
}
class DurationMinutes extends CandleTimeDurationType {
    final int minutes;
    DurationMinutes(this.minutes);    
    Duration get duration => Duration(minutes: minutes);
    DateTime closest_interval(DateTime t) {
        DateTime closest_minute = DateTime(t.year,t.month,t.day,t.hour,t.minute,0,0,0);
        int closest_minute_modulo_interval = closest_minute.minute % this.minutes;
        if (closest_minute_modulo_interval != 0) {
            return closest_minute.subtract(Duration(minutes: closest_minute_modulo_interval));
        } else {
            return closest_minute;
        }
    }
}
class DurationHours extends CandleTimeDurationType {
    final int hours;
    DurationHours(this.hours);
    Duration get duration => Duration(hours: hours);
    DateTime closest_interval(DateTime t) {
        DateTime closest_hour = DateTime(t.year,t.month,t.day,t.hour,0,0,0,0);
        int closest_hour_modulo_interval = closest_hour.hour % this.hours;
        if (closest_hour_modulo_interval != 0) {
            return closest_hour.subtract(Duration(hours: closest_hour_modulo_interval));
        } else {
            return closest_hour;
        }
    }
}
class DurationDays extends CandleTimeDurationType {
    final int days;
    DurationDays(this.days);
    Duration get duration => Duration(days: days);
    DateTime closest_interval(DateTime t) {
        DateTime closest_day = DateTime(t.year,t.month,t.day,0,0,0,0,0);
        int closest_day_modulo_interval = closest_day.day % this.days;
        if (closest_day_modulo_interval != 0) {
            return closest_day.subtract(Duration(days: closest_day_modulo_interval));
        } else {
            return closest_day;
        }
    }
}


List<Candle> cycles_market_icrc1token_trade_contract_candlesticks(Icrc1TokenTradeContract tc, CandleTimeDurationType candle_time_duration) {
    
    List<Candle> candlesticks = []; 

    Iterable<TradeLog> trades = tc.trade_logs.reversed; 
    
    if (trades.length == 0) { return <Candle>[]; }
    
    DateTime time_mark = candle_time_duration.closest_interval(trades.first.datetime());
    double first_trade_rate_double = double.parse(trades.first.cycles_per_token_rate.toString().replaceFirst('T','')); 
    
    late double open;
    double high = 0.0;
    double low = first_trade_rate_double;
    double close = first_trade_rate_double;
    double volume = 0.0;
    
    for (TradeLog trade in trades) {
        double trade_rate_double = double.parse(trade.cycles_per_token_rate.toString().replaceFirst('T',''));         
        double trade_cycles_double = double.parse(trade.cycles.toString().replaceFirst('T', ''));
        DateTime trade_datetime = trade.datetime();
        if (trade_datetime.isAfter(time_mark) || trade_datetime.isAtSameMomentAs(time_mark)) {
            volume += trade_cycles_double;
            open = trade_rate_double;
            high = max(high, trade_rate_double);
            low = min(low, trade_rate_double);
        }                
        else if (trade_datetime.isBefore(time_mark)) {
            candlesticks.add(Candle(
                date: time_mark,
                open: open,
                high: high,
                low: low,
                close: close,
                volume: volume
            ));
            // for the next candlestick
            time_mark = candle_time_duration.closest_interval(trade_datetime); 
            volume = trade_cycles_double;
            open = trade_rate_double;
            high = trade_rate_double;
            low = trade_rate_double;            
            close = trade_rate_double;
        }
    }
    // for the last candlestick
    candlesticks.add(Candle(
        date: time_mark,
        open: open,
        high: high,
        low: low,
        close: close,
        volume: volume
    ));
    return candlesticks; 
}

class Chart extends StatefulWidget {
    int cm_main_icrc1token_trade_contracts_i;
    Chart({required this.cm_main_icrc1token_trade_contracts_i, super.key});
    State<Chart> createState() => ChartState();
}
class ChartState extends State<Chart> {
    
    CandleTimeDurationType candle_time_duration = DurationHours(1);

    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
        
        
        
        return Container(
            //decoration: BoxDecoration(border: Border.all()),
            child: Candlesticks(
                key: ValueKey(candle_time_duration),
                candles: [
                    Candle(
                        date: DateTime.now(),
                        open: 1.0,
                        high: 7.0,
                        low: 0.5,
                        close: 5.0,
                        volume: 20
                    ),
                    Candle(
                        date: DateTime.now(),
                        open: 2.0,
                        high: 8.0,
                        low: 1.0,
                        close: 5.0,
                        volume: 25
                    )
                ],//cycles_market_icrc1token_trade_contract_candlesticks(state.cm_main.icrc1token_trade_contracts[widget.cm_main_icrc1token_trade_contracts_i], candle_time_duration), //MockDataTesla.candles, 
                actions: <ToolBarAction>[
                    ToolBarAction(
                        child: Text('5m'),
                        onPressed: () {
                            setState((){
                                candle_time_duration = DurationMinutes(5);
                            });
                        }
                    ),
                    ToolBarAction(
                        child: Text('15m'),
                        onPressed: () {
                            setState((){
                                candle_time_duration = DurationMinutes(15);
                            });
                        }
                    ),
                    ToolBarAction(
                        child: Text('30m'),
                        onPressed: () {
                            setState((){
                                candle_time_duration = DurationMinutes(30);
                            });
                        }
                    ),
                    ToolBarAction(
                        child: Text('1H'),
                        onPressed: () {
                            setState((){
                                candle_time_duration = DurationHours(1);
                            });
                        }
                    ),
                    ToolBarAction(
                        child: Text('1D'),
                        onPressed: () {
                            setState((){
                                candle_time_duration = DurationDays(1);
                            });
                        }
                    ),
                    ToolBarAction(
                        child: Text('1W'),
                        onPressed: () {
                            setState((){
                                candle_time_duration = DurationDays(7);
                            });
                        }
                    ),

                ]
            )
        );
    }
}
