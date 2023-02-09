import 'dart:math';

import 'package:flutter/material.dart';
import 'package:interactive_chart/interactive_chart.dart';
import 'package:candlesticks/candlesticks.dart';
import './mock_data.dart';
import './cycles_market_data.dart';
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


List<Candle> cycles_market_data_candlesticks(CyclesMarketData cmd, CandleTimeDurationType candle_time_duration) {
    
    List<Candle> candlesticks = []; 

    Iterable<CyclesMarketDataPositionPurchase> trades = 
        [...cmd.cycles_positions_purchases, ...cmd.icp_positions_purchases]
        ..sort((a,b){return b.timestamp_nanos.compareTo(a.timestamp_nanos);}); 
    
    if (trades.length == 0) { return <Candle>[]; }
    
    DateTime time_mark = candle_time_duration.closest_interval(trades.first.datetime());
    double first_trade_xdr_icp_rate_double = double.parse(trades.first.position_xdr_permyriad_per_icp_rate.toString()); 
    
    late double open;
    double high = 0.0;
    double low = first_trade_xdr_icp_rate_double;
    double close = first_trade_xdr_icp_rate_double;
    double volume = 0.0;
    
    for (CyclesMarketDataPositionPurchase trade in trades) {
        double trade_xdr_icp_rate_double = double.parse(trade.position_xdr_permyriad_per_icp_rate.toString());
        double trade_cycles_quantity_double = double.parse(trade.cycles_quantity.toString().replaceFirst('T', ''));
        DateTime trade_datetime = trade.datetime();
        if (trade_datetime.isAfter(time_mark) || trade_datetime.isAtSameMomentAs(time_mark)) {
            volume += trade_cycles_quantity_double;
            open = trade_xdr_icp_rate_double;
            high = max(high, trade_xdr_icp_rate_double);
            low = min(low, trade_xdr_icp_rate_double);
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
            volume = trade_cycles_quantity_double;
            open = trade_xdr_icp_rate_double;
            high = trade_xdr_icp_rate_double;
            low = trade_xdr_icp_rate_double;            
            close = trade_xdr_icp_rate_double;
        }
    }
    return candlesticks; 
}

class Chart extends StatefulWidget {
    Chart({super.key});
    State<Chart> createState() => ChartState();
}
class ChartState extends State<Chart> {
    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
        
        return Container(
            //decoration: BoxDecoration(border: Border.all()),
            child: Candlesticks(
                candles: cycles_market_data_candlesticks(state.cycles_market_data, DurationDays(7)) //MockDataTesla.candles, 
                /*
                <CandleData>[
                     CandleData(
                        timestamp: DateTime.now().millisecondsSinceEpoch, 
                        open: 17.0, 
                        close: 19.0, 
                        volume: 200, 
                        high: 25.0, 
                        low: 17, 
                        //List<double?>? trends
                    ), 
                    CandleData(
                        timestamp: DateTime.now().subtract(Duration(days: 1)).millisecondsSinceEpoch, 
                        open: 17.0, 
                        close: 19.0, 
                        volume: 200, 
                        high: 25.0, 
                        low: 17, 
                        //List<double?>? trends
                    ), 
                    CandleData(
                        timestamp: DateTime.now().subtract(Duration(days: 2)).millisecondsSinceEpoch, 
                        open: 17.0, 
                        close: 19.0, 
                        volume: 200, 
                        high: 25.0, 
                        low: 17, 
                        //List<double?>? trends
                    ), 
                ],
                */
                //initialVisibleCandleCount: 90,
                /*
                ChartStyle? style, 
                TimeLabelGetter? timeLabel, 
                PriceLabelGetter? priceLabel, 
                OverlayInfoGetter? overlayInfo, 
                ValueChanged<CandleData>? onTap, 
                ValueChanged<double>? onCandleResize
                */
            )
        );
    }
}
