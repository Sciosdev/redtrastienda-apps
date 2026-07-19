# iOS — Estado Fase 1 (rama `r-ios`)

**Fecha:** 2026-07-18 · **Máquina:** MacBook M2 Pro · **Territorio tocado:** solo `user/ios/` + este doc.

## TL;DR

`flutter build ios --no-codesign` **compila ✓ a la primera** (Runner.app 91.1 MB, cero errores). Smoke test en simulador iPhone 17 Pro (iOS 26.5) **sin defectos visuales iOS-específicos**: splash, onboarding, login, las 4 pestañas y detalle de producto se ven correctos, con contenido real del backend (`adminapp.redtrastiendaanpec.com`). Bundle id definitivo, display name, permisos en español e íconos de Red Trastienda aplicados. **Pendiente que requiere acción humana: push de la rama** (esta Mac no tiene credenciales de GitHub — correr `gh auth login` con la cuenta Sciosdev y `git push -u origin r-ios`).

## Entorno

- Xcode 26.6 (17F113), macOS 26.5.2, Flutter 3.44.6 stable (Dart 3.12.2), CocoaPods 1.17.0.
- `flutter doctor`: iOS toolchain ✓ limpio. (Android SDK ausente en esta Mac: esperado, Android vive en la máquina Windows.)

## Trabajo A — Identidad de la app (hecho, por commit)

1. **Bundle id** `club.scios.redtrastienda` en las 3 build configs (Debug/Release/Profile). Verificado en el binario compilado (`CFBundleIdentifier`). No hay targets de tests/extensiones que alinear (solo Runner).
2. **Display name** "Red Trastienda". Ojo: la plantilla lo tenía en `INFOPLIST_KEY_CFBundleDisplayName` (build settings), no en el Info.plist; se cambió en ambos lados de forma consistente. El diálogo de permisos del sistema ya muestra "Red Trastienda quiere enviarte notificaciones".
3. **Se retiró `DEVELOPMENT_TEAM = 7WSYLQ8Y87`** (team de 6amtech). Queda sin team a propósito hasta Fase 2.
4. **Permisos de Info.plist en español (MX)**: cámara, ubicación (when-in-use) y galería. Son los textos que Apple muestra al usuario y revisa en App Review.
5. **Limpieza de plantilla**: URL scheme `sixvalley` → `redtrastienda`; `CFBundleName` 6Valley → Red Trastienda; FacebookDisplayName actualizado; bloque comentado de applinks 6valley eliminado; entitlements: keychain group ahora `$(AppIdentifierPrefix)club.scios.redtrastienda` y se eliminó `associated-domains` con dominio de 6valley (re-agregar en Fase 2 con dominio real).
6. **`GoogleService-Info.plist`**: sigue siendo el placeholder de la plantilla; solo se alineó su `BUNDLE_ID` al bundle nuevo (mismo criterio que google-services.json en Android). El build no lo valida, no estorbó. Firebase real llega en otra fase.
7. **Versión iOS ligada a pubspec**: la plantilla hardcodeaba 2.0.0(1) vía `MARKETING_VERSION`; ahora `CFBundleShortVersionString`/`CFBundleVersion` usan `$(FLUTTER_BUILD_NAME)`/`$(FLUTTER_BUILD_NUMBER)` → iOS empaqueta lo que diga `version:` en pubspec (hoy 1.0.0+1), igual que Android.
8. **AppIcon de Red Trastienda**: los 21 PNG del appiconset se regeneraron desde `assets/launcher/launcher_icon.png` (1024², el mismo arte que Android), en RGB sin canal alfa (requisito de App Store). Se eliminaron ~34 PNGs huérfanos del generador de la plantilla. Ya no está el carrito azul de 6valley.
9. **LaunchImage nuevo**: el `LaunchScreen.storyboard` referenciaba una imagen que no existía en el catálogo (launch screen en blanco). Se creó `LaunchImage.imageset` (150pt @1x/2x/3x desde `logo_with_name.png`).

## Trabajo B — Build y simulador

- `flutter build ios --no-codesign`: **✓ sin errores ni fixes necesarios**. Sorpresa buena: no hubo pods desactualizados ni APIs deprecadas que arreglar.
- **Swift Package Manager**: este Flutter estable trae SPM habilitado; `flutter build` migró el proyecto (commit incluido). Firebase/FBSDK/GoogleSignIn/etc. llegan por SPM; solo 6 plugins siguen en CocoaPods (`flutter_downloader`, `flutter_inappwebview_ios`, `get_thumbnail_video`, `google_maps_flutter_ios`, `open_file_manager` + Flutter). Warning informativo: esos 5 deberán adoptar SPM en el futuro (hoy no bloquea). `Podfile.lock` y `Package.resolved` commiteados.
- Warning benigno de CocoaPods sobre la config Profile: Profile usa `Release.xcconfig`, que ya incluye el xcconfig de pods release (patrón estándar Flutter).

### Smoke test (iPhone 17 Pro, iOS 26.5)

Todo verificado con capturas (transportadas por chat; localmente en el scratchpad de la sesión):

| Pantalla | Estado |
|---|---|
| Splash | ✓ logo Red Trastienda centrado, fondo blanco |
| Onboarding p1 | ✓ ilustración + copy ANPEC + "Saltar" (p2/p3 no navegables sin gestos, ver Limitaciones) |
| Login | ✓ campos "Correo, teléfono o número ANP", **sin botones sociales**, "activa tu cuenta", "Invitado" |
| Home | ✓ contenido real del backend (productos, ofertas, búsqueda), barra Inicio/Chats/Pedidos/Menú |
| Chats | ✓ gate "inicia sesión para chatear" (correcto como invitado) |
| Pedidos | ✓ gate de sesión correcto |
| Menú | ✓ 4 secciones (Mi tienda / Proveedores / Mis compras / Ayuda y soporte), llega al fondo |
| Producto | ✓ detalle Coca-Cola 2L, precio, specs, "Añadir a la cesta" |

Safe areas, notch y home-indicator bien en todas. Sin problemas de fuentes. **No se probó teclado** (limitación de automatización, abajo).

Notas de runtime (no bloquean): excepción de `firebase_messaging` al arrancar (esperada: Firebase placeholder + simulador sin APNS); el permiso de notificaciones se pide en el primer arranque, antes del onboarding.

### Limitaciones del smoke (por qué no hubo taps)

Sin permisos de accesibilidad en esta Mac no se pueden inyectar toques al simulador. La navegación se hizo vía Dart VM Service (`flutter attach` + evaluación de `RouterHelper.goRoutes.go(...)`) y el permiso de notificaciones se pre-otorgó con `applesimutils` (instalado vía brew). Quedó sin cubrir: onboarding p2/p3 (requiere swipe), flujos con teclado, y cualquier tap real. Un smoke manual de 5 min en la Mac lo cubre cuando se pueda.

Hallazgo de plantilla detectado de paso (Dart, **no tocado** por territorio): navegar entre pestañas del dashboard vía ruta (`/dashboard?page=...`) no cambia la pestaña si el DashBoardScreen ya está montado (pageIndex solo se lee en initState). Solo afecta deep links a pestañas, no la navegación normal por taps.

## Pendientes

**Para Axel (ahora):**
1. `gh auth login` (cuenta Sciosdev) en esta Mac y `git push -u origin r-ios`. La rama tiene 6 commits temáticos listos; no se tocó main.

**Fase 2 (cuando Apple apruebe la cuenta Developer):**
1. Signing: DEVELOPMENT_TEAM propio, provisioning, TestFlight. El App ID `club.scios.redtrastienda` deberá habilitar Push Notifications y Sign in with Apple (entitlements presentes: `aps-environment`, applesignin).
2. `GoogleService-Info.plist` real del proyecto Firebase de ANPEC.
3. Google Maps: `AppDelegate.swift` tiene `GMSServices.provideAPIKey("YOUR_MAP_KEY_HERE")` — mapas en blanco hasta poner key real (mismo pendiente que Android).
4. Facebook: `FacebookAppID = "app_id"` placeholder (el login social está fuera del flujo ANPEC; decidir si se retira el SDK o se configura).
5. Associated domains (applinks) con el dominio real si se quieren universal links.
6. Revisar `NSAppTransportSecurity NSAllowsArbitraryLoads=true` antes de App Review (Apple lo cuestiona).
7. `UIFileSharingEnabled=true` (la app expone su carpeta Documents en Archivos): decidir si se quiere.
8. El Info.plist conserva permitir orientación landscape en iPhone; si la app es portrait-only, restringir.

**Reporte a la máquina Windows (fuera de mi territorio, no tocado):**
- El bug de pestañas por deep link descrito arriba, por si les interesa para el flujo de notificaciones push que navegan a `/dashboard?page=chats`.
