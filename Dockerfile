FROM ubuntu@sha256:bcc511d82482900604524a8e8d64bf4c53b2461868dac55f4d04d660e61983cb

RUN apt -yq update && \
    apt -yqq install --no-install-recommends curl ca-certificates \
        build-essential pkg-config libssl-dev llvm-dev clang cmake rsync git unzip xz-utils zip libglu1-mesa

ENV FVM_DIR="$HOME/.fvm_flutter"
ENV FMV_DIR_BIN="$FVM_DIR/bin"
ENV FVM_VERSION=3.1.4
ENV FVM_DOWNLOAD_URL="https://github.com/leoafarias/fvm/releases/download/$FVM_VERSION/fvm-$FVM_VERSION-linux-x64.tar.gz"

RUN mkdir -p "$FVM_DIR" && \
    curl -L "$FVM_DOWNLOAD_URL" -o fvm.tar.gz && \
    tar xzf fvm.tar.gz -C "$FVM_DIR" && \
    rm -f fvm.tar.gz && \
    mv "$FVM_DIR/fvm" "$FMV_DIR_BIN"

ENV PATH=${PATH}:${FMV_DIR_BIN}


COPY . /cts-frontcode
WORKDIR /cts-frontcode

ENV TAR_OPTIONS=--no-same-owner
RUN fvm install
RUN bash scripts/flutter_build_web.sh