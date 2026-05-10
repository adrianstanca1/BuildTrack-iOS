#!/bin/bash
set -e

KEYCHAIN_PASSWORD="buildtrack-ci"
KEYCHAIN_PATH="$RUNNER_TEMP/buildtrack.keychain"

# Create keychain
security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
security set-keychain-settings -lut 21600 "$KEYCHAIN_PATH"
security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
security list-keychains -d user -s "$KEYCHAIN_PATH" $(security list-keychains -d user | sed 's/.*"\(.*\)".*/\1/')

# Write cert and key from environment variables
python3 << 'PYEOF'
import base64, os

cert_b64 = os.environ.get('IOS_DISTRIBUTION_CERT', '')
key_b64 = os.environ.get('IOS_DISTRIBUTION_KEY', '')
prov_b64 = os.environ.get('IOS_PROVISIONING_PROFILE', '')

with open('/tmp/distribution.cer', 'wb') as f:
    f.write(base64.b64decode(cert_b64))
    
with open('/tmp/distribution.key', 'wb') as f:
    f.write(base64.b64decode(key_b64))
    
with open('/tmp/buildtrack.mobileprovision', 'wb') as f:
    f.write(base64.b64decode(prov_b64))
    
print(f"Cert: {os.path.getsize('/tmp/distribution.cer')} bytes")
print(f"Key: {os.path.getsize('/tmp/distribution.key')} bytes")
print(f"Prov: {os.path.getsize('/tmp/buildtrack.mobileprovision')} bytes")
PYEOF

# Convert DER cert to PEM (openssl pkcs12 needs PEM)
openssl x509 -inform DER -in /tmp/distribution.cer -out /tmp/distribution.pem

# Combine into P12
openssl pkcs12 -export -in /tmp/distribution.pem -inkey /tmp/distribution.key \
  -out /tmp/distribution.p12 -name "BuildTrack Distribution" \
  -passout pass:buildtrack123

# Import P12 into keychain
security import /tmp/distribution.p12 -P "buildtrack123" -k "$KEYCHAIN_PATH" -T /usr/bin/codesign -T /usr/bin/security
security set-key-partition-list -S apple-tool:,apple: -k "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"

# Install provisioning profile
mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles
cp /tmp/buildtrack.mobileprovision ~/Library/MobileDevice/Provisioning\ Profiles/buildtrack_app_store.mobileprovision

echo "=== Keychain contents ==="
security find-identity -v -p codesigning "$KEYCHAIN_PATH"

echo "=== Installed profiles ==="
ls -la ~/Library/MobileDevice/Provisioning\ Profiles/
