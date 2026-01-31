# 📄 API de Upload de Documentos - Postman

## Endpoint
```
POST https://driver.omny.app.br/api/v1/driver/upload/documents
```

## Headers
```
Authorization: Bearer {TOKEN}
Content-Type: multipart/form-data
```

## Body (Form-Data)

### Campos Obrigatórios:
- **document** (File): Arquivo do documento (imagem)
- **document_id** (Text): ID do documento (obtido da lista de documentos necessários)

### Campos Opcionais (dependem do tipo de documento):

#### Se o documento tem data de expiração (`has_expiry_date == true`):
- **expiry_date** (Text): Data de expiração no formato `YYYY-MM-DD HH:mm:ss` (apenas os primeiros 19 caracteres)
  - Exemplo: `2025-12-31 23:59:59`

#### Se o documento tem número de identificação (`has_identify_number == true`):
- **identify_number** (Text): Número de identificação do documento
  - Exemplo: `12345678901`

## Exemplo de Requisição no Postman

### 1. Configurar o Request:
- **Method**: POST
- **URL**: `https://driver.omny.app.br/api/v1/driver/upload/documents`

### 2. Headers:
```
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9...
```

### 3. Body (form-data):
| Key | Type | Value |
|-----|------|-------|
| document | File | [Selecione o arquivo de imagem] |
| document_id | Text | 1 |
| expiry_date | Text | 2025-12-31 23:59:59 |
| identify_number | Text | 12345678901 |

## Respostas

### Sucesso (200):
```json
{
  "message": "Document uploaded successfully"
}
```

### Erro de Validação (422):
```json
{
  "message": "The given data was invalid.",
  "errors": {
    "document": ["The document field is required."],
    "document_id": ["The document id field is required."]
  }
}
```

### Não Autorizado (401):
```json
{
  "message": "Unauthenticated."
}
```

## Como obter o document_id

Primeiro, faça uma chamada para obter os documentos necessários:

```
GET https://driver.omny.app.br/api/v1/driver/documents/needed
Headers: Authorization: Bearer {TOKEN}
```

Resposta:
```json
{
  "data": [
    {
      "id": 1,
      "name": "CNH",
      "has_expiry_date": true,
      "has_identify_number": true,
      ...
    },
    {
      "id": 2,
      "name": "CRLV",
      "has_expiry_date": true,
      "has_identify_number": false,
      ...
    }
  ],
  "enable_submit_button": false
}
```

Use o `id` do documento que você quer enviar como `document_id`.

## Notas Importantes

1. O campo `document` deve ser uma imagem (JPG, PNG, etc.)
2. O `expiry_date` deve ter exatamente 19 caracteres (formato: `YYYY-MM-DD HH:mm:ss`)
3. O `identify_number` só é necessário se `has_identify_number == true` para aquele documento
4. O `expiry_date` só é necessário se `has_expiry_date == true` para aquele documento
5. O token Bearer deve ser válido e não expirado
