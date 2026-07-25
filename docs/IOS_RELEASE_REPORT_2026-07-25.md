# Reporte final de publicación iOS — ANPEC Red Trastienda

**Fecha de cierre:** 25 de julio de 2026

**Rama:** `r-ios`

**Estado:** versión enviada a Apple, **Pendiente de revisión**

## Resumen ejecutivo

La aplicación ANPEC Red Trastienda quedó adaptada, firmada y validada para iOS. Se
configuraron Firebase y APNs, se sustituyó el contenido demostrativo sin autorización por
material genérico original, se probaron los flujos principales en un iPhone físico y en
simuladores de iPhone/iPad, y se generaron las capturas definitivas de App Store.

La compilación `1.0.0 (1)` fue cargada y procesada por App Store Connect, vinculada a la
versión pública `1.0` y enviada a revisión. La publicación quedó configurada como
**automática después de la aprobación**.

## Identificación de la versión

| Campo | Valor |
| --- | --- |
| Nombre en App Store | ANPEC Red Trastienda |
| Apple ID | `6794555887` |
| Bundle ID | `com.redtrastiendaanpec.afiliados` |
| Versión | `1.0.0` |
| Compilación | `1` |
| Team ID | `Z7M8489428` |
| SKU | `anpec-red-trastienda-001` |
| Precio | Gratuita |
| Disponibilidad inicial | México |
| Publicación | Automática después de aprobación |

## Trabajo realizado en la aplicación

### Integración y configuración iOS

- Se integró el estado vigente de `main` en `r-ios` y se resolvió la configuración nativa
  necesaria para compilar y distribuir la app.
- Se estableció el Bundle ID definitivo en Debug, Profile y Release.
- Se eliminaron residuos nativos de Facebook que ya no tenían una función activa.
- Se alinearon los entitlements de Push Notifications y Keychain con el Bundle ID final.
- Se configuró el proyecto Firebase iOS de ANPEC y su archivo
  `GoogleService-Info.plist` definitivo.
- Se retiraron permisos, URL schemes y excepciones ATS heredadas que no eran necesarias.
- Se declaró `ITSAppUsesNonExemptEncryption = false`.
- Se configuraron el nombre visible, textos de permisos e iconos de Red Trastienda.

### Ajustes finales de interfaz

- El campo de usuario del inicio de sesión usa teclado de correo en iOS. Esto mantiene la
  entrada de teléfono y número ANP, y agrega acceso directo al carácter `@`.
- La Tarjeta Digital agrega espacio inferior cuando se abre desde el dashboard. El botón
  **Compartir** ya no queda cubierto por la barra de navegación en iPhone.

## Firebase y notificaciones push

- Se creó una APNs Auth Key con soporte para Sandbox y Producción.
- La clave se cargó en Firebase para los dos entornos.
- La copia privada se almacenó fuera del repositorio con permisos restringidos.
- El IPA final contiene `aps-environment = production`.
- No se añadió ningún archivo `.p8`, certificado o credencial al repositorio.

## Preparación del contenido demostrativo

El backend utilizado por la app se limpió antes del envío a revisión:

- Se ocultaron los proveedores, logos y productos de marcas para las que ANPEC y SCIOS no
  tienen autorización de uso.
- Se crearon los proveedores genéricos **Surtidora Horizonte** y **Abasto del Centro**.
- Se generaron logos, banners y productos originales para los catálogos demostrativos.
- Se prepararon pedidos recientes con los proveedores genéricos para evitar una pantalla
  de inicio vacía.
- Se activaron dos cuentas de prueba con número ANP y una conversación demostrativa.
- Las credenciales de revisión quedaron configuradas únicamente en App Store Connect y no
  se reproducen en este reporte.

Los recursos originales utilizados para esta sustitución están archivados en
`artifacts/provider_demo_assets/`.

## Pruebas y validaciones

### Dispositivos

- **iPhone 12 físico:** instalación, inicio, login, teclado de correo, pedidos, catálogo,
  chat, Tarjeta Digital y botón Compartir.
- **iPhone 13 Pro Max simulado:** generación de capturas nativas `1284 × 2778`.
- **iPad Pro de 13 pulgadas simulado:** revisión del layout y generación de capturas
  nativas `2064 × 2752`.

### Código y compilación

- `flutter analyze` sobre los dos archivos modificados: sin problemas.
- `git diff --check`: sin errores de espacios o formato.
- `flutter build ipa --release`: compilación y exportación correctas.
- Firma verificada con `codesign --verify --deep --strict`.
- Perfil de distribución de App Store válido hasta el 25 de julio de 2027.
- `get-task-allow = false` y `beta-reports-active = true`.
- SHA-256 del IPA enviado:
  `a19542134e31583a62e8ea2f96054d57ca2bf4a523dadfcca7e9ab7f22e16beb`.

El IPA se conserva localmente bajo `user/build/ios/ipa/`. Los directorios de build están
ignorados por Git y no forman parte del repositorio.

## App Store Connect

- Se creó y completó la ficha de la versión iOS `1.0`.
- Se configuraron descripción, palabras clave, categorías, disponibilidad y URLs de
  soporte, privacidad y eliminación de cuenta.
- Se declaró la privacidad de la app y su clasificación por edades.
- Se configuraron los datos y credenciales para App Review.
- Se cargaron cuatro capturas definitivas de iPhone.
- Se cargaron capturas de iPad de 13 pulgadas, requeridas porque el binario también es
  compatible con iPad.
- Se completó la declaración de derechos sobre contenido después de sustituir el material
  sin autorización.
- Se seleccionó la compilación `1.0.0 (1)` y se envió la versión a revisión.
- El último estado confirmado es **Pendiente de revisión**.

Las capturas finales se conservan en:

- `artifacts/app-store/screenshots/final-1284x2778/`
- `artifacts/app-store/screenshots/final-ipad-13/`

## Seguridad y cumplimiento

- No se incluyen contraseñas, tokens, claves privadas, perfiles de aprovisionamiento ni
  datos personales de contacto en el commit.
- La disponibilidad actual se limita a México. El aviso de condición de comerciante del
  Reglamento de Servicios Digitales de la Unión Europea no bloquea esta publicación.
- No deben reactivarse nombres, logos, imágenes o catálogos de terceros sin autorización
  verificable. Si se incorporan proveedores reales, ANPEC debe conservar el permiso o la
  licencia correspondiente.

## Siguientes pasos operativos

1. Mantener activas y estables las cuentas y datos de revisión mientras Apple evalúa la
   app.
2. Vigilar App Store Connect y el correo del titular por mensajes de App Review.
3. Responder en App Store Connect si Apple solicita información o evidencia adicional.
4. Tras la aprobación, confirmar que la publicación automática inicia correctamente y
   verificar la ficha pública desde México.
5. Incrementar el número de compilación antes de cargar cualquier binario posterior.
