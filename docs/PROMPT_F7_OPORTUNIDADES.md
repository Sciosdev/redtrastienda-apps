# PROMPT MAESTRO — F7: Oportunidades / Solicitud de contacto (apps AFILIADOS + PROVEEDORES, solo Flutter)

> Copia TODO este documento como primer mensaje del chat. El BACKEND YA EXISTE y funciona — aquí solo se hace la parte Flutter que lo conecta.
> Corre EN PARALELO con F5; por eso hay reglas anti-conflicto (ver §5).

---

Eres un desarrollador senior de Flutter trabajando en las apps de "ANPEC Red Trastienda" (basadas en 6valley V16.3, ya con branding ANPEC). Conservador, cambios mínimos, NO toques el branding.

## 1. Contexto y concepto

- **Repos/apps:** `redtrastienda-apps/user` (afiliados) y `redtrastienda-apps/vendor` (proveedores). Trabajarás en AMBAS. Abre la sesión en `redtrastienda-apps`.
- **Entorno:** Flutter 3.44.5 / Dart 3.12. Ambas apps compilan. Device de prueba `A059P` id `00170155D001304`.
- **Backend en vivo:** `https://adminapp.redtrastiendaanpec.com`. **NO tocar backend.**
- **Concepto MVP (importante):** una "oportunidad" ES un **producto** publicado por un proveedor. El proveedor ya puede crear productos (flujo existente); NO hay que construir una pantalla nueva de "publicar oportunidad" para el MVP. Lo que falta es el **flujo de solicitud de contacto**: el afiliado ve un producto/oportunidad y presiona **"Solicitar contacto"**; el proveedor ve esas solicitudes y les cambia el estatus.
- **Los endpoints y las URIs YA EXISTEN** (constantes ya en `app_constants.dart` de cada app). Solo falta la UI que las use.

## 2. Contrato del backend (ya desplegado y probado)

**App afiliados (user):**
- Constantes ya presentes: `opportunityRequestStore = '/api/v1/customer/opportunity-requests/store'`, `opportunityRequestList = '/api/v1/customer/opportunity-requests/list?'`.
- **Crear solicitud:** `POST opportunity-requests/store` (Bearer del afiliado). Body: `product_id` (int, requerido), `comment` (string opcional, ≤1000). Si ya hay una solicitud del mismo afiliado para ese producto en estatus `new`/`in_review`, responde 200 con `{message: "You already have a pending request..."}` (no duplica). OK responde `{message: "Contact request sent successfully"}`.
- **Mis solicitudes:** `GET opportunity-requests/list?limit=&offset=` (Bearer). Devuelve `{data, total_size, limit, offset}` con las solicitudes del afiliado (incluye info del producto/proveedor y `status`).

**App proveedores (vendor):**
- Constantes ya presentes: `opportunityRequestListUri = '/api/v3/seller/opportunity-requests/list?'`, `opportunityRequestUpdateStatusUri = '/api/v3/seller/opportunity-requests/update-status'`.
- **Solicitudes recibidas:** `GET opportunity-requests/list?status=&limit=&offset=` (auth seller). `status` opcional (uno de los STATUSES). Devuelve `{data, total_size, ...}` con las solicitudes hacia ese proveedor (incluye datos del afiliado y del producto).
- **Cambiar estatus:** `POST opportunity-requests/update-status` (auth seller). Body: `id` (requerido), `status` (requerido, uno de STATUSES), `provider_response` (string opcional).

**STATUSES (exactos, úsalos tal cual en la API):** `new`, `in_review`, `contacted`, `served`, `rejected`.
Etiquetas ES sugeridas: `new`→"Nueva", `in_review`→"En revisión", `contacted`→"Contactado", `served`→"Atendida", `rejected`→"Rechazada". (Agrega estas claves a `es.json`.)

## 3. Objetivo

**A) App afiliados (user):**
1. En el **detalle de producto** (y/o donde tenga sentido en el listado), agrega un botón **"Solicitar contacto"** → abre un diálogo/bottom-sheet con un campo opcional de comentario → llama `store` con `product_id` + `comment`.
2. Maneja las 3 respuestas: éxito (snackbar "Solicitud enviada"), ya-existe-pendiente (snackbar con el message), error (snackbar).
3. Pantalla **"Mis solicitudes"** (accesible desde el menú "Más") → lista `opportunity-requests/list` mostrando producto, proveedor, fecha y **badge de estatus** (con las etiquetas ES).

**B) App proveedores (vendor):**
1. Pantalla **"Solicitudes recibidas"** (accesible desde su menú/dashboard) → lista `opportunity-requests/list` con filtro por estatus; muestra afiliado (nombre/contacto), producto, comentario, fecha, badge de estatus.
2. En cada solicitud, permitir **cambiar estatus** (ej. marcar "Contactado" / "Atendida" / "Rechazada") vía `update-status`, con un campo opcional `provider_response`. Con confirmación.

Sigue el patrón del proyecto en cada app: Controller (ChangeNotifier) → Service → Repository → Interface, con Dio. Mira un módulo existente como molde (ej. en user, cualquier feature con lista paginada; en vendor, el de pedidos/`orders`).

## 4. UX / diseño
- Limpio, coherente con la app; rojo #A1262B para acentos; badges de estatus con color por estado.
- Estados vacíos amables ("Aún no tienes solicitudes" / "No hay solicitudes recibidas") y loading/skeleton como el resto de la app.

## 5. Reglas duras / anti-conflicto (corre en paralelo con F5)

1. Rama nueva **`f7-oportunidades`** desde `main`. NUNCA en `main`.
2. En archivos COMPARTIDOS (`assets/language/*.json`, `app_constants.dart` de cada app, menús, `route_healper.dart`): **SOLO agrega; NUNCA reordenes ni borres** líneas existentes (F5 corre en paralelo y también agrega ahí). Prefiere crear archivos/módulos NUEVOS.
3. **NO toques branding:** constantes de nombre/color/idioma/baseUrl, `theme/*`, `assets/images/logo*`, `assets/launcher/*`, `AndroidManifest.xml`, ni los productos/pedidos existentes salvo agregar el botón "Solicitar contacto".
4. **NO agregues paquetes** salvo que sea imprescindible (justifícalo y pregunta). NO cambies versiones.
5. **NO toques backend.** Solo Flutter, usando las URIs ya existentes.
6. Cambios mínimos y explicables.

## 6. Verificación (hay backend + datos en vivo)
1. `flutter run` en cada app sobre el device (una a la vez; solo una app corre en el device a la vez).
2. Afiliado: entra a un producto → "Solicitar contacto" → verifica éxito y el caso "ya pendiente". Ve "Mis solicitudes".
3. Proveedor: en "Solicitudes recibidas" ve la solicitud creada → cámbiale estatus → verifica que persiste (relista).
4. Screenshots (adb vía **PowerShell**): solicitar contacto, mis solicitudes, solicitudes recibidas, cambio de estatus.

## 7. Entregables
1. Rama `f7-oportunidades`.
2. Lista de archivos creados/modificados (una línea c/u), por app.
3. Screenshots del flujo completo.
4. Paquetes agregados (idealmente ninguno) y por qué.
5. Confirmación: compila/corre sin crash en ambas apps, branding intacto, archivos compartidos solo-append.
6. NO push ni merge (yo audito primero).

## 8. Criterio de aceptación
- Afiliado puede solicitar contacto sobre un producto (con manejo de duplicado) y ver sus solicitudes con estatus.
- Proveedor ve las solicitudes recibidas y cambia su estatus (persiste en backend).
- Cero cambios a branding/backend/paquetes; archivos compartidos solo-append.
