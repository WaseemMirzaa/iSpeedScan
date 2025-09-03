#!/bin/bash

echo "🚀 Starting comprehensive iOS build process..."

# Set error handling
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    print_error "pubspec.yaml not found. Please run this script from the Flutter project root."
    exit 1
fi

print_status "Step 1: Cleaning Flutter project..."
flutter clean

print_status "Step 2: Getting Flutter dependencies..."
flutter pub get

print_status "Step 3: Cleaning iOS workspace..."
cd ios
rm -rf Pods Podfile.lock
rm -rf build/
rm -rf .symlinks/
cd ..

print_status "Step 4: Installing iOS pods..."
cd ios
pod install --repo-update
cd ..

print_status "Step 5: Attempting iOS build..."
print_warning "Building for device with codesigning disabled..."

# Try building with different approaches
echo "Attempting standard build..."
if flutter build ios --release --no-codesign; then
    print_status "✅ iOS build completed successfully!"
    
    # Show build artifacts
    echo ""
    echo "📦 Build artifacts created:"
    if [ -d "build/ios/iphoneos/Runner.app" ]; then
        echo "   • Runner.app: $(du -sh build/ios/iphoneos/Runner.app | cut -f1)"
    fi
    if [ -d "build/ios/Release-iphoneos/Runner.app" ]; then
        echo "   • Runner.app: $(du -sh build/ios/Release-iphoneos/Runner.app | cut -f1)"
    fi
    
    echo ""
    print_status "🎉 iOS build process completed successfully!"
    echo ""
    echo "📋 Next steps:"
    echo "   1. Open ios/Runner.xcworkspace in Xcode"
    echo "   2. Select your development team for code signing"
    echo "   3. Build and run on device or simulator"
    echo ""
    
else
    print_error "Standard build failed. This appears to be a Flutter framework linking issue."
    echo ""
    echo "🔧 Troubleshooting suggestions:"
    echo "   1. Update Flutter: flutter upgrade"
    echo "   2. Check Xcode version compatibility"
    echo "   3. Try building with Xcode directly:"
    echo "      open ios/Runner.xcworkspace"
    echo "   4. Verify iOS deployment target in ios/Podfile"
    echo ""
    echo "📊 Current configuration:"
    echo "   • Flutter version: $(flutter --version | head -n1)"
    echo "   • Xcode version: $(xcodebuild -version | head -n1)"
    echo "   • iOS deployment target: $(grep 'platform :ios' ios/Podfile)"
    echo ""
    
    exit 1
fi
