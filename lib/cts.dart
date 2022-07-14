import 'package:ic_tools/ic_tools.dart';



//final Canister cts = Canister(Principal('thp4z-laaaa-aaaam-qaaea-cai'));

/*TEST*/final Canister cts = Canister(Principal('bayhi-7yaaa-aaaai-qahca-cai'));

void main() {
    if (cts.principal.text != 'thp4z-laaaa-aaaam-qaaea-cai') {
        print('WARNING! Using the canister: ${cts.principal.text} as the CTS-MAIN. ');
    }
}




