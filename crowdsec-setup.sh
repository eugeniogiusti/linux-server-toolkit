#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  if command -v sudo >/dev/null 2>&1; then
    SUDO="sudo"
  else
    echo "Error: run as root or install sudo."
    exit 1
  fi
else
  SUDO=""
fi

for cmd in curl apt systemctl; do
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    echo "Error: required command not found: ${cmd}"
    exit 1
  fi
done

echo "[1/8] Installing CrowdSec repository..."
curl -s https://install.crowdsec.net | ${SUDO} sh

echo "[2/8] Installing crowdsec..."
${SUDO} apt install -y crowdsec

echo "[3/8] Installing firewall bouncer (iptables)..."
${SUDO} apt install -y crowdsec-firewall-bouncer-iptables

echo "[4/8] Enabling + starting crowdsec..."
${SUDO} systemctl enable crowdsec
${SUDO} systemctl start crowdsec

echo "[5/8] Enabling + starting crowdsec-firewall-bouncer..."
${SUDO} systemctl enable crowdsec-firewall-bouncer
${SUDO} systemctl start crowdsec-firewall-bouncer

echo "[6/8] Service status..."
${SUDO} systemctl status crowdsec --no-pager || true
${SUDO} systemctl status crowdsec-firewall-bouncer --no-pager || true

if command -v cscli >/dev/null 2>&1; then
  echo "[7/8] Checking cscli..."
  ${SUDO} cscli metrics || true
  ${SUDO} cscli collections list || true
  ${SUDO} cscli scenarios list || true
else
  echo "[7/8] cscli not found, skipping metrics/collections/scenarios."
fi

echo "[8/8] Done."
echo
echo "Hey: go to https://app.crowdsec.net and sign up,"
echo "then enroll this server with:"
echo "  sudo cscli console enroll <your-enrollment-key>"
echo "and verify with:"
echo "  sudo cscli console status"
echo
echo "Then enable the scenarios and blocklists you need."
