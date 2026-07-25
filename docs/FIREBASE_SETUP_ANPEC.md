# Firebase propio ANPEC — guía + registro

**Rama:** `r-firebase` (desde `r-pulido-aab`).
**Problema:** la app trae el `google-services.json` del proyecto DEMO de 6amtech
(`project_id: drivevalley-fdb7f`, `project_number: 76471554747`). Síntoma real: llegan
pushes ajenos "Demo reset alert" dentro de la app ANPEC. Hay que crear un proyecto Firebase
propio, recablear app (Android + iOS) y panel admin, y verificar.

- **applicationId Android / bundle id iOS:** `com.redtrastiendaanpec.afiliados`
- **SHA-1 release (upload-keystore.jks, alias `upload`):**
  `9E:A7:FF:D7:45:E7:30:DA:84:2F:BD:A5:D8:5E:3F:5B:C3:65:AB:9E`
- **SHA-256 release:**
  `0C:BE:F5:9D:48:30:8F:ED:14:A1:6A:1C:B0:72:81:48:72:E7:FC:43:35:7E:AE:62:70:18:32:66:0F:0E:41:61`

> **⚠️ CAMBIO DE applicationId / bundle id (decisión Axel 2026-07-20).** Se cambió de
> `club.scios.redtrastienda` a **`com.redtrastiendaanpec.afiliados`** ANTES del primer AAB, para
> que ANPEC no quede atada al namespace de SCIOS de forma permanente. `build.gradle.kts:40`
> ya editado en `r-firebase`. **Dos dependencias para el maestro:**
> 1. ✅ **CONFIRMADO por Axel 2026-07-20: NO se subió ningún AAB a Play** con el id viejo → el
>    cambio fue limpio, sin bloqueo de Play.
> 2. El **bundle id de iOS** también cambia → el enrollment de Apple (SCIOS, en curso) apuntaba a
>    `club.scios.redtrastienda`; hay que **re-crear el App ID** con el nuevo string. Ver
>    `docs/IOS_STATUS.md`.

---

## PARTE A — Lo que hace Axel en la consola (su cuenta Google)

Ir a https://console.firebase.google.com

### 1. Crear proyecto
- **Add project** → nombre: `ANPEC Red Trastienda` (o el que prefieras).
- Google Analytics: **puedes desactivarlo** (opcional; no lo necesita el push). Menos pasos.
- Al terminar, anota el **Project ID** que Firebase asigne (algo como `anpec-red-trastienda`
  o con sufijo). NO debe ser `drivevalley-fdb7f`.

### 2. Registrar app Android
- En el proyecto → **Add app** → icono **Android**.
- **Android package name:** `com.redtrastiendaanpec.afiliados`  ← exacto, sin espacios.
- **App nickname:** `ANPEC Afiliados`.
- **Debug signing certificate SHA-1** (opcional pero recomendado, pégalo):
  `9E:A7:FF:D7:45:E7:30:DA:84:2F:BD:A5:D8:5E:3F:5B:C3:65:AB:9E`
  (Social login está apagado, así que el SHA-1 no es requisito para el push; se agrega por si
  algún día se activa Google Sign-In.)
- **Download google-services.json** → **pásamelo** (lo coloco yo en el repo).
  No lo pegues en el chat como secreto si prefieres; este archivo no es secreto (no lleva llaves
  privadas), pero pásalo como archivo.

### 3. Registrar app iOS
- **Add app** → icono **Apple**.
- **Apple bundle ID:** `com.redtrastiendaanpec.afiliados`  ← exacto.
- **App nickname:** `ANPEC Afiliados iOS`.
- **Download GoogleService-Info.plist** → pásamelo (lo dejo en `docs/` + nota para el chat de la
  Mac que administra `user/ios/`; ver `docs/IOS_STATUS.md`).

### 4. Registrar app Web (para el panel admin)
El panel necesita el objeto de configuración **Web** de Firebase para el push web y el OTP.
- **Add app** → icono **Web** (`</>`).
- **App nickname:** `ANPEC Panel Web`. NO marques Firebase Hosting.
- Copia el objeto `firebaseConfig` que muestra (o luego desde **Project settings → General →
  Your apps → Web app → SDK setup and configuration → Config**). Necesito estos 7 valores para
  el panel:
  ```
  apiKey, authDomain, projectId, storageBucket, messagingSenderId, appId, measurementId
  ```
  (`measurementId` solo existe si activaste Analytics; si no, déjalo vacío.)

### 5. Credencial de push para el panel (FCM HTTP v1)
El panel v16.3 manda push por **FCM HTTP v1 con cuenta de servicio** (NO usa Legacy Server Key).
- **Project settings** (engranaje) → pestaña **Service accounts**.
- Asegúrate de que **Firebase Admin SDK** esté seleccionado → botón **Generate new private key**
  → **Generate key**. Descarga un archivo `.json` (contiene `project_id`, `client_email`,
  `private_key`).
- ⚠️ **Este JSON SÍ es secreto.** No lo pegues en el chat ni al repo. Va **solo** dentro del
  panel admin (Parte C, campo "Service Account Content"). Guárdalo en un lugar seguro.
- (Opcional) En **Cloud Messaging** verás que la "Cloud Messaging API (Legacy)" puede estar
  deshabilitada — es normal, no la necesitamos. La "Firebase Cloud Messaging API (V1)" debe
  estar **Enabled** (suele estarlo por defecto).

---

## PARTE B — Recableo en la app (lo hago yo, con el archivo del paso 2)

- [ ] Reemplazar `user/android/app/google-services.json` por el nuevo.
      Verificar `project_id` ≠ `drivevalley-fdb7f` y que exista `package_name`
      `com.redtrastiendaanpec.afiliados`.
- [ ] Colocar `GoogleService-Info.plist` en `docs/` + nota en `docs/IOS_STATUS.md` (el chat de la
      Mac lo integra en `user/ios/Runner/`).
- [ ] Grep de barrido: 0 referencias a `drivevalley` / `6amtech` / `sixamtech` / `76471554747`
      fuera de `vendor/` y del `namespace` legacy de Gradle.
- [ ] `flutter analyze` (línea base 57) + APK debug que compile con el JSON nuevo.

**Nota:** NO existe `firebase_options.dart` (FlutterFire) ni un `default_web_client_id` en
`strings.xml`; la app usa solo la ruta nativa del plugin `google-services`. R-Pulido ya sacó
Facebook. => el único archivo Android que apunta al demo es `google-services.json`.

---

## PARTE C — Recableo en el panel admin (lo hace Axel por el panel, lo guío yo)

Ruta en el panel: **Admin → 3rd Party (o Business Settings) → Firebase / Firebase Configuration**
(controlador `PushNotificationSettingsController`, ruta `admin.third-party.firebase-configuration.setup`).
Todo se guarda en `business_settings` (DB), **no en el repo**. Campos del formulario:

| Campo del formulario            | Qué pegar                                                        |
|---------------------------------|-----------------------------------------------------------------|
| **Service Account Content**     | El **JSON completo** de la cuenta de servicio (Parte A paso 5).  |
| Api Key                         | `apiKey` del config Web (paso 4).                                |
| Auth Domain                     | `authDomain` (p. ej. `tu-proyecto.firebaseapp.com`).            |
| Project ID                      | `projectId` (el nuevo, ≠ drivevalley).                           |
| Storage Bucket                  | `storageBucket`.                                                 |
| Messaging Sender ID             | `messagingSenderId` (el project_number nuevo).                  |
| App ID                          | `appId` del config Web.                                          |
| Measurement ID                  | `measurementId` (vacío si no hay Analytics).                     |

Al guardar, el panel **regenera** `firebase-messaging-sw.js` (raíz + `public/`) con esos valores.

**⚠️ Cambio de código en el admin (rama `r-firebase-admin` desde `main`):** los dos archivos
committeados `firebase-messaging-sw.js` y `public/firebase-messaging-sw.js` traen HOY el config
Web del **demo** (`drivevalley-fdb7f`, sender `76471554747`). Aunque el panel los reescribe al
guardar, siguen committeados → un `git pull` de deploy podría reponer los valores del demo. Hay
que actualizarlos con el config Web nuevo (paso 4) para que el baseline del repo coincida. Se
hace cuando Axel entregue el config Web. **Las llaves/secretos NO van al repo**; solo el config
Web público (apiKey Web de Firebase no es secreto).

**Residuo honesto (fuera de alcance Firebase):** `public/.well-known/assetlinks.json` lista
`com.sixamtech.sixvalley` con un SHA del demo (Android App Links, no es push). Señalado, sin
tocar — requiere el dominio real de ANPEC + el SHA-256 de release y es decisión aparte.

---

## PARTE D — Verificación (criterio de "quedó")

1. [ ] APK debug en device A059P (`00170155D001304`), app `com.redtrastiendaanpec.afiliados`.
2. [ ] Disparar push desde el panel (o evento real: cambio de estatus de pedido / chat) y
       confirmar que **llega** al teléfono.
3. [ ] Confirmar que **ya NO** llegan los "Demo reset alert" de 6amtech.
4. [ ] Reporte final: project_id nuevo, dónde quedó la credencial, resultado del push, residuos.

---

## Estado / bitácora

- 2026-07-20 — Rama `r-firebase` creada. SHA-1/256 extraídos del keystore. Confirmado: panel usa
  FCM v1 con service-account JSON (campo "Service Account Content" = `push_notification_key`);
  no hay `firebase_options.dart` ni claves del demo en `strings.xml`.
- 2026-07-20 — **applicationId cambiado** `club.scios.redtrastienda` → `com.redtrastiendaanpec.afiliados`
  en `build.gradle.kts:40` (decisión Axel; pre-AAB). Solo 2 refs al id viejo existían (gradle +
  google-services.json que se reemplaza). Pendiente: confirmar en Play que no había AAB subido +
  re-crear App ID de iOS con el maestro.
- 2026-07-20 — **ANDROID LISTO.** Proyecto Firebase propio creado: `project_id anpec-b7c3c`,
  sender `1011581065251`, Plan Spark. `google-services.json` reemplazado (0 refs a drivevalley/
  sixamtech/demo). `flutter analyze` = 57 (línea base, sin regresión). **APK debug compila** en
  28s (Gradle procesa el JSON, package_name ↔ applicationId OK).
- 2026-07-20 — **iOS: hallazgo.** El track iOS nunca se rebrandeó del demo: `ios/GoogleService-Info.plist`
  = proyecto demo `sixvally-ecommerce` (sender 975837518429), bundle `com.sixamtech.sixValley` en
  pbxproj (3 configs) y en `Runner.entitlements` (team 6amtech `7WSYLQ8Y87`). Documentado en
  `docs/IOS_STATUS.md` para la Mac; NO tocado (fuera de alcance).
- 2026-07-20 — **iOS plist entregado** (`docs/GoogleService-Info.plist`, proyecto anpec-b7c3c,
  bundle correcto) → `IOS_STATUS.md` actualizado para la Mac. **Admin:** rama `r-firebase-admin`
  con los dos `firebase-messaging-sw.js` (raíz + public) recableados al config Web anpec-b7c3c.
- 2026-07-20 — **Limpieza extra (aprobada Axel):** quitado el `Firebase.initializeApp` secundario
  placeholder (`name: 'your_project_name'`, opciones basura) de `main.dart` + import `dart:io`
  sobrante. Verificado en device: el arranque ahora solo inicializa `[DEFAULT]` = anpec-b7c3c
  (log ya no muestra `your_project_name`). analyze 57, APK reinstalado en A059P.
- **Config Web (no secreto), para el panel:** apiKey `AIzaSyCO7wsBv5ExQMIOdN7to-jtchV3ZQQl3_4`,
  authDomain `anpec-b7c3c.firebaseapp.com`, projectId `anpec-b7c3c`, storageBucket
  `anpec-b7c3c.firebasestorage.app`, messagingSenderId `1011581065251`, appId
  `1:1011581065251:web:38bb0add1cca37c692b996`, measurementId `G-BHGB17MF5R`.
- 2026-07-20 — **✅ PUSH E2E VERIFICADO EN DEVICE.** Axel pegó service-account JSON + config Web
  en el panel en vivo. Login en app nueva → `200 POST /api/v1/customer/cm-firebase-token` (token
  `fv43Ug08QS...:APA91b...` de anpec-b7c3c). Disparo por cambio de estatus de pedido (opción 1) →
  **notificación "Red Trastienda · orden" llegó al A059P**. Circuito completo panel→FCM v1→device
  contra el proyecto propio. Los "Demo reset alert" no pueden llegar a la app nueva (otro proyecto).
- **Nota cosmética (fuera de alcance Firebase):** el texto del push salió genérico ("orden /
  Order con Message") — son las plantillas de Notificaciones del panel, se pulen ahí, no es Firebase.
- **PENDIENTE menor:** desinstalar del A059P las apps demo viejas (`club.scios.redtrastienda`,
  `com.sixamtech.sixvalley.seller`) para que el teléfono deje de recibir "Demo reset alert".
  Commits de `r-firebase` y `r-firebase-admin` en espera de OK (sin push; el maestro mergea).
