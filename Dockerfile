FROM ubuntu:22.04 AS build-env

ENV DEBIAN_FRONTEND=noninteractive
ENV FLUTTER_HOME=/usr/local/flutter
ENV PATH=$FLUTTER_HOME/bin:$FLUTTER_HOME/bin/cache/dart-sdk/bin:$PATH
ENV CI=true

RUN apt-get update && apt-get install -y \
    curl git unzip xz-utils zip libglu1-mesa ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN git clone --branch 3.35.4 https://github.com/flutter/flutter.git $FLUTTER_HOME

RUN flutter config --no-analytics
RUN flutter config --enable-web

# Initialize flutter safely
RUN flutter --version

WORKDIR /app
COPY . .

RUN flutter pub get

RUN flutter build web --release

FROM nginx:alpine

COPY --from=build-env /app/build/web /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]