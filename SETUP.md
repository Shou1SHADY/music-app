# Egypt Music Community App - Setup Guide

## 1. Prerequisites
- Flutter SDK (latest stable)
- Firebase Account
- Google Maps API Key

## 2. Firebase Setup
1. Go to [Firebase Console](https://console.firebase.google.com/).
2. Create a new project "EgyptMusicCommunity".
3. **Android**:
   - Add an Android app with package name `com.example.egypt_music_community` (check `android/app/build.gradle` to confirm/change).
   - Download `google-services.json` and place it in `android/app/`.
4. **iOS**:
   - Add an iOS app.
   - Download `GoogleService-Info.plist` and place it in `ios/Runner/`.
   - Open `ios/Runner.xcworkspace` in Xcode and ensure the file is added to the project target.
5. **Authentication**:
   - Enable **Authentication** in the Firebase console.
   - Enable **Email/Password** provider.
   - (Optional) Enable **Google** provider (requires SHA-1 fingerprint setup for Android).
6. **Firestore**:
   - Enable **Firestore Database**.
   - Start in **Test Mode** (for development) or set appropriate security rules.

## 3. Google Maps Setup
1. Go to Google Cloud Console.
2. Enable **Maps SDK for Android** and **Maps SDK for iOS**.
3. Create an API Key.
4. Add the key to `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <meta-data android:name="com.google.android.geo.API_KEY" android:value="YOUR_API_KEY"/>
   ```
5. Add the key to `ios/Runner/AppDelegate.swift` or `Info.plist` as per instructions.

## 4. Run the Project
1. Install dependencies:
   ```bash
   flutter pub get
   ```
2. Generate JSON serialization code (required for Models):
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
3. Run the app:
   ```bash
   flutter run
   ```

## 5. Mock Data
To populate the app with some dummy data:
- Inspect `lib/shared/mock_data_generator.dart`.
- Call `MockDataGenerator().generateMusicians()` temporarily from `main.dart` or add a hidden button in the UI to trigger it.

## 6. Replit Notes
- If running on Replit, ensure `.replit` file is configured for Flutter.
- You might need to rely on the Web build (`flutter run -d chrome`) if mobile emulators are not available.
