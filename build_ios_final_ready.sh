#!/bin/bash

echo "🍎 iOS Build Script - Ready for Xcode"
echo "======================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    print_error "pubspec.yaml not found. Please run this script from the Flutter project root."
    exit 1
fi

echo ""
print_info "Checking iOS build prerequisites..."

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    print_error "Xcode is not installed or not in PATH"
    echo ""
    echo "📋 To fix this issue:"
    echo "1. Install Xcode from the App Store"
    echo "2. Run: sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer"
    echo "3. Run: sudo xcodebuild -runFirstLaunch"
    echo "4. Run this script again"
    echo ""
    exit 1
fi

# Check xcode-select path
XCODE_PATH=$(xcode-select --print-path)
if [[ "$XCODE_PATH" == *"CommandLineTools"* ]]; then
    print_error "Xcode command line tools detected, but full Xcode is required"
    echo ""
    echo "📋 To fix this issue:"
    echo "Run: sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer"
    echo ""
    exit 1
fi

print_status "Xcode is properly installed and configured"

# Check Flutter iOS support
if ! flutter config | grep -q "enable-ios: true"; then
    print_warning "Enabling iOS support in Flutter..."
    flutter config --enable-ios
fi

print_status "Starting iOS build process..."

# Step 1: Clean project
print_info "Step 1: Cleaning Flutter project..."
flutter clean

# Step 2: Get dependencies
print_info "Step 2: Getting Flutter dependencies..."
flutter pub get

# Step 3: Clean and install iOS pods
print_info "Step 3: Installing iOS pods..."
cd ios
rm -rf Pods Podfile.lock .symlinks build
pod install
cd ..

# Step 4: Build iOS app
print_info "Step 4: Building iOS app..."
echo ""
print_warning "Building for device with codesigning disabled..."

if flutter build ios --release --no-codesign; then
    echo ""
    print_status "🎉 iOS build completed successfully!"
    
    # Show build artifacts
    echo ""
    echo "📦 Build artifacts created:"
    if [ -d "build/ios/iphoneos/Runner.app" ]; then
        echo "   • Device build: $(du -sh build/ios/iphoneos/Runner.app | cut -f1)"
    fi
    if [ -d "build/ios/Release-iphoneos/Runner.app" ]; then
        echo "   • Release build: $(du -sh build/ios/Release-iphoneos/Runner.app | cut -f1)"
    fi
    
    echo ""
    print_status "✨ iOS build process completed successfully!"
    echo ""
    echo "📋 Next steps:"
    echo "   1. Open ios/Runner.xcworkspace in Xcode"
    echo "   2. Select your development team for code signing"
    echo "   3. Build and run on device or simulator"
    echo ""
    
else
    print_error "iOS build failed"
    echo ""
    echo "🔧 Troubleshooting suggestions:"
    echo "   1. Check Xcode version compatibility with Flutter"
    echo "   2. Verify iOS deployment target in ios/Podfile"
    echo "   3. Try building with Xcode directly:"
    echo "      open ios/Runner.xcworkspace"
    echo ""
    
    exit 1
fi
