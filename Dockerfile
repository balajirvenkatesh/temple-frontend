# --- STAGE 1: Build Stage ---
    FROM ubuntu:22.04 AS build-env

    ENV DEBIAN_FRONTEND=noninteractive
    ENV FLUTTER_HOME="/usr/local/flutter"
    ENV PATH="$FLUTTER_HOME/bin:$FLUTTER_HOME/bin/cache/dart-sdk/bin:${PATH}"
    
    # Install dependencies 
    RUN apt-get update && apt-get install -y \
        curl git unzip xz-utils zip libglu1-mesa ca-certificates \
        && rm -rf /var/lib/apt/lists/*
    
    # Setup Flutter 3.35.4
    RUN git clone --branch 3.35.4 https://github.com/flutter/flutter.git $FLUTTER_HOME
    
    # Disable analytics to speed things up and skip unnecessary checks
    RUN flutter config --no-analytics
    RUN flutter config --enable-web
    
    # Setup App
    WORKDIR /app
    
    # Run pub get first to leverage Docker caching
    COPY pubspec.* .
    RUN flutter pub get
    
    # Copy the rest of the code
    COPY . .
    
    # Build the web app directly 
    # We skip 'flutter precache' because 'build web' will fetch what it needs
    RUN flutter build web --release
    
    # --- STAGE 2: Deployment Stage ---
    FROM nginx:alpine
    # Flutter 3.x builds to build/web
    COPY --from=build-env /app/build/web /usr/share/nginx/html
    EXPOSE 80
    CMD ["nginx", "-g", "daemon off;"]