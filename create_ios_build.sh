#!/bin/bash

# Comprehensive iOS Build Script for iSpeedScan
# This script attempts multiple approaches to create a working iOS build

set -e

echo "🚀 Starting comprehensive iOS build process..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    print_error "pubspec.yaml not found. Please run this script from the Flutter project root."
    exit 1
fi

print_step "1. Cleaning everything..."
flutter clean
rm -rf ios/Pods ios/Podfile.lock
rm -rf build/

print_step "2. Getting dependencies..."
flutter pub get

print_step "3. Installing iOS pods..."
cd ios
pod install
cd ..

print_step "4. Attempting Flutter build for iOS..."

# Try different build approaches
BUILD_SUCCESS=false

# Approach 1: Standard Flutter build
print_status "Trying standard Flutter build..."
if flutter build ios --release --no-codesign; then
    print_status "✅ Standard Flutter build succeeded!"
    BUILD_SUCCESS=true
else
    print_warning "Standard Flutter build failed, trying alternative approaches..."
fi

# Approach 2: Build with verbose output to diagnose issues
if [ "$BUILD_SUCCESS" = false ]; then
    print_status "Trying Flutter build with verbose output..."
    if flutter build ios --release --no-codesign --verbose; then
        print_status "✅ Verbose Flutter build succeeded!"
        BUILD_SUCCESS=true
    else
        print_warning "Verbose Flutter build also failed..."
    fi
fi

# Approach 3: Try building just the framework first
if [ "$BUILD_SUCCESS" = false ]; then
    print_status "Trying to build Flutter framework separately..."
    if flutter assemble --output=build/ios/framework/Release/ ios_framework_Release; then
        print_status "Flutter framework built successfully, now trying full build..."
        if flutter build ios --release --no-codesign; then
            print_status "✅ Framework-first approach succeeded!"
            BUILD_SUCCESS=true
        fi
    fi
fi

# Check if we have a successful build
if [ "$BUILD_SUCCESS" = true ]; then
    print_step "5. Creating IPA from successful build..."
    
    # Look for the built app
    APP_PATH=""
    if [ -d "build/ios/iphoneos/Runner.app" ]; then
        APP_PATH="build/ios/iphoneos/Runner.app"
    elif [ -d "build/ios/Release-iphoneos/Runner.app" ]; then
        APP_PATH="build/ios/Release-iphoneos/Runner.app"
    fi
    
    if [ -n "$APP_PATH" ]; then
        print_status "Found app at: $APP_PATH"
        
        # Create IPA
        mkdir -p build/ios/ipa/Payload
        cp -r "$APP_PATH" build/ios/ipa/Payload/
        cd build/ios/ipa
        zip -r Runner.ipa Payload/
        cd ../../..
        
        if [ -f "build/ios/ipa/Runner.ipa" ]; then
            print_status "✅ IPA created successfully!"
            print_status "📱 IPA location: build/ios/ipa/Runner.ipa"
            IPA_SIZE=$(du -h build/ios/ipa/Runner.ipa | cut -f1)
            print_status "📦 IPA size: $IPA_SIZE"
            
            print_status "🎉 iOS build process completed successfully!"
            print_status "📁 Build artifacts:"
            print_status "   - App: $APP_PATH"
            print_status "   - IPA: build/ios/ipa/Runner.ipa"
            
            # Show app info
            print_status "📋 App Information:"
            if command -v plutil &> /dev/null; then
                BUNDLE_ID=$(plutil -p "$APP_PATH/Info.plist" | grep CFBundleIdentifier | cut -d'"' -f4)
                VERSION=$(plutil -p "$APP_PATH/Info.plist" | grep CFBundleShortVersionString | cut -d'"' -f4)
                print_status "   - Bundle ID: $BUNDLE_ID"
                print_status "   - Version: $VERSION"
            fi
            
            exit 0
        else
            print_error "Failed to create IPA"
            exit 1
        fi
    else
        print_error "Could not find built app"
        exit 1
    fi
else
    print_error "❌ All build approaches failed"
    print_error "This appears to be a Flutter framework configuration issue."
    print_error "Possible solutions:"
    print_error "1. Update Flutter: flutter upgrade"
    print_error "2. Update Xcode and iOS SDK"
    print_error "3. Check iOS deployment target in ios/Podfile"
    print_error "4. Try building with a different Flutter channel"
    exit 1
fi
