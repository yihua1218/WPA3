# WPA3 Certificate Tools

This project provides tools for checking and generating certificates for WPA3 Enterprise networks, specifically focusing on WPA-EAP-SUITE-B-192 support.

## Project Structure

```
.
├── bin/
│   └── check_suite_b_192.sh    # Certificate checking script
├── cert_config.conf            # Configuration file for certificate checking
├── certs/                      # Default directory for certificates to check
│   ├── ca.der                 # CA certificate to check
│   └── client.p12            # Client certificate to check
├── certs-basic/               # Standard FreeRADIUS certificate configurations
│   ├── Makefile              # Original certificate generation rules
│   ├── ca.cnf                # CA certificate configuration
│   ├── server.cnf            # Server certificate configuration
│   ├── client.cnf            # Client certificate configuration
│   ├── xpextensions          # X509v3 extensions configuration
│   └── passwords.mk          # Certificate passwords configuration
├── certs-suite-b192/         # SUITE-B-192 compatible certificate configurations
│   ├── Makefile              # Modified for SUITE-B-192 support
│   ├── ca.cnf                # Modified to use ECDSA P-384
│   ├── server.cnf            # Modified to use ECDSA P-384
│   ├── client.cnf            # Modified to use ECDSA P-384
│   ├── xpextensions          # X509v3 extensions configuration
│   └── passwords.mk          # Certificate passwords configuration
└── README.md
```

## Certificate Configurations

The project includes two sets of certificate configurations:

1. **certs-basic/**: Contains original FreeRADIUS certificate configurations
   - Standard RSA-based certificates
   - Compatible with regular WPA3 Enterprise setups

2. **certs-suite-b192/**: Contains modified configurations for WPA-EAP-SUITE-B-192
   - Uses ECDSA with P-384 curve
   - Uses SHA-384 signature algorithm
   - Meets Suite-B-192 requirements

To use these configurations, copy the required files from your FreeRADIUS installation:
```bash
# For standard certificates
cd /path/to/freeradius/3.0/certs
cp Makefile ca.cnf server.cnf client.cnf xpextensions passwords.mk /path/to/WPA3/certs-basic/

# For SUITE-B-192 certificates
cp Makefile ca.cnf server.cnf client.cnf xpextensions passwords.mk /path/to/WPA3/certs-suite-b192/
```

## Certificate Checker

### Requirements

- OpenSSL installed on your system
- Certificates to check:
  - CA certificate in DER format
  - Client certificate in PKCS12 format

### Configuration

Edit `cert_config.conf` in the project root to set your PKCS12 certificate password:

```bash
# Configuration for certificate checking
PKCS12_PASSWORD=your_password_here
```

### Usage

1. Make sure the script has execution permissions:
   ```bash
   chmod +x bin/check_suite_b_192.sh
   ```

2. Run the checker with a specific directory:
   ```bash
   ./bin/check_suite_b_192.sh [directory]
   ```

   Examples:
   ```bash
   # Check certificates in the default certs/ directory
   ./bin/check_suite_b_192.sh

   # Check certificates in certs-basic/ directory
   ./bin/check_suite_b_192.sh certs-basic

   # Check certificates in certs-suite-b192/ directory
   ./bin/check_suite_b_192.sh certs-suite-b192
   ```

   The script expects to find:
   - `ca.der` - CA certificate
   - `client.p12` - Client certificate
   in the specified directory

### What it Checks

The script verifies if your certificates meet WPA-EAP-SUITE-B-192 requirements:

1. ECDSA with P-384 curve
2. SHA-384 signature algorithm

For each certificate, it checks:
- Signature Algorithm (must be ECDSA with SHA384)
- Key Algorithm (must be ECDSA)
- Curve Type (must be NIST P-384)

### Output

The script provides colorized output indicating:
- ✓ Green: Requirement met
- ✗ Red: Requirement not met
- Yellow: Informational messages

Example output:
```
Checking certificates in directory: certs-suite-b192

Checking CA certificate (certs-suite-b192/ca.der):
✓ Signature Algorithm: Using ECDSA with SHA384
✓ Key Algorithm: Using ECDSA
✓ Curve: Using P-384

Checking Client certificate (certs-suite-b192/client.p12):
✓ Signature Algorithm: Using ECDSA with SHA384
✓ Key Algorithm: Using ECDSA
✓ Curve: Using P-384

Final Results:
✓ CA certificate supports Suite-B-192
✓ Client certificate supports Suite-B-192

Both certificates support WPA-EAP-SUITE-B-192!
```

### Exit Codes

- 0: All certificates support Suite-B-192
- 1: One or more certificates do not support Suite-B-192 or error occurred

### Troubleshooting

1. If you see "Error: Configuration file not found":
   - Make sure `cert_config.conf` exists in the project root directory
   - Check file permissions

2. If you see "Error: Directory not found":
   - Verify the specified directory exists
   - Check directory permissions

3. If you see "Error: Certificate file not found":
   - Verify certificates exist in the specified directory
   - Check file permissions
   - Verify filenames match expected names (ca.der, client.p12)

4. If you see "Error: Failed to read PKCS12 file":
   - Check if the password in `cert_config.conf` is correct
   - Verify the PKCS12 file is not corrupted
