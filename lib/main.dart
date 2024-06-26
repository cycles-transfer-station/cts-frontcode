import 'package:flutter/material.dart';
import 'config/router.dart';




void main() {
    runApp(const Base(key: ValueKey('Base')));
}


class Base extends StatefulWidget {
    const Base({Key? key}) : super(key: key);
    BaseState createState() => BaseState(); }
class BaseState extends State<Base> {
    CustomRouteParser route_parser = CustomRouteParser();
    CustomRouteLegate route_legate = CustomRouteLegate();
    @override
    Widget build(BuildContext context) {
        return MaterialApp.router(
            routeInformationParser : route_parser,
            routerDelegate         : route_legate,
            backButtonDispatcher   : RootBackButtonDispatcher(),
            title: 'CTS',//':C.-T.-S.',
            theme: ThemeData(
                brightness: Brightness.dark,
                //backgroundColor: grey_background, // old deprecated field
                //colorScheme: ColorScheme.fromSeed(
                //      seedColor: blue,
                //      brightness: Brightness.dark,
                //    surface: grey_background,
                //), 
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
                ),
                useMaterial3: false,
                inputDecorationTheme: InputDecorationTheme(
                    labelStyle: TextStyle(fontFamily: 'CourierNew'),
                    errorMaxLines: 5,
                ),
                textTheme: TextTheme(
                    titleMedium: TextStyle(fontFamily: 'CourierNew'), // setting the font for the TextFormField input text.
                ),
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

