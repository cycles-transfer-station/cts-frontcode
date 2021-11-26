import 'package:flutter/material.dart';
import 'package:flutter_session/flutter_session.dart';

import 'urls.dart';
import 'state.dart';
import 'state_bind.dart';




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
        state.addListener(notifyListeners); 
        loadfirststatefuture = loadfirststate();   
    }

    Future<void> loadfirststate() async {
        Map? session_map = await FlutterSession().get('state');
        if (session_map!= null) {
            state.map = session_map;
        }
        
    }

    @override
    Future<void> setNewRoutePath(CustomUrl custom_url) async {
        print('set new route path');
        // state.current_url = custom_url;
        state.move_url(custom_url); 
        // does this re-build the state?
    }

    CustomUrl get currentConfiguration {print('get currentconfiguration'); return state.current_url; }

    CustomState _getState() {
        return state;
    }

    void _changeState(CustomState new_state, {required bool tifyListeners}) {
        state = new_state;
        FlutterSession().set('state', state.map);
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
                                pages: state.url_branch_levels.map<Page>((CustomUrl url)=>url.get_page()),
                                onPopPage: (route, sult) {
                                    if (route.didPop(sult)==false) { return false; }
                                    state.url_branch_levels.removeLast();
                                    FlutterSession().set('state', state.map);
                                    // notifyListeners();
                                    return true; // see if this calls tifyListeners anyway
                                }
                            )
                        );
                    }
                }
            }
        )
    }
}



