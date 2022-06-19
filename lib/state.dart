import 'dart:html';

import 'package:ic_tools/ic_tools.dart';
import 'package:flutter/material.dart';

import 'urls.dart';




class CustomState { // with ChangeNotifier  // do i want change notifier here?

    CustomUrl current_url = CustomUrl('welcome');
    
    Principal? user_principal; 






    Future<void> loadfirststate() async {
        //await Future.delayed(Duration(seconds: 5));
        
        
    }

    void save_in_localstorage() {
        
    }

    
}








