# ---------- BUILD STAGE ----------
    FROM debian:bookworm-slim AS build-env

    ENV DEBIAN_FRONTEND=noninteractive
    ENV FLUTTER_HOME=/usr/local/flutter
    ENV PATH=$FLUTTER_HOME/bin:$FLUTTER_HOME/bin/cache/dart-sdk/bin:$PATH
    ENV CI=true
    ENV PUB_CACHE=/root/.pub-cache
    ENV FLUTTER_SUPPRESS_ANALYTICS=true
    
    RUN apt-get update && apt-get install -y --no-install-recommends \
        curl git unzip xz-utils zip ca-certificates \
        && update-ca-certificates \
        && rm -rf /var/lib/apt/lists/*
    
    RUN git clone https://github.com/flutter/flutter.git \
        --branch stable \
        --depth 1 \
        $FLUTTER_HOME
    
    # Configure first, then precache only web artifacts
    RUN flutter config --no-analytics && \
        flutter config --enable-web
    
    # Precache only web — split from config to isolate errors
    RUN flutter precache --web
    
    WORKDIR /app
    COPY pubspec.yaml pubspec.lock* ./
    RUN flutter pub get
    
    COPY . .
    RUN flutter build web --release --no-tree-shake-icons
    
    # ---------- RUNTIME STAGE ----------
    FROM python:3.11-alpine
    
    COPY --from=build-env /app/build/web /app
    WORKDIR /app
    
    EXPOSE 8080
    CMD ["sh", "-c", "python -m http.server ${PORT:-8080}"]