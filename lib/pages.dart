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

            }
    }

}





