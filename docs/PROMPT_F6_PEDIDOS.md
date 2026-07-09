# PROMPT MAESTRO — F6: Pedidos a proveedores (BACKEND config + app AFILIADOS + app PROVEEDORES)

> Copia TODO este documento como primer mensaje del chat que construirá F6.
> Es **la fase más grande que queda** del MVP ANPEC (prioridad ALTA del docx). Toca las 2 apps Flutter + configuración de backend. Se corre EN PARALELO con el cierre de 1.1–1.3 en otro chat; por eso hay reglas anti-conflicto (ver §7).
> **Regla de oro:** NO se crea módulo nuevo. Se **reutiliza** el flujo nativo de 6valley `cart → checkout → orders/order_details`, simplificándolo (solo pago contra entrega, sin envío). Cambios mínimos, conservador, NO tocar branding.

---

Eres un desarrollador senior full-stack (Flutter + Laravel/6valley) trabajando en "ANPEC Red Trastienda", un marketplace basado en 6valley V16.3 ya rebrandeado (rojo `#A1262B`, español por defecto, logos/íconos ANPEC). Tu trabajo es habilitar el flujo de **PEDIDOS**: el afiliado arma un pedido de productos a un proveedor (cantidades + comentarios) y el proveedor lo recibe y le cambia el estatus.

## 1. Contexto y concepto

- **Workspace:** abre la sesión en la raíz `D:\Github\RTTANPEC` (verás los dos repos).
  - `redtrastienda-apps/user` — app **afiliados** (Flutter).
  - `redtrastienda-apps/vendor` — app **proveedores** (Flutter).
  - `redtrastienda-admin` — backend Laravel/6valley (**solo tocar si la config del panel no basta**; ver §3.A).
- **Entorno Flutter:** 3.44.5 / Dart 3.12. Ambas apps compilan y corren. Device de prueba `A059P` id `00170155D001304` (Android, USB). **Solo una app corre en el device a la vez.**
- **Backend en vivo:** `https://adminapp.redtrastiendaanpec.com` (admin web = panel, en español). Login master admin lo tiene el humano.
- **Concepto MVP:** un "pedido" ES una **orden** de 6valley (`orders` + `order_details`). El afiliado ve productos de un proveedor → agrega al **carrito** (cantidades) → **confirma pedido** con un comentario → se crea la orden **sin pago en línea y sin envío** (pago contra entrega / offline). El proveedor ve "Pedidos Recibidos" (pantalla de orders que YA existe) y cambia el estatus. **No hay pasarelas, no hay repartidor, no hay tracking de envío** — esos módulos están apagados.
- **Qué YA existe (no reconstruir):**
  - `user/lib/features/cart`, `.../checkout` (con `choose_payment_widget`, `offline_payment_widget`, `payment_method_bottom_sheet_widget`), `.../order`, `.../order_details`.
  - `vendor/lib/features/order` (con `screens/order_screen.dart`, `controllers`, `enums`, `domain`) — **esta ES "Pedidos Recibidos"**. Ya llama a los endpoints de orders del seller.
  - Backend: `orders`/`order_details`, endpoints seller de orders (v3), config de métodos de pago y business settings.

## 2. Estado esperado antes de empezar (verifícalo tú primero)

Antes de escribir código, **audita el estado actual** y repórtalo:
1. ¿La pestaña **Carrito** del bottom nav de la app afiliados está visible o la ocultaron? (Se dejó hardcodeada en `user/lib/features/dashboard/screens/dashboard_screen.dart`; el ocultamiento se difirió a F6). Para F6 el carrito **debe estar usable**.
2. Corre `vendor/` y entra a la pantalla de pedidos existente: ¿carga? ¿con qué estatus muestra? (probablemente en inglés / traducciones automáticas malas).
3. En el admin panel, revisa **Business Settings → métodos de pago**: ¿está activo "Cash on Delivery"? ¿qué pasarelas en línea están activas? ¿la API `/api/v1/config` expone `cash_on_delivery`?

## 3. Objetivo (por capa)

### 3.A Backend / configuración (haz esto PRIMERO — habilita todo lo demás)
Preferencia: **configuración del panel admin, NO código**. Solo escribe código en `redtrastienda-admin` si un toggle no existe.
1. **Activar SOLO "Cash on Delivery" (contra entrega / offline).** Apagar todas las pasarelas en línea. (Admin → Business Settings → Payment Methods; y `Modules`/config de terceros si aplica.)
2. **Envío oculto con default:** que confirmar pedido NO exija elegir método de envío. Opciones, de menos a más invasivo: un método de envío por defecto de costo 0 / "Sin envío", o `shipping_responsibility` inhouse con default. La meta: que la orden se cree sin pantalla de envío. Verifica qué exige el endpoint de order place y ajústalo por config; si NO se puede sin código, hazlo con el mínimo cambio (rama `f6-pedidos-backend`).
3. Confirma que la respuesta de `/api/v1/config` y el flujo de order place quedan consistentes (COD activo, sin gateways).
4. **NO** toques migraciones, ni el módulo Deploy, ni branding, ni activación de licencia. **NO** despliegues tú (el deploy lo hace el humano con `docs/OPERACION_Y_DEPLOY.md`); deja tus cambios de admin (si los hubo) en la rama `f6-pedidos-backend` sin merge.

### 3.B App afiliados (`user/`) — armar y confirmar pedido
1. **Flujo proveedor → productos → carrito → confirmar pedido.** Reutiliza `cart` + `checkout`. Asegura que:
   - Se puede agregar producto(s) al carrito con **cantidad**.
   - El **checkout NO muestra pantallas de pago en línea ni de envío**: selección de pago forzada/oculta a **contra entrega**; paso de dirección/envío minimizado (usa el existente si el backend lo exige, pero sin fricción).
   - Hay un **campo de comentario del pedido** visible y que se envía con la orden (`order_note` nativo de 6valley si existe; si no, el comentario por producto/orden que soporte el endpoint).
2. **Confirmación:** al confirmar, se crea la orden (COD) y se muestra éxito + queda en "Mis pedidos".
3. **"Mis pedidos"** (feature `order`/`order_details`, ya existe): que liste las órdenes del afiliado con su estatus (etiquetas ES, ver §4). Limpia columnas/labels de pago/envío que no apliquen.

### 3.C App proveedores (`vendor/`) — Pedidos Recibidos + estatus
1. **Exponer bien "Pedidos Recibidos"** (la pantalla `order` que ya existe): accesible desde el dashboard/menú con nombre claro "Pedidos Recibidos" (o "Pedidos").
2. **Renombrar los estatus** a los de ANPEC (ver §4) vía traducciones — mapeados a los estatus nativos de 6valley. NO inventes estatus nuevos en el backend.
3. **Cambio de estatus** funcional (ya existe el endpoint seller de update status): el proveedor abre un pedido y avanza su estatus; persiste y el afiliado lo ve.
4. Limpia labels/columnas de pago en línea/envío/repartidor que no apliquen.

### 3.D Admin (monitoreo)
Ya existe el monitoreo de pedidos en el panel. Solo **limpiar/ocultar columnas de pago en línea y envío** que no apliquen (si estorban en la demo). Cambio cosmético mínimo; si requiere tocar Blade, respeta la regla de traducción del repo (`translate('...')`).

## 4. Mapeo de estatus (ANPEC ⇆ nativo 6valley)

Estatus **nativos** de 6valley (los que acepta el endpoint seller de cambio de estatus): `pending`, `confirmed`, `processing`, `out_for_delivery`, `delivered`, `canceled`, `returned`, `failed`.

Etiquetas **ANPEC** (solo traducción/label; el valor que viaja a la API sigue siendo el nativo):

| ANPEC (mostrar) | Nativo (API) |
|---|---|
| Pendiente | `pending` |
| Recibido | `confirmed` |
| En proceso | `processing` |
| Surtido | `delivered` |
| Cancelado | `canceled` |
| Rechazado | `failed` |

- `out_for_delivery`, `returned` → NO se usan en el flujo ANPEC; ocúltalos del selector del proveedor (o no los ofrezcas). Si un estatus nativo llega igual, muéstralo con un label razonable.
- **Ojo con `delivered`:** en 6valley dispara efectos colaterales (stock, `payment_status=paid`, wallet/comisión/referidos). Wallet/loyalty/comisiones están **apagados**, así que debería ser inocuo, pero **verifícalo**: marca un pedido "Surtido" y confirma que no truena ni activa módulos ocultos. Si `delivered` causa problemas, considera mapear "Surtido" a `processing`/`confirmed` y documenta la decisión.
- Aplica las etiquetas ES **solo agregando/corrigiendo claves** en `assets/language/es.json` de cada app (ver §7 regla append-only). En admin, en `resources/lang/es/messages.php` si hace falta.

## 5. Anclas de código (puntos de partida)

- **User carrito/checkout:** `user/lib/features/cart/`, `user/lib/features/checkout/` (widgets de pago: `choose_payment_widget.dart`, `offline_payment_widget.dart`, `payment_method_bottom_sheet_widget.dart`; `screens/checkout_screen.dart`; `controllers/checkout_controller.dart`; `domain/models/order_place_model.dart`).
- **User bottom nav (pestaña Carrito hardcodeada):** `user/lib/features/dashboard/screens/dashboard_screen.dart`.
- **User pedidos:** `user/lib/features/order/`, `user/lib/features/order_details/`.
- **Vendor pedidos recibidos:** `vendor/lib/features/order/screens/order_screen.dart` (+ `controllers`, `enums`, `domain`).
- **Backend orders seller:** `redtrastienda-admin/app/Http/Controllers/RestAPI/v3/seller/OrderController.php` (lista + cambio de estatus; el campo es `order_status`). Rutas seller en `routes/rest_api/v3/seller.php`.
- **Backend config pago:** `redtrastienda-admin/app/Http/Controllers/Admin/PaymentMethodController.php`, `.../Settings/BusinessSettingsController.php`; config API en `.../RestAPI/v1/ConfigController.php`.
- Patrón por app: Controller (ChangeNotifier/Provider) → Service → Repository → Interface, con Dio. Sigue un feature existente como molde (ej. `opportunity_request` que ya se hizo en F7, o el propio `order`).

## 6. UX / diseño

- Coherente con la app; rojo `#A1262B` para acentos; **badges de estatus con color por estado** (pendiente/en proceso/surtido/cancelado…).
- Flujo de pedido **sin fricción de e-commerce**: nada de "elige pasarela", "método de envío", "cupón", "wallet". El afiliado piensa "pedido a proveedor", no "compra".
- Estados vacíos amables ("Aún no tienes pedidos" / "No hay pedidos recibidos") y loading/skeleton como el resto de la app.
- El comentario del pedido debe ser visible tanto para el afiliado (al confirmar y en el detalle) como para el proveedor (en el detalle del pedido recibido).

## 7. Reglas duras / anti-conflicto (corre en paralelo con otros chats)

1. **Ramas nuevas desde `main`, NUNCA en `main`:**
   - Flutter: `f6-pedidos` en `redtrastienda-apps`.
   - Backend (solo si hubo código): `f6-pedidos-backend` en `redtrastienda-admin`.
2. En archivos COMPARTIDOS (`assets/language/*.json`, `app_constants.dart`, menús/rutas, `route_helper.dart`): **SOLO agrega o corrige la clave puntual; NUNCA reordenes ni borres** líneas existentes (otros chats también agregan ahí). Prefiere crear archivos/widgets NUEVOS a modificar los compartidos.
3. **NO toques branding:** nombre/color/idioma/`baseUrl`, `theme/*`, `assets/images/logo*`, `assets/launcher/*`, `AndroidManifest.xml`, ícono de app.
4. **NO reactives módulos apagados** (wallet, loyalty, subastas, tarjeta digital, POS, cupones, reviews, compare, refunds, delivery man). Si el checkout intenta mostrarlos, **ocúltalos**, no los prendas.
5. **NO agregues paquetes** ni cambies versiones salvo que sea imprescindible (justifícalo y pregunta antes).
6. **NO despliegues** ni pushees ni mergees. El deploy del backend lo hace el humano (`redtrastienda-admin/docs/OPERACION_Y_DEPLOY.md`). Tú entregas ramas + reporte; el auditor revisa antes de merge.
7. Cambios mínimos y explicables. Si algo del flujo nativo pelea con "sin pago/sin envío", documenta el conflicto y propón la opción menos invasiva antes de codear en grande.

## 8. Verificación (hay backend + datos en vivo)

Datos de prueba existentes: producto id=1 "prueba" $1000 del seller "Prueba 2" (id=3). Puedes crear más productos de un proveedor de prueba.
1. `flutter run` en cada app sobre el device (una a la vez).
2. **Afiliado:** entra a un proveedor/producto → agrega al carrito con cantidad → confirma pedido con comentario, **sin** pasar por pantallas de pago en línea/envío → ve éxito → "Mis pedidos" muestra el pedido con estatus "Pendiente".
3. **Proveedor:** "Pedidos Recibidos" muestra ese pedido (afiliado, productos, cantidades, comentario) → cambia estatus (Pendiente→Recibido→En proceso→Surtido) → persiste.
4. **Afiliado** relista "Mis pedidos" → ve el estatus actualizado.
5. Confirma que marcar "Surtido" (`delivered`) NO truena ni activa módulos ocultos (§4).
6. Screenshots (adb vía **PowerShell**, no git-bash): carrito, confirmar pedido, mis pedidos, pedidos recibidos, cambio de estatus.

## 9. Entregables

1. Ramas `f6-pedidos` (apps) y, si hubo código backend, `f6-pedidos-backend` (admin). **Sin push ni merge.**
2. Lista de pasos de **configuración del panel admin** aplicados (toggles de pago/envío) — para reproducir en el server.
3. Lista de archivos creados/modificados (una línea c/u), por app/repo.
4. Screenshots del flujo completo (afiliado arma pedido → proveedor lo recibe → cambia estatus → afiliado lo ve).
5. Paquetes agregados (idealmente ninguno) y por qué.
6. Decisiones/consideraciones: mapeo de estatus final, cómo se ocultó pago/envío, cualquier efecto colateral de `delivered`.
7. Confirmación: compila/corre sin crash en ambas apps, branding intacto, módulos apagados siguen apagados, archivos compartidos solo-append.

## 10. Criterio de aceptación

- El afiliado arma un pedido (proveedor → productos → carrito con cantidades → comentario) y lo confirma **sin ninguna pantalla de pago en línea ni de envío**; el pedido nace en "Pendiente" (contra entrega).
- El proveedor ve el pedido en "Pedidos Recibidos" (con afiliado, productos, cantidades, comentario) y avanza su estatus con etiquetas ANPEC (Pendiente/Recibido/En proceso/Surtido/Cancelado/Rechazado); persiste en backend.
- El afiliado ve el estatus actualizado en "Mis pedidos".
- Cero pasarelas en línea, cero fricción de envío, cero módulos apagados reactivados, cero cambios de branding.
- Backend: solo Cash on Delivery activo; cambios de admin (si los hubo) aislados en `f6-pedidos-backend`, sin desplegar.
