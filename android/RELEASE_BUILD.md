# Release Build Instructions

## Configuration
The app is configured to sign release builds with the keystore at:
- **Keystore Path**: `E:\Projects\Flutter\key.jks`
- **Key Alias**: `key`
- **Password**: Configured in `keystore.properties`

## Building Release APK
```bash
flutter build apk --release
```

## Building Release App Bundle (for Play Store)
```bash
flutter build appbundle --release
```

## Important Notes
- The `keystore.properties` file is excluded from version control (in .gitignore)
- Keep your keystore file secure and backed up
- The release build uses ProGuard for code obfuscation and optimization
- Output files will be in:
  - APK: `build/app/outputs/flutter-apk/app-release.apk`
  - App Bundle: `build/app/outputs/bundle/release/app-release.aab`

