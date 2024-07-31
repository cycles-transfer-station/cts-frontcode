import 'dart:typed_data';
import 'dart:html';
import 'dart:js' as js;
import 'dart:js_util';
import 'dart:convert';
import 'dart:ui' as dart_ui;

import 'package:flutter/material.dart';

import 'package:ic_tools/ic_tools.dart';
import 'package:ic_tools/candid.dart' show c_backwards, PrincipalReference, Nat64, Nat, Blob;
import 'package:ic_tools/candid.dart' as candid;
import 'package:ic_tools/tools.dart';
import 'package:ic_tools/common.dart' show IcpTokens;
import 'package:ic_tools/common.dart' as common;

import '../main.dart';
import '../tools/widgets.dart';
import '../tools/ii_login.dart';
import '../tools/tools.dart';
import 'urls.dart';
import 'state.dart';
import 'state_bind.dart';
import '../user.dart';
import '../transfer_icp/icp_ledger.dart';
import '../transfer_icp/scaffold_body.dart';
import '../bank/scaffold_body.dart';
import '../about/scaffold_body.dart';
import '../welcome/scaffold_body.dart';
import '../cycles_market/scaffold_body.dart';


// most state can be held in the MainState and can re-build with MainStateBind.set_state.tifyListeners so the page widgets can be StatelessWidget s


const List<String> lower_case_hex_chars = ['a','b','c','d','e','f'];
const List<String> number_chars = ['0','1','2','3','4','5','6','7','8','9'];





class LoadingPage extends Page {
    
    LoadingPage({LocalKey? key}) : super(key: key);
    
    Route createRoute(BuildContext context) {
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);        
        return PageRouteBuilder(
            settings: this,
            // do a cool fade in and fade out 
            transitionDuration: const Duration(milliseconds: 250),
            reverseTransitionDuration: const Duration(milliseconds: 175),
            pageBuilder: (context, animation, animation2) {
                animation.addStatusListener((AnimationStatus animation_status){
                    if (animation_status == AnimationStatus.completed) {
                        if (state.show_loading_page_transition_completer.isCompleted == false) {
                            state.show_loading_page_transition_completer.complete();
                        }
                    }
                });
                final tween = Tween(begin: 0.0, end: 1.0);
                final curve_tween = CurveTween(curve: Curves.easeOutSine);
                return FadeTransition(
                    opacity: animation.drive(tween).drive(curve_tween),
                    child: Loading()
                );
            }
        );
    }
}





// urls pages


class VoidPage {
    static create({LocalKey? key}) => MaterialPage(key: key, child: VoidPageWidget());
}
class VoidPageWidget extends StatelessWidget {
    Widget build(BuildContext context) {
        return Loading('page not found');
    }
}



class WelcomePage extends Page {
    WelcomePage({LocalKey? key}) : super(key: key);
    static WelcomePage create({LocalKey? key}) => WelcomePage(key: key);

    Route createRoute(BuildContext context) {
        
        return PageRouteBuilder(
            settings: this,
            pageBuilder: (context, animation, animation2) {
                final tween = Tween(begin: 0.0, end: 1.0);
                final curve_tween = CurveTween(curve: Curves.easeOutSine);
                return FadeTransition(
                    opacity: animation.drive(tween).drive(curve_tween),
                    child: WelcomePageWidget(key: ValueKey('WelcomePageWidget'))
                );
            }
        );
    }
}
class WelcomePageWidget extends StatefulWidget {
    const WelcomePageWidget({super.key});
    State createState() => WelcomePageWidgetState();
}
class WelcomePageWidgetState extends State<WelcomePageWidget> {

    GlobalKey<ScaffoldState> scaffold_key = GlobalKey<ScaffoldState>();
    
    
    @override
    Widget build(BuildContext context) {
    
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
        state.context = context;
        
        const double appbar_leading_width = 56.0;
        
        return /*SelectionArea(
            child: */Scaffold(
                    key: scaffold_key,
                    appBar: AppBar(
                        title: Center(child: Padding(
                            child: const Text('CYCLES-TRANSFER-STATION', style: TextStyle(fontFamily: 'AxaxaxBold')),
                            padding: EdgeInsets.fromLTRB(0,0,appbar_leading_width,0)
                        )),
                        automaticallyImplyLeading: true,
                        leadingWidth: appbar_leading_width,
                    ),
                    drawer: Drawer(
                        child: Column(
                            children: [
                                DrawerHeader(
                                    child: state.user == null ? Center(child: IILoginButton()) : SelectableText('USER-ID: ${state.user!.principal.text}')
                                ),
                                Expanded(
                                    child: ListView(
                                        padding: EdgeInsets.zero,
                                        children: [
                                            /*
                                            ListTile(
                                                title: const Text('HOME'),
                                                onTap: () {
                                                    state.current_url = CustomUrl('welcome');
                                                    MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                                                    Navigator.pop(context);
                                                },
                                            ),
                                            */
                                            ListTile(
                                                title: const Text('BANK'),
                                                onTap: () {
                                                    Navigator.pop(context);
                                                    change_url_into_cb(state.current_icrc1_ledger, context);
                                                },
                                            ),
                                            ListTile(
                                                title: const Text('MARKET'),
                                                onTap: () {
                                                    Navigator.pop(context);
                                                    change_url_into_cm_market(state.cm_main_icrc1token_trade_contracts_i, context);
                                                },
                                            ),
                                            ListTile(
                                                title: const Text('ABOUT'),
                                                onTap: () {
                                                    state.current_url = CustomUrl('about');
                                                    MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                                                    Navigator.pop(context);
                                                },
                                            )
                                        ]
                                    )
                                ),
                                Container(
                                    child: Align(
                                        alignment: FractionalOffset.bottomCenter,
                                        child: Column(
                                            children: <Widget>[
                                                Divider(),
                                                if (state.user != null) Container(
                                                    padding: EdgeInsets.all(17),
                                                    child: OutlineButton(
                                                        button_text: 'LOG-OUT',
                                                        on_press_complete: () {
                                                            state.user!.caller.indexdb_delete();
                                                            window.localStorage.remove('user_cycles_bank');
                                                            state.user = null;
                                                            MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);            
                                                            Navigator.pop(context);
                                                        }
                                                    )
                                                )
                                                else/*if (state.user == null)*/ SizedBox(height: 20) 
                                            ]
                                        )
                                    )
                                ),
                            ]
                        )
                    ),
                    body: SafeArea(
                        child: state.current_url.main_page_scaffold_body()!,
                    ),
                    bottomNavigationBar: BottomAppBar(
                        height: 50,
                        padding: EdgeInsets.zero,
                        //color: Colors.blue,
                        child: IconTheme(
                            data: IconThemeData(color: Theme.of(context).colorScheme.onPrimary),
                            child: Container(
                                child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: <Widget>[
                                        Container(
                                            child: state.user == null ? IILoginButton() : SelectableText(principal_short(state.user!.principal), style: TextStyle(fontFamily: 'CourierNew')),
                                            padding: EdgeInsets.symmetric(horizontal: 17, vertical: 13),  
                                        ),
                                        const Spacer(),
                                    ]
                                )
                            ) 
                        )
                    )
                
            )
        /*)*/;
    }
}




