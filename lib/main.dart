import 'package:flutter/material.dart';
import 'router.dart';




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
            title: ':C.-T.-S.',
            theme: ThemeData(
                brightness: Brightness.dark,
                backgroundColor: const Color.fromRGBO(30, 30, 31, 0.9), //Colors.blueGrey
                fontFamily: 'AxaxaxBold',
                //typography: Typography.material2018(platform: platform)
                appBarTheme: AppBarTheme(
                    color: const Color.fromRGBO(76,97,145, 0.9), 
                    //backgroundColor Color?, 
                    //foregroundColor: double?, 
                    elevation: 1.5,  
                    //shadowColor: Color?,  
                )
            )
        );
    }
}


/*

this.debugShowMaterialGrid = false,
this.showPerformanceOverlay = false,
  



*/

