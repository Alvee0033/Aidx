#!/bin/bash

# Medi-gay Logo Generation Script
# This script helps you generate different logo sizes for your Flutter app

echo "🎨 Medi-gay Logo Generation Script"
echo "=================================="
echo ""

# Check if ImageMagick is installed
if ! command -v convert &> /dev/null; then
    echo "❌ ImageMagick is not installed. Please install it first:"
    echo "   Ubuntu/Debian: sudo apt-get install imagemagick"
    echo "   macOS: brew install imagemagick"
    echo "   Windows: Download from https://imagemagick.org/"
    exit 1
fi

# Check if icon.png exists
if [ ! -f "assets/images/icon.png" ]; then
    echo "❌ assets/images/icon.png not found!"
    echo ""
    echo "📋 Instructions:"
    echo "1. Place your icon image as 'icon.png' in assets/images/ folder"
    echo "2. Make sure it's a square image (1:1 aspect ratio)"
    echo "3. Use PNG format with transparent background"
    echo "4. Recommended size: 1024x1024 pixels or larger"
    exit 1
fi

echo "✅ Found assets/images/icon.png"
echo "🔄 Generating logo sizes..."

# Create directories if they don't exist
mkdir -p android/app/src/main/res/mipmap-mdpi
mkdir -p android/app/src/main/res/mipmap-hdpi
mkdir -p android/app/src/main/res/mipmap-xhdpi
mkdir -p android/app/src/main/res/mipmap-xxhdpi
mkdir -p android/app/src/main/res/mipmap-xxxhdpi

# Generate Android logos
echo "📱 Generating Android logos..."
convert assets/images/icon.png -resize 48x48 android/app/src/main/res/mipmap-mdpi/ic_launcher.png
convert assets/images/icon.png -resize 72x72 android/app/src/main/res/mipmap-hdpi/ic_launcher.png
convert assets/images/icon.png -resize 96x96 android/app/src/main/res/mipmap-xhdpi/ic_launcher.png
convert assets/images/icon.png -resize 144x144 android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png
convert assets/images/icon.png -resize 192x192 android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png

# Generate iOS logos
echo "🍎 Generating iOS logos..."
mkdir -p ios/Runner/Assets.xcassets/AppIcon.appiconset

# iOS App Icon sizes
convert assets/images/icon.png -resize 20x20 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png
convert assets/images/icon.png -resize 40x40 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png
convert assets/images/icon.png -resize 60x60 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png
convert assets/images/icon.png -resize 29x29 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png
convert assets/images/icon.png -resize 58x58 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png
convert assets/images/icon.png -resize 87x87 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png
convert assets/images/icon.png -resize 40x40 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png
convert assets/images/icon.png -resize 80x80 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png
convert assets/images/icon.png -resize 120x120 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png
convert assets/images/icon.png -resize 120x120 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png
convert assets/images/icon.png -resize 180x180 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png
convert assets/images/icon.png -resize 76x76 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png
convert assets/images/icon.png -resize 152x152 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png
convert assets/images/icon.png -resize 167x167 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png
convert assets/images/icon.png -resize 1024x1024 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png

echo ""
echo "✅ Logo generation complete!"
echo ""
echo "📋 Next steps:"
echo "1. Review the generated logos in the respective directories"
echo "2. Test the app to see the new logo and splash screen"
echo "3. If you want to change the splash screen background, edit:"
echo "   - android/app/src/main/res/drawable/launch_background.xml"
echo "   - android/app/src/main/res/drawable-v21/launch_background.xml"
echo ""
echo "🎨 Customization tips:"
echo "   - Change colors in launch_background.xml"
echo "   - Add text or additional elements to splash screen"
echo "   - Modify the gradient angles and colors" 