# NewDetoxReactNativeApp

Create a new React Native app: 'react_native_detox_poc'

- `npx react-native init react_native_detox_poc`

Run app on Android device or emulator:

- `npx react-native run-android`

Start app

- `react-native start`

Setting up Detox ---

Install Detox dependencies:

- `sudo apt update`
- `sudo apt install detox`

Install Detox CLI global:

- `npm install -g detox-cli`

Add Detox to Your Project ----

Install the Detox Node-module

- `npm install detox --save-dev`

Configuring for Android -----

Go to your Android `build.gradle (project)`, and the update the `minSdkVersion` to minimum 18 - `minSdkVersion = 18`

    ```
      allprojects {
        repositories {
            maven {
                // All of the Detox artifacts are provided via the npm module
                url "$rootDir/../node_modules/detox/Detox-android"
            }
        }
      }
    ```

Go to Android `build.gradle (app)`, add the following under android.defaultConfig:

```
  android {
    defaultConfig {
        // Added these for running tests
        testBuildType System.getProperty('testBuildType', 'debug')
        testInstrumentationRunner 'androidx.test.runner.AndroidJUnitRunner'
    }
  }
```

Add dependencies also

```
  dependencies {
    // Added testing dependencies
    androidTestImplementation('com.wix:detox:+') { transitive = true }
    androidTestImplementation 'junit:junit:4.12'
  }
```

Create a file called `DetoxTest.java` in the path `android/app/src/androidTest/java/com/[your_package]/`

Put blow content created `DetoxTest.java` file
Replace [your_package] by your app package name

```
  package com.[your_package];

  import com.wix.detox.Detox;
  import com.wix.detox.config.DetoxConfig;

  import org.junit.Rule;
  import org.junit.Test;
  import org.junit.runner.RunWith;

  import androidx.test.ext.junit.runners.AndroidJUnit4;
  import androidx.test.filters.LargeTest;
  import androidx.test.rule.ActivityTestRule;

  @RunWith(AndroidJUnit4.class)
  @LargeTest
  public class DetoxTest {
    @Rule
    public ActivityTestRule<MainActivity> mActivityRule = new ActivityTestRule<>(MainActivity.class, false, false);

    @Test
    public void runDetoxTests() {
        DetoxConfig detoxConfig = new DetoxConfig();
        detoxConfig.idlePolicyConfig.masterTimeoutSec = 90;
        detoxConfig.idlePolicyConfig.idleResourceTimeoutSec = 60;
        detoxConfig.rnContextLoadTimeoutSec = (com.[your_package].BuildConfig.DEBUG ? 180 : 60);

        Detox.runTests(mActivityRule, detoxConfig);
    }
  }
```

Adding release build support

- Need to have a `keystore` file. Can generate it by using this command:

  `keytool -genkey -v -keystore keystore_name.keystore -alias alias_name -keyalg RSA -keysize 2048 -validity 10000`

- Create a new file `key.properties`, in `android/` folder. Add bellow properties to it:
  Remember to replace all the <value> with correct keystore file properties

  ```
  storePassword=<enter keystore password>
  keyPassword=<enter key alias password>
  keyAlias=<enter key alias name>
  storeFile=<enter .keystore file path>
  ```

Add these properties to `build.gradle (app)`, above the `android {`

```
  def keystorePropertiesFile= rootProject.file("key.properties")
  def keystoreProperties = new Properties()
  keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
```

Add the `signingConfigs`:

```
signingConfigs {
  release {
      keyAlias keystoreProperties['keyAlias']
      keyPassword keystoreProperties['keyPassword']
      storeFile file(keystoreProperties['storeFile'])
      storePassword keystoreProperties['storePassword']
  }
}
```

Inside `buildTypes release`, use the release `signingConfig`:

```
buildTypes {
    release {
        //...
        signingConfig signingConfigs.release
    }
}
```

Adding Detox configurations

- Add the `.detoxrc.json` file, `detox-cli` using below configurations for building and testing the app:

```
{
  "testRunner": "jest",
  "runnerConfig": "e2e/config.json",
  "configurations": {
    "android.emu.debug": {
      "type": "android.emulator",
      "binaryPath": "android/app/build/outputs/apk/debug/app-debug.apk",
      "build": "cd android && ./gradlew assembleDebug assembleAndroidTest -DtestBuildType=debug && cd ..",
      "device": {
        "avdName": "Pixel_API_29"
      }
    },
    "android.emu.release": {
      "binaryPath": "android/app/build/outputs/apk/release/app-release.apk",
      "build": "cd android && ./gradlew assembleRelease assembleAndroidTest -DtestBuildType=release && cd ..",
      "type": "android.emulator",
      "device": {
        "avdName": "Pixel_API_29"
      }
    }
  }
}
```

In the above JSON, replace the `avdName` with the proper emulator or device name that you are using.

Adding Detox tests

Jest use ad default test runner for React Native, https://jestjs.io

- Detox for initializing Jest:
  `detox init -r jest`

This command will create an “e2e” folder in the root project directory with sample test code.

Sample e2e test-case

- Add `testID` property to welcome screen in `App.js`

```
<Text testID="edit_id" style={styles.highlight}>
  App.js
</Text>
```

- e2e/firstTest.e2e.js, and replace its content with the following:

```
describe('Example', () => {

  beforeAll(async () => {
    await device.launchApp({newInstance: true});
  });

  beforeEach(async () => {
    await device.reloadReactNative();
  });

  it('should have welcome screen', async () => {
    await expect(element(by.id('edit_id'))).toBeVisible();
  });
});

```

------------ Faced Issues --------------

1. No connected devices

error msg
`error Failed to install the app. Make sure you have an Android emulator running or a device connected.`
`Error: Command failed: ./gradlew app:installDebug -PreactNativeDevServerPort=8081`

solution
Run - `adb reverse tcp:8081 tcp:8081`

2.

Setup React Native Detox test
https://blog.codemagic.io/react-native-detox-tests-on-codemagic/

-- Issus I faced when the CI/CD configuration --

1. React Native E2E w/ Detox error: “Failed to run application on the device”
   Problem: The app loads but tests fail to start in SDK >= 28

   - https://github.com/wix/Detox/blob/master/docs/Introduction.Android.md
   - Official Detox REact Native Demo app
     - https://github.com/wix/Detox/blob/master/examples/demo-react-native/android/app/src/main/AndroidManifest.xml

2. Support detox as a testing framework in AppCenter

- github issue page
  - https://github.com/microsoft/appcenter/issues/262
- - solution (AppCenter sample pre-build.sh)
    - https://github.com/microsoft/appcenter/issues/262#issuecomment-706143051
    - https://gist.github.com/badsyntax/4029600db276b0b51342626aebf9400a - I referred this one

3. Install and Create Emulators using AVDMANAGER and SDKMANAGER

- https://gist.github.com/mrk-han/66ac1a724456cadf1c93f4218c6060ae
# ReactNativeDetoxPoc
