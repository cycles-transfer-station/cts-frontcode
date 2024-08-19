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
            title: 'CTS',
            theme: ThemeData(
                //brightness: Brightness.dark,
                colorScheme: ColorScheme.fromSeed(
                    seedColor: good_light_blue_color,
                    brightness: Brightness.dark,
                ).copyWith(
                    background: grey_background, //Color(0xFF726f8c), // 1e202a // 353844 // 757b8f
                    secondaryContainer: good_light_green_color,
                ),
                fontFamily: 'AxaxaxBold',
                appBarTheme: AppBarTheme(
                    color: good_light_blue_color,//blue,
                    elevation: 1.5,
                    surfaceTintColor: Colors.transparent,
                    shadowColor: Theme.of(context).colorScheme.shadow,
                ),
                bottomAppBarTheme: BottomAppBarTheme(
                    elevation: 0.5,
                    //color: grey_background,
                    surfaceTintColor: Colors.transparent,
                    shadowColor: Theme.of(context).colorScheme.shadow,
                ),
                filledButtonTheme: const FilledButtonThemeData(
                    style: ButtonStyle(
                        backgroundColor: WidgetStatePropertyAll(good_light_green_color),
                    )
                ),
                outlinedButtonTheme: const OutlinedButtonThemeData(
                    style: ButtonStyle(

                    )
                ),
                useMaterial3: true,
                inputDecorationTheme: const InputDecorationTheme(
                    labelStyle: TextStyle(fontFamily: 'CourierNew'),
                    errorMaxLines: 5,
                ),
                textTheme: const TextTheme(
                    titleMedium: TextStyle(fontFamily: 'CourierNew'), // setting the font for the TextFormField input text.
                ),
                cardTheme: const CardTheme(
                //    color: grey_background, //Color(0xFF2b2b3b), //Color(0xFF334550),//Color(0xFF3B4A6B),
                    elevation: 1
                ),
                navigationDrawerTheme: const NavigationDrawerThemeData(
                     backgroundColor: grey_background,
                     //indicatorColor: good_light_blue_color,
                ),
                listTileTheme: const ListTileThemeData(
                    // for the drawer list tiles
                    //selectedColor: good_light_blue_color,
                ),
            ),
            debugShowCheckedModeBanner: false,
        );
    }
}



const Color grey_background = Color(0xFF22242a);//Color.fromRGBO(30, 30, 31, 1/*0.9*/);
const Color blue = Color(0xFF2A3854);//FF3B4A6B);//Color.fromRGBO(76,97,145, 1);
const Color purple = Color(0xFF2a254b); // 26365b // 27375c // 42456d

const Color good_light_blue_color = Color(0xFF3B4A6B);
const Color good_light_green_color = Color(0xFF334550);

// when seed-color = FF2a254b, then #1c1b20 is the color of the card

