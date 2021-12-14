import 'dart:html';
import 'package:flutter/material.dart';

import 'urls.dart';
import 'state.dart';
import 'state_bind.dart';




class CustomRouteParser extends RouteInformationParser<CustomUrl> {
    @override
    Future<CustomUrl> parseRouteInformation(RouteInformation route) async => CustomUrl.outOfABrowserUrlString(route.location!);
    @override
    RouteInformation restoreRouteInformation(CustomUrl custom_url) => RouteInformation(location: custom_url.string);
}




class CustomRouteLegate extends RouterDelegate<CustomUrl> with ChangeNotifier, PopNavigatorRouterDelegateMixin<CustomUrl> { // what is this popnavigatorrouterdelegatemixin?
    final GlobalKey<NavigatorState> navigatorKey;
    CustomState state = CustomState();
    late Future<void> loadfirststatefuture;
    
    CustomRouteLegate() : navigatorKey = GlobalKey<NavigatorState>() { 
        state.addListener(notifyListeners); 
        loadfirststatefuture = loadfirststate();   
    }

    Future<void> loadfirststate() async {
        await state.loadfirststate();
    }

    @override
    Future<void> setNewRoutePath(CustomUrl custom_url) async {
        print('set new route path');
        state.current_url = custom_url;
        // does this re-build the state?
    }

    CustomUrl get currentConfiguration {print('get currentconfiguration'); return state.current_url; }

    CustomState _getState() {
        return state;
    }

    void _changeState(CustomState new_state, {required bool tifyListeners}) {
        state = new_state;
        state.save_in_localstorage();
        if (tifyListeners==true) { notifyListeners(); }
    }


    @override
    Widget build(BuildContext context) {

        return FutureBuilder<void>(
            key: ValueKey<String>('loadfirststatefuturebuilder'),
            future: loadfirststatefuture,
            builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
                if (snapshot.hasError) {
                    return Text('something went wrong, try re-freshing the page');
                } else {
                    if (snapshot.connectionState != ConnectionState.done) {
                        return Text('loading page');
                    } else {
                        return MainStateBind<CustomState>(
                            key: ValueKey<String>('mainstatebind'),
                            getState: _getState,
                            changeState: _changeState,
                            child: Navigator(
                                key: navigatorKey,
                                pages: state.current_url.branch.item1.map<Page>((String branch_level) {
                                    
                                }).toList();   state.url_branch_levels.map<Page>((CustomUrl url)=>url.get_page()).toList(),
                                onPopPage: (route, sult) {
                                    if (route.didPop(sult)==false) { return false; }
                                    state.current_url = CustomUrl(state.current_url.branch.item1.reversed[1]);
                                    _changeState(state, tifyListeners: true);
                                    return true;
                                }
                            )
                        );
                    }
                }
            }
        );
    }
}



