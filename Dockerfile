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

# Flutter SDK
RUN git clone https://github.com/flutter/flutter.git \
    --branch 3.35.4 \
    --depth 1 \
    $FLUTTER_HOME

RUN flutter config --no-analytics
RUN flutter config --enable-web

WORKDIR /app

# Copy dependency files first (better caching)
COPY pubspec.* ./

# FAIL FAST with clear error (no sleep)
RUN flutter pub get -v

COPY . .

# Build web
RUN flutter build web --release -v

# Runtime stage
FROM nginx:alpine

COPY --from=build-env /app/build/web /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]