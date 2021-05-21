#!/usr/bin/env bash

if [ -z "$APP_CENTER_CURRENT_PLATFORM" ]
then
    echo "You need define the APP_CENTER_CURRENT_PLATFORM variable in App Center with values android or ios"
    exit
fi

if [ "$APP_CENTER_CURRENT_PLATFORM" == "android" ]
then
    echo "Setup Android simulator"
    SIMULATOR_IMAGE="system-images;android-29;default;x86"
    SIMULATOR_NAME="Pixel_API_29_AOSP" # detoxrc.json file device-avdName need to be same

    ANDROID_HOME=~/Library/Android/sdk
    export PATH=$PATH:$ANDROID_HOME/emulator
    export ANDROID_HOME=~/Library/Android/sdk
    export PATH=$PATH:$ANDROID_HOME/platform-tools/
    export PATH=$PATH:$ANDROID_HOME/tools/bin/
    export PATH=$PATH:$ANDROID_HOME/tools/
    PATH=$ANDROID_HOME/emulator:$PATH

    echo "PATH ---'$PATH'"

    # Install AVD files
    echo "Install AVD files---"
    $ANDROID_HOME/tools/bin/sdkmanager --install "$SIMULATOR_IMAGE"
    yes | $ANDROID_HOME/tools/bin/sdkmanager --licenses

    # Create emulator
    echo "Start creating emulator---"
    echo "no" | $ANDROID_HOME/tools/bin/avdmanager create avd -n "$SIMULATOR_NAME" -d pixel --package "$SIMULATOR_IMAGE" --force
    echo "Finish creating emulator---"

    $ANDROID_HOME/emulator/emulator -list-avds

    # Set screen dimensions
    echo "Set screen dimensions---"
    echo "hw.lcd.density=420" >> ~/.android/avd/$SIMULATOR_NAME.avd/config.ini
    echo "hw.lcd.height=1920" >> ~/.android/avd/$SIMULATOR_NAME.avd/config.ini
    echo "hw.lcd.width=1080" >> ~/.android/avd/$SIMULATOR_NAME.avd/config.ini

    echo "Starting emulator and waiting for boot to complete..."
    nohup $ANDROID_HOME/emulator/emulator -avd "$SIMULATOR_NAME" -no-snapshot -no-window -no-audio -no-boot-anim -camera-back none -camera-front none -qemu -m 2048 > /dev/null 2>&1 &
    $ANDROID_HOME/platform-tools/adb wait-for-device shell 'while [[ -z $(getprop sys.boot_completed | tr -d '\r') ]]; do sleep 1; done; input keyevent 82'

    echo "Emulator has finished booting--"
    $ANDROID_HOME/platform-tools/adb devices

    echo "Emulator list---"
    emulator -list-avds

    DETOX_CONFIG=android.emu.release
else
    # ---- IOS part is not tested ----
    echo "Install AppleSimUtils"

    # brew tap wix/brew
    # brew update
    # brew install applesimutils

    # echo "Install pods "
    # cd ios; pod install; cd ..

    DETOX_CONFIG=ios.sim.release
fi

echo "adb devices -----"
adb devices -l

echo "Building the project for Detox tests..."
npx detox build --configuration "$DETOX_CONFIG"

echo "Executing Detox tests..."
npx detox test --configuration "$DETOX_CONFIG" -l trace --record-logs all --cleanup