# redtrastienda-apps

Apps Flutter de ANPEC Red Trastienda (6valley V16.3).

- `user/` — App de cliente (`flutter_sixvalley_ecommerce`)
- `vendor/` — App de vendedor (`sixvalley_vendor_app`)

Ambas apuntan al backend admin (`baseUrl` en `lib/utill/app_constants.dart`):
`https://adminapp.redtrastiendaanpec.com`

## Correr una app
```
cd user      # o vendor
flutter pub get
flutter run  # con un dispositivo/emulador conectado
```

Requiere Flutter SDK (probado con 3.44.x / Dart 3.12.x).

## Demo de encuestas

En la app de afiliados: **Menú → Mis cosas → Encuestas**. Requiere iniciar sesión.
Las encuestas publicadas se cargan del panel; cada pregunta admite una opción y,
cuando está habilitado, **Otros** con texto obligatorio. Cada afiliado puede
enviar una respuesta por encuesta y consultar sus respuestas después.

El backend debe incluir la migración `2026_10_14_100000_create_anpec_surveys_tables`.
La migración carga una encuesta de ejemplo con tres preguntas, sin respuestas ficticias.
En el panel: **Gente → Encuestas**, o `/admin/surveys`.
Se pueden crear, publicar/cerrar y consultar respuestas o descargarlas en CSV.

Validación del módulo:

```powershell
cd user
flutter test --no-pub test/features/surveys
flutter analyze --no-pub lib/features/surveys test/features/surveys lib/features/more/screens/menu_anpec_screen.dart
```
