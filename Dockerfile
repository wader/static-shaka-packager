# bump: alpine /FROM alpine:([\d.]+)/ docker:alpine|^3
FROM alpine:3.15.4 AS builder
RUN \
    apk add --no-cache \
    bash \
    build-base \
    findutils \
    curl \
    git \
    ninja \
    python2 \
    python3 \
    py3-httplib2 \
    py3-parsing \
    py3-six \
    bsd-compat-headers \
    linux-headers \
    libexecinfo-dev \
    c-ares-dev \
    c-ares-static

# bump: shaka-packager /SHAKA_PACKAGER_VERSION=([\d.]+)/ git:https://github.com/google/shaka-packager.git|^2
ARG SHAKA_PACKAGER_VERSION=2.6.1
ARG DEPOT_TOOLS_VERSION=053a717f0231866f372cbb6b226d867c278b1cf0
# use system python as bundled python does not work on alpine
ARG DEPOT_TOOLS_BOOTSTRAP_PYTHON3=0
ARG GCLIENT_PY3=1

# install depot_tools http://www.chromium.org/developers/how-tos/install-depot-tools
RUN \
    git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git && \
    cd /depot_tools && \
    git checkout $DEPOT_TOOLS_VERSION
# depot_tools path last so that alpine ninjs is used (depot_tools ninja does not run on alpine atm)
ARG PATH=$PATH:/depot_tools

RUN sed -i \
    '/malloc_usable_size/a \\nstruct mallinfo {\n  int arena;\n  int hblkhd;\n  int uordblks;\n};' \
    /usr/include/malloc.h

# gpy ninja generator will look at these
ARG CFLAGS="-O3 -static-libgcc -fno-strict-overflow -fstack-protector-all -fPIE"
ARG CXXFLAGS="-O3 -static-libgcc -fno-strict-overflow -fstack-protector-all -fPIE"
ARG LDFLAGS="-static -Wl,-z,relro -Wl,-z,now"
# alpine specific config
# from https://github.com/google/shaka-packager/blob/master/Dockerfile
ARG GYP_DEFINES="clang=0 use_experimental_allocator_shim=0 use_allocator=none musl=1"
ARG VPYTHON_BYPASS="manually managed python not supported by chrome operations"

WORKDIR /shaka_packager
RUN gclient config https://www.github.com/google/shaka-packager.git --name=src
RUN gclient sync -r v$SHAKA_PACKAGER_VERSION --no-history
RUN ninja -C src/out/Release

FROM scratch
COPY --from=builder /shaka_packager/src/out/Release/packager /
# sanity test that the binary work in scratch container
RUN ["/packager"]
ENTRYPOINT ["/packager"]
