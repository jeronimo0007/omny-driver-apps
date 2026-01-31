# 🔒 Solução para Problema de CORS

## 📋 Problema
O navegador está bloqueando requisições de imagens devido à política CORS:
```
Access to XMLHttpRequest at 'https://driver.omny.app.br/images/country/flags/BR.png' 
from origin 'http://localhost:49381' has been blocked by CORS policy
```

**⚠️ Importante sobre portas:**
- O Flutter web pode usar qualquer porta (ex: `localhost:49381`, `localhost:8080`, etc)
- A configuração do Laravel precisa aceitar **qualquer porta** do localhost
- Use `allowed_origins_patterns` com regex para aceitar qualquer porta automaticamente

## ✅ Solução Recomendada: Ajustar no Backend (Laravel)

### Opção 1: Usar Middleware CORS do Laravel (Recomendado)

#### 1. Instalar o pacote `fruitcake/laravel-cors` (se ainda não tiver):
```bash
composer require fruitcake/laravel-cors
```

#### 2. Publicar a configuração:
```bash
php artisan vendor:publish --tag="cors"
```

#### 3. Configurar `config/cors.php`:
```php
<?php

return [
    /*
    |--------------------------------------------------------------------------
    | Cross-Origin Resource Sharing (CORS) Configuration
    |--------------------------------------------------------------------------
    */

    'paths' => ['api/*', 'images/*', 'storage/*'],

    'allowed_methods' => ['*'],

    'allowed_origins' => [
        // Não precisa especificar porta - use allowed_origins_patterns
        'https://driver.omny.app.br',
        // Adicione outros domínios de produção conforme necessário
    ],

    'allowed_origins_patterns' => [
        // Aceita qualquer porta do localhost (ex: localhost:49381, localhost:8080, etc)
        '/^http:\/\/localhost:\d+$/',
        '/^http:\/\/127\.0\.0\.1:\d+$/',
        '/^http:\/\/localhost$/',
        '/^http:\/\/127\.0\.0\.1$/',
    ],

    'allowed_headers' => ['*'],

    'exposed_headers' => [],

    'max_age' => 0,

    'supports_credentials' => false,
];
```

#### 4. Adicionar o middleware no `app/Http/Kernel.php`:
```php
protected $middleware = [
    // ... outros middlewares
    \Fruitcake\Cors\HandleCors::class,
];
```

### Opção 2: Criar Middleware Customizado

#### 1. Criar o middleware:
```bash
php artisan make:middleware CorsMiddleware
```

#### 2. Editar `app/Http/Middleware/CorsMiddleware.php`:
```php
<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

class CorsMiddleware
{
    public function handle(Request $request, Closure $next)
    {
        $response = $next($request);

        // Permitir origens específicas
        $allowedOrigins = [
            'https://driver.omny.app.br',
            // Adicione outros domínios de produção
        ];

        $origin = $request->headers->get('Origin');
        
        // Verificar se é localhost com qualquer porta (ex: localhost:49381, localhost:8080, etc)
        $isLocalhost = preg_match('/^http:\/\/localhost(:\d+)?$/', $origin) ||
                      preg_match('/^http:\/\/127\.0\.0\.1(:\d+)?$/', $origin);
        
        if (in_array($origin, $allowedOrigins) || $isLocalhost) {
            $response->headers->set('Access-Control-Allow-Origin', $origin);
        }

        $response->headers->set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
        $response->headers->set('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Requested-With');
        $response->headers->set('Access-Control-Allow-Credentials', 'true');
        $response->headers->set('Access-Control-Max-Age', '86400');

        // Responder a requisições OPTIONS
        if ($request->getMethod() === 'OPTIONS') {
            return response()->json([], 200, $response->headers->all());
        }

        return $response;
    }
}
```

#### 3. Registrar no `app/Http/Kernel.php`:
```php
protected $middleware = [
    // ... outros middlewares
    \App\Http\Middleware\CorsMiddleware::class,
];
```

### Opção 3: Configurar no `.htaccess` (Apache) ou Nginx

#### Para Apache (`.htaccess` na pasta `public`):
```apache
<IfModule mod_headers.c>
    # Permitir CORS para imagens de qualquer origem (incluindo localhost com qualquer porta)
    <FilesMatch "\.(png|jpg|jpeg|gif|svg|webp)$">
        Header set Access-Control-Allow-Origin "*"
        Header set Access-Control-Allow-Methods "GET, OPTIONS"
        Header set Access-Control-Allow-Headers "Content-Type"
    </FilesMatch>
    
    # Ou para permitir apenas localhost (qualquer porta) e domínio de produção:
    # SetEnvIf Origin "^http(s)?://(localhost|127\.0\.0\.1)(:\d+)?$" AccessControlAllowOrigin=$0
    # Header always set Access-Control-Allow-Origin %{AccessControlAllowOrigin}e env=AccessControlAllowOrigin
</IfModule>
```

#### Para Nginx (`nginx.conf`):
```nginx
location ~* \.(png|jpg|jpeg|gif|svg|webp)$ {
    add_header Access-Control-Allow-Origin "*";
    add_header Access-Control-Allow-Methods "GET, OPTIONS";
    add_header Access-Control-Allow-Headers "Content-Type";
}
```

## 🔧 Solução Temporária no App (Flutter)

Se não puder ajustar o backend imediatamente, você pode usar um widget que trata CORS:

### Criar widget helper para imagens com CORS:

```dart
// lib/widgets/cors_image.dart
import 'package:flutter/material.dart';
import 'dart:html' as html;

class CorsImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;

  const CorsImage({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // No web, usar img HTML que não tem restrição CORS para imagens
      return HtmlElementView(
        viewType: 'img',
        onPlatformViewCreated: (int viewId) {
          final img = html.document.getElementById('img-$viewId') as html.ImageElement?;
          if (img != null) {
            img.src = imageUrl;
            img.style.width = width != null ? '${width}px' : 'auto';
            img.style.height = height != null ? '${height}px' : 'auto';
          }
        },
      );
    } else {
      // Em mobile, usar Image.network normalmente
      return Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return Icon(Icons.flag, size: width ?? 24);
        },
      );
    }
  }
}
```

## 📝 Recomendação

**A melhor solução é ajustar no backend Laravel** usando uma das opções acima. Isso resolve o problema de forma definitiva e permite que todas as imagens sejam carregadas corretamente.

A solução temporária no app pode funcionar, mas é menos ideal e pode ter limitações.
