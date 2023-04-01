import 'package:flutter/material.dart';

import 'pages.dart';
import '../transfer_icp/scaffold_body.dart';
import '../cycles_bank/scaffold_body.dart';
import '../cycles_market/scaffold_body.dart';
import '../welcome/scaffold_body.dart';
import '../about/scaffold_body.dart';
import '../feedback/scaffold_body.dart';
import '../business_tegrations/scaffold_body.dart';



//:variables of the url-path are with the syntax: <variablename>.
// make sure that the paths of a deep branch contain the urlvariables of the parent-paths. 
// path branches are: __
// one variable per pathsegment, make sure the variable is the last part of the pathsegment.

const String path_branches_separator = '__';


final Map<String, Map> urlmap = {
    'void': {
        'path': '/void',
        'page': VoidPage.create,
    },
    'welcome': {
        'path': '/',
        'page': MainPage.create,
        'main_page_scaffold_body': WelcomeScaffoldBody.create
    },
    'transfer_icp': {
        'path': '/transfer-icp',
        'page': MainPage.create,
        'main_page_scaffold_body': TransferIcpScaffoldBody.create
    },
    'cycles_bank': {
        'path': '/cycles-bank',
        'page': MainPage.create,
        'main_page_scaffold_body': CyclesBankScaffoldBody.create
    },
    'cycles_bank_pay': {
        'path': '/cycles-bank/pay/for=<for_the_cycles_bank>/Tcycles=<Tcycles>/memo_type=<memo_type>/memo=<memo>',
        'page': MainPage.create,
        'main_page_scaffold_body': CyclesBankScaffoldBody.create
    },
    'cycles_market': {
        'path': '/cycles-market',
        'page': MainPage.create,
        'main_page_scaffold_body': CyclesMarketScaffoldBody.create
    },
    'about': {
        'path': '/about',
        'page': MainPage.create,
        'main_page_scaffold_body': AboutScaffoldBody.create
    },
    'feedback': {
        'path': '/feedback',
        'page': MainPage.create,
        'main_page_scaffold_body': FeedbackScaffoldBody.create
    },
    'business_tegrations': {
        'path': '/business-integrations',
        'page': MainPage.create,
        'main_page_scaffold_body': BusinessTegrationsScaffoldBody.create
    },
};



class CustomUrl {
    final String name;
    final Map<String, String> variables;
    late final String string;

    CustomUrl(this.name, {this.variables = const {}}) {             // variables should contain each variable for the whole path
        String urlstring = urlmap[this.name]!['path']!;
        this.variables.forEach((key,value)=>urlstring = urlstring.replaceAll('<'+key+'>', value));
        this.string = urlstring;
    }

    Page get_page() {
        return urlmap[this.name]!['page']!(key: ValueKey('${urlmap[this.name]!['page']!.toString()} page' /*not this.string bc some different urls are with the same page widget.*/));
    }

    Widget? main_page_scaffold_body() {
        Widget Function({Key? key}) f = urlmap[this.name]!['main_page_scaffold_body'];
        if (f != null) {
            return f(key: ValueKey('${urlmap[this.name]!['main_page_scaffold_body']!.toString()} main_page_scaffold_body'));
        } else {
            return null;
        }
    }

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
                    } else if (uriParseCustomUrlPath.pathSegments[i].contains('<') && uriParseCustomUrlPath.pathSegments[i].contains('>')) { 
                        // validate the urlvariable if want
                        samePathSegments += 1;
                        //old impl where a variable must take up a whole pathsegment // urlVariables[uriParseCustomUrlPath.pathSegments[i].replaceFirst('<', '').replaceFirst('>','')] = uriParseBrowserUrl.pathSegments[i]; 
                        // new impl where a variable can be in the last part of a pathsegment without taking up the whole pathsegment
                        String custom_url_path_segment = uriParseCustomUrlPath.pathSegments[i];
                        String key = custom_url_path_segment.substring(
                            custom_url_path_segment.indexOf('<')+1, 
                            custom_url_path_segment.indexOf('>')
                        );
                        String value = uriParseBrowserUrl.pathSegments[i].substring(custom_url_path_segment.indexOf('<'));
                        urlVariables[key] = value;                                                
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
