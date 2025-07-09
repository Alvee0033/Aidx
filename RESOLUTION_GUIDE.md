# 📐 Resolution Guide for Medi-gay App

## 🎯 **Quick Reference - Logo Resolutions**

### **Source Logo Requirements:**
- **Size**: 1024×1024 pixels (minimum)
- **Format**: PNG with transparent background
- **Aspect Ratio**: 1:1 (square)
- **Color Space**: sRGB

---

## 📱 **Android Logo Resolutions**

| Density | Resolution | File Path |
|---------|------------|-----------|
| **mdpi** | 48×48 px | `android/app/src/main/res/mipmap-mdpi/ic_launcher.png` |
| **hdpi** | 72×72 px | `android/app/src/main/res/mipmap-hdpi/ic_launcher.png` |
| **xhdpi** | 96×96 px | `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png` |
| **xxhdpi** | 144×144 px | `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png` |
| **xxxhdpi** | 192×192 px | `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png` |

---

## 🍎 **iOS Logo Resolutions**

| File Name | Resolution | Purpose |
|-----------|------------|---------|
| `Icon-App-20x20@1x.png` | 20×20 px | Settings |
| `Icon-App-20x20@2x.png` | 40×40 px | Settings (2x) |
| `Icon-App-20x20@3x.png` | 60×60 px | Settings (3x) |
| `Icon-App-29x29@1x.png` | 29×29 px | Spotlight |
| `Icon-App-29x29@2x.png` | 58×58 px | Spotlight (2x) |
| `Icon-App-29x29@3x.png` | 87×87 px | Spotlight (3x) |
| `Icon-App-40x40@1x.png` | 40×40 px | Spotlight |
| `Icon-App-40x40@2x.png` | 80×80 px | Spotlight (2x) |
| `Icon-App-40x40@3x.png` | 120×120 px | Spotlight (3x) |
| `Icon-App-60x60@2x.png` | 120×120 px | App Icon (2x) |
| `Icon-App-60x60@3x.png` | 180×180 px | App Icon (3x) |
| `Icon-App-76x76@1x.png` | 76×76 px | iPad |
| `Icon-App-76x76@2x.png` | 152×152 px | iPad (2x) |
| `Icon-App-83.5x83.5@2x.png` | 167×167 px | iPad Pro |
| `Icon-App-1024x1024@1x.png` | **1024×1024 px** | **App Store** |

---

## 🌅 **Splash Screen Resolutions**

### **Android Splash Screen:**
- **Current**: Vector-based (auto-scaling)
- **Custom Image**: 1080×1920 px (9:16 ratio)

### **iOS Splash Screen:**
| Device | Resolution | File |
|--------|------------|------|
| iPhone SE | 640×1136 px | `LaunchImage.png` |
| iPhone 6/7/8 | 750×1334 px | `LaunchImage@2x.png` |
| iPhone 6/7/8 Plus | 1242×2208 px | `LaunchImage@3x.png` |
| iPhone X/XS | 1125×2436 px | `LaunchImage@3x.png` |
| iPhone XR | 828×1792 px | `LaunchImage@2x.png` |
| iPhone XS Max | 1242×2688 px | `LaunchImage@3x.png` |
| iPad | 768×1024 px | `LaunchImage.png` |
| iPad Pro | 1024×1366 px | `LaunchImage@2x.png` |

---

## 🚀 **Quick Setup Commands**

### **1. Generate All Logo Sizes:**
```bash
cd flutter
./generate_logos.sh
```

### **2. Clean and Rebuild:**
```bash
flutter clean
flutter pub get
flutter run
```

### **3. Test on Different Devices:**
```bash
# Android
flutter run -d emulator-5554

# Web
flutter run -d chrome

# iOS (if available)
flutter run -d ios
```

---

## 🎨 **Design Best Practices**

### **Logo Design:**
- ✅ Keep it simple and recognizable at small sizes
- ✅ Use transparent background
- ✅ Test at 48×48 px to ensure clarity
- ✅ Follow platform guidelines
- ❌ Avoid complex details or text

### **Splash Screen Design:**
- ✅ Match your app's color scheme
- ✅ Keep loading time under 3 seconds
- ✅ Include your logo prominently
- ✅ Use safe areas (80% of screen)
- ❌ Don't overcrowd with information

---

## 📁 **File Locations**

### **Android:**
```
flutter/android/app/src/main/res/
├── mipmap-mdpi/ic_launcher.png (48×48)
├── mipmap-hdpi/ic_launcher.png (72×72)
├── mipmap-xhdpi/ic_launcher.png (96×96)
├── mipmap-xxhdpi/ic_launcher.png (144×144)
├── mipmap-xxxhdpi/ic_launcher.png (192×192)
├── drawable/launch_background.xml
└── drawable-v21/launch_background.xml
```

### **iOS:**
```
flutter/ios/Runner/Assets.xcassets/
├── AppIcon.appiconset/ (all icon files)
└── LaunchImage.imageset/ (splash screen files)
```

---

## 🔧 **Troubleshooting**

### **Common Issues:**
1. **Blurry logos**: Use high-resolution source images
2. **Wrong aspect ratio**: Ensure 1:1 ratio for logos
3. **Splash screen not updating**: Clean and rebuild project
4. **iOS build fails**: Check all required icon sizes are present

### **Tools:**
- **ImageMagick**: For batch image processing
- **Sketch/Figma**: For logo design
- **Flutter DevTools**: For debugging

---

**📝 Note**: Always test your logos and splash screens on multiple devices and screen densities to ensure they look good everywhere! 