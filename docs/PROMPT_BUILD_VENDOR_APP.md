# PROMPT MAESTRO — Primera compilación de la app de PROVEEDORES (Flutter)

> Copia TODO este documento como primer mensaje del chat de implementación.
> Objetivo: lograr que la app compile, se instale y corra en un teléfono Android físico, arreglando SOLO errores de compilación de primera build. NO tocar branding ni lógica de negocio.

---

Eres un desarrollador senior de Flutter. Tu única tarea es hacer que la app de proveedores **compile y corra en un dispositivo físico**, arreglando errores de compilación de forma mínima y conservadora. El branding ya está hecho — no lo toques.

## 1. Contexto

- **App:** `redtrastienda-apps/vendor` (app de proveedores de "ANPEC Red Trastienda", basada en la app vendor de 6valley V16.3). Abre la sesión de Claude Code en esa carpeta.
- **Es su PRIMERA compilación.** Nunca se ha construido. Es normal que salgan incompatibilidades de API de paquetes, porque las versiones resueltas (Flutter 3.44.5 / Dart 3.12) son más nuevas que las que asumía el código original de 6valley.
- **Entorno:** Flutter 3.44.5 / Dart 3.12.2 instalado local. `pubspec.yaml` con `environment: sdk: '>=3.2.0 <4.0.0'`.
- **Dispositivo de pruebas (ya conectado por USB, depuración activada):** `A059P`, id **`00170155D001304`**, Android 16. Comando base:
  ```
  flutter run -d 00170155D001304
  ```
- **Backend en vivo:** `https://adminapp.redtrastiendaanpec.com` (ya configurado en `lib/utill/app_constants.dart` → `baseUrl`). Login de proveedor: `POST /api/v3/seller/auth/login`. El backend responde (verificable en `/api/v1/config`).
- **App hermana ya resuelta:** la app de afiliados (`redtrastienda-apps/user`) YA compila y corre en este mismo teléfono. Úsala como referencia de cómo se resolvieron los problemas.

## 2. Fix de referencia (patrón de cómo arreglar incompatibilidades)

Ya se aplicó UN fix de este tipo en AMBAS apps, y es el modelo a seguir:
- Archivo: `lib/data/datasource/remote/exception/api_error_handler.dart`.
- Problema: `dio` se resolvió a 5.x, que añadió `DioExceptionType.transformTimeout`; el `switch(error.type)` no era exhaustivo → error de compilación.
- Fix: se agregó un `default:` al switch (ya está presente en la app de proveedores, líneas ~90 y ~107).

Cuando salgan errores nuevos, resuélvelos con **la misma filosofía**: adaptar el código a la API nueva del paquete con el cambio MÍNIMO (agregar un case faltante, ajustar una firma cambiada, un import), NO reescribir features.

## 3. Reglas duras (violarlas = trabajo rechazado)

1. **NO toques el branding** — nada de: `lib/utill/app_constants.dart` (nombres, colores, idioma, baseUrl), `lib/theme/*` (color #A1262B), `assets/images/logo*`, `assets/launcher/*`, los mipmaps/íconos en `android/app/src/main/res/`, `AndroidManifest.xml` (label "RT Proveedores"), ni los `assets/language/es.json`. Todo eso ya está correcto.
2. **NO cambies versiones en `pubspec.yaml`** salvo que sea la ÚNICA salida y no exista un fix en código. Si de plano hay que tocar una versión, primero explícalo y pide confirmación. Prefiere SIEMPRE arreglar el código Dart para que compile con las versiones ya resueltas en `pubspec.lock`.
3. **NO** `flutter upgrade` ni cambiar el SDK. **NO** borrar features ni pantallas.
4. **NO** cambies lógica de negocio ni endpoints. Solo lo necesario para que compile/instale/arranque.
5. Trabaja en rama nueva `build-vendor-app` (NO en `main`).
6. Cada arreglo debe ser mínimo y explicable. Si un error requiere una decisión no obvia, PÁRATE y pregunta.

## 4. Procedimiento

1. `flutter pub get` en `redtrastienda-apps/vendor`.
2. `flutter run -d 00170155D001304`. Lee los errores.
3. Arregla el primer error (o grupo del mismo tipo) con el cambio mínimo. Repite build. Itera hasta que compile, instale y arranque.
4. Si Gradle falla (Android build), lee el error específico; suelen ser desugaring/AGP/minSdk. Arréglalo conservadoramente; si implica tocar `android/app/build.gradle.kts` o `gradle`, explícalo antes.
5. Cuando arranque, verifica el branding en pantalla (screenshots vía adb):
   - **adb** está en `%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe`. Para screenshot usa **PowerShell** (NO git-bash, que mutila rutas `/sdcard/...`):
     ```
     adb -s 00170155D001304 shell screencap -p /sdcard/s.png ; adb -s 00170155D001304 pull /sdcard/s.png ./s.png
     ```
   - Confirma: splash con **fondo rojo + logo blanco**, pantalla de login con **logo** y textos en **español** ("Iniciar sesión"), nombre de app y color rojo.

## 5. Nota sobre login (para verificación)

Para ver más allá del login necesitas una cuenta de **proveedor/seller** válida en el backend. Si no la tienes a la mano, con verificar splash + pantalla de login (que ya muestran branding) es suficiente para esta tarea. NO crees datos ni toques el backend.

## 6. Entregables

1. Rama `build-vendor-app` con los arreglos.
2. Lista de TODOS los archivos modificados, con una línea explicando cada arreglo y por qué (qué paquete/API cambió).
3. Si tocaste alguna versión en `pubspec.yaml` o algo de `android/`, resáltalo aparte.
4. 2–3 screenshots del dispositivo mostrando el branding (splash/login).
5. Confirmación de que la app compila, instala y arranca sin crash en el A059P.

## 7. Criterio de aceptación

- `flutter run -d 00170155D001304` compila, instala y abre la app sin errores.
- Se ve el branding ANPEC (rojo, logo, español, nombre/ícono correctos).
- Cero cambios al branding, a la lógica de negocio o a versiones de paquetes (salvo que se haya justificado y confirmado).
