# ---------- STAGE 1: BUILD ----------
    FROM ubuntu:22.04 AS build-env

    ENV DEBIAN_FRONTEND=noninteractive
    ENV FLUTTER_HOME=/usr/local/flutter
    ENV PATH=$FLUTTER_HOME/bin:$FLUTTER_HOME/bin/cache/dart-sdk/bin:$PATH
    
    # Install dependencies
    RUN apt-get update && apt-get install -y \
        curl git unzip xz-utils zip \
        libglu1-mesa \
        clang cmake ninja-build pkg-config \
        ca-certificates \
        && rm -rf /var/lib/apt/lists/*
    
    # Clone Flutter
    RUN git clone https://github.com/flutter/flutter.git \
        --branch stable \
        --depth 1 \
        $FLUTTER_HOME
    
    # Verify Flutter installation
    RUN flutter doctor
    
    # Enable web support
    RUN flutter config --enable-web
    
    # App setup
    WORKDIR /app
    COPY . .
    
    # Install dependencies
    RUN flutter pub get
    
    # Build web app
    RUN flutter build web --release
    
    # ---------- STAGE 2: NGINX ----------
    FROM nginx:alpine
    
    COPY --from=build-env /app/build/web /usr/share/nginx/html
    
    EXPOSE 80
    
    CMD ["nginx", "-g", "daemon off;"]