#!/bin/bash
# Compila ambos os apps (driver e user) para publicação na App Store.
# Uso: ./build_ios_appstore.sh
# Requer: Flutter no PATH, Xcode 15.2+, signing configurado no Xcode.

set -e
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

echo "=========================================="
echo "  Build iOS App Store - driver-app-driver"
echo "=========================================="
cd driver-app-driver
flutter clean
flutter pub get
flutter build ipa
echo "Driver: build concluído. IPA em build/ios/ipa/"
cd "$ROOT"

echo ""
echo "=========================================="
echo "  Build iOS App Store - driver-app-user"
echo "=========================================="
cd driver-app-user
flutter clean
flutter pub get
flutter build ipa
echo "User: build concluído. IPA em build/ios/ipa/"
cd "$ROOT"

echo ""
echo "=========================================="
echo "  Concluído"
echo "=========================================="
echo "Driver IPA: driver-app-driver/build/ios/ipa/"
echo "User IPA:   driver-app-user/build/ios/ipa/"
echo ""
echo "Próximo passo: enviar os IPAs via Xcode (Organizer) ou Transporter."
