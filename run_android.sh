#!/bin/bash

echo "🚀 Starting MediGay App for Android..."

# Clean the project
echo "🧹 Cleaning project..."
flutter clean

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Check for connected devices
echo "📱 Checking for connected devices..."
flutter devices

# Build and run on Android
echo "🏗️ Building and running on Android..."
flutter run -d android 