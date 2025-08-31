#!/bin/bash
set -e

# Install Flutter (only if not already cloned)
if [ ! -d "flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
else
  echo "Flutter already exists, skipping clone."
fi

# Add Flutter to PATH
export PATH="$PWD/flutter/bin:$PATH"

# Verify Flutter
flutter --version

# Install dependencies
flutter pub get

# Build web
flutter build web --release
