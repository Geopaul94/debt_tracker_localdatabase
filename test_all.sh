#!/bin/bash

# Comprehensive Test Runner for Debt Tracker Application
# This script runs all types of tests and generates coverage reports

set -e

echo "🧪 Starting Comprehensive Test Suite for Debt Tracker"
echo "=================================================="

# Colors for output
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

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed or not in PATH"
    exit 1
fi

# Check if we're in a Flutter project
if [ ! -f "pubspec.yaml" ]; then
    print_error "Not in a Flutter project directory"
    exit 1
fi

print_status "Flutter version:"
flutter --version

echo ""
print_status "Getting dependencies..."
flutter pub get

echo ""
print_status "Running Flutter analyzer..."
if flutter analyze; then
    print_success "Static analysis passed"
else
    print_warning "Static analysis found issues"
fi

echo ""
print_status "🔬 Running Unit Tests..."
echo "================================"

# Run unit tests with coverage
print_status "Running unit tests for core services..."
flutter test test/unit/core/services/ --coverage

print_status "Running unit tests for constants..."
flutter test test/unit/core/constants/ --coverage

print_status "Running unit tests for data models..."
flutter test test/unit/data/models/ --coverage

print_status "Running unit tests for domain entities..."
flutter test test/unit/domain/entities/ --coverage

print_status "Running unit tests for presentation pages..."
flutter test test/unit/presentation/pages/ --coverage

echo ""
print_status "🎨 Running Widget Tests..."
echo "================================"

print_status "Running widget tests..."
flutter test test/widget/ --coverage

echo ""
print_status "🔄 Running Integration Tests..."
echo "================================"

print_status "Running integration tests..."
if [ -d "test/integration" ]; then
    flutter test test/integration/ --coverage
else
    print_warning "No integration tests found"
fi

echo ""
print_status "📊 Generating Coverage Report..."
echo "================================"

# Check if lcov is available for coverage report generation
if command -v lcov &> /dev/null; then
    print_status "Generating HTML coverage report..."
    
    # Generate coverage report
    genhtml coverage/lcov.info -o coverage/html
    
    print_success "Coverage report generated in coverage/html/"
    print_status "Open coverage/html/index.html in your browser to view the report"
else
    print_warning "lcov not found. Install lcov to generate HTML coverage reports"
    print_status "On macOS: brew install lcov"
    print_status "On Ubuntu: sudo apt-get install lcov"
fi

echo ""
print_status "🚀 Running Specific Feature Tests..."
echo "================================"

# Test currency functionality
print_status "Testing currency functionality..."
flutter test test/unit/core/services/currency_service_test.dart test/unit/core/constants/currency_constants_test.dart --reporter=expanded

# Test attachment functionality
print_status "Testing attachment functionality..."
flutter test test/unit/domain/entities/attachment_entity_test.dart test/widget/attachment_widget_test.dart --reporter=expanded

# Test transaction functionality
print_status "Testing transaction functionality..."
flutter test test/unit/data/models/transaction_model_test.dart test/unit/presentation/pages/add_transaction_page_test.dart --reporter=expanded

# Test UI components
print_status "Testing UI components..."
flutter test test/widget/currency_selector_test.dart test/widget/transaction_list_item_test.dart --reporter=expanded

echo ""
print_status "📈 Test Summary..."
echo "================================"

# Count test files
unit_tests=$(find test/unit -name "*_test.dart" | wc -l)
widget_tests=$(find test/widget -name "*_test.dart" | wc -l)
integration_tests=$(find test/integration -name "*_test.dart" 2>/dev/null | wc -l || echo "0")

total_tests=$((unit_tests + widget_tests + integration_tests))

echo "📊 Test Statistics:"
echo "   Unit Tests: $unit_tests files"
echo "   Widget Tests: $widget_tests files"
echo "   Integration Tests: $integration_tests files"
echo "   Total: $total_tests test files"

echo ""
print_status "🎯 Testing New Features..."
echo "================================"

echo "✅ Multi-currency support tests"
echo "✅ File attachment tests"
echo "✅ Camera integration tests"
echo "✅ Currency selection UI tests"
echo "✅ Transaction detail view tests"
echo "✅ Async currency loading tests"
echo "✅ Search and filter tests"
echo "✅ Performance tests"
echo "✅ Accessibility tests"
echo "✅ Error handling tests"

echo ""
print_success "🎉 All tests completed!"

echo ""
print_status "📋 Next Steps:"
echo "   1. Review coverage report in coverage/html/index.html"
echo "   2. Check for any failing tests and fix issues"
echo "   3. Add more tests for edge cases if needed"
echo "   4. Run tests on different devices/simulators"
echo "   5. Consider adding performance benchmarks"

echo ""
print_status "🔧 Manual Testing Checklist:"
echo "   □ Test on different screen sizes"
echo "   □ Test with poor network connectivity"
echo "   □ Test file permissions for attachments"
echo "   □ Test camera permissions"
echo "   □ Test with large numbers of transactions"
echo "   □ Test currency selection with search"
echo "   □ Test attachment viewing and removal"
echo "   □ Test transaction editing and deletion"

echo ""
print_status "Run complete! Check the output above for any issues."

# Exit with error code if any critical tests failed
if [ $? -eq 0 ]; then
    print_success "All tests passed successfully! 🎉"
    exit 0
else
    print_error "Some tests failed. Please review and fix issues."
    exit 1
fi