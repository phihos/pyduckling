ARG GHC_VERSION
ARG ALPINE_VERSION

FROM alpine:${ALPINE_VERSION}

ARG GHC_VERSION

RUN apk add --no-cache \
    bash \
    build-base \
    bzip2 \
    bzip2-dev \
    curl \
    git \
    gmp-dev \
    libffi-dev \
    ncurses-dev \
    ncurses-static \
    openssl-dev \
    pcre \
    pcre-dev \
    perl \
    xz \
    zlib \
    zlib-dev \
    zlib-static

# Install GHC from pre-built Alpine native bindist (already PIC-compiled)
RUN cd /tmp \
  && curl -sSLO "https://downloads.haskell.org/~ghc/$GHC_VERSION/ghc-$GHC_VERSION-x86_64-alpine3.12-linux-native.tar.xz" \
  && tar xf "ghc-$GHC_VERSION-x86_64-alpine3.12-linux-native.tar.xz" \
  && cd ghc-$GHC_VERSION-x86_64-unknown-linux \
  && ./configure --prefix=/usr \
  && make install \
  && rm -rf /tmp/*

RUN curl -sSL https://get.haskellstack.org/ | sh
