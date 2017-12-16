#!/bin/bash
# aosp gapps installtion script by  abhi bhalgami

prepare_device()
{
    echo " * Checking available devices..."
    ping -c 1 $IP > /dev/null 2>&1
    reachable="$?"
    if [ "$reachable" -ne "0" ]; then
        echo "ERR: no device with address $IP found"
        exit 1
    fi

    echo " * Enabling root access..."
    adb root

    echo " * Remounting system partition..."
    adb remount


    echo " * Creating local system partition..."
    rm -rf gapps/sys > /dev/null 2>&1
    mkdir -p gapps/sys
    for dir in gapps/tmp/*/
    do
      pkg=${dir%*/}
      dpi=$(ls -1 $pkg | head -1)

      echo "  - including $pkg/$dpi"
      rsync -aq $pkg/$dpi/ gapps/sys/
    done
}

install_package()
{
    echo " * Removing old package installer..."
    adb shell "rm -rf system/priv-app/PackageInstaller"

    echo " * Pushing system files..."
    adb push gapps/sys/app /system
	adb push gapps/sys/etc /system
	adb push gapps/sys/framework /system
	adb push gapps/sys/priv-app /system
    
	echo " * Enforcing a reboot, please be patient..."
    adb reboot & sleep 10

    echo " * Waiting for ADB (errors are OK)..."
    while true; do
        sleep 1
        adb kill-server > /dev/null
        adb connect $IP > /dev/null
        if $(adb shell getprop sys.boot_completed | tr -d '\r') == 1; then
            break
        fi
    done

    echo " * Applying correct permissions..."
    adb shell "pm grant com.google.android.gms android.permission.ACCESS_COARSE_LOCATION"
    adb shell "pm grant com.google.android.gms android.permission.ACCESS_FINE_LOCATION"
    adb shell "pm grant com.google.android.tungsten.setupwraith android.permission.READ_PHONE_STATE"
}

# ------------------------------------------------
# Script entry point
# ------------------------------------------------

echo "GApps installation script for RPi"
echo "Used package: $PACKAGE"
echo "ADB IP address: $IP"
echo ""

IP=$1
prepare_device
install_package

echo "All done. The device will reboot once again."
adb reboot

#enjoy!