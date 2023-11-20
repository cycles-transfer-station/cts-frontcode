import 'dart:ui' as dart_ui;

import 'package:flutter/material.dart';

import '../config/state.dart';
import '../config/state_bind.dart';

import './ii_login.dart';



// must be a cendant of the mainstatebind widget if there is no text given in the constructor 
class Loading extends StatelessWidget {
    String? opt_loading_text;
    Loading([this.opt_loading_text]);
    
    @override
    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
        
        String loading_text = opt_loading_text != null ? opt_loading_text! : state.loading_text;    
        
        return /*SelectionArea(
            child: */Scaffold(
                body: Padding(
                    padding: EdgeInsets.all(17.0),
                    child: Text(loading_text)
                )
            )
        /*)*/;
    }
}

    

    

class OutlineButton extends StatelessWidget {
    Function()? on_press_complete;
    String? button_text;
    Widget? child;
    
    OutlineButton({this.child, this.button_text, required this.on_press_complete, super.key}) {
        if ((this.child == null && this.button_text == null) || (this.child != null && this.button_text != null)) {
            throw Exception('OutlineButton, must take one of a button_text or a child');        
        }    
    }
    
    
    Widget build(BuildContext context) {    
        
        return OutlinedButton(
            child: this.button_text != null ? Text(this.button_text!) : child!,
            style: ButtonStyle(
                foregroundColor: MaterialStateProperty.all(Theme.of(context).colorScheme.onPrimary),
            ),
            onPressed: on_press_complete
        );
    }
       
}



class OutlineButtonIILogin extends StatefulWidget {
    OutlineButtonIILogin({super.key});
    State createState() => OutlineButtonIILoginState();
}
class OutlineButtonIILoginState extends State<OutlineButtonIILogin> {
    Future? ii_login_future;
    
    Widget build(BuildContext context) {
        return OutlineButton(
            button_text: 'ii login',
            on_press_complete: () async {
                ii_login_future = ii_login(context);  
                await ii_login_future; 
            }
        );   
    }
}
    




class ScaffoldBodyHeader extends StatelessWidget {
    final Widget header;
    ScaffoldBodyHeader(this.header);
    Widget build(BuildContext context) {
        return Column(
            children: [
                Padding(
                    padding: EdgeInsets.fromLTRB(17.0, 19.0, 17.0, 17.0),
                    child: Center(
                        child: header,
                    )
                ),
                Container(
                    padding: EdgeInsets.fromLTRB(0,4.5,0,0),
                    margin: EdgeInsets.symmetric(horizontal: 13),
                    child: Divider(
                        height: 4.0,   
                        thickness: 4.0,
    //                    indent: 34.0,
    //                    endIndent: 34.0,
                        //color: 
                    )
                )
            ]
        ); 
    }
}

class ScrollConfigurationWithTheMouse extends StatelessWidget {
    Widget child;
    ScrollConfigurationWithTheMouse(this.child);
    Widget build(BuildContext context) { 
        ScrollBehavior scroll_behavior_context = ScrollConfiguration.of(context);
        return ScrollConfiguration(
            behavior: scroll_behavior_context.copyWith(dragDevices: scroll_behavior_context.dragDevices.toSet()..add(dart_ui.PointerDeviceKind.mouse), ),
            child: this.child
        ); 
    }
}






