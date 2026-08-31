#!/bin/bash
set -euo pipefail

# --- SETTINGS ---
DAYS=3650
CA_NAME="RemoteSensingCA"
SERVER_CN="edge-broker"
SAN="DNS:localhost,DNS:mosquitto,DNS:edge-broker,IP:127.0.0.1"
CLIENTS="highbyte nodered"

# --- OUTPUT DIR ---
CERTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/certs"
mkdir -p "$CERTDIR"
cd "$CERTDIR"
rm -f ./*.crt ./*.key ./*.csr ./*.ext ./*.srl

# --- CA ---
openssl genrsa -out ca.key 4096
openssl req -x509 -new -nodes -key ca.key -sha256 -days "$DAYS" -subj "/CN=$CA_NAME" -out ca.crt

# --- SERVER ---
openssl genrsa -out server.key 2048
openssl req -new -key server.key -subj "/CN=$SERVER_CN" -out server.csr
printf 'subjectAltName=%s\nextendedKeyUsage=serverAuth\nbasicConstraints=CA:FALSE\n' "$SAN" > server.ext
openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt -days "$DAYS" -sha256 -extfile server.ext

# --- CLIENTS (HighByte, NodeRed) ---
for CLIENT in $CLIENTS; do
  openssl genrsa -out "$CLIENT.key" 2048
  openssl req -new -key "$CLIENT.key" -subj "/CN=$CLIENT" -out "$CLIENT.csr"
  printf 'extendedKeyUsage=clientAuth\nbasicConstraints=CA:FALSE\n' > "$CLIENT.ext"
  openssl x509 -req -in "$CLIENT.csr" -CA ca.crt -CAkey ca.key -CAcreateserial -out "$CLIENT.crt" -days "$DAYS" -sha256 -extfile "$CLIENT.ext"
done

# --- CLEANUP ---
rm -f ./*.csr ./*.ext
chmod 644 ./*.crt
chmod 600 ./*.key

# --- VERIFY ---
echo
for CRT in server.crt $(for C in $CLIENTS; do echo "$C.crt"; done); do
  printf '%-16s ' "$CRT"
  openssl verify -CAfile ca.crt "$CRT" >/dev/null 2>&1 && echo OK || echo FAILED
done
echo
openssl x509 -in server.crt -noout -ext subjectAltName 2>/dev/null | tail -n +2
echo
ls -l
