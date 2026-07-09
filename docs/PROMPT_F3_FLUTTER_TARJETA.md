# PROMPT MAESTRO — F3-Flutter: Número ANP en registro + Tarjeta Digital (app AFILIADOS)

> Copia TODO este documento como primer mensaje del chat de implementación.
> Alcance: app de afiliados (Flutter). El backend ya está desplegado y probado end-to-end. Aquí se hace la parte Flutter.

---

Eres un desarrollador senior de Flutter trabajando en la app de afiliados de "ANPEC Red Trastienda" (basada en la app de cliente de 6valley V16.3). Trabaja incremental y conservador. El branding ya está hecho — no lo toques.

## 1. Contexto

- **App:** `redtrastienda-apps/user` (afiliados). Abre la sesión de Claude Code ahí.
- **Entorno:** Flutter 3.44.5 / Dart 3.12. La app YA compila y corre en un teléfono físico (`A059P`, id `00170155D001304`, Android 16). `flutter run -d 00170155D001304`.
- **Backend en vivo:** `https://adminapp.redtrastiendaanpec.com` (ya en `lib/utill/app_constants.dart` → `baseUrl`). YA existe y funciona:
  - `POST /api/v1/auth/check-numero-anp` body `{numero_anp}` → `{"existe":bool,"disponible":bool,"message":string}`
  - `POST /api/v1/auth/register` — ya acepta `numero_anp` y `nombre_negocio` opcionales. Si mandas `numero_anp`, el backend valida que exista y esté "disponible"; si no, responde 403 con `{"errors":[{"code":"numero_anp","message":"..."}]}`. Al registrar OK: crea el perfil de afiliado en estatus "pendiente" y consume el número.
  - `GET /api/v1/customer/affiliate-profile` (con Bearer del usuario logueado) → JSON del perfil, o **404** si el usuario no tiene perfil de afiliado. Campos: `id, customer_id, numero_anp, nombre_negocio, whatsapp, direccion, estado, municipio, colonia, foto_negocio, estatus, approved_at, approved_by, created_at`.
- **Arquitectura del proyecto (síguela):** Controller (Provider/ChangeNotifier) → Service → Repository → Interface, con Dio. Referencia exacta del flujo de registro:
  - `lib/features/auth/screens/` + `lib/features/auth/widgets/sign_up_widget.dart` (formulario de registro)
  - `lib/features/auth/domain/models/register_model.dart` (modelo que se postea; tiene `toJson()`)
  - `lib/features/auth/controllers/auth_controller.dart` → `.../domain/services/auth_service.dart` → `.../domain/repositories/auth_repository.dart` (postea `registrationUri`)
- **Constantes/URIs:** `lib/utill/app_constants.dart` (ya tiene `registrationUri`, `customerUri`, etc.). Agrega ahí las URIs nuevas.
- **Perfil / menú:** `lib/features/profile/screens/profile_screen.dart` (pantalla de perfil activa; ahí van los items de menú tipo "Mi perfil", "Cerrar sesión"). Rutas en `lib/helper/route_healper.dart` (GoRouter).
- **Idioma:** español por defecto. TODO texto visible usa `getTranslated('clave', context)` y su valor se agrega a `assets/language/es.json` (y opcionalmente `en.json`). NO reordenes los json; solo agrega claves.

## 2. Objetivo

**Parte A — Número ANP + nombre de negocio en el registro:**
1. Agrega dos campos al formulario de registro de afiliados (`sign_up_widget.dart`): **Número ANP** (requerido) y **Nombre del negocio** (requerido).
2. **Pre-validación del ANP** (UX): al perder foco / antes de enviar, llama `check-numero-anp`. Muestra feedback claro (verde "disponible" / rojo "inválido" o "no disponible"). No bloquees todo el form por esto, pero si al enviar el ANP no es válido, no permitas continuar.
3. Envía `numero_anp` y `nombre_negocio` en el body del registro (agrega los campos a `RegisterModel` + su `toJson()`).
4. Maneja el error 403 del backend (`errors[].code == 'numero_anp'`) mostrando el `message` que devuelve, sin romper el flujo.
5. El resto del registro (email, teléfono, OTP, etc.) queda **igual**.

**Parte B — Tarjeta Digital (F4):**
1. Nueva pantalla **"Mi Tarjeta Digital"**, accesible desde el menú de perfil (`profile_screen.dart`) con su ruta en el GoRouter.
2. Llama `GET /api/v1/customer/affiliate-profile` (Controller→Service→Repository nuevos, patrón del proyecto).
3. Muestra una tarjeta con: **logo ANPEC** (usa `Images.logo`/el logo de marca ya existente), **nombre del afiliado** (del perfil del usuario, `ProfileController`/`customerUri`), **nombre del negocio**, **número ANP**, **estatus** (badge: pendiente/activo/rechazado/bloqueado con color), **fecha de afiliación** (`created_at`), un **QR** (con el número ANP como contenido) y un **botón compartir**.
4. Si el endpoint responde **404** (usuario sin perfil de afiliado): muestra un estado vacío amable ("Aún no tienes tarjeta digital / regístrate con tu número ANP"), no un error.
5. Diseño: limpio, con el rojo institucional #A1262B, coherente con el resto de la app.

## 3. Dependencias (única excepción permitida)

- Agrega **`qr_flutter`** (última versión null-safe compatible con Dart 3.12) a `pubspec.yaml` para el QR, y corre `flutter pub get`.
- Para compartir: si el proyecto ya tiene `share_plus` úsalo; si no, agrégalo, y si complica el build, como fallback usa "copiar al portapapeles" (`Clipboard`). Explica qué elegiste.
- NO agregues otros paquetes sin justificar.

## 4. Reglas duras (violarlas = trabajo rechazado)

1. **NO toques el branding:** `app_constants.dart` (nombres, colores, idioma, baseUrl — solo AGREGA URIs nuevas), `lib/theme/*`, `assets/images/logo*`, `assets/launcher/*`, `AndroidManifest.xml`, ni el resto de `assets/language/es.json` (solo AGREGA claves nuevas).
2. **NO rompas el registro actual:** email/phone/OTP/social login siguen igual. Los campos nuevos se suman, no reemplazan.
3. **NO cambies versiones de otros paquetes** en `pubspec.yaml` (solo agrega `qr_flutter` y quizá `share_plus`). Si algo obliga a más, explícalo y pregunta.
4. Sigue el patrón Controller→Service→Repository→Interface del proyecto para las llamadas nuevas (mira `auth_repository.dart` como molde). Registra los providers nuevos donde se registran los demás (busca el `MultiProvider`/lista de providers en `main.dart` o `di_container`).
5. Todo texto con `getTranslated()` + su español en `es.json`.
6. Trabaja en rama nueva `f3-flutter` (NO en `main`).
7. Cambios mínimos y explicables; si una decisión no es obvia, pregunta.

## 5. Procedimiento y verificación

1. Implementa Parte A, luego Parte B.
2. `flutter run -d 00170155D001304`, compila y prueba en el dispositivo. Errores de build se arreglan como en la app hermana (cambio mínimo, no reescribir).
3. **Prueba real end-to-end** (hay backend en vivo):
   - Genera un número ANP disponible desde el admin (o pide uno). Regístrate en la app con ese número + nombre de negocio → debe registrar OK y el perfil quedar "pendiente".
   - Prueba un ANP inválido → debe mostrar el mensaje de error del backend.
   - Entra a "Mi Tarjeta Digital" → debe mostrar los datos + QR.
4. Screenshots vía adb (usa **PowerShell**, no git-bash: `adb -s 00170155D001304 shell screencap -p /sdcard/s.png ; adb ... pull ...`). adb en `%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe`.

## 6. Entregables

1. Rama `f3-flutter` con los cambios.
2. Lista de archivos creados/modificados con una línea por cada uno.
3. Qué paquetes agregaste (qr_flutter / share_plus) y por qué.
4. 2–3 screenshots: registro con los campos nuevos, y la Tarjeta Digital.
5. Resumen de decisiones/supuestos y cualquier duda.

## 7. Criterio de aceptación

- Registro con Número ANP + Nombre de negocio funciona contra el backend en vivo (OK y casos de error).
- Registro actual (sin cambios en el resto del flujo) sigue intacto.
- "Mi Tarjeta Digital" muestra datos reales del perfil + QR + compartir, y maneja el 404 con un estado vacío amable.
- Cero cambios a branding; solo `qr_flutter` (y quizá `share_plus`) agregados a pubspec.
