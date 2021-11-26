import 'pages.dart';

//:variables of the url-path are with the syntax: <variablename> with this set by this postmaster: Levi.
// make sure that the paths of a deep branch contain the urlvariables of the parent-paths. (automate that by cluding parent paths before the child paths??)
// in the now, paths dont add onto the path of their parents

final Map<String, Map> urlmap = {
    'void': {
        'path': '/void',
        'page': VoidPage.create,
    },
    'welcome': {
        'path': '/welcome',
        'page': WelcomePage.create,
        'branches': {
            'buy_wallet': {
                'path': '/buy-wallet',
                'page': BuyWalletPage.create,

            }
        }
    },
};


typedef BranchLevels = List<String>;
typedef Branch = Tuple2<BranchLevels, Map>;             // Map is a map with a possible-key: 'branches'


Branch? getbranch_ofthekey(String keyname, Map branches, [ List<String> current_branch_level = const [] ]) {
    if (branches.containsKey(keyname)) {
        return Tuple2(current_branch_level + [ keyname ], branches[keyname]);
    } 
    for (MapEntry branch in branches.entries) {
        if (branch.value.containsKey('branches')) { 
            Branch? branch_levels = getbranch_ofthekey(keyname, branch.value['branches'], current_branch_level + [ branch.key ]);
            if (branch_levels != null) return branch_levels;
        }  
    }
}

Branch? getbranch_ofthemapkeyvalue(String valuemapkey, bool Function(dynamic valuemapkeyvalue) isvaluematch , Map branches, [ List<String> current_branch_level = const [] ]) {
    for (MapEntry mapitem in branches.entries) {
        List<String> branch_level = current_branch_level + [ mapitem.key ];
        if (mapitem.value.containsKey(valuemapkey) && isvaluematch(mapitem.value[valuemapkey])) {
            return Tuple2(branch_level, mapitem.value);
        }
        if (mapitem.value.containsKey('branches')) {
            Branch? circles = getbranch_ofthemapkeyvalue(valuemapkey, isvaluematch, mapitem.value['branches'], branch_level);
            if (circles != null) return circles;
        }
    }
}    
    

Map get_url_map(String urlname) => getbranch_ofthekey(urlname, urlmap).item2;





class CustomUrl {
    final String name;
    final Map<String, String> variables;
    late final String string;
    CustomUrl(this.name, {this.variables = const {}}) { // variables should contain each variable for the whole path
        String urlstring = get_url_map(this.name)['path'];
        this.variables.forEach((key,value){
            urlstring.replace('<'+key+'>', value); // replaceAll if url-variable is ever used more than once
        })
        this.string = urlstring;
    }

    Page get_page() => get_url_map(this.name)['page'](key: ValueKey<String>(this.string));

    static CustomUrl outOfABrowserUrlString(String urlstring) {
        CustomUrl? curl;
        // if (urlstring!=null) {
            



        // }
        
    }
    
}
