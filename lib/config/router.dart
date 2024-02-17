import 'dart:html';

import 'package:flutter/material.dart';
import 'package:ic_tools/common.dart' show Icrc1Ledgers;

import 'urls.dart';
import 'state.dart';
import 'state_bind.dart';
import 'pages.dart';
import '../tools/widgets.dart';
import '../cycles_market/scaffold_body.dart';
import '../bank/scaffold_body.dart';

class CustomRouteParser extends RouteInformationParser<CustomUrl> {
    @override
    Future<CustomUrl> parseRouteInformation(RouteInformation route) async => CustomUrl.outOfABrowserUrlString(route.location);
    @override
    RouteInformation restoreRouteInformation(CustomUrl custom_url) => RouteInformation(location: custom_url.string);
}




class CustomRouteLegate extends RouterDelegate<CustomUrl> with ChangeNotifier, PopNavigatorRouterDelegateMixin<CustomUrl> { // what is this popnavigatorrouterdelegatemixin?
    final GlobalKey<NavigatorState> navigatorKey;
    CustomState state = CustomState();
    late Future<void> loadfirststatefuture;
    
    CustomRouteLegate() : navigatorKey = GlobalKey<NavigatorState>() { 
        loadfirststatefuture = state.loadfirststate().then((x){
            state.is_loading = false;
            //notifyListeners(); this is not needed here because since the setNewRoutePath method awaits for the loadfirststatefuture, when the loadfirststatefuture completes, the setNewRoutePath method calls build. 
        }).catchError((e, s) async {
            print(e);
            print(s);
            state.is_loading = false;
            state.loading_text = 'Error loading the first state: ${e}';
            await showDialog(
                context: state.context,
                builder: (BuildContext context) {
                    return AlertDialog(
                        title: Text('Error loading the first state:'),
                        content: Text('${e}'),
                        actions: <Widget>[
                            TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('OK'),
                            ),
                        ]
                    );
                }   
            );                 
            notifyListeners();
        });
    }

    @override
    Future<void> setNewRoutePath(CustomUrl custom_url) async {
        await loadfirststatefuture; // for the cycles-market urls, must know the trading pairs before solving for the url.
        
        state.current_url = custom_url;
        
        if (custom_url.name == 'cycles_market') {
            // set the state.cm_main_icrc1token_trade_contracts_i
            int cm_main_icrc1token_trade_contracts_i_of_the_url 
                = state.cm_main.icrc1token_trade_contracts.indexWhere((tc)=>tc.ledger_data.ledger.principal.text == custom_url.variables['token_ledger_id']!);
            
            if (cm_main_icrc1token_trade_contracts_i_of_the_url >= 0) {
                state.cm_main_icrc1token_trade_contracts_i = cm_main_icrc1token_trade_contracts_i_of_the_url;
            } else {
                state.current_url = CustomUrl('void');
            }
        } 
        else if (custom_url.name == 'cycles_bank') {
            int known_icrc1_ledger_i_of_the_url = 
                state.known_icrc1_ledgers
                .indexWhere((l)=>l.ledger.principal.text == custom_url.variables['token_ledger_id']!);
                
            if (known_icrc1_ledger_i_of_the_url >= 0) {
                state.current_icrc1_ledger = state.known_icrc1_ledgers[known_icrc1_ledger_i_of_the_url];
            } else {
                state.current_url = CustomUrl('void');
            }
        }
        
        state.first_show_scaffold = false; // when url changes, treat it like a fresh url load. // :portant.
        print('setNewRoutePath');
        // does this re-build the state? yes.
    }

    CustomUrl get currentConfiguration {/*print('get currentconfiguration'); */return state.current_url; }

    CustomState _getState() {
        return state;
    }

    void _changeState(CustomState new_state, {required bool tifyListeners}) {
        state = new_state;
        if (tifyListeners==true) { notifyListeners(); }
    }
    
    @override
    Widget build(BuildContext context) {
        
        if (state.is_loading == false) { // portant. Don't mess with other loading flows. this can run after.
            if (state.current_url.name == 'cycles_bank') {
                List<Future> wait_futures = generate_possible_cb_first_load_futures(state.current_icrc1_ledger, state);
                if (wait_futures.isNotEmpty) {
                    state.loading_text = 'loading ${state.current_icrc1_ledger.symbol} balance and transactions ...';
                    state.is_loading = true;
                    Future.wait(wait_futures).then((_x){
                        state.is_loading = false;
                        notifyListeners();
                    });
                }
            } else if (state.current_url.name == 'cycles_market') {
                List<Future> wait_futures = generate_possible_cm_page_first_load_futures(state.cm_main_icrc1token_trade_contracts_i, state);
                if (wait_futures.isNotEmpty) {
                    state.loading_text = 'loading ${state.cm_main.trade_contracts[state.cm_main_icrc1token_trade_contracts_i].ledger_data.symbol} market ...';    
                    state.is_loading = true;
                    Future.wait(wait_futures).then((_x){
                        state.is_loading = false;
                        notifyListeners();
                    });
                }
            }
        }
        
        List<String> page_branches = state.current_url.name.split('__');
        List<Page> navigator_pages = List.generate(page_branches.length, (int i) => CustomUrl(page_branches.take(i+1).join('__'), variables: state.current_url.variables).get_page());
        late bool Function(Route route, dynamic sult) onPopPage; 
        
        if (state.is_loading) {
            navigator_pages.add(LoadingPage());
            onPopPage = (r,s)=>false;
        } else {
            if (state.first_show_scaffold == false) { state.first_show_scaffold = true; }
            onPopPage = (route, sult) {
                if (route.didPop(sult)==false) { return false; }
                state.current_url = CustomUrl(page_branches.take(page_branches.length - 1).join('__'), variables: state.current_url.variables);
                return true;
            };

        }
                
        print('router build. loading: ${state.is_loading}, current-url: ${state.current_url.name}, navigator pages: ${navigator_pages.map((p)=>p.runtimeType).toList()}');
        return MainStateBind<CustomState>(
            key: ValueKey<String>('mainstatebind'),
            getState: _getState,
            changeState: _changeState,
            child: Navigator(
                key: navigatorKey,
                pages: navigator_pages,
                onPopPage: onPopPage
            )
        );
    }
}
