#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Emojis (using simple alternatives to avoid encoding issues)
CHECK="✓"
CROSS="✗"
WARNING="⚠"
INFO="ℹ"

echo -e "${BLUE}${INFO} Flutter Debit Tracker Test Suite${NC}"
echo "========================================"

# Function to run tests and capture results
run_tests() {
    local test_path="$1"
    local test_name="$2"
    
    echo -e "${BLUE}${INFO} Running $test_name...${NC}"
    echo "---------------------------"
    
    if flutter test "$test_path"; then
        echo -e "${GREEN}${CHECK} $test_name PASSED${NC}"
        return 0
    else
        echo -e "${RED}${CROSS} $test_name FAILED${NC}"
        return 1
    fi
}

# Initialize counters
total_tests=0
passed_tests=0

echo -e "${BLUE}${INFO} Unit Tests${NC}"
echo "==============="

# Run unit tests
if run_tests "test/unit/" "Unit Tests"; then
    ((passed_tests++))
fi
((total_tests++))

echo ""
echo -e "${BLUE}${INFO} Widget Tests${NC}"
echo "=================="

# Run widget tests
if run_tests "test/widget/" "Widget Tests"; then
    ((passed_tests++))
fi
((total_tests++))

echo ""
echo -e "${BLUE}${INFO} Main App Test${NC}"
echo "---------------------------"

# Run main app test
if run_tests "test/widget_test.dart" "Main App Test"; then
    ((passed_tests++))
fi
((total_tests++))

# Generate coverage report if lcov is available
echo ""
if command -v lcov &> /dev/null; then
    echo -e "${BLUE}${INFO} Generating coverage report...${NC}"
    flutter test --coverage
    if [ -f "coverage/lcov.info" ]; then
        echo -e "${GREEN}${CHECK} Coverage report generated in coverage/lcov.info${NC}"
    fi
else
    echo -e "${YELLOW}${WARNING} lcov not found, coverage report not generated${NC}"
fi

echo ""
echo -e "${BLUE}${INFO} Test Summary${NC}"
echo "==============="
echo -e "Tests passed: ${GREEN}$passed_tests/$total_tests${NC}"

if [ $passed_tests -eq $total_tests ]; then
    echo -e "${GREEN}${CHECK} All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}${CROSS} Some tests failed!${NC}"
    exit 1
fi 