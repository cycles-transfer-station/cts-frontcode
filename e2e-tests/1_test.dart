import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'dart:async';

import 'package:ic_tools/ic_tools.dart';



import 'package:cts_frontcode/main.dart' as app;
import 'package:cts_frontcode/tools/widgets.dart' show OutlineButtonIILoginState; 
import 'package:cts_frontcode/cycles_bank/create_bank.dart' show CreateMembershipButton, CreateMembershipButtonState;


void main() {
    final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized() as IntegrationTestWidgetsFlutterBinding;
    
    testWidgets('verify home',
        (tester) async {
            app.main();          
            
            await tester.pumpAndSettle();
            
            print('finding loading');
            expect(find.text('loading ...'), findsOneWidget);
            
            await tester.state<app.BaseState>(find.byType(app.Base)).route_legate.loadfirststatefuture;
            
            await tester.pumpAndSettle();
            
            print('finding website title');
            expect(find.text(':CYCLES-TRANSFER-STATION.'), findsOneWidget);
            
            print('clicking navigation menu');
            final navigation_button = find.widgetWithIcon(IconButton, Icons.menu); 
            await tester.tap(navigation_button);
            await tester.pumpAndSettle();
                        
            print('verifying drawer buttons');
            for (String s in ['HOME', 'BANK', 'MARKET', 'ABOUT']) {
                expect(find.text(s), findsOneWidget);
            } 
            
            await tester.tap(find.text('BANK'));
            await tester.pumpAndSettle();
            
            print('finding ii-login-button');
            Finder cb_scaffold_body_ii_login_button = find.byKey(ValueKey('cb-scaffold_body-ii-login-button'));
            await tester.tap(cb_scaffold_body_ii_login_button);
            
            Future ii_login_future = tester.state<OutlineButtonIILoginState>(cb_scaffold_body_ii_login_button).ii_login_future!;
            
            await tester.pumpAndSettle();
            expect(find.text('ii login ...'), findsOneWidget);
            
            print('awaiting ii-login');
            await ii_login_future;
            await tester.pumpAndSettle();
            
            print('drag until visible create membership');
            Finder create_membership_button_finder = find.byType(CreateMembershipButton); 
            await tester.dragUntilVisible(
                create_membership_button_finder,
                find.byKey(ValueKey('cycles_bank scaffold_body main-list-view')), 
                const Offset(0, 50), // delta to move
            );
            expect(create_membership_button_finder, findsOneWidget);
            
            await tester.tap(create_membership_button_finder);
            
            CreateMembershipButtonState create_membership_button_state = tester.state<CreateMembershipButtonState>(create_membership_button_finder); 
            Future create_membership_future = create_membership_button_state.create_membership_future!;
            Future purchase_cycles_bank_future = create_membership_button_state.purchase_cycles_bank_future!;
            
            await tester.pumpAndSettle();
            expect(find.text('creating membership ...'), findsOneWidget);
                        
            print('awaiting purchase_cycles_bank_future');
            await purchase_cycles_bank_future;
            await tester.pumpAndSettle();
            
            expect(find.byType(AlertDialog), findsOneWidget);
            expect(find.text('Create membership success:'), findsOneWidget);
            Finder bank_id_text_widget = find.textContaining('Bank id:'); 
            expect(bank_id_text_widget, findsOneWidget);
            
            Principal bank_id = Principal.text((bank_id_text_widget.evaluate().first.widget as Text).data!.replaceFirst('Bank id: ', ''));
            
            await tester.tap(find.text('OK'));
            await tester.pumpAndSettle();
            
            await create_membership_future;
            await tester.pumpAndSettle();
            
            expect(find.text('CYCLES-BANK'), findsOneWidget);
            expect(find.text(bank_id.text), findsOneWidget);
            
            
            
            
            // mint cycles
            
            // transfer cycles
            
            // transfer icp
            
            // verify transfer amounts.
                       
            
            
            
            await Future.delayed(Duration(seconds:13));           
            
        }
    );
}
