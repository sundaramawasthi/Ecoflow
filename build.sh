#!/bin/bash
set -e

# Install Flutter
git clone https://github.com/flutter/flutter.git -b stable --depth 1
export PATH="$PWD/flutter/bin:$PATH"

# Verify Flutter
flutter --version

# Install dependencies
flutter pub get

# Build web
flutter build web --release
