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
import base64, os, subprocess, plistlib

cert_b64 = os.environ.get('IOS_DISTRIBUTION_CERT', '')
key_b64 = os.environ.get('IOS_DISTRIBUTION_KEY', '')
prov_b64 = os.environ.get('IOS_PROVISIONING_PROFILE', '')

with open('/tmp/distribution.cer', 'wb') as f:
    f.write(base64.b64decode(cert_b64))
    
with open('/tmp/distribution.key', 'wb') as f:
    f.write(base64.b64decode(key_b64))
    
with open('/tmp/buildtrack.mobileprovision', 'wb') as f:
    f.write(base64.b64decode(prov_b64))
    
# Extract UUID and name from provisioning profile
with open('/tmp/buildtrack.mobileprovision', 'rb') as f:
    data = f.read()
start = data.find(b'\x3c\x3f\x78\x6d\x6c')
end = data.rfind(b'\x3c\x2f\x70\x6c\x69\x73\x74\x3e') + 8
plist_data = data[start:end]
pl = plistlib.loads(plist_data)

uuid = pl.get('UUID', '')
name = pl.get('Name', 'BuildTrack')
app_id = pl.get('AppIDName', '')
team_id = pl.get('TeamIdentifier', [''])[0]

print(f"Profile Name: {name}")
print(f"Profile UUID: {uuid}")
print(f"App ID: {app_id}")
print(f"Team ID: {team_id}")

with open('/tmp/profile_uuid.txt', 'w') as f:
    f.write(uuid)
with open('/tmp/profile_name.txt', 'w') as f:
    f.write(name)

# Verify cert thumbprint
import hashlib
certs = pl.get('DeveloperCertificates', [])
print(f"Number of certs in profile: {len(certs)}")
for i, cert in enumerate(certs):
    print(f"Cert {i}: {len(cert)} bytes, SHA1={hashlib.sha1(cert).hexdigest()}")

print(f"Cert file: {os.path.getsize('/tmp/distribution.cer')} bytes")
print(f"Key file: {os.path.getsize('/tmp/distribution.key')} bytes")
print(f"Prov file: {os.path.getsize('/tmp/buildtrack.mobileprovision')} bytes")
PYEOF

UUID=$(cat /tmp/profile_uuid.txt)
NAME=$(cat /tmp/profile_name.txt)
echo "Using profile UUID: $UUID, Name: $NAME"

# Convert DER cert to PEM
openssl x509 -inform DER -in /tmp/distribution.cer -out /tmp/distribution.pem

# Combine into P12
openssl pkcs12 -export -in /tmp/distribution.pem -inkey /tmp/distribution.key \
  -out /tmp/distribution.p12 -name "BuildTrack Distribution" \
  -passout pass:buildtrack123

# Import P12 into keychain
security import /tmp/distribution.p12 -P "buildtrack123" -k "$KEYCHAIN_PATH" -T /usr/bin/codesign -T /usr/bin/security
security set-key-partition-list -S apple-tool:,apple: -k "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"

# Install provisioning profile in ALL possible locations
PROV_DIR="$HOME/Library/MobileDevice/Provisioning Profiles"
mkdir -p "$PROV_DIR"

# Install with UUID filename (Xcode preferred)
cp /tmp/buildtrack.mobileprovision ""$PROV_DIR"/${UUID}.mobileprovision"

# Also install with name filename
cp /tmp/buildtrack.mobileprovision ""$PROV_DIR"/${NAME}.mobileprovision"

# Also install as generic name
cp /tmp/buildtrack.mobileprovision ""$PROV_DIR"/buildtrack_app_store.mobileprovision"

echo "=== Installed profiles ==="
ls -la "$PROV_DIR"/

echo "=== Keychain certificates ==="
security find-identity -v -p codesigning "$KEYCHAIN_PATH"

echo "=== Default keychain certificates ==="
security find-identity -v -p codesigning || true

# Clean up sensitive files
rm -f /tmp/distribution.cer /tmp/distribution.key /tmp/distribution.pem /tmp/distribution.p12 /tmp/buildtrack.mobileprovision /tmp/profile_uuid.txt /tmp/profile_name.txt
