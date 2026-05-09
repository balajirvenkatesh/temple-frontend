# ---------- STAGE 1: BUILD ----------
    FROM ubuntu:22.04 AS build-env

    # Environment variables
    ENV DEBIAN_FRONTEND=noninteractive
    ENV FLUTTER_HOME=/usr/local/flutter
    ENV PATH=$FLUTTER_HOME/bin:$FLUTTER_HOME/bin/cache/dart-sdk/bin:$PATH
    ENV CI=true
    
    # Install required system packages
    RUN apt-get update && apt-get install -y \
        curl \
        git \
        unzip \
        xz-utils \
        zip \
        libglu1-mesa \
        ca-certificates \
        && rm -rf /var/lib/apt/lists/*
    
    # Clone Flutter SDK
    RUN git clone https://github.com/flutter/flutter.git \
        --branch 3.35.4 \
        --depth 1 \
        $FLUTTER_HOME
    
    # Initialize Flutter
    RUN flutter config --no-analytics
    RUN flutter config --enable-web
    RUN flutter --version
    
    # Set working directory
    WORKDIR /app
    
    # Copy only dependency files first (better Docker caching)
    COPY pubspec.yaml pubspec.lock ./
    
    # Fetch dependencies with verbose logs
    RUN flutter pub get -v
    
    # Copy the remaining project files
    COPY . .
    
    # Build Flutter web app with verbose logs
    RUN flutter build web --release -v
    
    # ---------- STAGE 2: NGINX ----------
    FROM nginx:alpine
    
    # Copy Flutter web build output
    COPY --from=build-env /app/build/web /usr/share/nginx/html
    
    # Expose web port
    EXPOSE 80
    
    # Start nginx
    CMD ["nginx", "-g", "daemon off;"]