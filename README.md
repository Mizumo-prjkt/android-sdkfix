# Android SDK Fix for COW-based Filesystem Problems

This repo contains a fix to address the COW problems for Android SDK, which is not working on my machine.

## The Problem
This script is not realy innovational. A basic script that shpuld be adressing some issues regarding COW-based filesystems having issues with the Android SDK.

I have tried to solve them by using a script that uses fuse-overlayfs to mount the Android SDK in a way that it is not affected by the COW problems.

## The Fix
The script uses fuse-overlayfs to mount the Android SDK in a way that it is not affected by the COW problems.

## Installation

### Install fuse-overlayfs

```bash
sudo pacman -S fuse-overlayfs
```

## Usage

### Install

```bash
./run.sh -i
```

### Uninstall

```bash
./run.sh -r
```