#!/bin/bash

# iOS Build Fix Script for iSpeedScan
# This script temporarily disables problematic plugins to create a working iOS build

set -e

echo "🔧 Starting iOS build fix process..."

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

# Backup original pubspec.yaml
print_status "Creating backup of pubspec.yaml..."
cp pubspec.yaml pubspec.yaml.backup

# Create a temporary pubspec.yaml with problematic plugins commented out
print_status "Creating temporary pubspec.yaml without problematic plugins..."
sed -e 's/^  pdfx:/  # pdfx:/' \
    -e 's/^  cunning_document_scanner:/  # cunning_document_scanner:/' \
    pubspec.yaml > pubspec_temp.yaml

mv pubspec_temp.yaml pubspec.yaml

# Clean and get dependencies
print_status "Cleaning and getting dependencies..."
flutter clean
flutter pub get

# Clean iOS build
print_status "Cleaning iOS pods..."
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..

# Try building iOS
print_status "Attempting iOS build..."
flutter build ios --release --no-codesign

# Check if build was successful
if [ $? -eq 0 ]; then
    print_status "✅ iOS build successful!"
    
    # Create IPA from the built app
    if [ -d "build/ios/iphoneos/Runner.app" ]; then
        print_status "Creating IPA..."
        mkdir -p build/ios/ipa/Payload
        cp -r build/ios/iphoneos/Runner.app build/ios/ipa/Payload/
        cd build/ios/ipa
        zip -r Runner.ipa Payload/
        cd ../../..
        
        if [ -f "build/ios/ipa/Runner.ipa" ]; then
            print_status "✅ IPA created successfully!"
            print_status "📱 IPA location: build/ios/ipa/Runner.ipa"
            IPA_SIZE=$(du -h build/ios/ipa/Runner.ipa | cut -f1)
            print_status "📦 IPA size: $IPA_SIZE"
        fi
    fi
    
    print_status "🎉 iOS build completed successfully!"
    print_warning "Note: Some plugins were temporarily disabled for this build."
    print_warning "To restore full functionality, run: mv pubspec.yaml.backup pubspec.yaml"
    
else
    print_error "❌ iOS build failed even with plugins disabled"
    print_status "Restoring original pubspec.yaml..."
    mv pubspec.yaml.backup pubspec.yaml
    exit 1
fi
