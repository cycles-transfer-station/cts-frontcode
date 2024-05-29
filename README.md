# CTS-FRONTCODE

## This repo contains the code of the CYCLES-TRANSFER-STATION frontend website.

### Build Verification
The build aims to be reproducible on Ubuntu Linux.

The reproducibility and verifiability of the frontend files is as follows. We calculate a batch-hash which is a single hash of all the frontend files.
The batch-hash is the [representation-independent-hash](https://internetcomputer.org/docs/current/references/ic-interface-spec/#hash-of-map) of a map with the map-keys as the file-paths and with the map-values as the gzip-encoding of the files. The file-paths start from the build output directory `build/web`. The file-path map-key for `build/web/main.dart.js` is `/main.dart.js`. One file gets renamed for the hash and for the upload and that is the `index.html` file which file-path map-key is `/`. The calculation of the batch-hash from the build output files is done in the `scripts/batch_hash.dart` file for reference.

The build command when done will print out the batch-hash of the files, look in one of the last 20 or so output lines for the output line:  
`batch_hash: <the batch-hash will be here>`

 The batch-hash can then be verified to match the batch-hash in the proposal. The current-batch for the current-proposal can be viewed using the [`view_current_batch_hash`](https://dashboard.internetcomputer.org/canister/em3jm-bqaaa-aaaar-qabxa-cai#view_current_batch_hash) query method on the CTS frontcode canister.

The live batch-hash of the files currently being served from the frontend canister (in contrast with the batch that is up for proposal but not yet being served) can be viewed using the [`view_live_files_hash`](https://dashboard.internetcomputer.org/canister/em3jm-bqaaa-aaaar-qabxa-cai#view_live_files_hash) query method on the CTS frontcode canister.

The CTS frontend canister code can be found in the main cts repo: https://github.com/cycles-transfer-station/cts.

The following command builds the frontend, prints the batch-hash, and outputs the frontend files into the `build/web` directory.

> `bash scripts/podman_build.sh`
