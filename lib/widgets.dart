import 'package:flutter/material.dart';

import 'state.dart';
import 'state_bind.dart';




// must be a cendant of the mainstatebind widget if there is no text given in the constructor 
class Loading extends StatelessWidget {
    String? opt_loading_text;
    Loading([this.opt_loading_text]);
    
    @override
    Widget build(BuildContext context) {
        String loading_text = opt_loading_text != null ? opt_loading_text! : MainStateBind.get_state<CustomState>(context).loading_text;    
        return Scaffold(
            body: Padding(
                padding: EdgeInsets.all(17.0),
                child: Text(loading_text)
            )
        );
    }
}

    
