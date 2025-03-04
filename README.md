# WPA3 Certificate Checker

This tool helps verify if your certificates meet the requirements for WPA-EAP-SUITE-B-192 authentication in WPA3 Enterprise networks.

## Requirements

- OpenSSL installed on your system
- Certificates to check:
  - CA certificate in DER format
  - Client certificate in PKCS12 format

## Project Structure

```
.
├── bin/
│   ├── check_suite_b_192.sh    # Main checking script
│   └── cert_config.conf        # Configuration file
├── certs/
│   ├── ca.der                  # CA certificate
│   └── client.p12             # Client certificate
└── README.md
```

## Configuration

Edit `bin/cert_config.conf` to set your PKCS12 certificate password:

```bash
# Configuration for certificate checking
PKCS12_PASSWORD=your_password_here
```

## Usage

1. Place your certificates in the `certs/` directory:
   - CA certificate as `ca.der`
   - Client certificate as `client.p12`

2. Make sure the script has execution permissions:
   ```bash
   chmod +x bin/check_suite_b_192.sh
   ```

3. Run the checker:
   ```bash
   ./bin/check_suite_b_192.sh
   ```

## What it Checks

The script verifies if your certificates meet WPA-EAP-SUITE-B-192 requirements:

1. ECDSA with P-384 curve
2. SHA-384 signature algorithm

For each certificate, it checks:
- Signature Algorithm (must be ECDSA with SHA384)
- Key Algorithm (must be ECDSA)
- Curve Type (must be NIST P-384)

## Output

The script provides colorized output indicating:
- ✓ Green: Requirement met
- ✗ Red: Requirement not met
- Yellow: Informational messages

Example output:
```
Checking CA certificate (certs/ca.der):
✓ Signature Algorithm: Using ECDSA with SHA384
✓ Key Algorithm: Using ECDSA
✓ Curve: Using P-384

Checking Client certificate (certs/client.p12):
✓ Signature Algorithm: Using ECDSA with SHA384
✓ Key Algorithm: Using ECDSA
✓ Curve: Using P-384

Final Results:
✓ CA certificate supports Suite-B-192
✓ Client certificate supports Suite-B-192

Both certificates support WPA-EAP-SUITE-B-192!
```

## Exit Codes

- 0: All certificates support Suite-B-192
- 1: One or more certificates do not support Suite-B-192 or error occurred

## Troubleshooting

1. If you see "Error: Configuration file not found":
   - Make sure `cert_config.conf` exists in the `bin/` directory
   - Check file permissions

2. If you see "Error: Certificate file not found":
   - Verify certificates are in the `certs/` directory
   - Check file permissions
   - Verify filenames match expected names (ca.der, client.p12)

3. If you see "Error: Failed to read PKCS12 file":
   - Check if the password in `cert_config.conf` is correct
   - Verify the PKCS12 file is not corrupted
