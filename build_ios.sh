#!/bin/bash

# iOS Build Script for iSpeedScan
# This script builds the iOS app and creates an IPA file

set -e

echo "🚀 Starting iOS build process..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    print_error "pubspec.yaml not found. Please run this script from the Flutter project root."
    exit 1
fi

# Clean previous builds
print_status "Cleaning previous builds..."
flutter clean

# Get dependencies
print_status "Getting Flutter dependencies..."
flutter pub get

# Create build directory
mkdir -p build/ios

# Try building with Flutter first to generate necessary files
print_status "Building Flutter framework..."
flutter build ios --release --no-codesign || {
    print_warning "Flutter build failed, trying alternative approach..."

    # Try building just the Flutter framework
    print_status "Building Flutter framework only..."
    flutter assemble --output=build/ios/framework/Release/ ios_framework_Release || {
        print_error "Failed to build Flutter framework"
        exit 1
    }
}
xcodebuild -workspace ios/Runner.xcworkspace \
           -scheme Runner \
           -configuration Release \
           -destination generic/platform=iOS \
           -archivePath build/ios/Runner.xcarchive \
           archive \
           CODE_SIGNING_ALLOWED=NO \
           CODE_SIGNING_REQUIRED=NO \
           CODE_SIGN_IDENTITY="" \
           PROVISIONING_PROFILE="" \
           DEVELOPMENT_TEAM=""

# Check if build was successful
if [ $? -eq 0 ]; then
    print_status "✅ iOS archive created successfully!"

    # Create export options plist for unsigned IPA
    print_status "Creating export options..."
    cat > build/ios/ExportOptions.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>development</string>
    <key>compileBitcode</key>
    <false/>
    <key>signingStyle</key>
    <string>manual</string>
    <key>stripSwiftSymbols</key>
    <true/>
</dict>
</plist>
EOF

    # Export the archive to IPA
    print_status "Exporting IPA..."
    xcodebuild -exportArchive \
               -archivePath build/ios/Runner.xcarchive \
               -exportPath build/ios/ipa \
               -exportOptionsPlist build/ios/ExportOptions.plist

    if [ $? -eq 0 ]; then
        print_status "✅ IPA exported successfully!"
        print_status "📱 IPA location: build/ios/ipa/Runner.ipa"

        # Show file size
        if [ -f "build/ios/ipa/Runner.ipa" ]; then
            IPA_SIZE=$(du -h build/ios/ipa/Runner.ipa | cut -f1)
            print_status "📦 IPA size: $IPA_SIZE"
        fi

        print_status "🎉 iOS build process completed successfully!"
        print_status "📁 Build artifacts:"
        print_status "   - Archive: build/ios/Runner.xcarchive"
        print_status "   - IPA: build/ios/ipa/Runner.ipa"
    else
        print_error "❌ Failed to export IPA"

        # Try creating a simple unsigned IPA manually
        print_warning "Attempting to create unsigned IPA manually..."

        if [ -d "build/ios/Runner.xcarchive/Products/Applications/Runner.app" ]; then
            mkdir -p build/ios/manual_ipa/Payload
            cp -r build/ios/Runner.xcarchive/Products/Applications/Runner.app build/ios/manual_ipa/Payload/
            cd build/ios/manual_ipa
            zip -r ../Runner_unsigned.ipa Payload/
            cd ../../..

            if [ -f "build/ios/Runner_unsigned.ipa" ]; then
                print_status "✅ Unsigned IPA created manually!"
                print_status "📱 Unsigned IPA location: build/ios/Runner_unsigned.ipa"
                IPA_SIZE=$(du -h build/ios/Runner_unsigned.ipa | cut -f1)
                print_status "📦 IPA size: $IPA_SIZE"
            fi
        fi
    fi
else
    print_error "❌ iOS build failed"
    print_error "Please check the build logs above for specific errors."
    exit 1
fi
