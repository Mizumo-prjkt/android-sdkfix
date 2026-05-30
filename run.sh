#!/bin/bash

# Files and Directories
SERVICE="android_sdk_overlay.service"
TARGET="/home/$USER/.config/systemd/user/android_sdk_overlay.service"
DIR_TARGET="/home/$USER/.config/systemd/user"
CONFIG_DIR="/home/$USER/.config/"

# .bashrc configuration for android sdk
BASHRC_TARGET="/home/$USER/.bashrc"

STRINGS="""


# Point Android Home to your new FUSE overlay mount point
export ANDROID_HOME="$HOME/.local/android/sdk"

# Add the tools to your system PATH so you can run 'sdkmanager' or 'adb' anywhere
export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools"
"""


# Color
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
NC="\033[0m"

copy() {
    cp -rf $SERVICE $TARGET
}

check_and_deploy() {
    if [ ! -d "$DIR_TARGET" ]
    then
        echo -e "$RED[ERROR]$NC: Systemd user directory not found..."
        echo -e "$YELLOW[ACTION]$NC: Investigating..."
        identify_problem --ns
    fi
    
    echo -e "$YELLOW[ACTION]$NC: Copying SDK service..."
    copy
    if [ $? -eq 0 ]
    then
        echo -e "$GREEN[INFO]$NC: Copied SDK service..."
    else
        echo -e "$RED[ERROR]$NC: Failed to copy SDK service..."
        identify_problem -nc
    fi
    echo -e "$YELLOW[APPLY ENV]$NC: Applying the environment variables for android sdk..."
    echo "$STRINGS" >> $BASHRC_TARGET
    if [ $? -eq 0 ]
    then
        echo -e "$GREEN[INFO]$NC: Applied environment variables..."
    else
        echo -e "$RED[ERROR]$NC: Failed to apply environment variables..."
        identify_problem -env
    fi
}

identify_problem() {
    echo -e "$YELLOW[IDENTIFY]$NC: Checking for possible issues..."
    if [ "$1" == "--ns" ]
    then
        # Lets check for a possible missing systemd user
        if [ -d "$DIR_TARGET" ]
        then
            echo -e "$GREEN[INFO]$NC: Systemd user directory found..."
        else
            echo -e "$RED[ERROR]$NC: Systemd user directory not found..."
            echo -e "$YELLOW[ACTION]$NC: Creating systemd user directory..."
            mkdir -p "$DIR_TARGET"
            if [ $? -eq 0 ]
            then
                echo -e "$GREEN[INFO]$NC: Systemd user directory created..."
            else
                echo -e "$RED[ERROR]$NC: Failed to create systemd user directory..."
                echo -e "Aborting"
                exit 1
            fi
        fi
    elif [ "$1" == "-nc" ]; then
        # Find if android_sdk_overlay.service exists in our current position...
        if [ -d "$(pwd)/$SERVICE" ]
        then
            echo -e "$GREEN[INFO]$NC: Service file found... "
            echo -e "Still Strange why it isn't located at $TARGET"
            # Check permissions we have on .config directory
            if [ -w "$CONFIG_DIR" ]
            then
                echo -e "$GREEN[INFO]$NC: Write permissions on .config directory..."
                echo -e "$GREEN[INFO]$NC: Advise to redo the whole thing"
                exit
            else
                echo -e "$RED[ERROR]$NC: Write permissions on .config directory..."
                echo -e "$YELLOW[ACTION]$NC: Please run this script with sudo... $RED(NOT RECOMMENDED)$NC"
                echo -e "            $YELLOW Or solve permission issues by your own...$NC"
                exit 1
            fi
        else
            echo -e "$RED[ERROR]$NC: Service file not found..."
            echo -e "$YELLOW[ACTION]$NC: Please run this script with sudo..."
            exit 1
        fi
    elif [ "$1" == "-env" ]; then
        # Check if bashrc exists...
        if [ -f "$BASHRC_TARGET" ]
        then
            echo -e "$GREEN[INFO]$NC: Bashrc file found..."
        else
            echo -e "$RED[ERROR]$NC: Bashrc file not found..."
            echo -e "$YELLOW[ACTION]$NC: Creating bashrc file..."
            touch "$BASHRC_TARGET"
            if [ $? -eq 0 ]
            then
                echo -e "$GREEN[INFO]$NC: Bashrc file created..."
            else
                echo -e "$RED[ERROR]$NC: Failed to create bashrc file..."
                exit 1
            fi
        fi
    fi
}

spawn_user_systemd() {
    # Let SystemD process the overlay using the service file
    echo -e "$YELLOW[ACTION]$NC: Spawning user systemd to process the overlay..."
    systemctl --user daemon-reload
    systemctl --user enable $SERVICE
    systemctl --user start $SERVICE

    # Check if the service is running
    if [ $? -eq 0 ]
    then
        echo -e "$GREEN[INFO]$NC: Successfully spawned user systemd..."
        echo -e "$GREEN[INFO]$NC: Done!!!"
        systemctl --user status android_sdk_overlay.service
    else
        echo -e "$RED[ERROR]$NC: Failed to spawn user systemd..."
        identify_problem --ns
    fi
}


remove() {
    # Check if the service is still active
    # We should stop the service and remove the service file
    echo -e "$YELLOW[ACTION]$NC: Stopping and removing user systemd..."
    systemctl --user stop $SERVICE
    systemctl --user disable $SERVICE
    rm -f $TARGET
    systemctl --user daemon-reload
    echo -e "$GREEN[INFO]$NC: Successfully stopped and removed user systemd..."
    echo -e "$GREEN[INFO]$NC: Done!!!"
}

help() {
    cat << EOF
    Usage: $0 [OPTIONS]
    Options:
        -i    Install user systemd
        -r    Remove user systemd
        -s    Check Status
    
EOF
}

check_if_fuse_available() {
    # Check if fuse-overlayfs is installed
    if command -v fuse-overlayfs &> /dev/null
    then
        echo -e "$GREEN[INFO]$NC: fuse-overlayfs is installed..."
    else
        echo -e "$RED[ERROR]$NC: fuse-overlayfs is not installed..."
        echo -e "$YELLOW[ACTION]$NC: Please install fuse-overlayfs..."
        exit 1
    fi
}

status() {
    echo -e "$YELLOW[INFO]$NC: Checking status of user systemd..."
    systemctl --user status $SERVICE
}

thread() {
    # the __main__ function
    case $1 in 
        -i)
            echo -e "$YELLOW[INFO]$NC: Installing user systemd..."
            check_if_fuse_available
            check_and_deploy
            spawn_user_systemd
            ;; 
        -r)
            echo -e "$YELLOW[INFO]$NC: Removing user systemd..."
            remove
            ;; 
        -h | --help)
            help
            exit
            ;;
        -s)
            status
            exit
            ;;
        *)
            echo -e "$RED[ERROR]$NC: Invalid option..."
            help
            exit 1
            ;;
    esac
}

thread $1

