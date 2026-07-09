# PROMPT MAESTRO — Smoke test guiado en device: F7 Oportunidades + F5 WhatsApp

> Copia TODO esto como primer mensaje. Es un test EN el teléfono físico, **guiado por ti**:
> tú compilas/corres la app (flutter) y le DICTAS los pasos al humano; el humano los ejecuta en su teléfono y te dice qué aparece (texto o screenshot). Tú interpretas y sigues. NO manejas la UI tú — el humano hace los taps.
> El código ya está en `main` (F5+F7 mergeados y auditados). Aquí solo se VERIFICA.

---

Eres un QA/dev senior. Verificas en el teléfono físico el flujo de oportunidades (F7) y el contacto WhatsApp (F5) de las apps de "ANPEC Red Trastienda". Tu método:

1. **Compilas y corres** la app con `flutter run` (eso sí lo haces tú).
2. **Guías al humano paso a paso**: le dices exactamente qué tocar ("ve al menú Más → toca 'WhatsApp ANPEC'").
3. El humano lo hace en su teléfono y te reporta qué ve (o te manda screenshot).
4. Tú interpretas, confirmas, y pasas al siguiente paso.
5. Si aparece un bug (crash, pantalla en blanco, error), captúralo de los logs de `flutter run` con el error exacto, documenta y **para** — NO cambies código (es solo verificación; el arreglo lo hace el auditor).

## 1. Entorno

- Repo apps: `redtrastienda-apps` (abre la sesión ahí). `main` ya tiene F5 + F7.
- Flutter 3.44.5 / Dart 3.12. Device: **A059P**, id **`00170155D001304`** (Android 16), conectado por USB.
- Correr apps: `flutter run -d 00170155D001304` desde `user/` (afiliados) o `vendor/` (proveedores). **Solo una app a la vez** en el device.
- Si quieres CONFIRMAR lo que el humano describe, puedes tomar un screenshot tú (solo lectura) por **PowerShell** (git-bash mutila rutas `/sdcard/...`):
  ```
  adb -s 00170155D001304 shell screencap -p /sdcard/s.png ; adb -s 00170155D001304 pull /sdcard/s.png ./s.png
  ```
  adb en `%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe`. Pero el que TOCA la UI es el humano.

## 2. Prerrequisitos (pídelos al humano al inicio)

1. Que **exista un PRODUCTO** publicado por un proveedor (la "oportunidad"). Si no, que lo cree (admin + panel web del proveedor).
2. **Login de un afiliado** de prueba (email + password) — el humano ya tiene cuentas creadas.
3. **Login del proveedor** dueño de ese producto (para la app de proveedores).

## 3. Contrato del backend (para corroborar por API si quieres)

- Base: `https://adminapp.redtrastiendaanpec.com`.
- Afiliado crea: `POST /api/v1/customer/opportunity-requests/store` (Bearer) body `product_id`+`comment`. Duplicado (new/in_review) → 200 "already have a pending request".
- Afiliado lista: `GET /api/v1/customer/opportunity-requests/list?limit=&offset=`.
- Proveedor recibe: `GET /api/v3/seller/opportunity-requests/list?status=&limit=&offset=`.
- Proveedor cambia estatus: `POST /api/v3/seller/opportunity-requests/update-status` body `id`+`status`+`provider_response`. Estatus: `new, in_review, contacted, served, rejected`.

## 4. Flujos a verificar (guía al humano en cada paso)

**A) App afiliados (`user/`):** corre la app, guía al humano a hacer login con el afiliado.
1. **F5 WhatsApp:** menú "Más" → "WhatsApp ANPEC" → debe abrir el bottom sheet "Contacto ANPEC" con WhatsApp + Llamar. (Si el item no aparece, es que `company_phone` está vacío en el admin — anótalo.)
2. **F7 Solicitar contacto:** entra al detalle del producto → botón "Solicitar contacto" → comentario → enviar → snackbar de éxito. Repite para ver el caso "ya tienes una solicitud pendiente".
3. **F7 Mis solicitudes:** menú "Más" → "Mis solicitudes" → aparece la solicitud con su badge de estatus.

**B) App proveedores (`vendor/`):** cierra la app afiliados, corre la de proveedores, guía el login con el proveedor.
4. **F7 Solicitudes recibidas:** abre "Solicitudes recibidas" → se ve la solicitud del afiliado (nombre, producto, comentario) con barra de filtro por estatus.
5. **Cambiar estatus:** abre una solicitud → cambia estatus (ej. "Contactado"/"Atendida") con `provider_response` opcional → confirma → verifica que persiste (relista).
6. (Opcional) Vuelve a la app afiliados → "Mis solicitudes" → el estatus/respuesta se actualizó.

## 5. Reglas
1. **Tú corres flutter y dictas; el humano toca y reporta.** No manejes la UI por adb.
2. **NO cambies código.** Si algo truena, captura el error de `flutter run`/`adb logcat` y para.
3. Estás verificando `main`; sin ramas nuevas, sin commits, sin push.

## 6. Entregable
Reporte para el auditor: qué flujos pasaron/fallaron (con lo que reportó el humano y/o screenshots), y si el ciclo end-to-end funcionó (afiliado solicita → proveedor recibe → cambia estatus → afiliado ve el nuevo estatus). Cualquier bug con su error exacto.
