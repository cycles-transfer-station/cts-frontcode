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
            title: 'CTS',//':C.-T.-S.',
            theme: ThemeData(
                brightness: Brightness.dark,
                backgroundColor: grey_background, 
                fontFamily: 'AxaxaxBold',
                /* try this on a child widget of this materialapp
                textTheme: Theme.of(context).textTheme.apply(
                    fontSizeFactor: 1.1,
                    fontSizeDelta: 1.0,
                ),
                */
                //typography: Typography.material2018(platform: platform)
                appBarTheme: AppBarTheme(
                    color: blue, 
                    //backgroundColor Color?, 
                    //foregroundColor: double?, 
                    elevation: 1.5,  
                    //shadowColor: Color?,  
                )
            ),
            debugShowCheckedModeBanner: false,
        );
    }
}



const Color grey_background = Color.fromRGBO(30, 30, 31, 0.9);
const Color blue = Color.fromRGBO(76,97,145, 0.9);



/*

this.debugShowMaterialGrid = false,
this.showPerformanceOverlay = false,
  



*/

