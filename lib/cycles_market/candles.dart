import 'dart:ui' as dart_ui;
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import 'package:ic_tools/common.dart';
import 'package:ic_tools/tools.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

import './cycles_market.dart';
import '../config/state.dart';
import './scaffold_body.dart';
import '../config/state_bind.dart';

// volume of the candles is the quantity of the number of tokens traded during that time. (not the number of cycles.)

// can implement zooming and click and drag to move instead of pages if i want.




const double width_between_bar_centers = 17;
const double bar_width = width_between_bar_centers - 5;

const double save_space_on_the_right_for_the_rate_marks = 85;

const double height_between_timestamp_markers = 3;

const double candle_chart_painter_height = 350;
const double volume_chart_painter_height = 50;
const double space_between_candle_chart_and_volume_chart = 7;

const double rate_marker_vertical_line_width = 2;
const double rate_marker_horizontal_line_width_on_each_side_after_the_vertical_line = 10;//4;



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

// returns time_nanos
BigInt lign_candle_time_nanos(BigInt time_nanos, BigInt nanos_per_segment) {
    return time_nanos - (time_nanos % nanos_per_segment);
}



class CandlesChart extends StatefulWidget {
    final int cm_main_trade_contracts_i;
    CandlesChart({required this.cm_main_trade_contracts_i}) : super(key: ValueKey('CandlesChart ${cm_main_trade_contracts_i}'));
    State createState() => CandlesChartState();
}
class CandlesChartState extends State<CandlesChart> {

    final double card_max_width = 900;
    
    int segment_length_minutes = 1; // option user can change this dropdown setState
    int page = 0; // first page is zero. first page is latest candles.

    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        //MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
        
        // TESTTEMP! DELETE THIS!
        //state.cm_main.trade_contracts[widget.cm_main_trade_contracts_i].candles = make_test_candles();

        final int candles_per_page = ((min(MediaQuery.of(context).size.width, card_max_width) - save_space_on_the_right_for_the_rate_marks) ~/ width_between_bar_centers) - 1;

        // make segment lengths  
        // be careful about references and copying. use Candle.clone().
        List<Candle> candles = [];
        if (segment_length_minutes == 1) {
            candles = state.cm_main.trade_contracts[widget.cm_main_trade_contracts_i].candles; 
        } else {
            if (state.cm_main.trade_contracts[widget.cm_main_trade_contracts_i].candles.isNotEmpty) {
                
                BigInt nanos_per_segment = BigInt.from(NANOS_IN_A_SECOND * 60 * segment_length_minutes);
                
                Candle current_candle = Candle.clone(state.cm_main.trade_contracts[widget.cm_main_trade_contracts_i].candles.first); 
                current_candle.time_nanos = lign_candle_time_nanos(current_candle.time_nanos, nanos_per_segment); 
                
                for (Candle candle in state.cm_main.trade_contracts[widget.cm_main_trade_contracts_i].candles.skip(1)) {
                    BigInt time_nanos = lign_candle_time_nanos(candle.time_nanos, nanos_per_segment); 
                    if (time_nanos == current_candle.time_nanos) {
                        current_candle.volume_tokens = current_candle.volume_tokens.add_quantums(candle.volume_tokens.quantums);
                        current_candle.volume_cycles += candle.volume_cycles;
                        current_candle.high_rate = CyclesPerTokenRate.max(current_candle.high_rate, candle.high_rate);
                        current_candle.low_rate = CyclesPerTokenRate.min(current_candle.low_rate, candle.low_rate);
                        current_candle.close_rate = candle.close_rate;
                    } else { // should be greater than the current_candle.time_nanos
                        candles.add(current_candle); // flush
                        current_candle = Candle.clone(candle)..time_nanos = time_nanos;
                    }
                }
                candles.add(current_candle);
            }           
        }
        
        int candles_length = candles.length;

        // overlapping chunks between pages
        int candles_start_i = max(candles_length - candles_per_page - (page * (candles_per_page ~/ 4 * 3)), 0); // each page moves 3/4ths of the candles_per_page
        int candles_finish_i = min(candles_start_i + candles_per_page, candles_length);

        List<Candle> page_candles = 
            candles
            .getRange(candles_start_i, candles_finish_i).toList(); // toList for now. later maybe optimize painters to work with iterable.

        final double timestamp_markers_painter_height = create_text_painter_for_timestamp_markers(page_candles[0]).size.height;
        /*switch (page_candles.length) {
            >= 2 => create_text_painter_for_timestamp_markers(page_candles[0]).size.height + height_between_timestamp_markers + create_text_painter_for_timestamp_markers(page_candles[1]).size.height,
            1 => create_text_painter_for_timestamp_markers(page_candles[0]).size.height,
            _ => 0,
        };*/


        const double candle_segment_length_selector_font_size = 11;
        const String candle_segment_length_selector_font_family = 'CourierNew';
        const double segment_length_selector_left_padding = 3;
        const double segment_length_selector_height = 22;

        return Card(
            semanticContainer: false,
            child: Container(
                constraints: BoxConstraints(
                    maxWidth: card_max_width,
                ),
                child: Column(
                    children: [
                        SizedBox(height: 7),
                        // controls
                        Row(
                            children: [
                                SizedBox(width: 7),
                                Container(
                                    height: segment_length_selector_height,
                                    child: IconButton(
                                        iconSize: 14,
                                        icon: const Icon(Icons.arrow_back_ios_new),
                                        padding: EdgeInsets.zero,
                                        onPressed: candles_start_i == 0 ? null : (){
                                            page += 1;
                                            setState((){});
                                        },
                                    ),
                                ),
                                SizedBox(width: 7),
                                DropdownButtonHideUnderline(
                                    child: DropdownButton2<int>(
                                        value: segment_length_minutes,
                                        onChanged: (int? select) {
                                            if (select is int) {
                                                if (select != segment_length_minutes) {
                                                    segment_length_minutes = select;
                                                    page = 0; // portant!
                                                    setState((){});
                                                }
                                            }
                                        },
                                        items: [
                                            for (var (String label, int value) in [
                                                ('1 minute', 1),
                                                ('5 minutes', 5),
                                                ('15 minutes', 15),
                                                ('30 minutes', 30),
                                                ('1 hour', 60),
                                                ('6 hours', 60 * 6),
                                                ('24 hours', 60 * 24),
                                            ])
                                                DropdownMenuItem<int>(
                                                    child: Container(
                                                        padding: EdgeInsets.only(left: segment_length_selector_left_padding),
                                                        child: Text(label)
                                                    ),
                                                    value: value,
                                                ),
                                        ],
                                        style: TextStyle(color: Colors.white70, fontFamily: candle_segment_length_selector_font_family, fontSize: candle_segment_length_selector_font_size),
                                        buttonStyleData: ButtonStyleData(
                                            padding: EdgeInsets.zero,
                                            height: segment_length_selector_height,
                                            width: 97,
                                            decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(
                                                    color: Colors.white10,
                                                ),
                                            ),
                                        ),
                                        iconStyleData: IconStyleData(
                                            iconSize: 13,
                                        ),
                                        menuItemStyleData: const MenuItemStyleData(
                                            height: segment_length_selector_height,
                                            padding: EdgeInsets.zero,
                                        ),
                                        dropdownStyleData: const DropdownStyleData(
                                            padding: EdgeInsets.zero,
                                            scrollPadding: EdgeInsets.zero,
                                            elevation: 0,
                                        )
                                    ),
                                ),                                
                                SizedBox(width: 7),
                                SizedBox(width: 7),
                                Expanded(
                                    child: TopRowCandleData(),
                                ),
                                //Spacer(),
                                SizedBox(width: 7),
                                Container(
                                    height: segment_length_selector_height,
                                    child: Transform.flip(
                                        flipX: true,
                                        //FilterQuality? filterQuality,
                                        child: IconButton(
                                            iconSize: 14,
                                            icon: const Icon(Icons.arrow_back_ios_new),
                                            padding: EdgeInsets.zero,
                                            onPressed: candles_finish_i == candles_length ? null : (){
                                                page -= 1;
                                                setState((){});
                                            },
                                        )
                                    ),
                                ),
                                SizedBox(width: 7),
                                //SizedBox(width: save_space_on_the_right_for_the_rate_marks),
                            ]
                        ),
                        SizedBox(height: 7),
                        Stack(
                            children: [
                                Column(
                                    children: [
                                        // candlestick chart
                                        SizedBox(
                                            height: candle_chart_painter_height,
                                            child: CustomPaint(
                                                size: Size.infinite,
                                                painter: CandleChartPainter(
                                                    candles: page_candles,
                                                    is_latest_page: page == 0,
                                                    latest_candle: state.cm_main.trade_contracts[widget.cm_main_trade_contracts_i].candles.isNotEmpty
                                                        ? state.cm_main.trade_contracts[widget.cm_main_trade_contracts_i].candles.last
                                                        : null,
                                                )
                                            ),
                                        ),
                                        SizedBox(height: space_between_candle_chart_and_volume_chart),
                                        // volume chart
                                        SizedBox(
                                            height: volume_chart_painter_height,
                                            child: CustomPaint(
                                                size: Size.infinite,
                                                painter: VolumeChartPainter(
                                                    candles: page_candles,
                                                )
                                            )
                                        ),
                                        SizedBox(height: 7),
                                        // candles-timestamps chart
                                        SizedBox(
                                            height: timestamp_markers_painter_height,
                                            child: CustomPaint(
                                                size: Size.infinite,
                                                painter: TimestampsMarkersPainter(
                                                    candles: page_candles,
                                                )
                                            )
                                        ),
                                    ]
                                ),
                                Positioned.fill( // size with the largest sibling in the stack
                                    child: ChartMouseRegion(
                                        candles: page_candles,
                                        hovercolor: Theme.of(context).hoverColor,
                                    )
                                ),
                            ]
                        ),
                        SizedBox(height: 7),
                    ]
                )
            )
        );
    }
}



class CandleChartPainter extends CustomPainter {

    final List<Candle> candles;
    final bool is_latest_page;
    final Candle? latest_candle; // null if there are no trades yet

    final Paint red_paint = Paint()..color = red;
    final Paint green_paint = Paint()..color = green;
    final double wick_width = 3;

    CandleChartPainter({
        required this.candles,
        required this.is_latest_page,
        required this.latest_candle,
    });

    @override
    void paint(Canvas canvas, Size size) {

        if (candles.isEmpty) {
            return; // do something else like maybe still draw the rate markers $0-$5 or say something like make a trade.
        }

        // draw horizontal rate markers
        final double horizontal_rate_marker_start_x = size.width - save_space_on_the_right_for_the_rate_marks;
        final double horizontal_rate_marker_finish_x = horizontal_rate_marker_start_x + rate_marker_horizontal_line_width_on_each_side_after_the_vertical_line + rate_marker_vertical_line_width + rate_marker_horizontal_line_width_on_each_side_after_the_vertical_line;
        
        final RateMarkersRangeSpecifics(
            :global_low_rate, 
            :global_high_rate, 
            :height_per_rate_quantum, 
            :marker_rates_low_high) 
        = find_rate_markers_range_specifics(candles);

        for (int marker_rate in marker_rates_low_high) {

            double marker_base_y = calculate_marker_base_y(marker_rate: marker_rate, global_low_rate: global_low_rate, height_per_rate_quantum: height_per_rate_quantum);
            
            canvas.drawRect(
                Rect.fromLTRB(
                    horizontal_rate_marker_start_x,
                    marker_base_y + 1, // base it on the marker_rate, not on the pixel-width-between-markers. because the candles are based on the candle-rates.
                    horizontal_rate_marker_finish_x,
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
                    horizontal_rate_marker_finish_x + 5, // plus a few for some space
                    marker_base_y - 6// minus a few to make the marker in the center-left of the text not on the top-left
                )
            );
        }

        // draw vertical line for the rate markers
        canvas.drawRect(
            Rect.fromLTRB(
                size.width - save_space_on_the_right_for_the_rate_marks + rate_marker_horizontal_line_width_on_each_side_after_the_vertical_line,
                size.height - (marker_rates_low_high.last - global_low_rate) * height_per_rate_quantum,
                size.width - save_space_on_the_right_for_the_rate_marks + rate_marker_horizontal_line_width_on_each_side_after_the_vertical_line + rate_marker_vertical_line_width,
                size.height,
            ),
            Paint()..color = Colors.grey,
        );

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

        // draw latest trade rate
        if (latest_candle != null && is_latest_page) { // is_latest_trade bc earlier pages might not be in the same rate-marker-range as the latest trade.
            draw_rate_selection(
                canvas: canvas,
                size: size,
                rate: latest_candle!.close_rate,
                global_low_rate: global_low_rate,
                height_per_rate_quantum: height_per_rate_quantum,
                text_color: Colors.black,
                background_paint: latest_candle!.open_rate > latest_candle!.close_rate ? red_paint : green_paint,
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

    final List<Candle> candles;
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



class TimestampsMarkersPainter extends CustomPainter {
    final List<Candle> candles;
    TimestampsMarkersPainter({required this.candles});
        
    Paint horizontal_border_paint = Paint()..color = Colors.white30;
        
    void paint(Canvas canvas, Size size) {

        late double i_minus_1_text_painter_height;

        const double horizontal_border_width = 0.3;

        for (int i=0; i<candles.length; i+=5) {
            Candle candle = candles[i];

            TextPainter text_painter = create_text_painter_for_timestamp_markers(candle);

            final double text_center_x = (i + 1) * width_between_bar_centers;

            final double paint_text_left = text_center_x - (text_painter.size.width / 2); 
            final double paint_text_top = 0;//i % 2 == 0 ? 0 : i_minus_1_text_painter_height + height_between_timestamp_markers;
            text_painter.paint(
                canvas,
                Offset(
                    paint_text_left,
                    paint_text_top,
                )
            );

            i_minus_1_text_painter_height = text_painter.size.height;

            /*
            canvas.drawRect(
                Rect.fromLTWH(
                    ((i + 1) * width_between_bar_centers) - width_between_bar_centers - (horizontal_border_width / 2),
                    paint_text_top,
                    horizontal_border_width,
                    text_painter.size.height,

                ),
                horizontal_border_paint,
            );
            canvas.drawRect(
                Rect.fromLTWH(
                    ((i + 1) * width_between_bar_centers) + width_between_bar_centers - (horizontal_border_width / 2),
                    paint_text_top,
                    horizontal_border_width,
                    text_painter.size.height,
                ),
                horizontal_border_paint,
            );
            */
            
            text_painter.dispose();
        }
        
    }
    
    bool shouldRepaint(CustomPainter old) {
        return true; // optimize this.
    }
}



class ChartMouseRegion extends StatefulWidget {
    List<Candle> candles;
    final Paint hovercolor_paint;
    ChartMouseRegion({required this.candles, required Color hovercolor}) : hovercolor_paint = Paint()..color = hovercolor;
    State createState() => ChartMouseRegionState();     
}
class ChartMouseRegionState extends State<ChartMouseRegion> {
    
    Offset? mouse_position = null; // null if not in the region;
    
    Widget build(BuildContext context) {
        //print(mouse_position);
        return MouseRegion(
            cursor: SystemMouseCursors.precise,
            onHover: (PointerHoverEvent event) {
                mouse_position = event.localPosition;
                setState((){});
                if (top_row_candle_data_set_state != null) {
                    top_row_candle_data_set_state!();
                }
            },
            onEnter: (event) {
                mouse_position = event.localPosition;
                setState((){});
                if (top_row_candle_data_set_state != null) {
                    top_row_candle_data_set_state!();
                }
            },
            onExit: (event) {
                mouse_position = null;
                candle_selection = null;
                setState((){});
                if (top_row_candle_data_set_state != null) {
                    top_row_candle_data_set_state!();
                }
            },
            child: CustomPaint(
                size: Size.infinite, // check this, maybe use layout builder and set this to maxConstarints
                painter: PointerPainter(
                    candles: widget.candles,
                    hovercolor_paint: widget.hovercolor_paint,
                    mouse_position: mouse_position,
                ) 
            )
        );
    }
}



class PointerPainter extends CustomPainter {
    List<Candle> candles;
    final Paint hovercolor_paint;
    final Offset? mouse_position;

    final Paint horizontal_dot_lines_paint = Paint()..color = Colors.grey;
    final Paint horizontal_line_rate_selection_background = Paint()..color = Colors.grey;
    final Color horizontal_line_rate_selection_text_color = Colors.black;
    
    PointerPainter({required this.candles, required this.hovercolor_paint, required this.mouse_position});
    
    void paint(Canvas canvas, Size size) {
        
        if (mouse_position == null || candles.isEmpty) {
            return;
        }
        
        // draw hovercolor on the candle column
        // find candle
        Candle? hover_candle;
        late final double left;
        late final double right;
        for (int i=0; i<candles.length;i++) {
            Candle candle = candles[i];
            final double center_x = (i + 1) * width_between_bar_centers;
            final double left_ = center_x - (width_between_bar_centers / 2); // or i can use bar_width
            final double right_ = center_x + (width_between_bar_centers / 2);
            
            if (mouse_position!.dx >= left_ && mouse_position!.dx < right_) {
                hover_candle = candle;
                left = left_;
                right = right_;
                break;
            }
        }
        if (hover_candle != null) { // if on a candle-vertical
            // draw hovercolor on the vertical column of the candle
            canvas.drawRect(
                Rect.fromLTRB(
                    left,
                    0,
                    right,
                    candle_chart_painter_height + space_between_candle_chart_and_volume_chart + volume_chart_painter_height,
                ),
                hovercolor_paint
            );
            candle_selection = hover_candle;
        } else {
            candle_selection = null;
        }


        // draw horizontal dotted lines of the current mouse position and horizontal line rate
        final RateMarkersRangeSpecifics(
            :global_low_rate, 
            :global_high_rate, 
            :height_per_rate_quantum, 
            :marker_rates_low_high,
            :change_last_digits_to_zero,
        ) = find_rate_markers_range_specifics(candles);
    
        // if in within the rate_markers_range
        if (mouse_position!.dy >= calculate_marker_base_y(marker_rate: marker_rates_low_high.last, global_low_rate: global_low_rate, height_per_rate_quantum: height_per_rate_quantum) - 1
        && mouse_position!.dy <= calculate_marker_base_y(marker_rate: marker_rates_low_high.first, global_low_rate: global_low_rate, height_per_rate_quantum: height_per_rate_quantum) + 1
        && mouse_position!.dx <= size.width - save_space_on_the_right_for_the_rate_marks + rate_marker_horizontal_line_width_on_each_side_after_the_vertical_line
        ) {
            const double line_width = 9;
            const double space_between_lines = 3;
            const double line_height = 0.5;
            final int number_of_horizontal_lines = ((size.width - save_space_on_the_right_for_the_rate_marks + rate_marker_horizontal_line_width_on_each_side_after_the_vertical_line) - mouse_position!.dx) ~/ (line_width + space_between_lines);
            for (int i=0; i<number_of_horizontal_lines; i++) {
                final double line_left_position = mouse_position!.dx + (i * (line_width + space_between_lines)) + space_between_lines; 
                canvas.drawRect(
                    Rect.fromLTRB(
                        line_left_position,
                        mouse_position!.dy + (line_height / 2),
                        line_left_position + line_width,
                        mouse_position!.dy - (line_height / 2),
                    ),
                    horizontal_dot_lines_paint,
                );
            }
            
            
            BigInt cptqr = BigInt.from(((candle_chart_painter_height - mouse_position!.dy) / height_per_rate_quantum) + global_low_rate);                     
            if (change_last_digits_to_zero >= 2) {
                String cptqr_str = cptqr.toString();
                cptqr = BigInt.parse(
                    cptqr_str.replaceRange(
                        max(0, cptqr_str.length - (change_last_digits_to_zero - 1)), // (change_last_digits_to_zero - 1) do one level deeper than the rate markers
                        null,
                        ''.padRight(change_last_digits_to_zero - 1, '0')
                    )
                );
            }
            draw_rate_selection(
                canvas: canvas,
                size: size,
                rate: CyclesPerTokenRate(
                    cycles_per_token_quantum_rate: cptqr,
                    token_decimal_places: candles[0].volume_tokens.decimal_places
                ),
                global_low_rate: global_low_rate,
                height_per_rate_quantum: height_per_rate_quantum,
                text_color: horizontal_line_rate_selection_text_color,
                background_paint: horizontal_line_rate_selection_background,
            );            
            
        }
    }
    
    bool shouldRepaint(CustomPainter old) {
        return true;
    }
}


Candle? candle_selection;
void Function()? top_row_candle_data_set_state;

class TopRowCandleData extends StatefulWidget {
    TopRowCandleData({super.key});
    State createState() => TopRowCandleDataState();
}
class TopRowCandleDataState extends State<TopRowCandleData> {
    
    @override
    void initState() {
        super.initState();
        top_row_candle_data_set_state = () { setState((){}); };
    }
    @override
    void dispose() {
        top_row_candle_data_set_state = null;
        super.dispose();
    }
    
    Widget build(BuildContext context) {
        
        if (candle_selection == null) {
            return Container();
        }
        
        DateTime dt = DateTime.fromMillisecondsSinceEpoch(milliseconds_of_the_nanos(candle_selection!.time_nanos).toInt());
        String minute_str = dt.minute.toString();
        if (minute_str.length == 1) {
            minute_str = '0' + minute_str;
        }
        
        const double data_item_width = 97;
        
        return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DefaultTextStyle.merge(
                style: TextStyle(fontFamily: 'ChakraPetch', fontSize: 13, color: Colors.white70), 
                child: Row(
                    children: [
                        for (String s in [
                            '${dt.hour}:${minute_str} ${dt.month}/${dt.day}/${dt.year}',
                            'open: ${candle_selection!.open_rate}',
                            'low: ${candle_selection!.low_rate}',
                            'high: ${candle_selection!.high_rate}',
                            'close: ${candle_selection!.close_rate}',
                            'volume: ${candle_selection!.volume_tokens}',
                        ]) 
                            Container(
                                //width: data_item_width,
                                padding: EdgeInsets.symmetric(horizontal: 11),
                                child: Text(s),
                            ),
                    ]
                )
            )
        );
    }
}







// tools

class RateMarkersRangeSpecifics {
    final int global_low_rate;
    final int global_high_rate;
    final double height_per_rate_quantum;
    final List<int> marker_rates_low_high;
    final int change_last_digits_to_zero;
    RateMarkersRangeSpecifics({
        required this.global_low_rate, 
        required this.global_high_rate, 
        required this.height_per_rate_quantum, 
        required this.marker_rates_low_high,
        required this.change_last_digits_to_zero,
    });
}

RateMarkersRangeSpecifics find_rate_markers_range_specifics(List<Candle> candles) {     // candles is the page_candles
    
    int global_high_rate = candles
        .map((c)=>c.high_rate.cycles_per_token_quantum_rate.toInt())
        .reduce((a,b)=>max(a,b));

    int global_low_rate = candles
        .map((c)=>c.low_rate.cycles_per_token_quantum_rate.toInt())
        .reduce((a,b)=>min(a,b));

    const int make_rate_room_after_global_lows_and_highs = 4;
    if (global_high_rate - global_low_rate < make_rate_room_after_global_lows_and_highs) {
        global_low_rate -= global_low_rate ~/ make_rate_room_after_global_lows_and_highs;
        global_high_rate += global_high_rate ~/ make_rate_room_after_global_lows_and_highs; // global_high_rate ~/ ... ?
    } else {
        global_low_rate = max(0, global_low_rate - ((global_high_rate - global_low_rate) ~/ make_rate_room_after_global_lows_and_highs));
        global_high_rate += (global_high_rate - global_low_rate) ~/ make_rate_room_after_global_lows_and_highs;
    }

    const double starting_pixel_width_between_rate_markers = 30;
    final int number_of_rate_markers = candle_chart_painter_height ~/ starting_pixel_width_between_rate_markers;
    int rate_width_between_rate_markers = (global_high_rate - global_low_rate) ~/ number_of_rate_markers;
    double height_per_rate_quantum = candle_chart_painter_height / (global_high_rate - global_low_rate);

    if (rate_width_between_rate_markers == 0) {
        rate_width_between_rate_markers = 1;
    }

    List<int> marker_rates_low_high = [];
    for (int i=0; i<number_of_rate_markers; i++) {
        final int marker_rate = global_low_rate + i*rate_width_between_rate_markers;
        marker_rates_low_high.add(marker_rate);
    }

    // possible change last digits to zero
    int change_last_digits_to_zero = 0;
    final int marker_rates_last_str_length = marker_rates_low_high.last.toString().length; 
    if (marker_rates_last_str_length >= 2) {
                
        for (int i=0; i<marker_rates_last_str_length-1; i++) { // lowest rate
            
            Set<int> set_of_marker_rates_with_last_digit_zeros = 
                marker_rates_low_high
                .map((r){
                    String r_str = r.toString();
                    if (r_str.length >= marker_rates_last_str_length - i) {
                        return int.parse(
                            r_str.replaceRange(
                                max(0, r_str.length - 1 - i),
                                null,
                                ''.padRight(1 + i, '0')
                            )
                        );
                    } else {
                        return r;
                    }
                }) 
                .toSet();

            if (set_of_marker_rates_with_last_digit_zeros.length == marker_rates_low_high.length) {
                // still unique, change last digit to zero
                marker_rates_low_high = set_of_marker_rates_with_last_digit_zeros.toList();
                change_last_digits_to_zero += 1;
                // continue
            } else {
                break;
            }
        }
        
        if (change_last_digits_to_zero > 0) {
            
            // update global_low_rate, global_high_rate, rate_width_between_rate_markers, and height_per_rate_quantum
            global_low_rate = marker_rates_low_high.first;
            global_high_rate = marker_rates_low_high.last;
            rate_width_between_rate_markers = marker_rates_low_high[1] - marker_rates_low_high[0];
            height_per_rate_quantum = candle_chart_painter_height / (global_high_rate - global_low_rate);

            // now make same space between rates.
            for (int i=0; i<marker_rates_low_high.length; i++) {
                marker_rates_low_high[i] = global_low_rate + i*rate_width_between_rate_markers;
            }

            // update number of markers if need
            while (candle_chart_painter_height - (marker_rates_low_high.last - global_low_rate) * height_per_rate_quantum < 0) {
                marker_rates_low_high.removeLast();
            }
            while (candle_chart_painter_height - (marker_rates_low_high.last - global_low_rate) * height_per_rate_quantum >= rate_width_between_rate_markers * height_per_rate_quantum) {
                marker_rates_low_high.add(global_low_rate + marker_rates_low_high.length * rate_width_between_rate_markers);
            }

        }
    }
    
    return RateMarkersRangeSpecifics(
        global_low_rate: global_low_rate,
        global_high_rate: global_high_rate,
        marker_rates_low_high: marker_rates_low_high,
        height_per_rate_quantum: height_per_rate_quantum,
        change_last_digits_to_zero: change_last_digits_to_zero,
    );

}

double calculate_marker_base_y({required int marker_rate, required int global_low_rate, required double height_per_rate_quantum}) {
    return candle_chart_painter_height - (marker_rate - global_low_rate) * height_per_rate_quantum;
}



bool is_same_day(DateTime dt1, DateTime dt2) {
    if (dt1.month == dt2.month && dt1.year == dt2.year && dt1.day == dt2.day) {
        return true;
    } else {
        return false;
    }
}

TextPainter create_text_painter_for_timestamp_markers(Candle candle) {
    // create timestamp string
    DateTime dt = DateTime.fromMillisecondsSinceEpoch(milliseconds_of_the_nanos(candle.time_nanos).toInt());
    String s = '';
    s += '${dt.hour}:';
    if (dt.minute < 10) {
        s += '0';
    }
    s += '${dt.minute}';
    if (is_same_day(dt, DateTime.now()) == false) {
        s += '\n${dt.month}/${dt.day}';
    }
    
    TextPainter text_painter = TextPainter(
        text: TextSpan(
            text: s,
            style: TextStyle(
                color: Colors.white70,
                fontSize: 9,
                fontFamily: 'ChakraPetch',// 'CourierNew',
            ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
    );
    text_painter.layout(
        minWidth: 0,
        maxWidth: double.infinity,
    );
    return text_painter;
    
}


void draw_rate_selection({
    required Canvas canvas,
    required Size size,
    required CyclesPerTokenRate rate,
    required int global_low_rate,
    required double height_per_rate_quantum,
    required Color text_color,
    required Paint background_paint,    
}) {
                
    double latest_trade_marker_base_y = calculate_marker_base_y(marker_rate: rate.cycles_per_token_quantum_rate.toInt(), global_low_rate: global_low_rate, height_per_rate_quantum: height_per_rate_quantum);

    TextPainter text_painter = TextPainter(
        text: TextSpan(
            text: '${rate}',
            style: TextStyle(
                color: text_color,
                fontSize: 13,
                fontFamily: 'CourierNewBold',
            ),
        ),
        textDirection: TextDirection.ltr,
    );
    text_painter.layout(
        minWidth: 0,
        maxWidth: size.width,
    );

    final double text_center_x = size.width - save_space_on_the_right_for_the_rate_marks + rate_marker_horizontal_line_width_on_each_side_after_the_vertical_line + (rate_marker_vertical_line_width / 2);

    const double text_padding_x = 4;
    const double text_padding_y = 2;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTRB(
                text_center_x - (text_painter.size.width / 2) - text_padding_x,
                latest_trade_marker_base_y - (text_painter.size.height / 2) - text_padding_y,
                text_center_x + (text_painter.size.width / 2) + text_padding_x,
                latest_trade_marker_base_y + (text_painter.size.height / 2) + text_padding_y,
            ),
            Radius.circular(20)
        ),
        background_paint,
    );

    text_painter.paint(
        canvas,
        Offset(
            text_center_x - (text_painter.size.width / 2),
            latest_trade_marker_base_y - (text_painter.size.height / 2),
        )
    );

    text_painter.dispose();
}
            



List<Candle> make_test_candles() {
    List<Candle> candles = [];
    CyclesPerTokenRate base_rate = CyclesPerTokenRate.oftheTCyclesDoubleString('10', token_decimal_places: 8);
    for (int i=0;i<1000; i++) {
        BigInt change_quantums_quantity = BigInt.from(i * 10);
        CyclesPerTokenRate rate = CyclesPerTokenRate(cycles_per_token_quantum_rate: base_rate.quantums + change_quantums_quantity, token_decimal_places: 8);
        candles.add(
            Candle(
                volume_tokens: Tokens.of_the_double_string('5', decimal_places: 8),
                volume_cycles: Cycles.oftheTCyclesDoubleString('50'),
                open_rate: rate,
                high_rate: rate,
                low_rate: rate,
                close_rate: rate,
                time_nanos: BigInt.from(i * NANOS_IN_A_SECOND * 60),
            )
        );
    }
    return candles;
}

