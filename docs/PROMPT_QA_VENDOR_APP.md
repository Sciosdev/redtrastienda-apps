# PROMPT MAESTRO — QA + arreglo de bugs: app de PROVEEDORES (Flutter)

> Copia TODO esto como primer mensaje. Sesión interactiva de pruebas + corrección:
> tú corres la app, el humano la usa y te dicta los problemas que ve, y tú los DIAGNOSTICAS y ARREGLAS (con cambios mínimos), reconfirmando con él.

---

Eres un desarrollador senior de Flutter. Tu tarea: hacer una **pasada de QA sobre la app de proveedores** de "ANPEC Red Trastienda" (basada en la app vendor de 6valley V16.3, ya con branding ANPEC) y **arreglar los bugs** que el humano vaya reportando mientras la usa. La app casi no se ha usado, así que es normal que salgan varios.

## 1. Método de trabajo (loop)
1. Compilas y corres la app: `flutter run -d 00170155D001304` desde `redtrastienda-apps/vendor`.
2. El humano usa la app en su teléfono y te dice qué problema ve (pantalla, acción, mensaje de error).
3. Tú **obtienes el error real** de los logs (no adivines): del output de `flutter run`, o `adb -s 00170155D001304 logcat` filtrando `flutter`/`E/`.
4. Diagnosticas la causa (archivo:línea) y aplicas el **arreglo mínimo**.
5. `hot reload`/`hot restart` o rebuild; el humano reconfirma que quedó. Siguiente bug.

## 2. Entorno
- App: `redtrastienda-apps/vendor`. Abre la sesión ahí. Flutter 3.44.5 / Dart 3.12.
- Device: **A059P**, id **`00170155D001304`** (Android 16), USB. Una sola app a la vez en el device (si hay otro `flutter run`, ciérralo).
- Backend en vivo: `https://adminapp.redtrastiendaanpec.com` (ya en `app_constants.dart`).
- **Credenciales de proveedor de prueba (ya existe, aprobado):** `proveedor.test@anpec.test` / `proveedor123` (tienda "Distribuidora Test ANPEC", categoría "Refrescos"). Úsalas para login.
- Screenshots (si los necesitas para ver estado): **PowerShell**, no git-bash (`adb ... screencap -p /sdcard/s.png` + `adb ... pull`). adb en `%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe`.

## 3. Contexto útil (bugs típicos de esta base)
- **Incompatibilidades de API de paquetes** (por versiones resueltas más nuevas): el patrón de arreglo ya aplicado es agregar el `default:` faltante en `switch(error.type)` de `lib/data/datasource/remote/exception/api_error_handler.dart` (por `DioExceptionType.transformTimeout` de dio 5.x). Resuelve otras del mismo estilo con el cambio mínimo (case faltante, firma cambiada, import), NO reescribiendo features.
- **Traducciones ES malas** heredadas del auto-traductor (ej. literales raros): puedes corregir la clave puntual en `vendor/assets/language/es.json` (solo el valor, no reordenar).
- La app tiene módulos que ANPEC **oculta** (POS, delivery man, wallet, withdraw, cupones, subastas, clearance). Bugs SOLO dentro de esos módulos ocultos son **baja prioridad**; enfócate en lo del flujo real (abajo).

## 4. Prioridad (flujos que importan para la demo)
Enfoca los arreglos en, por orden:
1. **Login** del proveedor.
2. **Dashboard / inicio** (que cargue sin crash).
3. **Mi empresa / perfil** (ver/editar datos de la tienda).
4. **Productos** — listar y **agregar producto** (este flujo lo va a usar el humano para crear la "oportunidad" del test de F7; que funcione es importante).
5. **Pedidos recibidos** y **Solicitudes recibidas** (oportunidades, F7).
6. Notificaciones.
Lo demás (POS, delivery, etc.) → baja prioridad / ignorar si está oculto.

## 5. Reglas duras
1. **NO toques el branding:** `lib/utill/app_constants.dart` (nombres/colores/idioma/baseUrl), `lib/theme/*` (rojo #A1262B), `assets/images/logo*`, `assets/launcher/*`, íconos en `android/app/src/main/res/`, `AndroidManifest.xml`.
2. **NO cambies versiones en `pubspec.yaml`** salvo que sea la ÚNICA salida — y entonces explícalo y pide confirmación primero. Prefiere arreglar el código Dart.
3. **Arreglos mínimos y explicables.** No refactorices ni reescribas features enteras. No rompas otros flujos.
4. **Diagnostica con logs reales** (flutter run / logcat), no a ciegas.
5. Trabaja en rama nueva **`qa-vendor-app`** (NO en `main`). No push ni merge (el auditor revisa primero).
6. Si un bug es de backend (no de la app), documéntalo con el request/response y no lo "arregles" en el cliente con un parche raro — repórtalo.

## 6. Entregable (para el auditor)
1. Rama `qa-vendor-app` con los arreglos.
2. **Lista de bugs**, cada uno con: qué reportó el humano, la causa (archivo:línea), y el arreglo aplicado (una línea).
3. Si tocaste `pubspec.yaml` o algo de `android/`, resáltalo.
4. Confirmación de que la app compila/corre sin crash tras los arreglos, y de que NO tocaste branding.
5. Bugs de backend detectados (si los hay), listados aparte.

## 7. Criterio de aceptación
- Los flujos prioritarios (login, dashboard, empresa, productos/agregar producto, pedidos/solicitudes recibidas) funcionan sin crash.
- Cambios mínimos, branding intacto, sin cambios de versión no justificados, en la rama `qa-vendor-app`.
