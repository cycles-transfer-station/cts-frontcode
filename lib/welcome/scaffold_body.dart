import 'dart:html';

import 'package:flutter/material.dart';
import 'package:ic_tools/ic_tools.dart';

import '../tools/widgets.dart';
import '../tools/ii_login.dart';
import '../user.dart';
import '../config/state.dart';
import '../config/state_bind.dart';
import '../config/urls.dart';


class WelcomeScaffoldBody extends StatelessWidget {
    WelcomeScaffoldBody({super.key});
    static WelcomeScaffoldBody create({Key? key}) => WelcomeScaffoldBody(key: key);
    @override
    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
        
        
        List<Widget> column_children = [
            Padding(
                padding: EdgeInsets.fromLTRB(17.0, 34.0, 17.0, 27.0),
                child: Container(
                    child: Text('Mint, transfer, and trade the native stable-currency on the world-computer: CYCLES.', style: TextStyle(fontSize: 23))
                )
            ),
            Padding(
                padding: EdgeInsets.fromLTRB(0, 4.5, 0, 17.0),
                child: Divider(
                    height: 4.0,   
                    thickness: 4.0,
                    indent: 34.0,
                    endIndent: 34.0,
                    //color: 
                ),
            )
        
        ];
        
        column_children.add(   
            Container(
                padding: EdgeInsets.all(17.0),
                child: state.user == null ? 
                    OutlineButton(
                        button_text: 'LOG-IN',
                        on_press_complete: () async { await ii_login(context); }
                    )
                : SelectableText('USER-ID: ${state.user!.principal.text}')
            )
        );
        
        column_children.addAll([
            Container(
                constraints: BoxConstraints(maxWidth: 570),
                padding: EdgeInsets.fromLTRB(0, 17, 0, 0),
                child: Divider(
                    height: 4.0,
                    thickness: 4.0,
                    indent: 54.0,
                    endIndent: 54.0,
                    //color: 
                ),
            ),
            Expanded(
                child: Container(
                    padding: EdgeInsets.all(0),
                    child: SingleChildScrollView(
                        child: Padding(
                            padding: EdgeInsets.all(27), 
                            child: DefaultTextStyle.merge(
                                style: TextStyle(fontSize: 21),
                                child: Column(
                                    children: [
                                        SizedBox(
                                            width: 3,
                                            height: 25
                                        ),
                                        /*Text(
        """
        Welcome, here is the home for the world-computer's native CYCLES. 
    
        """
                                        ),*/
                                        Text(
        //"""CYCLES are the perfect natural stable-coin for the blockchain cyber-space. 
        """Store your money on the blockchain in the CYCLES-BANK! 
        """
                                        ),
                                        Text(
        """Send money between friends, or make payments in stores! 
        """
                                        ),
                                        Text(
        """Hedge against fiat inflation and crypto-volatility! 
        """
                                        ),
                                        Text(
        """Trade or liquidate through the CYCLES-MARKET! 
        """
                                        ),
                                        Text(
        """The CYCLES are here.
        """
                                        ),
                                    ]
                                )
                            )
                        )
                    )
                )
            )
        ]);
        
        return Center(
            child: Container(
                constraints: BoxConstraints(maxWidth: 1000),
                child: DefaultTextStyle.merge(
                    style: TextStyle(fontFamily: 'AxaxaxBold'),
                    child: Column(                
                        children: column_children,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center
                    )
                )
            )
        );
    }

}


