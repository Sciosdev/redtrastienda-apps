# IOS_STATUS — coordinación con el track iOS (Mac)

Este archivo coordina cambios de `user/ios/` entre el chat maestro/módulos y el chat que corre
en la Mac de SCIOS. **Regla:** el chat de módulos NO edita `user/ios/` salvo colocar archivos
puntuales aquí descritos; la Mac integra.

## Pendiente para el track iOS

### ⚠️ Cambio de bundle id (decisión Axel 2026-07-20)
- El bundle id pasó de `club.scios.redtrastienda` a **`com.redtrastiendaanpec.afiliados`** (para
  que ANPEC no quede atada al namespace de SCIOS). Se cambió el `applicationId` de Android en
  `r-firebase`; iOS debe igualar.
- **Acción maestro/Apple:** el enrollment de Apple (org SCIOS, en curso) apuntaba al bundle viejo.
  Hay que **crear el App ID `com.redtrastiendaanpec.afiliados`** en el Apple Developer portal y
  usar ese `PRODUCT_BUNDLE_IDENTIFIER` en Xcode. El App ID puede vivir bajo la org SCIOS aunque el
  string sea de ANPEC; si a futuro se transfiere la app a una cuenta ANPEC, el bundle ya es propio.
- **Bloqueante iOS:** verificar que no se haya subido nada a App Store Connect con el bundle viejo.

### 🔴 Residuos del demo en iOS encontrados 2026-07-20 (barrido r-firebase)
El track iOS **nunca se rebrandeó del demo**. El chat de módulos NO los toca (scope); la Mac debe
corregir todo esto al integrar el plist nuevo + rebrandear el bundle:
- `ios/GoogleService-Info.plist` = proyecto **demo** `sixvally-ecommerce` (sender `975837518429`,
  bundle `com.sixamtech.sixValley`, `GOOGLE_APP_ID 1:975837518429:ios:...`). Es OTRO demo 6amtech,
  distinto del Android. **Reemplazar** por el `GoogleService-Info.plist` de ANPEC y moverlo a
  `ios/Runner/` + agregarlo al target Runner (hoy está en `ios/` raíz, quizá ni se empaqueta).
- `ios/Runner.xcodeproj/project.pbxproj` (3 configs, líneas ~412/557/597):
  `PRODUCT_BUNDLE_IDENTIFIER = com.sixamtech.sixValley` → cambiar a `com.redtrastiendaanpec.afiliados`.
- `ios/Runner/Runner.entitlements:17`: `7WSYLQ8Y87.com.sixamtech.sixValley` (team `7WSYLQ8Y87` es
  de 6amtech) → actualizar al Team ID de SCIOS/ANPEC + bundle nuevo (keychain/APS group).

### Firebase propio ANPEC — colocar `GoogleService-Info.plist`
- **Contexto:** se migró del proyecto Firebase DEMO de 6amtech (`drivevalley-fdb7f`) a un
  proyecto propio de ANPEC. Ver `docs/FIREBASE_SETUP_ANPEC.md`.
- **Bundle id:** `com.redtrastiendaanpec.afiliados` (debe coincidir con el registro iOS en Firebase).
- **Archivo:** `GoogleService-Info.plist` del nuevo proyecto ANPEC.
  - Estado: ✅ **disponible en `docs/GoogleService-Info.plist`** (proyecto `anpec-b7c3c`, bundle
    `com.redtrastiendaanpec.afiliados`, sender `1011581065251`). Listo para integrar en la Mac.
- **Acción en la Mac:** copiar ese plist a `user/ios/Runner/GoogleService-Info.plist` e incluirlo
  en el target Runner de Xcode (Build Phases → Copy Bundle Resources). Verificar que el
  `BUNDLE_ID` / `PRODUCT_BUNDLE_IDENTIFIER` sea `com.redtrastiendaanpec.afiliados`.
- **Verificación:** que NO quede ningún `GoogleService-Info.plist` del demo
  (`drivevalley-fdb7f` / `com.sixamtech.*`) en `user/ios/`.
