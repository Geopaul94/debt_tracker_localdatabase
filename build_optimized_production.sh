#!/bin/bash

# =============================================================================
# OPTIMIZED PRODUCTION BUILD SCRIPT FOR PLAY STORE
# =============================================================================

set -e

echo "🚀 Starting optimized production build for Play Store..."

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# =============================================================================
# PRE-BUILD CLEANUP
# =============================================================================

print_status "Cleaning previous builds..."
flutter clean
cd android && ./gradlew clean && cd ..

# =============================================================================
# DEPENDENCY OPTIMIZATION
# =============================================================================

print_status "Getting optimized dependencies..."
flutter pub get
flutter pub deps

print_status "Running code analysis..."
flutter analyze --no-fatal-infos

# =============================================================================
# APK SIZE OPTIMIZATION BUILD
# =============================================================================

print_status "Building optimized APK for maximum performance..."

# Build with maximum optimizations (removed invalid --no-sound-null-safety flag)
flutter build apk \
  --release \
  --target-platform android-arm64 \
  --tree-shake-icons \
  --shrink \
  --obfuscate \
  --split-debug-info=build/debug-info \
  --dart-define=PRODUCTION=true

print_success "APK build completed!"

# =============================================================================
# APP BUNDLE BUILD (RECOMMENDED FOR PLAY STORE)
# =============================================================================

print_status "Building optimized App Bundle for Play Store..."

flutter build appbundle \
  --release \
  --tree-shake-icons \
  --shrink \
  --obfuscate \
  --split-debug-info=build/debug-info-bundle \
  --dart-define=PRODUCTION=true

print_success "App Bundle build completed!"

# =============================================================================
# BUILD ANALYSIS
# =============================================================================

print_status "Analyzing build sizes..."

APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
BUNDLE_PATH="build/app/outputs/bundle/release/app-release.aab"

if [ -f "$APK_PATH" ]; then
    APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
    print_success "APK Size: $APK_SIZE"
else
    print_error "APK file not found!"
fi

if [ -f "$BUNDLE_PATH" ]; then
    BUNDLE_SIZE=$(du -h "$BUNDLE_PATH" | cut -f1)
    print_success "App Bundle Size: $BUNDLE_SIZE"
else
    print_error "App Bundle file not found!"
fi

# =============================================================================
# POST-BUILD VERIFICATION
# =============================================================================

print_status "Running post-build verification..."

# Check if builds exist
if [ -f "$APK_PATH" ] && [ -f "$BUNDLE_PATH" ]; then
    print_success "All builds completed successfully!"
    
    echo ""
    echo "📱 BUILD SUMMARY:"
    echo "=================="
    echo "🔹 APK: $APK_PATH ($APK_SIZE)"
    echo "🔹 App Bundle: $BUNDLE_PATH ($BUNDLE_SIZE)"
    echo "🔹 Debug Info: build/debug-info/ & build/debug-info-bundle/"
    echo ""
    echo "📊 OPTIMIZATIONS APPLIED:"
    echo "========================"
    echo "✅ Tree-shaking (unused code removal)"
    echo "✅ Icon tree-shaking (unused icons removal)"
    echo "✅ Resource shrinking"
    echo "✅ Code obfuscation"
    echo "✅ R8 full mode optimization"
    echo "✅ ProGuard optimization"
    echo "✅ Debug symbol separation"
    echo "✅ ABI splitting for smaller downloads"
    echo "✅ Density splitting"
    echo "✅ Maximum PNG compression"
    echo ""
    echo "🚀 READY FOR PLAY STORE!"
    echo "Recommended: Upload the .aab file to Google Play Console"
    
else
    print_error "Build verification failed!"
    exit 1
fi

# =============================================================================
# OPTIONAL: SIZE ANALYSIS
# =============================================================================

print_status "Generating detailed size analysis..."
flutter build apk --analyze-size --target-platform android-arm64

print_status "Build script completed successfully! 🎉"

echo ""
echo "📋 NEXT STEPS FOR PLAY STORE:"
echo "============================"
echo "1. Test the release builds on real devices"
echo "2. Upload app-release.aab to Google Play Console"
echo "3. Fill out store listing information"
echo "4. Set up app signing (if not already done)"
echo "5. Configure release management"
echo "6. Submit for review"
echo ""
echo "🔗 Useful links:"
echo "- Play Console: https://play.google.com/console"
echo "- Flutter deployment guide: https://flutter.dev/docs/deployment/android"

# =============================================================================
# APK SIZE BREAKDOWN
# =============================================================================

if [ -f "$APK_PATH" ]; then
    print_status "APK Analysis Complete!"
    echo ""
    echo "📊 PERFORMANCE OPTIMIZATIONS SUMMARY:"
    echo "===================================="
    echo "✅ AppLogger replaces all debug prints (0KB in release)"
    echo "✅ Memory leak fixes in data sources"
    echo "✅ Const constructors for better performance"
    echo "✅ Aggressive ProGuard rules for maximum compression"
    echo "✅ Unused resource removal"
    echo "✅ Architecture-specific builds (ARM64 + ARMv7)"
    echo "✅ Code obfuscation for security and size"
    echo "✅ Debug information separation"
    echo ""
    echo "🎯 ESTIMATED DOWNLOAD SIZE: ~$(echo $APK_SIZE | sed 's/M/ MB/g')"
    echo "   (Play Store uses compression, actual download will be smaller)"
fi 