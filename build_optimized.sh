#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Building optimized AAB for Play Store...${NC}"

# Clean previous builds
flutter clean
flutter pub get

# Build with maximum optimizations
flutter build appbundle \
  --release \
  --obfuscate \
  --split-debug-info=build/app/outputs/symbols \
  --tree-shake-icons \
  --shrink \
  --no-tree-shake-icons \
  --dart-define=dart.vm.profile=false \
  --dart-define=dart.vm.product=true

echo -e "${GREEN}Optimized AAB built successfully!${NC}"
echo "Location: build/app/outputs/bundle/release/app-release.aab"

# Show file size
if [ -f "build/app/outputs/bundle/release/app-release.aab" ]; then
    size=$(du -h build/app/outputs/bundle/release/app-release.aab | cut -f1)
    echo -e "${GREEN}AAB Size: $size${NC}"
fi 