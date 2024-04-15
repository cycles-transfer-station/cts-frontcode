import 'package:flutter/material.dart';

import '../tools/widgets.dart';
import '../config/state.dart';


class AboutScaffoldBody extends StatelessWidget {
    AboutScaffoldBody({Key? key}) : super(key: key);
    static AboutScaffoldBody create({Key? key}) => AboutScaffoldBody(key: key);
    
    final ScrollController main_listview_scroll_controller = ScrollController();  

    @override
    Widget build(BuildContext context) {
        //CustomState state = MainStateBind.get_state<CustomState>(context);
        //MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
        
        
        List<Widget> column_children = [];
        
        column_children.addAll([
            Container(
                padding: EdgeInsets.fromLTRB(0, 34.0, 0, 27.0), 
                width: double.infinity,
                child: Text(
"""The goal of the CYCLES-TRANSFER-STATION is for the mainstream-usage of the native CYCLES as the stable-currency of the world-computer. 

The CYCLES-BANK mints, holds, and transfers the cycles, and keeps logs of the transfers. At the CTS, people can hold other ICRC-1 tokens too. 

The cycles-market is the place where people trade the native CYCLES and various tokens back and forth in both ways. 
"""
                    , style: TextStyle(fontSize: 17)
                )
            ),
            /*
            Padding(
                padding: EdgeInsets.fromLTRB(0, 0, 0, 27.0),
                child: Divider(
                    height: 13.0,   
                    thickness: 4.0,
                    indent: 34.0,
                    endIndent: 34.0,
                    //color: 
                ),
            ),
            */
            /*
            Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(11,11,11,27),
                child: Center(
                    child: Text('BUSINESS INTEGRATION', style: TextStyle(fontSize: 19))
                )
            ),
            /*
            Container(
                //padding: EdgeInsets.all(0),
                width: double.infinity,
                child: Text(
//"""For accepting CYCLES for payments in a blockchain service, implement the CYCLES-TRANSFER-SPECIFICATION in the receiving smart-contract: \n\nCANDID:
"""Cycles transfers are sent using the CYCLES-TRANSFER-SPECIFICATION:

"""
                    , style: TextStyle(fontSize: 17)
                )
            ),
            /*
            Container(
                width: double.infinity,
                child: Text('\nCYCLES-TRANSFER-SPECIFICATION CANDID: \n', style: TextStyle(fontSize: 17))
            ),
            */
            Container(
                width: double.infinity,
                child: SelectableText(
"""
type CyclesTransfer = record {
    memo: CyclesTransferMemo;
};

type CyclesTransferMemo = variant {
    Text: text;
    Nat: nat;
    Int: int;
    Blob: blob;
};

service cycles-transfer-specification : {
    cycles_transfer(CyclesTransfer) -> ();
}

"""
                    ,
                    style: TextStyle(fontSize: 17, fontFamily: 'NotoSansMono')
                )
            ),
            */
            Container(
                width: double.infinity,
                child: Text(
"""Identify specific payments using the memo-field of the cycles-transfer. The memo can be a number, natural-number (>=0), text, or binary data. The maximum size of a memo is 32-bytes. 

Use the following cycles-transfer pre-fill payment url for a simple way to collect user-payments in your service:
"""
                    , style: TextStyle(fontSize: 17)
                )
            ),
            Container(
                width: double.infinity,
                child: SelectableText(
"""https://cycles-transfer-station.com/#/bank/pay/cycles/for=<bank>/Tcycles=<Tcycles>/memo_type=<memo_type>/memo=<memo>"""
                    , style: TextStyle(fontSize: 17, fontFamily: 'NotoSansMono')
                )
            ),
            Container(
                width: double.infinity,
                child: Text(
"""Switch out the variables in the url with the variable-values. The <memo_type> variable must be one of 'Text', 'Nat', 'Int', or 'Blob'.

Users can click on the payment-url and it will fill out the cycles-transfer for them for a quick payment method.
"""
                    , style: TextStyle(fontSize: 17)
                )
            ),
            */
        ]);
        
        return Center(
            child: Container(
                constraints: BoxConstraints(maxWidth: 900),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                        ScaffoldBodyHeader(Text('ABOUT THE CTS', style: TextStyle(fontSize: 19))),
                        Expanded(
                            child: DefaultTextStyle.merge(
                                style: TextStyle(fontFamily: 'CourierNew'),
                                child: ListView(
                                    controller: main_listview_scroll_controller,
                                    padding: EdgeInsets.fromLTRB(17,0,17,0),
                                    children: [
                                        Column(
                                            children: column_children 
                                        )
                                    ],
                                    addAutomaticKeepAlives: true
                                )
                            )
                        )
                    ]
                )
            )
        );
    }
}


