# --- STAGE 1: Build Stage ---
    FROM ubuntu:22.04 AS build-env

    # Set environment variables
    ENV DEBIAN_FRONTEND=noninteractive
    ENV FLUTTER_HOME="/usr/local/flutter"
    ENV PATH="$FLUTTER_HOME/bin:$FLUTTER_HOME/bin/cache/dart-sdk/bin:${PATH}"
    
    # Install dependencies 
    # Added 'ca-certificates' explicitly to handle download SSL issues
    RUN apt-get update && apt-get install -y \
        curl git unzip xz-utils zip libglu1-mesa ca-certificates \
        && rm -rf /var/lib/apt/lists/*
    
    # Setup Flutter
    RUN git clone --branch 3.35.4 https://github.com/flutter/flutter.git $FLUTTER_HOME
    
    # FIX: Only precache WEB artifacts to avoid the Gradle download error
    RUN flutter precache --web
    
    # Setup App
    WORKDIR /app
    COPY . .
    RUN flutter pub get
    RUN flutter build web --release
    
    # --- STAGE 2: Deployment Stage ---
    FROM nginx:alpine
    COPY --from=build-env /app/build/web /usr/share/nginx/html
    EXPOSE 80
    CMD ["nginx", "-g", "daemon off;"]