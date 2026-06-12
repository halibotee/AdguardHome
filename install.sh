#!/bin/sh
REPO="https://raw.githubusercontent.com/halibotee/AdguardHome/main"
curl -fsSL -o /tmp/agh-installer "$REPO/installer" && chmod +x /tmp/agh-installer && sh /tmp/agh-installer master "$@"; rm -f /tmp/agh-installer
