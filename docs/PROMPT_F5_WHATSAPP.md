# PROMPT MAESTRO — F5: WhatsApp ANPEC (app AFILIADOS, solo Flutter)

> Copia TODO este documento como primer mensaje del chat. Fase pequeña y aislada.
> Corre EN PARALELO con F7; por eso hay reglas anti-conflicto (ver §4).

---

Eres un desarrollador senior de Flutter en la app de afiliados de "ANPEC Red Trastienda" (app de cliente de 6valley V16.3, ya con branding ANPEC). Conservador, cambios mínimos, NO toques el branding.

## 1. Contexto

- **App:** `redtrastienda-apps/user`. Abre la sesión ahí.
- **Entorno:** Flutter 3.44.5 / Dart 3.12. Ya compila y corre en device (`A059P`, id `00170155D001304`). `flutter run -d 00170155D001304`.
- **Backend en vivo:** `https://adminapp.redtrastiendaanpec.com` (ya en `app_constants.dart`). **NO necesitas tocar backend.**
- **`url_launcher` ya está en el proyecto** (se usa en `dashboard_screen.dart`). Úsalo. No agregues paquetes.
- **Idioma:** español por defecto; textos con `getTranslated()` + claves nuevas al final de `assets/language/es.json` (y `en.json`).

## 2. Objetivo

Agregar **"WhatsApp ANPEC"** como canal de contacto directo del afiliado (docx: comunicación rápida con ANPEC):

1. **Número de contacto:** léelo del config del backend, campo **`company_phone`** (ya lo devuelve `GET /api/v1/config`; ANPEC lo configura en el admin). Revisa `SplashController`/`ConfigModel` — si `company_phone` no está mapeado en el `ConfigModel`, agrégalo (parse simple). NO hardcodees el número.
2. **Item de menú "WhatsApp ANPEC"** en el menú de "Más"/perfil (`lib/features/more/screens/more_screen_view_new.dart` — ahí viven los items; mira cómo se agregó "Mi Tarjeta Digital"). Al tocarlo:
   - Abre WhatsApp con `https://wa.me/<numero>` (limpia el número: solo dígitos; si no trae código de país, asume México `52`). Mensaje opcional pre-cargado: "Hola, soy afiliado de Red Trastienda…".
   - Opcional: un segundo botón/acción **Llamar** con `tel:<numero>`.
3. Si `company_phone` viene vacío en el config: oculta el item (o deshabilítalo con un tooltip), no crashees.
4. Usa `launchUrl(..., mode: LaunchMode.externalApplication)`.

## 3. Detalles de UX
- Un ícono de WhatsApp (usa uno de los assets/íconos existentes o un `Icons`), color coherente (rojo #A1262B para acentos, o el verde de WhatsApp para el botón — a tu criterio, limpio).
- Puede ser directo (el item abre WhatsApp) o una pantallita "Contacto ANPEC" con WhatsApp + Llamar. Elige lo más simple y limpio.

## 4. Reglas duras / anti-conflicto (corre en paralelo con F7)

1. Rama nueva **`f5-whatsapp`** desde `main`. NUNCA en `main`.
2. En archivos COMPARTIDOS (`assets/language/es.json`, `en.json`, `lib/utill/app_constants.dart`, el menú, `route_healper.dart`): **SOLO agrega al final / en bloque propio; NUNCA reordenes ni borres** líneas existentes. Esto evita conflictos con F7.
3. **NO toques branding:** `app_constants.dart` (nombres/colores/idioma/baseUrl — solo agrega si necesitas una URI, pero para F5 no debería hacer falta), `theme/*`, `assets/images/logo*`, `assets/launcher/*`, `AndroidManifest.xml`.
4. **NO agregues paquetes** (usa `url_launcher` existente). NO cambies versiones.
5. NO toques backend ni otras features. Solo el canal de WhatsApp/llamada.
6. Cambios mínimos y explicables. Duda no obvia → pregunta.

## 5. Verificación

1. `flutter run -d 00170155D001304`. Compila y prueba en device.
2. El item "WhatsApp ANPEC" abre WhatsApp con el número del config (para probar, pide que se configure un `company_phone` en el admin, o usa el que ya esté). Verifica que arma bien el `wa.me`.
3. Screenshots (adb vía **PowerShell**): el menú con el item, y WhatsApp abriéndose (o el intent).

## 6. Entregables

1. Rama `f5-whatsapp` con los cambios.
2. Lista de archivos tocados (una línea c/u).
3. Screenshots.
4. Confirmación de que compila/corre sin crash y de que NO tocaste branding ni paquetes.
5. NO hagas push ni merge (yo audito primero).

## 7. Criterio de aceptación
- Item "WhatsApp ANPEC" en el menú, abre `wa.me/<company_phone>` correctamente; maneja número vacío.
- Cero cambios a branding/paquetes; archivos compartidos solo-append.
