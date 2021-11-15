import 'package:flutter/material.dart';
import 'urls.dart';


class CustomState with ChangeNotifier { // do i want change notifier here?

    List<CustomUrl> url_branch_levels = [ CustomUrl(name: 'welcome') ];

    void move_url_branch(CustomUrl new_url) {
        List<Strings> url_branch_levels_strings = this.url_branch_levels.map<String>((CustomUrl url)=>url.string).toList()..;
        if (url_branch_levels_strings.contains(new_url.string)) {
            this.url_branch_levels = this.url_branch_levels.take(url_branch_levels_strings.indexOf(new_url.string)+1).toList()..;
        } else {
            List<String> branch_levels_names = getbranchlevels(new_url.name, urlmap);
            this.url_branch_levels = List.generate(branch_levels_names.length, (i) {
                if (i==branch_levels_names.length-1) {
                    return new_url;
                } else {
                    return CustomUrl(name: branch_levels_names[i], variables: new_url.variables);
                }
            });
        }
    }











    Map get map => {
        'url_branch_levels_strings': url_branch_levels.map<String>((customurl)=>custom_url.string).toList()..,     
    };

    set map(Map session_map) { 
        this.url_branch_levels = session_map['url_branch_levels_strings'].map<CustomUrl>( (String urlstring) => CustomUrl.ofaurlstring(urlstring) ).toList(); 

    }
}








