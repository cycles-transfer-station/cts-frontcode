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
import '../tools/indexdb.dart';
import '../tools/widgets.dart';
import '../tools/ii_login.dart';
import 'urls.dart';
import 'state.dart';
import 'state_bind.dart';
import '../user.dart';
import '../transfer_icp/icp_ledger.dart';
import '../transfer_icp/scaffold_body.dart';
import '../cycles_bank/cycles_bank.dart';
import '../cycles_bank/scaffold_body.dart';
import '../cycles_market/cycles_market_data.dart';
import '../cycles_market/scaffold_body.dart';
import '../about/scaffold_body.dart';
import '../welcome/scaffold_body.dart';


// most state can be held in the MainState and can re-build with MainStateBind.set_state.tifyListeners so the page widgets can be StatelessWidget s


const List<String> lower_case_hex_chars = ['a','b','c','d','e','f'];
const List<String> number_chars = ['0','1','2','3','4','5','6','7','8','9'];





class LoadingPage extends Page {
    
    LoadingPage({LocalKey? key}) : super(key: key);
    
    Route createRoute(BuildContext context) {
        
        return PageRouteBuilder(
            settings: this,
            // do a cool fade in and fade out 
            pageBuilder: (context, animation, animation2) {
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


class MainPage extends Page {
    MainPage({LocalKey? key}) : super(key: key);
    static MainPage create({LocalKey? key}) => MainPage(key: key);

    Route createRoute(BuildContext context) {
        
        return PageRouteBuilder(
            settings: this,
            pageBuilder: (context, animation, animation2) {
                final tween = Tween(begin: 0.0, end: 1.0);
                final curve_tween = CurveTween(curve: Curves.easeOutSine);
                return FadeTransition(
                    opacity: animation.drive(tween).drive(curve_tween),
                    child: MainPageWidget(key: ValueKey('MainPageWidget'))
                );
            }
        );
    }
}
class MainPageWidget extends StatefulWidget {
    const MainPageWidget({super.key});
    State createState() => MainPageWidgetState();
}
class MainPageWidgetState extends State<MainPageWidget> with TickerProviderStateMixin {

    GlobalKey<ScaffoldState> scaffold_key = GlobalKey<ScaffoldState>();
    late TabController tab_controller;
    
    List tabs = [
        {
            'showname': 'HOME',
            'urlname': 'welcome',
        },
        {
            'showname': 'MY-BANK',
            'urlname': 'cycles_bank',
        },
        {
            'showname': 'MARKET',
            'urlname': 'cycles_market',
        },
        {
            'showname': 'BUSINESS-INTEGRATION',
            'urlname': 'business_tegrations',
        },
        {
            'showname': 'ABOUT',
            'urlname': 'about',
        },
        {
            'showname': 'FEEDBACK',
            'urlname': 'feedback',
        },   
    ];
    
    
    @override
    void initState() {
        super.initState();
        tab_controller = TabController(length: tabs.length, vsync: this);
    }
    
    @override
    void dispose() {
        tab_controller.dispose();
        super.dispose();
    }
    
    
    @override
    Widget build(BuildContext context) {
    
        CustomState state = MainStateBind.get_state<CustomState>(context);
        MainStateBindScope<CustomState> main_state_bind_scope = MainStateBind.get_main_state_bind_scope<CustomState>(context);
        state.context = context;
        
        tab_controller.addListener(() {
            if (!tab_controller.indexIsChanging) {
                state.current_url = CustomUrl(tabs[tab_controller.index]['urlname']!);
                main_state_bind_scope.state_bind.changeState(state, tifyListeners: true);
            }
        });
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
            tab_controller.animateTo(tabs.indexWhere((e)=>e['urlname']! == state.current_url.name));            
        });
        
        
        return /*SelectionArea(
            child: */Scaffold(
                key: scaffold_key,
                backgroundColor: blue2,
                appBar: AppBar(
                    toolbarHeight: 120,
                    title: Container(
                        child: const Text(':CYCLES-TRANSFER-STATION.', style: TextStyle(fontFamily: 'AxaxaxBold', fontSize: 25)),
                    ),
                    leading: TextButton(
                        child: Text('CTS', style: TextStyle(fontSize: 70, color: Theme.of(context).colorScheme.onPrimary)),
                        onPressed: () {
                            tab_controller.animateTo(tabs.indexWhere((e)=>e['urlname']! == 'welcome'));            
                        }
                    ),
                    leadingWidth: 200,
                    centerTitle: true,
                    automaticallyImplyLeading: false,
                    bottom: TabBar(
                        controller: tab_controller,
                        indicator:  UnderlineTabIndicator(
                            borderSide: const BorderSide(width: 0.0, color: Colors.white),
                            borderRadius: BorderRadius.all(Radius.zero)
                        ),
                        tabs: tabs.map((t)=>Tab(text: t['showname']!)).toList(),
                    ),
                ),
                body: TabBarView(
                    controller: tab_controller,
                    children: tabs.map<Widget>((t){
                        String urlname = t['urlname']!;
                        return urlmap[urlname]!['main_page_scaffold_body']!(key: ValueKey('${urlname} main-page-body'));
                    }).toList(),
                ),
                drawer: Drawer(
                    child: Column(
                        children: [
                            DrawerHeader(
                                child: state.user==null ? Center(child: OutlineButton(button_text: 'ii login', on_press_complete: () async { await ii_login(context); })) : SelectableText('USER-ID: ${state.user!.principal.text}')
                            ),
                            Expanded(
                                child: ListView(
                                    padding: EdgeInsets.zero,
                                    children: [
                                        ListTile(
                                            title: const Text('HOME'),
                                            onTap: () {
                                                state.current_url = CustomUrl('welcome');
                                                MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                                                Navigator.pop(context);
                                                
                                            },
                                        ),
                                        /*
                                        ListTile(
                                            title: const Text('TRANSFER-ICP'),
                                            onTap: () {
                                                state.current_url = CustomUrl('transfer_icp');
                                                MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                                                Navigator.pop(context);
                                            },
                                        ),
                                        */
                                        ListTile(
                                            title: const Text('BANK'),
                                            onTap: () {
                                                state.current_url = CustomUrl('cycles_bank');
                                                MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                                                Navigator.pop(context);
                                            },
                                        ),
                                        ListTile(
                                            title: const Text('MARKET'),
                                            onTap: () {
                                                state.current_url = CustomUrl('cycles_market');
                                                MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
                                                Navigator.pop(context);
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
                                                        state.user = null;
                                                        IndexDB.delete_database('cts');
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
                bottomNavigationBar: BottomAppBar(
                    color: blue2,
                    elevation: 0.0,
                    child: IconTheme(
                        data: IconThemeData(color: Theme.of(context).colorScheme.onPrimary),
                        child: Row(
                            children: <Widget>[
                                IconButton(
                                    tooltip: 'Navigation',
                                    icon: const Icon(Icons.menu),
                                    onPressed: () {
                                        scaffold_key.currentState!.openDrawer();
                                    },
                                ),
                                /*
                                if (true) const Spacer(),
                                IconButton(
                                    tooltip: 'Search',
                                    icon: const Icon(Icons.search),
                                    onPressed: () {},
                                ),
                                IconButton(
                                    tooltip: 'Favorite',
                                    icon: const Icon(Icons.favorite),
                                    onPressed: () {},
                                ),
                                */
                            ]
                        ) 
                    )       
                )
            )
        /*)*/;
    }
}




