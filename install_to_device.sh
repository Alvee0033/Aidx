#!/bin/bash

echo "🚀 Installing AidX App to Physical Device..."

# Check if device is connected
echo "📱 Checking for connected devices..."
if ! adb devices | grep -q "device$"; then
    echo "❌ No Android device found. Please connect your device and enable USB debugging."
    exit 1
fi

# Clean the project
echo "🧹 Cleaning project..."
flutter clean

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Build APK
echo "🏗️ Building APK..."
flutter build apk --release

# Install to device
echo "📲 Installing to device (streaming)..."
adb install --streaming -r build/app/outputs/flutter-apk/app-release.apk

echo "✅ Installation complete! The app should now be available on your device."
echo "📱 Look for 'AidX' in your app drawer." 