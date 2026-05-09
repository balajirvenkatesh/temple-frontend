# --- STAGE 1: Build Stage ---
    FROM ubuntu:22.04 AS build-env

    # Install dependencies
    RUN apt-get update && apt-get install -y \
        curl git unzip xz-utils zip libglu1-mesa ca-certificates \
        && rm -rf /var/lib/apt/lists/*
    
    # Setup Flutter
    RUN git clone --branch 3.35.4 https://github.com/flutter/flutter.git /usr/local/flutter
    ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"
    
    RUN flutter precache
    
    # Setup App
    WORKDIR /app
    COPY . .
    RUN flutter pub get
    RUN flutter build web --release
    
    # --- STAGE 2: Deployment Stage ---
    FROM nginx:alpine
    
    # Copy the build output from the first stage to the nginx server
    # Flutter builds the web files into /app/build/web
    COPY --from=build-env /app/build/web /usr/share/nginx/html
    
    # Expose port 80
    EXPOSE 80
    
    # Start Nginx
    CMD ["nginx", "-g", "daemon off;"]