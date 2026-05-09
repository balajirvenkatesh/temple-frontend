# ---------- BUILD STAGE ----------
    FROM ubuntu:22.04 AS build-env

    ENV DEBIAN_FRONTEND=noninteractive
    ENV FLUTTER_HOME=/usr/local/flutter
    ENV PATH=$FLUTTER_HOME/bin:$FLUTTER_HOME/bin/cache/dart-sdk/bin:$PATH
    ENV CI=true
    ENV PUB_CACHE=/root/.pub-cache
    
    # System dependencies (important for HTTPS + extraction tools)
    RUN apt-get update && apt-get install -y \
        curl git unzip xz-utils zip libglu1-mesa ca-certificates \
        && update-ca-certificates \
        && rm -rf /var/lib/apt/lists/*
    
    # Install Flutter SDK
    RUN git clone https://github.com/flutter/flutter.git \
        --branch 3.35.4 \
        --depth 1 \
        $FLUTTER_HOME
    
    # Flutter config (minimal + safe)
    RUN flutter config --no-analytics
    RUN flutter config --enable-web
    
    WORKDIR /app
    
    # Copy dependency files first (better Docker caching)
    COPY pubspec.yaml pubspec.lock ./
    
    # Fetch dependencies (fail fast, no hiding errors)
    RUN flutter pub get -v
    
    # Copy full source
    COPY . .
    
    # Build web release
    RUN flutter build web --release -v
    
    
    # ---------- RUNTIME STAGE ----------
    FROM nginx:alpine
    
    # Copy build output
    COPY --from=build-env /app/build/web /usr/share/nginx/html
    
    EXPOSE 80
    
    CMD ["nginx", "-g", "daemon off;"]