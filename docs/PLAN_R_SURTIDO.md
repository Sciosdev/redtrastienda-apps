# PLAN R-SURTIDO — "maquinita del preventista" (steppers en la lista del proveedor + Repetir pedido)

> **Estado: PLAN PARA AUDITORÍA. Cero código todavía.** Rama objetivo `r-surtido` (desde `main`, que ya trae R-Nav mergeado — `b82d737`). Nada se implementa hasta el visto bueno.

---

## 0. Principio rector: `anpecSurtidoFlow`

- Nuevo flag en `user/lib/utill/app_constants.dart`, patrón idéntico a `anpecMercadoFlow`:
  ```dart
  // R-Surtido: surtir por cantidades directo en la lista del proveedor + "Repetir pedido".
  // Gatea TODO el módulo; en false la app queda idéntica a main.
  static const bool anpecSurtidoFlow = true; // en la rama r-surtido
  ```
- **Regla de oro:** cada punto de entrada nuevo (stepper en la card, barra resumen, botón "Repetir pedido") se envuelve en `if (AppConstants.anpecSurtidoFlow)`. Con el flag en `false`, todos los widgets nuevos devuelven la ruta vieja / `SizedBox.shrink()` / `null`, y ningún archivo compartido cambia de comportamiento.
- El flag se commitea en `true` en la rama (es el estado de trabajo). Para un build de review de tienda basta ponerlo en `false`.

---

## 1. Hallazgos de auditoría (contratos reales)

### 1.1 APIs de carrito (ya existen, sin backend nuevo)
Todas POST con body (cumple regla Mod_Security de la casa). Todas mandan `guest_id` (token de invitado o del logueado).

| Acción | URI (`AppConstants`) | Body real (`cart_repository.dart`) | Notas |
|---|---|---|---|
| Cargar carrito | `getCartDataUri` `/api/v1/cart` | GET `?coupon_code=..&guest_id=..` | Devuelve `List<CartModel>` (agrupa por seller vía `cartGroupId`/`sellerId`) |
| Agregar | `addToCartUri` `/api/v1/cart/add` | `{id, guest_id, variant, quantity, buy_now:0, shipping_method_exist, shipping_method_id, (+choice_x, +color)}` | Para producto **simple**: `variant=null`, sin choice ni color |
| Actualizar cantidad | `updateCartQuantityUri` `/api/v1/cart/update` | `{_method:'put', key, quantity, guest_id}` | **`quantity` es ABSOLUTO** (no delta). `key` = id de la línea de carrito |
| Quitar | `removeFromCartUri` `/api/v1/cart/remove` | `{_method:'delete', key, guest_id}` | `key` = id de la línea |

- El `CartService`/`CartRepository` ya exponen `getCartList`, `addToCartListData`, `updateQuantity`, `delete`. Ambos están registrados como singletons en DI (`sl<CartServiceInterface>()`).
- **Cuidado:** `CartController.addToCartAPI()` hace `Navigator.pop()` + snackbar (asume que hay un bottom sheet abierto). **NO reutilizable tal cual** para el stepper. → El módulo llama al `CartService` por un controller propio, sin efectos secundarios de navegación.

### 1.2 Modelo `Product` — criterio de "producto simple" (stepper aplica)
Un producto es **simple** (stepper habilitado) si y solo si:
```
productType == 'physical'
&& (variation == null || variation!.isEmpty)
&& (choiceOptions == null || choiceOptions!.isEmpty)
&& (colors == null || colors!.isEmpty)
```
Si tiene `colors`, `choiceOptions` o `variation` → **con variante** → tap abre la ficha como hoy (la variante se elige ahí). Confirmado contra `cart_bottom_sheet_widget.dart`, que arma la `variationType` justo desde `colors` + `choiceOptions`.
- `currentStock` (default 0), `minimumOrderQuantity` (default 1) vienen en el modelo. `multiply_qty` se ignora en MVP (paso = 1).

### 1.3 Pantalla del proveedor (TRABAJO A)
- `shop/screens/shop_screen.dart` → `TopSellerProductScreen` (Scaffold propio, **sin** `bottomNavigationBar` hoy → hueco libre para la barra resumen).
- Tab "All Products" renderiza `shop/widgets/shop_product_view_list.dart` → `MasonryGridView` (2 col) de `ProductCardWidget`.
- **`ProductCardWidget` es común, usado en ~24 lugares** (home, deals, search, clearance, etc.). **Jamás cambia su default.** Se le añade un parámetro opcional `showQuantityStepper=false`; solo la lista del proveedor lo pasa `true` (y solo con el flag on).

### 1.4 Pedidos (TRABAJO B)
- Card historial: `order/widgets/order_widget.dart` (`OrderWidget`, `StatefulWidget`, InkWell completo → detalle). Tiene `orderModel.id`, `orderStatus`, `orderDetailsCount`.
- Detalle: `order_details/screens/order_details_screen.dart`; los botones de acción viven en `order_details/widgets/cancel_and_support_center_widget.dart` (`CancelAndSupportWidget`, `showSupport:false`).
- **Ya existe** "Order Again" nativo de 6valley: endpoint único `reorder` `/api/v1/customer/order/again` + `ReOrderController`, pero **solo se muestra en pedidos `delivered`** y **no da reporte de faltantes ni control de suma**. → No cumple el requerimiento; se implementa el flujo propio con APIs de carrito. Se **suprime** el botón nativo cuando el flag está on (para no duplicar) añadiendo `&& !AppConstants.anpecSurtidoFlow` a su condición.
- El item de pedido (`OrderDetailsModel`) trae: `productId`, `qty`, `variant` (string), `productDetails` (Product completo con `status`, `currentStock`, `colors`/`choiceOptions`/`variation`). `getOrderDetails(orderId)` devuelve la lista parseable → base para reconstruir el carrito.

### 1.5 Infra
- DI: `get_it` en `di_container.dart` (`sl.registerFactory`), providers en `main.dart` (`ChangeNotifierProvider(create: (_) => di.sl<X>())`).
- i18n: `assets/language/es.json` + `assets/language/en.json` (claves nuevas van a **ambos**).
- Carrito recarga solo al entrar a `cart_screen` (`getCartData` en init) → el "Ver pedido"/"→ carrito" siempre muestra estado de servidor fresco.

---

## 2. Arquitectura nueva (aditiva, toda gateada)

**Nuevo módulo `user/lib/features/surtido/`:**
- `controllers/surtido_controller.dart` — `ChangeNotifier`. Depende de `CartServiceInterface` + `OrderDetailsServiceInterface` (ambos ya en DI). Orquesta steppers y repetir-pedido **sin** tocar `CartController` (que sigue siendo la fuente de verdad del cart screen).
- `widgets/product_quantity_stepper.dart` — el `[+ Agregar]` / `[− n +]` compacto para la card.
- `widgets/shop_cart_summary_bar.dart` — barra fija inferior "N productos · $total — Ver pedido".
- `widgets/repeat_order_button.dart` — botón "Repetir pedido" reutilizable (detalle + card historial).
- `widgets/repeat_order_progress_dialog.dart` — diálogo de progreso "Agregando X de N…".

**Registro:**
- `di_container.dart`: `sl.registerFactory(() => SurtidoController(cartServiceInterface: sl(), orderDetailsServiceInterface: sl()));`
- `main.dart`: `ChangeNotifierProvider(create: (_) => di.sl<SurtidoController>()),`
- (Ambos son aditivos; con el flag off el controller existe pero nunca se invoca → cero impacto.)

### Estado interno del `SurtidoController`
```
Map<int, _CartLine> _byProductId;   // productId -> { key(lineId), quantity }
Set<int> _busyProductIds;           // productos con llamada en vuelo (spinner + bloqueo)
bool _repeating; int _repeatDone; int _repeatTotal;  // progreso repetir
```
- `_CartLine` se siembra una sola vez con `getCartList()` al entrar a la pantalla del proveedor (evita N+1). Los `+/−` puntuales no recargan todo.

---

## 3. TRABAJO A — Steppers en la lista + barra resumen

### 3.1 Mockup textual

**Card de producto (grid 2-col), producto SIMPLE, no en carrito:**
```
┌────────────────────┐
│      [imagen]     ♡ │
│  Aceite 900ml        │
│  $38.00              │
│  ┌────────────────┐  │
│  │   + Agregar    │  │  ← botón compacto, ancho de card
│  └────────────────┘  │
└────────────────────┘
```

**Misma card, YA en carrito (qty=3):**
```
│  ┌──┬────────┬──┐    │
│  │ −│   3    │ +│    │  ← stepper sincronizado con el carrito real
│  └──┴────────┴──┘    │
```
- `−` en qty == mínimo → se transforma en icono 🗑 (quitar). `+` deshabilitado si `qty >= currentStock`.
- Mientras una llamada está en vuelo: el número se reemplaza por un spinner pequeño y los botones quedan inertes (per-producto; el resto de la lista sigue usable).

**Producto CON variante:** la card queda **idéntica a hoy** (sin stepper); tap → ficha.

**Barra resumen (fija abajo, `Scaffold.bottomNavigationBar` del shop_screen, solo si hay items de este proveedor en el carrito):**
```
┌──────────────────────────────────────────────┐
│  4 productos · $612.00        [ Ver pedido → ]│
└──────────────────────────────────────────────┘
```
- Aparece/desaparece animada según el carrito de ESTE proveedor. "Ver pedido" → `RouterHelper.getCartScreenRoute` (de ahí F6/`anpecPedidoFlow` sigue igual).

### 3.2 Lógica del stepper (optimista con revert, sin fantasmas)
Como `update` recibe **cantidad absoluta**, siempre mandamos el objetivo → tras éxito, local == servidor.

- **Agregar (0 → mínimo):** optimista set qty=`minimumOrderQuantity`, `busy=on` → `addToCartListData(id, qty)` → en éxito **una** recarga `getCartList()` para conocer el `key` de la nueva línea; en error revert a "no en carrito" + snackbar.
- **`+` (n → n+1):** validar `n+1 <= currentStock` (si no, snackbar "Sin stock suficiente" y no-op). Optimista, `busy=on` → `updateQuantity(key, n+1)` → éxito conserva; error revert.
- **`−` (n → n−1):** si `n-1 < minimumOrderQuantity` → tratar como quitar. Si no, `updateQuantity(key, n-1)`.
- **Quitar (→ 0):** `delete(key)` → drop local. Error revert.
- **Anti-N+1:** carga única al entrar; `+/−` NO recargan (confían en el eco absoluto). Solo hay recarga puntual tras un ADD (para el `key`) y opcional tras remove.
- **Sincronía global:** al navegar a "Ver pedido" o al `dispose` del shop_screen, se dispara `CartController.getCartData(reload:false)` una vez → el cart screen y cualquier badge quedan frescos (el cart screen además recarga en su init).

### 3.3 Puntos de edición (TRABAJO A)
| Archivo | Cambio | Flag off = |
|---|---|---|
| `common/basewidget/product_card_widget.dart` | + param `bool showQuantityStepper=false`. Si true: envolver el contenido actual en `Column([InkWell(<contenido idéntico>), ProductQuantityStepper(...)])`. Si false: `return` el InkWell **byte-idéntico** a hoy. | idéntico (default false) |
| `shop/widgets/shop_product_view_list.dart` | pasar `showQuantityStepper: AppConstants.anpecSurtidoFlow` al `ProductCardWidget` | idéntico (false) |
| `shop/screens/shop_screen.dart` | `bottomNavigationBar: AppConstants.anpecSurtidoFlow ? ShopCartSummaryBar(sellerId: ...) : null` | `null` (idéntico) |
| `features/surtido/**` | archivos nuevos | inertes |

> El stepper se limita a la grilla vertical de "All Products" (la lista que el tendero recorre para surtir). Los carruseles horizontales del "Overview" (featured/recommended) **no** se tocan en este MVP (cards angostas; fuera de la experiencia "recorrer y marcar"). Ampliable como iteración menor si se pide.

---

## 4. TRABAJO B — "Repetir pedido"

### 4.1 Ubicación
- **Detalle de pedido:** dentro de `CancelAndSupportWidget` (`showSupport:false`), botón "Repetir pedido" gateado; y `&& !anpecSurtidoFlow` en el branch nativo `re_order` para no duplicar.
- **Card del historial:** en `OrderWidget`, un sub-botón "Repetir pedido" (tap independiente del InkWell del card).
- Ambos disparan `SurtidoController.repeatOrder(context, orderId)`.

### 4.2 Flujo `repeatOrder(orderId)`
1. Mostrar diálogo de progreso no-dismissible.
2. `getOrderDetails(orderId)` → `List<OrderDetailsModel>`.
3. Cargar carrito actual una vez (`getCartList`) → mapa `productId → línea` (para decidir suma).
4. **Secuencial** (await uno antes del siguiente — respeta rate limit del hosting, sin ráfaga paralela). Por cada item, actualizar contador de progreso:
   - **No disponible** (`productDetails == null` || `status != 1` || físico con `currentStock <= 0`) → omitir, `faltantes++`, razón "no disponible".
   - **Con variante** (`variant` no vacío, o `productDetails` con `colors`/`choiceOptions`/`variation`) → omitir, `faltantes++`, razón "producto con variante — agrégalo desde su ficha". *(Decisión documentada: no se reconstruye la variante desde el string del pedido de forma fiable; el catálogo de proveedor ANPEC es de productos simples. El endpoint /add recalcula la variante desde color+choice, no desde el string suelto.)*
   - **Simple disponible:**
     - Si ya está en carrito → `updateQuantity(key, qtyExistente + qtyPedido)` → **SUMA** (decisión documentada, garantizada del lado app, no dependemos del comportamiento del backend).
     - Si no → `addToCartListData(id, qtyPedido)`.
     - Éxito → `agregados++`; error → `faltantes++`, razón "error al agregar".
5. Cerrar diálogo. Snackbar honesto:
   - Todos ok → "Se agregaron N productos a tu pedido".
   - Parcial → "Se agregaron 4 de 5 productos (1 ya no está disponible)".
   - Cero → "Ninguno de los productos sigue disponible" (no navega).
6. Si `agregados > 0` → navegar a carrito (`getCartScreenRoute`) para confirmar con "Solicitar pedido" (**F6 intacto**).

### 4.3 Puntos de edición (TRABAJO B)
| Archivo | Cambio | Flag off = |
|---|---|---|
| `order_details/widgets/cancel_and_support_center_widget.dart` | + botón "Repetir pedido" gateado; `&& !anpecSurtidoFlow` en branch nativo | idéntico |
| `order/widgets/order_widget.dart` | + sub-botón "Repetir pedido" gateado | idéntico |
| `features/surtido/**` | lógica en el controller/widgets nuevos | inerte |

---

## 5. Decisiones documentadas

| Tema | Decisión | Por qué |
|---|---|---|
| Detección de variante | simple = físico sin `variation`/`choiceOptions`/`colors` | espeja `cart_bottom_sheet_widget.dart` |
| Repetir + producto ya en carrito | **SUMA** cantidades (leemos carrito y `update` a `existente+pedido`) | pedido del prompt; garantizado en app, no dependemos del backend |
| Repetir + variante | **omite** y cuenta como faltante, con razón clara | reconstrucción no fiable; catálogo proveedor es simple |
| Repetir | secuencial (await encadenado), no paralelo | rate limit del hosting |
| Cantidad en `update` | **absoluta** | así lo espera `/cart/update`; garantiza local==servidor (sin fantasmas) |
| Anti-N+1 | 1 carga al entrar + updates puntuales; recarga solo en add(→key) | requisito del prompt |
| Mínimo / stock | piso = `minimumOrderQuantity`, techo = `currentStock`; bajo mínimo = quitar | respeta el producto |
| `multiply_qty` | ignorado (paso 1) en MVP | simplicidad; backlog si aplica |
| Endpoint nativo `/order/again` | **no** se usa; se suprime su botón con el flag on | no da faltantes ni control de suma |
| Alcance stepper | solo grilla "All Products" | es "la lista" del tendero |

---

## 6. Contratos de API (ejemplos concretos)

```jsonc
// AGREGAR simple (0 -> 3)  POST /api/v1/cart/add
{ "id": 62, "guest_id": 1, "variant": null, "quantity": 3, "buy_now": 0,
  "shipping_method_exist": null, "shipping_method_id": null }
// -> 200 { "message": "Successfully added ..." }

// SUBIR/BAJAR (3 -> 4, absoluto)  POST /api/v1/cart/update
{ "_method": "put", "key": 812, "quantity": 4, "guest_id": 1 }

// QUITAR  POST /api/v1/cart/remove
{ "_method": "delete", "key": 812, "guest_id": 1 }

// CARGAR  GET /api/v1/cart?coupon_code=null&guest_id=1  -> List<CartModel>
// DETALLE PEDIDO (repetir)  GET /api/v1/customer/order/details?order_id=100010 -> List item{product_id, qty, variant, product_details{...}}
```

---

## 7. Garantía "flag OFF = idéntico"

Con `anpecSurtidoFlow=false`:
- `product_card_widget.dart`: `showQuantityStepper` default false → devuelve el InkWell exacto de hoy.
- `shop_product_view_list.dart`: pasa `false`.
- `shop_screen.dart`: `bottomNavigationBar: null`.
- `cancel_and_support_center_widget.dart` / `order_widget.dart`: los `if (anpecSurtidoFlow)` no renderan nada; el branch nativo `re_order` recupera su condición original.
- `features/surtido/**`, entradas de DI/providers: existen pero nunca se invocan.
- **Verificación:** con el flag en false, `git diff` de comportamiento = ninguno; smoke de regresión (F6 clásico, chat, tarjeta) intacto.

---

## 8. Plan de commits (rama `r-surtido`)
1. `feat(surtido): flag anpecSurtidoFlow + SurtidoController + DI/providers` (esqueleto inerte).
2. `feat(surtido): steppers en la lista del proveedor + barra resumen` (TRABAJO A).
3. `feat(surtido): Repetir pedido en detalle e historial` (TRABAJO B).
4. `i18n(surtido): claves es/en` (agregar, ver_pedido, repetir_pedido, sin_stock, se_agregaron_x_de_y, etc.).
- `flutter analyze` limpio en cada uno.

---

## 9. Checklist de smoke en device (A059P · `00170155D001304` · `otro.correo@test.com`/`secreto1`)
1. Entrar a un proveedor → tab "Productos". Surtir **3 productos** con cantidades distintas **sin abrir un solo detalle** (Agregar → stepper).
2. Barra resumen aparece con conteo/total correctos → "Ver pedido" → carrito coincide → "Solicitar pedido" → pedido creado correcto (F6).
3. Editar cantidades con `+/−` y **quitar** con el stepper → verificar contra el carrito real (recargar cart screen).
4. "Repetir pedido" del pedido recién creado → progreso → carrito idéntico → "Solicitar pedido" de nuevo.
5. Producto **con variante** → la card abre el detalle (sin stepper).
6. `anpecSurtidoFlow=false` → app **idéntica** (sin stepper, sin barra, sin botón; branch nativo re_order vuelve).
7. Regresión: F6 clásico (agregar desde ficha), chat tienda↔tienda, Tarjeta Digital.

---

## 10. Fuera de alcance
Reordenar home / proveedores-primero (R-Nav) · pedido sugerido / promos por volumen / crédito (backlog) · cambios de backend / vendor / mercado / chat · pedidos del Mercado (tienda↔tienda). Esto es **solo** pedidos a proveedores (F6).
