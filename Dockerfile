# ---------- STAGE 1: BUILD ----------
    FROM ubuntu:22.04 AS build-env

    ENV DEBIAN_FRONTEND=noninteractive
    ENV FLUTTER_HOME=/usr/local/flutter
    ENV PATH=$FLUTTER_HOME/bin:$FLUTTER_HOME/bin/cache/dart-sdk/bin:$PATH
    ENV CI=true
    
    # System dependencies
    RUN apt-get update && apt-get install -y \
        curl git unzip xz-utils zip libglu1-mesa ca-certificates \
        && rm -rf /var/lib/apt/lists/*
    
    # Clone Flutter SDK
    RUN git clone https://github.com/flutter/flutter.git \
        --branch 3.35.4 \
        --depth 1 \
        $FLUTTER_HOME
    
    # Flutter setup
    RUN flutter config --no-analytics
    RUN flutter config --enable-web
    RUN flutter --version
    
    WORKDIR /app
    
    # Copy ONLY pub files first (better dependency isolation)
    COPY pubspec.* ./
    
    # FORCE FULL LOG OUTPUT FOR DEBUGGING
    RUN flutter pub get -v || (echo "❌ PUB GET FAILED" && sleep 3600 && exit 1)
    
    # Copy full project
    COPY . .
    
    # FORCE FULL BUILD LOG OUTPUT
    RUN flutter build web --release -v || (echo "❌ BUILD FAILED" && sleep 3600 && exit 1)
    
    # ---------- STAGE 2: NGINX ----------
    FROM nginx:alpine
    
    COPY --from=build-env /app/build/web /usr/share/nginx/html
    
    EXPOSE 80
    
    CMD ["nginx", "-g", "daemon off;"]