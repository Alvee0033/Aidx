#!/bin/bash

# Icon generation script for Medi-gay Flutter app
# This script generates all required icon sizes from a source icon

echo "🎨 Generating app icons from assets/images/icon.png..."

# Create directories if they don't exist
mkdir -p android/app/src/main/res/mipmap-mdpi
mkdir -p android/app/src/main/res/mipmap-hdpi
mkdir -p android/app/src/main/res/mipmap-xhdpi
mkdir -p android/app/src/main/res/mipmap-xxhdpi
mkdir -p android/app/src/main/res/mipmap-xxxhdpi

# Generate Android icons
echo "📱 Generating Android icons..."

# MDPI (48x48)
convert assets/images/icon.png -resize 48x48 android/app/src/main/res/mipmap-mdpi/ic_launcher.png
echo "✅ Generated MDPI icon (48x48)"

# HDPI (72x72)
convert assets/images/icon.png -resize 72x72 android/app/src/main/res/mipmap-hdpi/ic_launcher.png
echo "✅ Generated HDPI icon (72x72)"

# XHDPI (96x96)
convert assets/images/icon.png -resize 96x96 android/app/src/main/res/mipmap-xhdpi/ic_launcher.png
echo "✅ Generated XHDPI icon (96x96)"

# XXHDPI (144x144)
convert assets/images/icon.png -resize 144x144 android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png
echo "✅ Generated XXHDPI icon (144x144)"

# XXXHDPI (192x192)
convert assets/images/icon.png -resize 192x192 android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png
echo "✅ Generated XXXHDPI icon (192x192)"

# Generate adaptive icons for Android
echo "🎯 Generating adaptive icons..."

# MDPI adaptive (108x108)
convert assets/images/icon.png -resize 108x108 -background transparent -gravity center -extent 108x108 android/app/src/main/res/mipmap-mdpi/ic_launcher_round.png
echo "✅ Generated MDPI adaptive icon (108x108)"

# HDPI adaptive (162x162)
convert assets/images/icon.png -resize 162x162 -background transparent -gravity center -extent 162x162 android/app/src/main/res/mipmap-hdpi/ic_launcher_round.png
echo "✅ Generated HDPI adaptive icon (162x162)"

# XHDPI adaptive (216x216)
convert assets/images/icon.png -resize 216x216 -background transparent -gravity center -extent 216x216 android/app/src/main/res/mipmap-xhdpi/ic_launcher_round.png
echo "✅ Generated XHDPI adaptive icon (216x216)"

# XXHDPI adaptive (324x324)
convert assets/images/icon.png -resize 324x324 -background transparent -gravity center -extent 324x324 android/app/src/main/res/mipmap-xxhdpi/ic_launcher_round.png
echo "✅ Generated XXHDPI adaptive icon (324x324)"

# XXXHDPI adaptive (432x432)
convert assets/images/icon.png -resize 432x432 -background transparent -gravity center -extent 432x432 android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_round.png
echo "✅ Generated XXXHDPI adaptive icon (432x432)"

# Create iOS directories
mkdir -p ios/Runner/Assets.xcassets/AppIcon.appiconset

# Generate iOS icons
echo "🍎 Generating iOS icons..."

# iOS 20pt (@1x, @2x, @3x)
convert assets/images/icon.png -resize 20x20 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png
convert assets/images/icon.png -resize 40x40 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png
convert assets/images/icon.png -resize 60x60 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png

# iOS 29pt (@1x, @2x, @3x)
convert assets/images/icon.png -resize 29x29 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png
convert assets/images/icon.png -resize 58x58 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png
convert assets/images/icon.png -resize 87x87 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png

# iOS 40pt (@1x, @2x, @3x)
convert assets/images/icon.png -resize 40x40 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png
convert assets/images/icon.png -resize 80x80 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png
convert assets/images/icon.png -resize 120x120 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png

# iOS 60pt (@2x, @3x)
convert assets/images/icon.png -resize 120x120 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png
convert assets/images/icon.png -resize 180x180 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png

# iOS 76pt (@1x, @2x)
convert assets/images/icon.png -resize 76x76 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png
convert assets/images/icon.png -resize 152x152 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png

# iOS 83.5pt (@2x)
convert assets/images/icon.png -resize 167x167 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png

# iOS 1024pt (@1x) - App Store
convert assets/images/icon.png -resize 1024x1024 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png

echo "✅ Generated all iOS icons"

# Create Contents.json for iOS
cat > ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json << 'EOF'
{
  "images" : [
    {
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "20x20"
    },
    {
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "20x20"
    },
    {
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "29x29"
    },
    {
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "29x29"
    },
    {
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "40x40"
    },
    {
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "40x40"
    },
    {
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "60x60"
    },
    {
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "60x60"
    },
    {
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "20x20"
    },
    {
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "20x20"
    },
    {
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "29x29"
    },
    {
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "29x29"
    },
    {
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "40x40"
    },
    {
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "40x40"
    },
    {
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "76x76"
    },
    {
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "83.5x83.5"
    },
    {
      "idiom" : "ios-marketing",
      "scale" : "1x",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF

echo "✅ Created iOS Contents.json"

echo "🎉 All icons generated successfully!"
echo "📱 Android icons: mipmap-*/ic_launcher.png"
echo "🍎 iOS icons: ios/Runner/Assets.xcassets/AppIcon.appiconset/"
echo "🔄 Run 'flutter clean && flutter pub get' to ensure changes take effect" 