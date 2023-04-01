import 'dart:html';

import 'package:flutter/material.dart';
import 'package:ic_tools/ic_tools.dart';
import 'package:ic_tools_web/ic_tools_web.dart';

import '../tools/widgets.dart';
import '../tools/ii_login.dart';
import '../user.dart';
import '../config/state.dart';
import '../config/state_bind.dart';
import '../config/urls.dart';


class BusinessTegrationsScaffoldBody extends StatelessWidget {
    BusinessTegrationsScaffoldBody({super.key});
    static BusinessTegrationsScaffoldBody create({Key? key}) => BusinessTegrationsScaffoldBody(key: key);
    @override
    Widget build(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
        
        
        List<Widget> column_children = [
            Padding(
                padding: EdgeInsets.fromLTRB(17.0, 34.0, 17.0, 27.0),
                child: Container(
                    child: Text('BUSINESS TEGRATIONS')
                )
            ),
        ];
        
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


