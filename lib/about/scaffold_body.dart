import 'package:flutter/material.dart';

import '../tools/widgets.dart';



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
            Padding(
                padding: EdgeInsets.fromLTRB(17.0, 34.0, 17.0, 27.0),
                child: Container(
                    child: Text(
"""The mainstream-usage of the native CYCLES as a stable-currency on the world-computer stands on these 3 key pillars. 

Pillar #1: The cycles-bank. Each user has their own personal cycles-bank that cepts, holds, and transfers the cycles, and keeps logs of the transfers. Cycles-banks use the cycles-transfer-specification of Pillar #2 to transfer the CYCLES.

Pillar #2: The cycles-transfer-specification. The cycles-transfer-specification sets the communication standard between the smart-contracts (canisters) for the cycles-transfers. The cycles-transfer-specification method has a memo-field that functions as an identifier for specific cycles-transfers/payments. 

Pillar #3: The cycles-market. The cycles-market is the place where people can trade the native CYCLES and ICP both ways. People who want to liquidate CYCLES can sell them for ICP and people who want CYCLES can purchase them with ICP. 
"""
                    , style: TextStyle(fontSize: 17))
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
            Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(11,11,11,17),
                child: Center(
                    child: Text('BUSINESS INTEGRATION', style: TextStyle(fontSize: 19))
                )
            ),
            Container(
                width: double.infinity,
                child: Text('\nCYCLES-TRANSFER-SPECIFICATION CANDID: \n', style: TextStyle(fontSize: 17))
            ),
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
    Blob: blob;
};

service cycles-transfer-specification : {
    cycles_transfer(CyclesTransfer) -> ();
}


"""
                    ,
                    style: TextStyle(fontSize: 17, fontFamily: 'NimbusMonoPS-Bold')
                )
            )
        ]);
        
        return Center(
            child: Container(
                constraints: BoxConstraints(maxWidth: 900),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                        ScaffoldBodyHeader('ABOUT CTS'),
                        Expanded(
                            child: ListView(
                                controller: main_listview_scroll_controller,
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
    }
}


