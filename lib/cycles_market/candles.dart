import 'dart:ui' as dart_ui;
import 'package:flutter/material.dart';
import 'dart:math';

import './cycles_market.dart';
import '../config/state.dart';
import './scaffold_body.dart';
import '../config/state_bind.dart';

// volume of the candles is the quantity of the number of tokens traded during that time. (not the number of cycles.)





const double width_between_bar_centers = 17;
const double bar_width = width_between_bar_centers - 5;

const double card_max_width = 900;

const double save_space_on_the_right_for_the_rate_marks = card_max_width / 9;



/*
enum CandleSegmentLength {
    one_minute,
    five_minutes,
    ten_minutes,
    fifteen_minutes,
    thirty_minutes,
    one_hour,
    six_hours,
    one_day,
    seven_days,
    one_month,
}
*/

class CandlesChart extends StatefulWidget {
    final int cm_main_trade_contracts_i;
    CandlesChart({required this.cm_main_trade_contracts_i}) : super(key: ValueKey('CandlesChart ${cm_main_trade_contracts_i}'));
    State createState() => CandlesChartState();
}
class CandlesChartState extends State<CandlesChart> {

    final int candles_per_page = (card_max_width - save_space_on_the_right_for_the_rate_marks) ~/ width_between_bar_centers;

    int segment_length_minutes = 1; // option user can change this dropdown setState
    int page = 0; // first page is zero. first page is latest candles.

    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        //MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);

        int candles_length = state.cm_main.trade_contracts[widget.cm_main_trade_contracts_i].candles.length;

        // overlapping chunks between pages
        int candles_start_i = max(candles_length - candles_per_page - (page * (candles_per_page ~/ 4 * 3)), 0); // each page moves 3/4ths of the candles_per_page
        int candles_finish_i = min(candles_start_i + candles_per_page, candles_length);

        List<Candle> page_candles = state.cm_main.trade_contracts[widget.cm_main_trade_contracts_i]
            .candles
            .getRange(candles_start_i, candles_finish_i).toList(); // toList for now. later maybe optimize painters to work with iterable.



        return Card(
            semanticContainer: false,
            child: Container(
                constraints: BoxConstraints(
                    maxWidth: card_max_width,
                ),
                margin: EdgeInsets.symmetric(vertical: 7),
                child: Column(
                    children: [
                        // candlestick chart
                        SizedBox(
                            height: 350,
                            child: CustomPaint(
                                size: Size.infinite,
                                painter: CandleChartPainter(
                                    candles: page_candles,
                                )
                            ),
                        ),
                        SizedBox(height: 7),
                        // volume chart
                        SizedBox(
                            height: 50,
                            child: CustomPaint(
                                size: Size.infinite,
                                painter: VolumeChartPainter(
                                    candles: page_candles,
                                )
                            )
                        ),
                    ]
                )
            )
        );
    }
}



class CandleChartPainter extends CustomPainter {

    List<Candle> candles;
    final Paint red_paint = Paint()..color = red.withOpacity(0.9);
    final Paint green_paint = Paint()..color = green.withOpacity(0.9);
    final double wick_width = 3;

    CandleChartPainter({
        required this.candles,
    });

    @override
    void paint(Canvas canvas, Size size) {

        if (candles.isEmpty) {
            return; // do something else like maybe still draw the rate markers $0-$5 or say something like make a trade.
        }

        // set up

        int global_high_rate = candles
            .map((c)=>c.high_rate.cycles_per_token_quantum_rate.toInt())
            .reduce((a,b)=>max(a,b));

        int global_low_rate = candles
            .map((c)=>c.low_rate.cycles_per_token_quantum_rate.toInt())
            .reduce((a,b)=>min(a,b));

        //if (global_low_rate == global_high_rate) {
        const int make_rate_room_after_global_lows_and_highs = 4;
        global_low_rate -= global_low_rate ~/ make_rate_room_after_global_lows_and_highs;
        global_high_rate += global_high_rate ~/ make_rate_room_after_global_lows_and_highs; // global_high_rate ~/ ... ?
        //}

        double height_per_rate_quantum = size.height / (global_high_rate - global_low_rate);


        // draw rate markers
        // draw vertical line
        const double rate_marker_vertical_line_width = 2;
        const double rate_marker_horizontal_line_width_on_each_side_after_the_vertical_line = 4;
        canvas.drawRect(
            Rect.fromLTRB(
                size.width - save_space_on_the_right_for_the_rate_marks + rate_marker_horizontal_line_width_on_each_side_after_the_vertical_line,
                0,
                size.width - save_space_on_the_right_for_the_rate_marks + rate_marker_horizontal_line_width_on_each_side_after_the_vertical_line + rate_marker_vertical_line_width,
                size.height,
            ),
            Paint()..color = Colors.grey,
        );
        // draw horizontal rate markers
        const double pixel_width_between_rate_markers = 30;
        final int number_of_rate_markers = size.height ~/ pixel_width_between_rate_markers;
        final int rate_width_between_rate_markers = (global_high_rate - global_low_rate) ~/ number_of_rate_markers;
        for (int i=0; i<number_of_rate_markers; i++) {
            final int marker_rate = global_low_rate + i*rate_width_between_rate_markers;
            print('marker_rate: ${marker_rate}');

            double marker_base_y = size.height - (marker_rate - global_low_rate) * height_per_rate_quantum;
            double marker_start_x = size.width - save_space_on_the_right_for_the_rate_marks;
            double marker_finish_x = marker_start_x + rate_marker_horizontal_line_width_on_each_side_after_the_vertical_line + rate_marker_vertical_line_width + rate_marker_horizontal_line_width_on_each_side_after_the_vertical_line;

            canvas.drawRect(
                Rect.fromLTRB(
                    marker_start_x,
                    marker_base_y + 1, // base it on the marker_rate, not on the pixel-width-between-markers. because the candles are based on the candle-rates.
                    marker_finish_x,
                    marker_base_y - 1
                ),
                Paint()..color = Colors.grey,
            );

            dart_ui.ParagraphBuilder paragraph_builder = dart_ui.ParagraphBuilder(dart_ui.ParagraphStyle())
                ..pushStyle(dart_ui.TextStyle(
                    color: Colors.grey,
                    fontSize: 11
                ))
                ..addText('${CyclesPerTokenRate(cycles_per_token_quantum_rate: BigInt.from(marker_rate), token_decimal_places: candles[0].volume_tokens.decimal_places)}');
            dart_ui.Paragraph paragraph = paragraph_builder.build();
            paragraph.layout(dart_ui.ParagraphConstraints(width: 55));

            canvas.drawParagraph(
                paragraph,
                Offset(
                    marker_finish_x + 5, // plus a few for some space
                    marker_base_y - 6// minus a few to make the marker in the center-left of the text not on the top-left
                )
            );
        }








        // draw wicks and wax.
        List<CandleChartCandle> chart_candles = generate_chart_candles(
            size: size,
            global_low_rate: global_low_rate,
            height_per_rate_quantum: height_per_rate_quantum,
        );

        for (CandleChartCandle chart_candle in chart_candles) {
            // draw wick
            canvas.drawRect(
                Rect.fromLTRB(
                    chart_candle.center_x - (wick_width / 2),
                    size.height - chart_candle.wick_high_y,
                    chart_candle.center_x + (wick_width / 2),
                    size.height - chart_candle.wick_low_y,
                ),
                chart_candle.paint,
            );
            // draw wax
            canvas.drawRect(
                Rect.fromLTRB(
                    chart_candle.center_x - (bar_width / 2),
                    size.height - chart_candle.wax_high_y,
                    chart_candle.center_x + (bar_width / 2),
                    size.height - chart_candle.wax_low_y,
                ),
                chart_candle.paint,
            );
        }

    }



    List<CandleChartCandle> generate_chart_candles({required Size size, required int global_low_rate, required double height_per_rate_quantum}) {

        List<CandleChartCandle> chart_candles = [];
        for (int i=0; i<candles.length; i++) {
            Candle candle = candles[i];

            double wick_high_y = (candle.high_rate.cycles_per_token_quantum_rate.toInt() - global_low_rate) * height_per_rate_quantum;
            double wick_low_y = (candle.low_rate.cycles_per_token_quantum_rate.toInt() - global_low_rate) * height_per_rate_quantum;

            double open_y = (candle.open_rate.cycles_per_token_quantum_rate.toInt() - global_low_rate) * height_per_rate_quantum;
            double close_y = (candle.close_rate.cycles_per_token_quantum_rate.toInt() - global_low_rate) * height_per_rate_quantum;

            double wax_high_y = open_y >= close_y ? open_y : close_y;
            double wax_low_y = open_y >= close_y ? close_y : open_y;

            // make sure candles are at least a few pixels wide.
            // add to all candles for consistency, even ones that don't need it.
            wick_high_y += 1;
            wick_low_y -= 1;
            wax_high_y += 1;
            wax_low_y -= 1;

            chart_candles.add(
                CandleChartCandle(
                    center_x: (i + 1) * width_between_bar_centers,
                    wick_high_y: wick_high_y,
                    wick_low_y: wick_low_y,
                    wax_high_y: wax_high_y,
                    wax_low_y: wax_low_y,
                    paint: candle.open_rate > candle.close_rate ? red_paint : green_paint,
                )
            );
        }

        return chart_candles;
    }

    bool shouldRepaint(CustomPainter old) {
        return true; // optimize this
    }
}

class CandleChartCandle {
    final double wick_high_y;
    final double wick_low_y;
    final double wax_high_y;
    final double wax_low_y;
    final double center_x;
    final Paint paint;

    CandleChartCandle({
        required this.wick_high_y,
        required this.wick_low_y,
        required this.wax_high_y,
        required this.wax_low_y,
        required this.center_x,
        required this.paint,
    });

}






class VolumeChartPainter extends CustomPainter {

    List<Candle> candles;
    final Paint red_paint = Paint()..color = red.withOpacity(0.5);
    final Paint green_paint = Paint()..color = green.withOpacity(0.5);

    VolumeChartPainter({
        required this.candles,
    });

    @override
    void paint(Canvas canvas, Size size) {

        List<VolumeChartBar> bars = generate_bars(size);

        for (VolumeChartBar bar in bars) {
            canvas.drawRect(
                Rect.fromLTWH(
                    bar.center_x - (bar.width / 2),
                    size.height - bar.height,
                    bar.width,
                    bar.height,
                ),
                bar.paint,
            );
        }
    }

    List<VolumeChartBar> generate_bars(Size size) {

        double height_per_volume_quantum = size.height / candles.fold(1, (v,c)=>max(v, c.volume_tokens.quantums.toInt())); // initial-value = 1 so that we don't divide by zero'

        List<VolumeChartBar> bars = [];
        for (int i=0; i < candles.length; i++) {
            Candle candle = candles[i];
            bars.add(
                VolumeChartBar(
                    width: bar_width,
                    height: height_per_volume_quantum * candle.volume_tokens.quantums.toInt(),
                    center_x: (i + 1) * width_between_bar_centers,
                    paint: candle.open_rate > candle.close_rate ? red_paint : green_paint,
                )
            );
        }
        return bars;
    }


    @override
    bool shouldRepaint(CustomPainter old) {
        return true; // optimize this.
    }
}


class VolumeChartBar {
    final double width;
    final double height;
    final double center_x;
    final Paint paint;
    VolumeChartBar({
        required this.width,
        required this.height,
        required this.center_x,
        required this.paint,
    });

}





