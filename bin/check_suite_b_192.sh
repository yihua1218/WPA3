#!/bin/bash

# Script to check if certificates support WPA-EAP-SUITE-B-192
# Requirements:
# - ECDSA with P-384 curve
# - SHA-384 signature algorithm

# Load configuration file from project root
CONFIG_FILE="$(dirname "$(dirname "$0")")/cert_config.conf"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Configuration file not found: $CONFIG_FILE"
    exit 1
fi

source "$CONFIG_FILE"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'
YELLOW='\033[1;33m'

# Usage information
usage() {
    echo "Usage: $0 [directory]"
    echo "  directory: Directory containing ca.der and client.p12 (default: certs/)"
    echo "Example: $0 certs-suite-b192"
    exit 1
}

check_requirements() {
    if ! command -v openssl &> /dev/null; then
        echo -e "${RED}Error: OpenSSL is not installed${NC}"
        exit 1
    fi
}

print_result() {
    local name=$1
    local result=$2
    if [ "$result" = true ]; then
        echo -e "${GREEN}✓ $name supports Suite-B-192${NC}"
    else
        echo -e "${RED}✗ $name does not support Suite-B-192${NC}"
    fi
}

check_ca_cert() {
    local cert_file=$1
    local supports_suite_b=true
    
    echo -e "\n${YELLOW}Checking CA certificate ($cert_file):${NC}"
    
    # Check if file exists
    if [ ! -f "$cert_file" ]; then
        echo -e "${RED}Error: Certificate file not found${NC}"
        return 1
    fi
    
    # Get certificate info
    local cert_info
    cert_info=$(openssl x509 -inform DER -in "$cert_file" -text -noout 2>/dev/null)
    
    # Check signature algorithm
    if ! echo "$cert_info" | grep -q "Signature Algorithm: ecdsa-with-SHA384"; then
        echo -e "${RED}✗ Signature Algorithm: Not using ECDSA with SHA384${NC}"
        supports_suite_b=false
    else
        echo -e "${GREEN}✓ Signature Algorithm: Using ECDSA with SHA384${NC}"
    fi
    
    # Check public key
    if ! echo "$cert_info" | grep -q "Public Key Algorithm: id-ecPublicKey"; then
        echo -e "${RED}✗ Key Algorithm: Not using ECDSA${NC}"
        supports_suite_b=false
    else
        echo -e "${GREEN}✓ Key Algorithm: Using ECDSA${NC}"
    fi
    
    # Check curve
    if ! echo "$cert_info" | grep -q "NIST CURVE: P-384"; then
        echo -e "${RED}✗ Curve: Not using P-384${NC}"
        supports_suite_b=false
    else
        echo -e "${GREEN}✓ Curve: Using P-384${NC}"
    fi
    
    [ "$supports_suite_b" = true ]
    return $?
}

check_client_cert() {
    local cert_file=$1
    local supports_suite_b=true
    
    echo -e "\n${YELLOW}Checking Client certificate ($cert_file):${NC}"
    
    # Check if file exists
    if [ ! -f "$cert_file" ]; then
        echo -e "${RED}Error: Certificate file not found${NC}"
        return 1
    fi
    
    # Extract certificate from PKCS12 and convert to text
    local cert_info
    cert_info=$(openssl pkcs12 -in "$cert_file" -nodes -passin "pass:$PKCS12_PASSWORD" 2>/dev/null | \
                openssl x509 -text 2>/dev/null)
    
    if [ -z "$cert_info" ]; then
        echo -e "${RED}Error: Failed to read PKCS12 file. Check your password in $CONFIG_FILE${NC}"
        return 1
    fi
    
    # Check signature algorithm
    if ! echo "$cert_info" | grep -q "Signature Algorithm: ecdsa-with-SHA384"; then
        echo -e "${RED}✗ Signature Algorithm: Not using ECDSA with SHA384${NC}"
        supports_suite_b=false
    else
        echo -e "${GREEN}✓ Signature Algorithm: Using ECDSA with SHA384${NC}"
    fi
    
    # Check public key
    if ! echo "$cert_info" | grep -q "Public Key Algorithm: id-ecPublicKey"; then
        echo -e "${RED}✗ Key Algorithm: Not using ECDSA${NC}"
        supports_suite_b=false
    else
        echo -e "${GREEN}✓ Key Algorithm: Using ECDSA${NC}"
    fi
    
    # Check curve
    if ! echo "$cert_info" | grep -q "NIST CURVE: P-384"; then
        echo -e "${RED}✗ Curve: Not using P-384${NC}"
        supports_suite_b=false
    else
        echo -e "${GREEN}✓ Curve: Using P-384${NC}"
    fi
    
    [ "$supports_suite_b" = true ]
    return $?
}

main() {
    check_requirements
    
    # Get directory from argument or use default
    local CERT_DIR="certs"
    if [ $# -eq 1 ]; then
        CERT_DIR="$1"
    elif [ $# -gt 1 ]; then
        usage
    fi
    
    # Remove trailing slash if present
    CERT_DIR=${CERT_DIR%/}
    
    # Check if directory exists
    if [ ! -d "$CERT_DIR" ]; then
        echo -e "${RED}Error: Directory not found: $CERT_DIR${NC}"
        exit 1
    fi
    
    local ca_result=false
    local client_result=false
    
    echo -e "${YELLOW}Checking certificates in directory: $CERT_DIR${NC}"
    
    # Check CA certificate
    if check_ca_cert "$CERT_DIR/ca.der"; then
        ca_result=true
    fi
    
    # Check Client certificate
    if check_client_cert "$CERT_DIR/client.p12"; then
        client_result=true
    fi
    
    echo -e "\n${YELLOW}Final Results:${NC}"
    print_result "CA certificate" "$ca_result"
    print_result "Client certificate" "$client_result"
    
    if [ "$ca_result" = true ] && [ "$client_result" = true ]; then
        echo -e "\n${GREEN}Both certificates support WPA-EAP-SUITE-B-192!${NC}"
        exit 0
    else
        echo -e "\n${RED}One or more certificates do not support WPA-EAP-SUITE-B-192${NC}"
        exit 1
    fi
}

main "$@"
