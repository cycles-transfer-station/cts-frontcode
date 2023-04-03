import 'package:flutter/material.dart';
import 'config/router.dart';




void main() {
    runApp(const Base(key: ValueKey('Base')));
}


class Base extends StatefulWidget {
    const Base({Key? key}) : super(key: key);
    _BaseState createState() => _BaseState(); }
class _BaseState extends State<Base> {
    CustomRouteParser _routeParser = CustomRouteParser();
    CustomRouteLegate _routeLegate = CustomRouteLegate();
    @override
    Widget build(BuildContext context) {
        return MaterialApp.router(
            routeInformationParser : _routeParser,
            routerDelegate         : _routeLegate,
            backButtonDispatcher   : RootBackButtonDispatcher(),
            title: ':CTS.',//':C.-T.-S.',
            theme: ThemeData(
                brightness: Brightness.dark,
                backgroundColor: blue2, 
                fontFamily: 'AxaxaxBold',
                /* try this on a child widget of this materialapp
                textTheme: Theme.of(context).textTheme.apply(
                    fontSizeFactor: 1.1,
                    fontSizeDelta: 1.0,
                ),
                */
                //typography: Typography.material2018(platform: platform)
                appBarTheme: AppBarTheme(
                    //color: blue, 
                    backgroundColor: blue2, 
                    //foregroundColor: double?, 
                    elevation: 0.0,  
                    shadowColor: null,  
                )
            ),
            debugShowCheckedModeBanner: false 
        );
    }
}



const Color grey_background = Color.fromRGBO(30, 30, 31, 0.9);
const Color blue = Color.fromRGBO(76,97,145, 0.9);



const Color blue2 = Color(0xFF506CBF);
const Color purple = Color(0xFF7C3FCB);
//const Color red = Color(0xFF8c3a11);
const Color red = Color(0xFF953905);

/*

this.debugShowMaterialGrid = false,
this.showPerformanceOverlay = false,
  



*/

