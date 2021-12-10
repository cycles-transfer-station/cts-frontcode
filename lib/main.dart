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
        return SafeArea(
            minimum: EdgeInsets.symmetric(), 
            child: Material(
                color: const Color(0x303747), 
                child: MaterialApp.router(
                    title: 'FOR THE CYCLES-TRANSFER-STATION.',
                    routeInformationParser : _routeParser,
                    routerDelegate         : _routeLegate
                )
            )
        );
    }
}




