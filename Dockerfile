FROM ubuntu:22.04 AS build-env

ENV DEBIAN_FRONTEND=noninteractive
ENV FLUTTER_HOME=/usr/local/flutter
ENV PATH=$FLUTTER_HOME/bin:$FLUTTER_HOME/bin/cache/dart-sdk/bin:$PATH
ENV CI=true

# System dependencies + CA certs (critical for downloads)
RUN apt-get update && apt-get install -y \
    curl git unzip xz-utils zip libglu1-mesa ca-certificates \
    && update-ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Clone Flutter
RUN git clone https://github.com/flutter/flutter.git \
    --branch 3.35.4 \
    --depth 1 \
    $FLUTTER_HOME

# Minimal config only (NO precache)
RUN flutter config --no-analytics
RUN flutter config --enable-web

WORKDIR /app

# Copy dependency files first
COPY pubspec.* ./

# Safe dependency resolution
RUN flutter pub get -v || \
    (echo "❌ PUB GET FAILED (NETWORK ISSUE)" && sleep 3600 && exit 1)

# Copy full project
COPY . .

# Build only (Flutter will lazily fetch what it needs)
RUN flutter build web --release -v || \
    (echo "❌ BUILD FAILED" && sleep 3600 && exit 1)

# NGINX
FROM nginx:alpine

COPY --from=build-env /app/build/web /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]