set -euxo pipefail

fvm flutter build web --release --web-renderer=canvaskit --pwa-strategy=none --dart-define=FLUTTER_WEB_CANVASKIT_URL=/canvaskit/ --csp --no-web-resources-cdn --no-frequency-based-minification

fvm dart scripts/post_flutter_build.dart

fvm dart scripts/batch_hash.dart