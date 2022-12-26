#!/bin/bash
flutter build linux
rm -rf ./release/linux
cp -R ./build/linux/x64/release/bundle/ ./release/linux/
