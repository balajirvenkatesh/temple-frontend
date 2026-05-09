# ---------- BUILD STAGE ----------
    FROM ubuntu:22.04 AS build-env

    ENV DEBIAN_FRONTEND=noninteractive
    ENV FLUTTER_HOME=/usr/local/flutter
    ENV PATH=$FLUTTER_HOME/bin:$FLUTTER_HOME/bin/cache/dart-sdk/bin:$PATH
    ENV CI=true
    ENV PUB_CACHE=/root/.pub-cache
    
    # System dependencies
    RUN apt-get update && apt-get install -y \
        curl git unzip xz-utils zip libglu1-mesa ca-certificates \
        && update-ca-certificates \
        && rm -rf /var/lib/apt/lists/*
    
    # Install Flutter SDK — use a real stable tag
    RUN git clone https://github.com/flutter/flutter.git \
        --branch stable \
        --depth 1 \
        $FLUTTER_HOME
    
    # Pre-cache web artifacts so build works offline
    RUN flutter precache --web
    
    # Flutter config
    RUN flutter config --no-analytics && \
        flutter config --enable-web
    
    WORKDIR /app
    
    # Copy dependency files
    COPY pubspec.yaml pubspec.lock ./
    
    # Get dependencies
    RUN flutter pub get
    
    # Copy full source
    COPY . .
    
    # Build web release
    RUN flutter build web --release
    
    # ---------- RUNTIME STAGE ----------
    FROM nginx:alpine
    
    # SPA routing: redirect all 404s back to index.html
    RUN printf 'server {\n\
        listen 80;\n\
        root /usr/share/nginx/html;\n\
        index index.html;\n\
        location / {\n\
            try_files $uri $uri/ /index.html;\n\
        }\n\
    }\n' > /etc/nginx/conf.d/default.conf
    
    # Copy Flutter web build
    COPY --from=build-env /app/build/web /usr/share/nginx/html
    
    EXPOSE 80
    
    CMD ["nginx", "-g", "daemon off;"]