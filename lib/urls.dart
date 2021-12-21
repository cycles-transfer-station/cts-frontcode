import 'package:flutter/material.dart';

import 'pages.dart';



//:variables of the url-path are with the syntax: <variablename> with this set by this postmaster: Levi.
// make sure that the paths of a deep branch contain the urlvariables of the parent-paths. 
// path branches are: __

final Map<String, Map> urlmap = {
    'void': {
        'path': '/void',
        'page': VoidPage.create,
    },
    'welcome': {
        'path': '/welcome',
        'page': WelcomePage.create,
    },
    'welcome__buy_wallet': {
        'path': '/buy-wallet',
        'page': BuyWalletPage.create,
    },
};



class CustomUrl {
    final String name;
    final Map<String, String> variables;
    late final String string;

    CustomUrl(this.name, {this.variables = const {}}) {             // variables should contain each variable for the whole path
        String urlstring = urlmap[this.name]['path'];
        this.variables.forEach((key,value) => urlstring.replaceAll('<'+key+'>', value));
        this.string = urlstring;
    }

    Page get_page() => urlmap[this.name]['page'](key: ValueKey<String>(this.string));

    static CustomUrl outOfABrowserUrlString(String urlstring) {
        final Uri uriParseBrowserUrl = Uri.parse(urlstring);
        for (MapEntry map_entry in urlmap.entries) {
            Uri uriParseCustomUrlPath = Uri.parse(map_entry.value['path']);
            if (uriParseCustomUrlPath.pathSegments.length == uriParseBrowserUrl.pathSegments.length) {
                int samePathSegments = 0;
                Map<String,String> urlVariables = {};
                for (int i=0; i < uriParseCustomUrlPath.pathSegments.length; i++) {
                    if (uriParseCustomUrlPath.pathSegments[i] == uriParseBrowserUrl.pathSegments[i]) {
                        samePathSegments += 1;  
                    } else if (uriParseCustomUrlPath.pathSegments[i].startsWith('<')) { 
                        // validate the urlvariable if want
                        samePathSegments += 1;
                        urlVariables[uriParseCustomUrlPath.pathSegments[i].replaceFirst('<', '').replaceFirst('>','')] = uriParseBrowserUrl.pathSegments[i]; 
                    } else {
                        break; 
                    }
                }
                if (uriParseCustomUrlPath.pathSegments.length == samePathSegments) {
                    CustomUrl curl = CustomUrl(map_entry.key, variables: urlVariables);
                    assert(curl.string == urlstring);
                    return curl;
                }
            }
        } 
        return CustomUrl('void');
    }

    
}
