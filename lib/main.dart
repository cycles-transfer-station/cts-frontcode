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
                //brightness: Brightness.dark,
                colorScheme: ColorScheme.fromSeed(
                      seedColor: blue,
                      brightness: Brightness.dark,
                ).copyWith(
                    background: grey_background, //Color(0xFF726f8c), // 1e202a // 353844 // 757b8f
                ),
                fontFamily: 'AxaxaxBold',
                appBarTheme: AppBarTheme(
                    color: blue,
                    elevation: 1.0,
                ),
                useMaterial3: true,
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
const Color purple = Color(0xFF2a254b); // 26365b // 27375c // 42456d


// when seed-color = FF2a254b, then #1c1b20 is the color of the card

