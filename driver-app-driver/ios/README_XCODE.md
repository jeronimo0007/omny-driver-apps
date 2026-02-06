# Build iOS – app driver

## Erro: FirebaseSharedSwift "sending", "nonisolated"

O Firebase iOS SDK 12.x usa recursos do **Swift 5.10+** (`sending`, `nonisolated`).  
O **Xcode 14.2** usa Swift 5.7 e não reconhece essas palavras-chave.

**Solução:** usar **Xcode 15.2 ou superior** (inclui Swift 5.10).

1. Atualize o Xcode pela App Store ou em [developer.apple.com](https://developer.apple.com/xcode/).
2. Depois de instalar, escolha a nova versão:
   ```bash
   sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
   ```
3. Rode de novo:
   ```bash
   cd ios && pod install && cd ..
   flutter run
   ```

Com Xcode 15.2+ o build do app driver no simulador ou dispositivo deve concluir sem esse erro.
