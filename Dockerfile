# --- STAGE 1: Build Stage ---
FROM ubuntu:22.04 AS build-env

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV FLUTTER_HOME="/usr/local/flutter"
ENV PATH="$FLUTTER_HOME/bin:$FLUTTER_HOME/bin/cache/dart-sdk/bin:${PATH}"

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl git unzip xz-utils zip libglu1-mesa ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# 1. Clone Flutter (Stable branch)
RUN git clone --branch 3.35.4 https://github.com/flutter/flutter.git $FLUTTER_HOME

# 2. STRICT CONFIG: Disable mobile platforms to prevent Gradle/Binary downloads
# This is the key fix for the "ProcessException: The command failed with exit code 2"
RUN flutter config --no-analytics
RUN flutter config --no-enable-android
RUN flutter config --no-enable-ios
RUN flutter config --enable-web

# 3. Precache only the Web engine 
# We use --no-android to ensure the tool stays away from storage.googleapis.com/flutter_infra_release/gradle-wrapper
RUN flutter precache --web --no-android --no-ios

# 4. Final verification of the toolchain
RUN flutter doctor -v

# Setup App
WORKDIR /app
COPY . .

# Ensure dependencies are fetched for the current project
RUN flutter pub get

# Build the web production files
RUN flutter build web --release

# --- STAGE 2: Deployment Stage ---
FROM nginx:alpine

# Copy the build output from the first stage to the nginx folder
COPY --from=build-env /app/build/web /usr/share/nginx/html

# Expose port 80 for the web server
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
