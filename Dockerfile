FROM ubuntu:22.04 AS build-env

ENV DEBIAN_FRONTEND=noninteractive
ENV FLUTTER_HOME=/usr/local/flutter
ENV PATH=$FLUTTER_HOME/bin:$FLUTTER_HOME/bin/cache/dart-sdk/bin:$PATH
ENV CI=true
ENV PUB_CACHE=/root/.pub-cache

# --- system deps (IMPORTANT: ca-certificates fixed networking issues) ---
RUN apt-get update && apt-get install -y \
    curl git unzip xz-utils zip libglu1-mesa ca-certificates \
    && update-ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# --- Flutter install ---
RUN git clone https://github.com/flutter/flutter.git \
    --branch 3.35.4 \
    --depth 1 \
    $FLUTTER_HOME

# --- pre-warm flutter (avoid partial cache issues) ---
RUN flutter config --no-analytics
RUN flutter config --enable-web

# Force flutter to initialize cache directories
RUN flutter precache --web

WORKDIR /app

COPY pubspec.* ./

# --- retry-safe pub get ---
RUN flutter pub get -v || \
    (echo "PUB GET FAILED - NETWORK ISSUE LIKELY" && sleep 3600 && exit 1)

COPY . .

RUN flutter build web --release -v || \
    (echo "BUILD FAILED" && sleep 3600 && exit 1)

# --- nginx ---
FROM nginx:alpine

COPY --from=build-env /app/build/web /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]