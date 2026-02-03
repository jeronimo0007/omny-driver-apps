import 'package:flutter/foundation.dart';

/// URL base da API.
/// - **Debug (local)**: backend no XAMPP
/// - **Release (produção)**: servidor Omny
String get apiBaseUrl => kReleaseMode
    ? 'https://driver.omny.app.br/'
    : 'https://driver.omny.app.br/';
