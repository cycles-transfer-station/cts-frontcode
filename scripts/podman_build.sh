SCRIPTS_DIR=$(readlink -f $(dirname ${0}))
cd $SCRIPTS_DIR/..

BUILD_DIR=build/web
rm -rf $BUILD_DIR

podman build --no-cache -t cts-frontcode .

container_id=$(podman create cts-frontcode)
podman cp $container_id:/cts-frontcode/$BUILD_DIR $BUILD_DIR
podman rm --volumes $container_id

for f in `find $BUILD_DIR -name '*'`
do
    if ! [ -d "$f" ]
    then
        sha256sum $f
    fi
done