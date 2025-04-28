#!/bin/sh

#  ci_pre_xcodebuild.sh
#  CryptoX
#
#  Created by Zhanna Komar on 28.04.2025.
#  Copyright © 2025 pioneeringtechventures. All rights reserved.

echo "Preparing Config.xcconfig for Xcode Cloud build..."

CONFIG_FILE_PATH="$CI_WORKSPACE/Config.xcconfig"
SCHEME_NAME="$XCODE_CLOUD_SCHEME"

# Create the Config.xcconfig if missing
if [ ! -f "$CONFIG_FILE_PATH" ]; then
    echo "// Auto-generated for Xcode Cloud" > "$CONFIG_FILE_PATH"
    echo "API_KEY=${API_KEY}" >> "$CONFIG_FILE_PATH"

    case "$SCHEME_NAME" in
        "MAINNET")
            echo "MAINNET_WERT_API_KEY=${MAINNET_WERT_API_KEY}" >> "$CONFIG_FILE_PATH"
            echo "MAINNET_WERT_PARTNER_ID=${MAINNET_WERT_PARTNER_ID}" >> "$CONFIG_FILE_PATH"
            ;;
        "TESTNET")
            echo "TESTNET_WERT_API_KEY=${TESTNET_WERT_API_KEY}" >> "$CONFIG_FILE_PATH"
            echo "TESTNET_WERT_PARTNER_ID=${TESTNET_WERT_PARTNER_ID}" >> "$CONFIG_FILE_PATH"
            ;;
        "STAGENET")
            echo "STAGENET_WERT_API_KEY=${STAGENET_WERT_API_KEY}" >> "$CONFIG_FILE_PATH"
            echo "STAGENET_WERT_PARTNER_ID=${STAGENET_WERT_PARTNER_ID}" >> "$CONFIG_FILE_PATH"
            ;;
        *)
            echo "Unknown scheme: $SCHEME_NAME"
            exit 1
            ;;
    esac

else
    echo "Config.xcconfig already exists, skipping creation."
fi
