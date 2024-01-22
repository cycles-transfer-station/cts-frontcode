import 'dart:html';

import 'package:flutter/material.dart';

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
            notifyListeners();
        }).catchError((e, s) async {
            print(e);
            print(s);
            state.is_loading = false;/*TAKE THIS LINE OUT WHEN SET FOR THE GO.*/
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
            
            //throw e; // for the debugging,
        });
    }

    @override
    Future<void> setNewRoutePath(CustomUrl custom_url) async {
        //print('set new route path');
        await loadfirststatefuture; // for the cycles-market urls, must know the trading pairs before solving for the url.
        state.current_url = custom_url;
        // does this re-build the state?
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



