# Platform configuration

After you run `flutter create . --org com.ocean --project-name trail` the iOS and Android folders will exist with default permission entries that **don't** include camera or location. Paste the following snippets into the generated files.

## iOS — `ios/Runner/Info.plist`

Inside the top-level `<dict>`:

```xml
<key>NSCameraUsageDescription</key>
<string>Trail needs the camera to capture shipment and item proofs.</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>Trail needs the photo library to attach proof images.</string>

<key>NSLocationWhenInUseUsageDescription</key>
<string>Trail tags each proof with your current GPS coordinates.</string>

<key>UISupportedInterfaceOrientations</key>
<array>
  <string>UIInterfaceOrientationPortrait</string>
</array>

<key>CFBundleLocalizations</key>
<array>
  <string>en</string>
  <string>ar</string>
</array>
```

If you target plain HTTP for local testing, also add:

```xml
<key>NSAppTransportSecurity</key>
<dict>
  <key>NSAllowsArbitraryLoads</key>
  <true/>
</dict>
```

Remove the ATS exception before submitting to the App Store.

## Android — `android/app/src/main/AndroidManifest.xml`

Inside `<manifest>` (above `<application>`):

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
<uses-feature android:name="android.hardware.camera" android:required="false"/>
```

For plaintext HTTP development, in `<application>`:

```xml
android:usesCleartextTraffic="true"
```

## Android — `android/app/build.gradle`

Make sure `minSdkVersion` is **23+** (geolocator + image_picker require it):

```gradle
defaultConfig {
    applicationId "com.ocean.delivery"
    minSdkVersion 23
    targetSdkVersion flutter.targetSdkVersion
    versionCode flutterVersionCode.toInteger()
    versionName flutterVersionName
}
```

## Android — `android/build.gradle`

Gradle Kotlin DSL minimum versions:

```gradle
ext.kotlin_version = '1.9.0'
```

## RTL

Both iOS and Android pick up the system locale automatically and respect the `Directionality` widget set by `MaterialApp.router` via `supportedLocales`. To force a specific locale during development, use the Locale toggle in the dashboard header (translate icon).
