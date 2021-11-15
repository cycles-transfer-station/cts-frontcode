import 'pages.dart';

//:variables of the url-path are with the syntax: <variablename> with this set by this postmaster: Levi.
// make sure that the paths of a deep branch contain the urlvariables of the parent-paths. (automate that by cluding parent paths before the child paths??)

final Map<String, Map> urlmap = {
    'void': {
        'path': '/void',
        'page': VoidPage.create,
    },
    'welcome': {
        'path': '/welcome',
        'create_page': WelcomePage.create,
        'branches': {
            'buy_wallet': {
                'path': '/buy-wallet',
                'create_page': BuyWalletPage.create,

            }
        }
    },
};


List<String>? getbranchlevels(String urlname, Map branches, [ List<String> current_branch_level = const [] ]) {
    List<String>? branch_levels;
    if (branches.containsKey(urlname)) {
        branch_levels = current_branch_level + [ urlname ];
    } else {
        for (MapEntry branch in branches.entries) {
            if (!(branch.value.containsKey('branches'))) { continue; }  
            branch_levels = getbranchlevels(urlname, branch.value['branches'], current_branch_level + [ branch.key ]);
            if (branch_levels != null) {
                // return branch_levels;
                break;
            }
        }
    }   
    return branch_levels;
}



class CustomUrl {
    String name;
    Map<String, String> variables;
    String string;
    CustomUrl(this.name, [this.variables = const {}]) {

    }

    
}
