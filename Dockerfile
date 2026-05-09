# ---------- BUILD STAGE ----------
    FROM ubuntu:22.04 AS build-env

    ENV DEBIAN_FRONTEND=noninteractive
    ENV FLUTTER_HOME=/usr/local/flutter
    ENV PATH=$FLUTTER_HOME/bin:$FLUTTER_HOME/bin/cache/dart-sdk/bin:$PATH
    ENV CI=true
    ENV PUB_CACHE=/root/.pub-cache
    
    RUN apt-get update && apt-get install -y \
        curl git unzip xz-utils zip libglu1-mesa ca-certificates \
        && update-ca-certificates \
        && rm -rf /var/lib/apt/lists/*
    
    # Use stable channel to get latest Dart SDK (satisfies ^3.9.2)
    RUN git clone https://github.com/flutter/flutter.git \
        --branch master \
        --depth 1 \
        $FLUTTER_HOME
    
    RUN flutter precache --web
    RUN flutter config --no-analytics && flutter config --enable-web
    
    WORKDIR /app
    COPY pubspec.yaml pubspec.lock* ./
    RUN flutter pub get
    
    COPY . .
    RUN flutter build web --release
    
    # ---------- RUNTIME STAGE ----------
    FROM python:3.11-alpine
    
    COPY --from=build-env /app/build/web /app
    
    WORKDIR /app
    
    EXPOSE 8080
    
    CMD ["sh", "-c", "python -m http.server ${PORT:-8080}"]