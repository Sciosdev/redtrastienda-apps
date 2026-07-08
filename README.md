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
