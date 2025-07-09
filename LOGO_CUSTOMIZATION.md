# 🎨 Logo and Splash Screen Customization Guide

This guide will help you customize the logo and splash screen for your Medi-gay Flutter app.

## 📱 Changing the App Logo

### Method 1: Using the Automated Script (Recommended)

1. **Install ImageMagick** (if not already installed):
   ```bash
   # Ubuntu/Debian
   sudo apt-get install imagemagick
   
   # macOS
   brew install imagemagick
   
   # Windows
   # Download from https://imagemagick.org/
   ```

2. **Create your logo**:
   - Design a square logo (1:1 aspect ratio)
   - Save as PNG with transparent background
   - Recommended size: 1024x1024 pixels or larger
   - Save as `logo_source.png` in the `flutter/` directory

3. **Run the generation script**:
   ```bash
   cd flutter
   ./generate_logos.sh
   ```

4. **Test the app**:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

### Method 2: Manual Replacement

#### Android Icons
Replace these files with your custom icons:

| File | Size | Purpose |
|------|------|---------|
| `android/app/src/main/res/mipmap-mdpi/ic_launcher.png` | 48x48 | Low density |
| `android/app/src/main/res/mipmap-hdpi/ic_launcher.png` | 72x72 | High density |
| `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png` | 96x96 | Extra high density |
| `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png` | 144x144 | Extra extra high density |
| `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png` | 192x192 | Extra extra extra high density |

#### iOS Icons
Replace files in `ios/Runner/Assets.xcassets/AppIcon.appiconset/`:

| File | Size | Purpose |
|------|------|---------|
| `Icon-App-20x20@1x.png` | 20x20 | Settings icon |
| `Icon-App-20x20@2x.png` | 40x40 | Settings icon (2x) |
| `Icon-App-20x20@3x.png` | 60x60 | Settings icon (3x) |
| `Icon-App-29x29@1x.png` | 29x29 | Spotlight icon |
| `Icon-App-29x29@2x.png` | 58x58 | Spotlight icon (2x) |
| `Icon-App-29x29@3x.png` | 87x87 | Spotlight icon (3x) |
| `Icon-App-40x40@1x.png` | 40x40 | Spotlight icon |
| `Icon-App-40x40@2x.png` | 80x80 | Spotlight icon (2x) |
| `Icon-App-40x40@3x.png` | 120x120 | Spotlight icon (3x) |
| `Icon-App-60x60@2x.png` | 120x120 | App icon (2x) |
| `Icon-App-60x60@3x.png` | 180x180 | App icon (3x) |
| `Icon-App-76x76@1x.png` | 76x76 | iPad icon |
| `Icon-App-76x76@2x.png` | 152x152 | iPad icon (2x) |
| `Icon-App-83.5x83.5@2x.png` | 167x167 | iPad Pro icon |
| `Icon-App-1024x1024@1x.png` | 1024x1024 | App Store icon |

## 🌅 Changing the Splash Screen

### Android Splash Screen

The splash screen is configured in these files:
- `android/app/src/main/res/drawable/launch_background.xml` (API < 21)
- `android/app/src/main/res/drawable-v21/launch_background.xml` (API 21+)

#### Current Configuration
The current splash screen has:
- Dark gradient background (slate colors)
- Centered app logo
- Matches the app's dark theme

#### Customization Options

1. **Change Background Colors**:
   ```xml
   <gradient
       android:angle="135"
       android:startColor="#YOUR_COLOR_1"
       android:centerColor="#YOUR_COLOR_2"
       android:endColor="#YOUR_COLOR_3"
       android:type="linear" />
   ```

2. **Add Custom Image**:
   ```xml
   <item>
       <bitmap
           android:gravity="center"
           android:src="@drawable/your_custom_image" />
   </item>
   ```

3. **Add Text**:
   ```xml
   <item android:bottom="50dp">
       <bitmap
           android:gravity="center"
           android:src="@drawable/app_name_text" />
   </item>
   ```

### iOS Splash Screen

For iOS, replace the launch images in:
- `ios/Runner/Assets.xcassets/LaunchImage.imageset/`

## 🎨 Design Tips

### Logo Design
- **Keep it simple**: Complex logos don't scale well
- **Use transparent background**: PNG format recommended
- **Test at small sizes**: Make sure it's recognizable at 48x48
- **Follow platform guidelines**: 
  - [Android Material Design](https://material.io/design/platform-guidance/android-icons.html)
  - [iOS Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/ios/icons-and-images/app-icon/)

### Splash Screen Design
- **Match app theme**: Use colors from your app
- **Keep it fast**: Users should see it briefly
- **Include branding**: Logo and app name
- **Consider loading time**: Don't make it too complex

## 🔧 Advanced Customization

### Custom Splash Screen with Animation

For more advanced splash screens, you can:

1. **Use a Flutter splash screen package**:
   ```yaml
   dependencies:
     flutter_native_splash: ^2.3.0
   ```

2. **Configure in pubspec.yaml**:
   ```yaml
   flutter_native_splash:
     color: "#0F172A"
     image: assets/images/logo.png
     branding: assets/images/branding.png
     color_dark: "#1E293B"
     image_dark: assets/images/logo_dark.png
     branding_dark: assets/images/branding_dark.png
   ```

3. **Generate splash screen**:
   ```bash
   flutter pub get
   flutter pub run flutter_native_splash:create
   ```

### Custom Launch Animation

You can also create custom launch animations by modifying the main.dart file to show a custom splash screen before the main app loads.

## 🚀 Testing Your Changes

After making changes:

1. **Clean and rebuild**:
   ```bash
   flutter clean
   flutter pub get
   ```

2. **Test on different devices**:
   ```bash
   flutter run -d emulator-5554  # Android
   flutter run -d chrome         # Web
   ```

3. **Check different screen densities**:
   - Test on various Android devices/emulators
   - Test on different iOS devices/simulators

## 📝 Troubleshooting

### Common Issues

1. **Logo appears blurry**:
   - Ensure you're using the correct sizes
   - Use high-resolution source images
   - Check that the aspect ratio is 1:1

2. **Splash screen doesn't change**:
   - Clean and rebuild the project
   - Check that you edited the correct files
   - Verify the file paths are correct

3. **iOS build fails**:
   - Ensure all required icon sizes are present
   - Check the Contents.json file in AppIcon.appiconset

### Getting Help

If you encounter issues:
1. Check the Flutter documentation
2. Review the platform-specific guidelines
3. Test on different devices and screen sizes
4. Use the Flutter DevTools for debugging

---

**Happy customizing! 🎨** 