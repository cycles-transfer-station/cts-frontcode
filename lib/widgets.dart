import 'package:flutter/material.dart';

import 'state.dart';
import 'state_bind.dart';




// must be a cendant of the mainstatebind widget if there is no text given in the constructor 
class Loading extends StatelessWidget {
    String? opt_loading_text;
    Loading([this.opt_loading_text]);
    
    @override
    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
        state.context = context;
        
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
    String button_text;
    
    OutlineButton({required this.button_text, required this.on_press_complete}) : super(key: ValueKey(button_text));
    
    
    Widget build(BuildContext context) {    
        
        return Padding(
            padding: EdgeInsets.all(17.0),
            child: Container(
                child: OutlinedButton(
                    child: Text(this.button_text),
                    style: ButtonStyle(
                        foregroundColor: MaterialStateProperty.all(Theme.of(context).colorScheme.onPrimary),
                    ),
                    onPressed: on_press_complete
                )
            )
        );
    
    }
    
    
}
