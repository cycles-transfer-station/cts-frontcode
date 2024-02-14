import 'dart:html';

import 'package:flutter/material.dart';
import 'package:ic_tools/common.dart' show Icrc1Ledgers;

import 'urls.dart';
import 'state.dart';
import 'state_bind.dart';
import 'pages.dart';
import '../tools/widgets.dart';


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
                List<Future> wait_futures = [];
                if (state.user != null) {
                    if (state.user!.first_load_icrc1ledgers_balances.containsKey(state.user!.current_icrc1_ledger) == false) {
                        state.user!.first_load_icrc1ledgers_balances[state.user!.current_icrc1_ledger] = state.user!.fresh_icrc1_balances([state.user!.current_icrc1_ledger]);
                        wait_futures.add(state.user!.first_load_icrc1ledgers_balances[state.user!.current_icrc1_ledger]!);
                        print('bank ${state.user!.current_icrc1_ledger.symbol} balances first load');
                    }
                    if (state.user!.first_load_icrc1ledgers_transactions.containsKey(state.user!.current_icrc1_ledger) == false) {
                        state.user!.first_load_icrc1ledgers_transactions[state.user!.current_icrc1_ledger] = state.user!.fresh_icrc1_transactions([state.user!.current_icrc1_ledger]);
                        wait_futures.add(state.user!.first_load_icrc1ledgers_transactions[state.user!.current_icrc1_ledger]!);
                        print('bank ${state.user!.current_icrc1_ledger.symbol} transactions first load');
                    }
                }
                if (wait_futures.isNotEmpty) {
                    state.loading_text = 'loading ${state.user!.current_icrc1_ledger.symbol} balance and transactions ...';
                    state.is_loading = true;
                    // put LoadingPage as the page instead of putting it as a branch on top of the bank page. this way, it won't have to load these pages before loading the first state.  
                    Future.wait(wait_futures).then((_x){
                        state.is_loading = false;
                        Future.delayed(Duration(milliseconds: 1)/*make sure notifyListeners gets called after this build finishes*/, ()=>notifyListeners());
                    });
                }
            } else if (state.current_url.name == 'cycles_market') {
                List<Future> wait_futures = [];
                if (state.cm_main.trade_contracts[state.cm_main_icrc1token_trade_contracts_i].first_load_data == null) { // state.cm_main.trade_contracts[i] will not be null, because the setNewRoutePath waits till the loadfirststate which loads the view_tcs. so it can only be a cycles_market current url when the loadfirststate is done.
                    state.cm_main.trade_contracts[state.cm_main_icrc1token_trade_contracts_i].first_load_data = state.cm_main.trade_contracts[state.cm_main_icrc1token_trade_contracts_i].load_data();                
                    wait_futures.add(state.cm_main.trade_contracts[state.cm_main_icrc1token_trade_contracts_i].first_load_data!);
                    print('cm ${state.cm_main.trade_contracts[state.cm_main_icrc1token_trade_contracts_i].ledger_data.symbol} first load_data');
                }
                if (state.user != null) {
                    if (state.user!.first_load_tcs.containsKey(state.cm_main.trade_contracts[state.cm_main_icrc1token_trade_contracts_i]) == false) {
                        state.user!.first_load_tcs[state.cm_main.trade_contracts[state.cm_main_icrc1token_trade_contracts_i]] = state.user!.load_cm_data([state.cm_main.trade_contracts[state.cm_main_icrc1token_trade_contracts_i]]);
                        wait_futures.add(state.user!.first_load_tcs[state.cm_main.trade_contracts[state.cm_main_icrc1token_trade_contracts_i]]!);
                        print('cm ${state.cm_main.trade_contracts[state.cm_main_icrc1token_trade_contracts_i].ledger_data.symbol} user first load_cm_data');
                    }
                    if (state.user!.first_load_icrc1ledgers_balances.containsKey(state.cm_main.trade_contracts[state.cm_main_icrc1token_trade_contracts_i].ledger_data) == false) {
                        state.user!.first_load_icrc1ledgers_balances[state.cm_main.trade_contracts[state.cm_main_icrc1token_trade_contracts_i].ledger_data] = state.user!.fresh_icrc1_balances([state.cm_main.trade_contracts[state.cm_main_icrc1token_trade_contracts_i].ledger_data]); 
                        wait_futures.add(state.user!.first_load_icrc1ledgers_balances[state.cm_main.trade_contracts[state.cm_main_icrc1token_trade_contracts_i].ledger_data]!);
                        print('cm ${state.cm_main.trade_contracts[state.cm_main_icrc1token_trade_contracts_i].ledger_data.symbol} user load balance');
                    }
                    if (state.user!.first_load_icrc1ledgers_balances.containsKey(CYCLES_BANK_LEDGER) == false) {
                        state.user!.first_load_icrc1ledgers_balances[CYCLES_BANK_LEDGER] = state.user!.fresh_icrc1_balances([CYCLES_BANK_LEDGER]); 
                        wait_futures.add(state.user!.first_load_icrc1ledgers_balances[CYCLES_BANK_LEDGER]!);
                        print('cm ${'CYCLES'} user load balance');
                    }
                }
                if (wait_futures.isNotEmpty) {
                    state.loading_text = 'loading ${state.cm_main.trade_contracts[state.cm_main_icrc1token_trade_contracts_i].ledger_data.symbol} market ...';
                    state.is_loading = true;
                    Future.wait(wait_futures).then((_x){
                        state.is_loading = false;
                        Future.delayed(Duration(milliseconds: 1)/*make sure notifyListeners gets called after this build finishes*/, ()=>notifyListeners());
                    });
                }
            }
        }
        
        // url branches config
        
        List<String> page_branches = state.current_url.name.split('__');
        
        // yes i know the last CustomUrl is already in the state, ... i could generate only the parent-branches and + with the state.current_url.get_page() but is the [] + [] faster than the CustomUrl()-stantiation?
        List<Page> navigator_pages = List.generate(page_branches.length, (int i) => CustomUrl(page_branches.take(i+1).join('__'), variables: state.current_url.variables).get_page() );
    
        late bool Function(Route route, dynamic sult) onPopPage; 
        
        if (state.is_loading) {
            navigator_pages.add(LoadingPage());
            onPopPage = (r,s)=>false;
        } else {
            onPopPage = (route, sult) {
                if (route.didPop(sult)==false) { return false; }
                state.current_url = CustomUrl(page_branches.take(page_branches.length - 1).join('__'), variables: state.current_url.variables);
                //_changeState(state, tifyListeners: true);
                return true;
            };
            
        }
        
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



