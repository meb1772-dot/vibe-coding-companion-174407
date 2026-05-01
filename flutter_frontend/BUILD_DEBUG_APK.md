# Android Debug APK Build (Flutter)

This project now includes Android platform scaffolding and successfully builds a debug APK.

## APK artifact

- **Path:** `build/app/outputs/flutter-apk/app-debug.apk`
- **SHA1 file:** `build/app/outputs/flutter-apk/app-debug.apk.sha1`

## Commands used

From `flutter_frontend/`:

```bash
flutter pub get
flutter create . --platforms=android
flutter build apk --debug
```

## Notes

- The initial build failed with: `Your app is using an unsupported Gradle project...`
- Root cause was missing `android/` directory. Running `flutter create . --platforms=android` regenerated the Android project files.
