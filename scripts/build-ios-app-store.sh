#!/bin/bash
# Gera builds iOS para publicação na App Store (User e Driver)
# Uso: ./scripts/build-ios-app-store.sh [user|driver|all]

set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

APP="${1:-all}"

build_app() {
  local app_dir="$1"
  local app_name="$2"
  echo "=========================================="
  echo "  Building $app_name ($app_dir)"
  echo "=========================================="
  cd "$ROOT/$app_dir"
  flutter pub get
  flutter build ipa
  echo "✓ $app_name: build concluído."
  echo "  IPA em: $app_dir/build/ios/ipa/"
  echo ""
}

case "$APP" in
  user)
    build_app "driver-app-user" "Omny User"
    ;;
  driver)
    build_app "driver-app-driver" "Omny Driver"
    ;;
  all)
    build_app "driver-app-user" "Omny User"
    build_app "driver-app-driver" "Omny Driver"
    ;;
  *)
    echo "Uso: $0 [user|driver|all]"
    echo "  user   - gera apenas o app User"
    echo "  driver - gera apenas o app Driver"
    echo "  all    - gera os dois apps (padrão)"
    exit 1
    ;;
esac

echo "Build(s) iOS para App Store finalizado(s)."
echo "Próximo passo: abra o Xcode ou use Transporter para enviar o(s) IPA ao App Store Connect."
