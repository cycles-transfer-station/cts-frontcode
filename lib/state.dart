import 'package:flutter/material.dart';
import 'urls.dart';


class CustomState with ChangeNotifier { // do i want change notifier here?

    List<CustomUrl> url_branch_levels = [ CustomUrl(name: 'welcome') ];

    void move_url(CustomUrl new_url) {
        this.url_branch_levels = getbranchlevels(new_url.name, urlmap).map<CustomUrl>((String urlname)=>CustomUrl(name: urlname, variables: new_url.variables)); 
    }
    CustomUrl get current_url => this.url_branch_levels.last;










    Map get map => {
        'url_branch_levels_strings': url_branch_levels.map<String>((customurl)=>custom_url.string).toList()..,     
    };

    set map(Map session_map) { 
        this.url_branch_levels = session_map['url_branch_levels_strings'].map<CustomUrl>( (String urlstring) => CustomUrl.ofaurlstring(urlstring) ).toList(); 

    }
}








