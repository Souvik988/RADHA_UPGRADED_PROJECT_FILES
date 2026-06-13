plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// ── Razorpay × AGP 9 namespace de-duplication ────────────────────────────────
// razorpay_flutter 1.4.5 → `com.razorpay:checkout:1.6.+` transitively pulls TWO
// AARs that BOTH declare the `com.razorpay` namespace: `standard-core` (the
// modern Standard Checkout SDK) and the legacy `core`. AGP 9 forbids duplicate
// namespaces ("Namespace 'com.razorpay' is used in multiple modules"). The two
// are a matched pair (standard-core's layouts reference core's `rzp_logo`), so
// neither can simply be dropped. We exclude the remote `core` and substitute a
// locally-vendored copy whose manifest namespace is rewritten to
// `com.razorpay.legacycore` (see android/app/libs/razorpay-core-1.0.14-patched.aar).
// Its resources still merge into the app resource table, so standard-core's
// layouts keep resolving them — only the colliding namespace becomes unique.
configurations.all {
    exclude(group = "com.razorpay", module = "core")
}

dependencies {
    implementation(files("libs/razorpay-core-1.0.14-patched.aar"))
}

android {
    namespace = "com.radha.radha_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.radha.radha_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config before publishing to the Play Store.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            // R8 code shrinking + our keep rules (ML Kit optional scripts +
            // Razorpay reflection). Resource shrinking trims unused resources.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
