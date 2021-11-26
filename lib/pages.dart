import 'state_bind.dart';


class WelcomePage extends Page {
    WelcomePage({Key? key}) : super(key: key);
    static WelcomePage create({Key? key}) => WelcomePage(key: key);

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
            child: Text('buy this wallet')
            onPressed: () {
                CustomState state = MainStateBind<CustomState>.get_state(context);
                state.move_url(CustomUrl(name: 'buy_wallet'));
                MainStateBind<CustomState>.set_state(state, tifyListeners: true);
            }
        );
    }
}



class BuyWalletPage extends Page {
    BuyWalletPage({Key? key}) : super(key: key);
    static BuyWalletPage create({Key? key}) => BuyWalletPage(key: key);

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
    State<StatefulWidget> createState => _BuyWalletPageWidgetState();
}
class _BuyWalletPageWidgetState extends State<StatefulWidget> {


    @override
    Widget build(BuildContext context) {
        return ElevatedButton(
            child: Text('buy wallet now')
            onPressed: () {
                print('buying wallet ....');
            }
        );
    }
}


