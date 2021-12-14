import 'package:flutter/material.dart';
import 'urls.dart';


class CustomState with ChangeNotifier { // do i want change notifier here?

    CustomUrl current_url = CustomUrl('welcome');







    Future<void> loadfirststate() {
        await Future.delayed(Duration(seconds: 5));
        
    }

    void save_in_localstorage() {
        
    }

    
}








