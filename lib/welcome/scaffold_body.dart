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
                    child: Text('Mint, transfer, and trade the native stable-currency on the world-computer: CYCLES.', style: TextStyle(fontSize: 19))
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
        
        
        if (state.user == null) {
            
            column_children.add(   
                Container(
                    padding: EdgeInsets.all(17.0),
                    child: OutlineButton(
                        button_text: 'ii login',
                        on_press_complete: () async { await ii_login(context); }
                    )
                )
            );
        }
        
        else /*if (state.user != null)*/ {
            
            column_children.addAll([
                Container(
                    padding: EdgeInsets.all(17.0),
                    child: SelectableText('USER-ID: ${state.user!.principal.text}')
                ) 
            ]);

        }
        
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
                                        , style: TextStyle(fontSize: 17)
                                    ),*/
                                    Text(
    //"""CYCLES are the perfect natural stable-coin for the blockchain cyber-space. 
    """Store your money on the blockchain in your own personal CYCLES-BANK! 
    """
                                        , style: TextStyle(fontSize: 17)
                                    ),
                                    Text(
    """Send money between friends, or make payments in stores! 
    """
                                        , style: TextStyle(fontSize: 17)
                                    ),
                                    Text(
    """Hedge against fiat inflation and crypto-volatility! 
    """
                                        , style: TextStyle(fontSize: 17)
                                    ),
                                    Text(
    """Trade or liquidate through the CYCLES-MARKET! 
    """
                                        , style: TextStyle(fontSize: 17)
                                    ),
                                    Text(
    """\nThe CYCLES are here!
    """
                                        , style: TextStyle(fontSize: 17)
                                    ),
                                    Text(
    """\n\n\n\nUse the menu-button in the bottom-left corner for the navigation. 
    """
                                        , style: TextStyle(fontSize: 17)
                                    ),
                                ]
                            )
                        )
                    )
                )
            )
        ]);
        
        return Center(
            child: Container(
                constraints: BoxConstraints(maxWidth: 900),
                child: Column(                
                    children: column_children,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center
                )
            )
        );
    }

}


