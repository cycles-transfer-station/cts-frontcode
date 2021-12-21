import 'package:flutter/material.dart';

import 'urls.dart';
import 'state.dart';
import 'state_bind.dart';



class VoidPage {
    static create({LocalKey? key}) => MaterialPage(key: key, child: VoidPageWidget());
}
class VoidPageWidget extends StatelessWidget {
    Widget build(BuildContext context) {
        return Text('The page is not found');
    }
}



class WelcomePage extends Page {
    WelcomePage({LocalKey? key}) : super(key: key);
    static WelcomePage create({LocalKey? key}) => WelcomePage(key: key);

    Route createRoute(BuildContext context) {
        return PageRouteBuilder(
            settings: this,
            pageBuilder: (context, animation, animation2) {
                final tween = Tween(begin: Offset(0.0, 1.0), end: Offset.zero);
                final curveTween = CurveTween(curve: Curves.easeInOut);
                return SlideTransition(
                    position: animation.drive(curveTween).drive(tween),
                    child: WelcomePageWidget()
                );
            }
        );
    }
}
class WelcomePageWidget extends StatelessWidget {
    const WelcomePageWidget({Key? key}) : super(key: key);

    @override
    Widget build(BuildContext context) {
        return ElevatedButton(
            child: Text('buy this wallet'),
            onPressed: () {
                CustomState state = MainStateBind.get_state<CustomState>(context);
                state.current_url = CustomUrl('buy_wallet');
                MainStateBind.set_state<CustomState>(context, state, tifyListeners: true);
            }
        );
    }
}



class BuyWalletPage extends Page {
    BuyWalletPage({LocalKey? key}) : super(key: key);
    static BuyWalletPage create({LocalKey? key}) => BuyWalletPage(key: key);

    Route createRoute(BuildContext context) {
        return PageRouteBuilder(
            settings: this,
            pageBuilder: (context, animation, animation2) {
                final tween = Tween(begin: Offset(0.0, 1.0), end: Offset.zero);
                final curveTween = CurveTween(curve: Curves.easeInOut);
                return SlideTransition(
                    position: animation.drive(curveTween).drive(tween),
                    child: BuyWalletPageWidget()
                );
            }
        );
    }
}
class BuyWalletPageWidget extends StatefulWidget {
    BuyWalletPageWidget({Key? key}) : super(key: key);
    State<StatefulWidget> createState() => _BuyWalletPageWidgetState();
}
class _BuyWalletPageWidgetState extends State<StatefulWidget> {


    @override
    Widget build(BuildContext context) {
        return Column(
            children: [
                ElevatedButton(
                    child: Text('buy wallet now'),
                    onPressed: () {
                        print('buying wallet ....');
                    }
                ),
                ElevatedButton(
                    child: Text('back'),
                    onPressed: () {
                        Navigator.pop(context);
                    }
                ),
            ]
        );
    }
}


