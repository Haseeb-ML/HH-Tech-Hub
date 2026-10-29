#!/bin/bash
set -e

echo "=== Installing Flutter SDK on Vercel ==="
if [ ! -d "$HOME/flutter" ]; then
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable $HOME/flutter
fi

export PATH="$PATH:$HOME/flutter/bin"
flutter --version

echo "=== Getting dependencies ==="
flutter pub get

echo "=== Building Flutter Web Release ==="
flutter build web --release

echo "=== Build Complete ==="
