#!/bin/bash

# Script to check if certificates support WPA-EAP-SUITE-B-192
# Requirements:
# - ECDSA with P-384 curve
# - SHA-384 signature algorithm

# Source configuration file
CONFIG_FILE="$(dirname "$0")/cert_config.conf"
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
    if ! echo "$cert_info" | grep -A 2 "Public Key Algorithm" | grep -q "ECDSA"; then
        echo -e "${RED}✗ Key Algorithm: Not using ECDSA${NC}"
        supports_suite_b=false
    else
        echo -e "${GREEN}✓ Key Algorithm: Using ECDSA${NC}"
    fi
    
    # Check curve
    if ! echo "$cert_info" | grep -q "NIST P-384"; then
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
    
    # Get PKCS12 info using password from config
    local cert_info
    cert_info=$(openssl pkcs12 -info -in "$cert_file" -nodes -password "pass:$PKCS12_PASSWORD" 2>/dev/null)
    
    if [ $? -ne 0 ]; then
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
    if ! echo "$cert_info" | grep -A 2 "Public Key Algorithm" | grep -q "ECDSA"; then
        echo -e "${RED}✗ Key Algorithm: Not using ECDSA${NC}"
        supports_suite_b=false
    else
        echo -e "${GREEN}✓ Key Algorithm: Using ECDSA${NC}"
    fi
    
    # Check curve
    if ! echo "$cert_info" | grep -q "NIST P-384"; then
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
    
    local ca_result=false
    local client_result=false
    
    # Check CA certificate
    if check_ca_cert "certs/ca.der"; then
        ca_result=true
    fi
    
    # Check Client certificate
    if check_client_cert "certs/client.p12"; then
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

main
