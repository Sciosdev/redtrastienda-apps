import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/cart/domain/models/cart_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/cart/domain/services/cart_service_interface.dart';
import 'package:flutter_sixvalley_ecommerce/features/order_details/domain/models/order_details_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/order_details/domain/services/order_details_service_interface.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/domain/models/product_model.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';

/// Resultado de "Repetir pedido": cuántos entraron, cuántos faltaron y el total
/// del pedido original. El widget arma el reporte honesto con estos números.
class RepeatOrderResult {
  final int added;
  final int missing;
  final int total;
  RepeatOrderResult({required this.added, required this.missing, required this.total});
}

/// Una línea del carrito tal como la necesita el flujo de surtido: la llave (id
/// de la línea, para update/remove), el precio unitario ya con descuento y la
/// cantidad. El vendedor NO se guarda: la barra resumen se calcula sobre el set
/// de productos del proveedor visible (ver [registerShopProducts]) para no
/// depender de la ambigüedad 6valley entre seller_id y user_id.
class SurtidoCartLine {
  int key;
  final double unitPrice;
  int quantity;
  SurtidoCartLine({required this.key, required this.unitPrice, required this.quantity});
}

/// Orquesta la experiencia "maquinita del preventista": steppers de cantidad
/// directo en la lista del proveedor y "Repetir pedido". Habla con el
/// [CartServiceInterface] (add/update/remove/get) SIN los efectos secundarios de
/// navegación del CartController (que hace Navigator.pop() al agregar). Mantiene
/// un mapa productId -> línea, sembrado con UNA sola carga del carrito al entrar
/// a la pantalla del proveedor (evita N+1); los +/- son puntuales y absolutos,
/// así el estado local siempre queda igual al del servidor (sin fantasmas).
class SurtidoController extends ChangeNotifier {
  final CartServiceInterface cartServiceInterface;
  final OrderDetailsServiceInterface orderDetailsServiceInterface;
  SurtidoController({required this.cartServiceInterface, required this.orderDetailsServiceInterface});

  final Map<int, SurtidoCartLine> _byProductId = {};
  final Set<int> _busyProductIds = <int>{};
  final Set<int> _shopProductIds = <int>{};
  bool _cartLoaded = false;

  bool get cartLoaded => _cartLoaded;
  int quantityFor(int? productId) => productId == null ? 0 : (_byProductId[productId]?.quantity ?? 0);
  bool isBusy(int? productId) => productId != null && _busyProductIds.contains(productId);
  bool isInCart(int? productId) => productId != null && _byProductId.containsKey(productId);

  /// Cantidad de productos (líneas distintas) de este proveedor en el carrito.
  int get shopItemCount =>
      _byProductId.keys.where((pid) => _shopProductIds.contains(pid)).length;

  /// Subtotal (precio con descuento × cantidad) de este proveedor.
  double get shopSubtotal => _byProductId.entries
      .where((e) => _shopProductIds.contains(e.key))
      .fold(0.0, (sum, e) => sum + e.value.unitPrice * e.value.quantity);

  /// El shop registra los ids de sus productos (cada página que carga) para que
  /// la barra resumen cuente solo lo de esta tienda. Acumula; no notifica.
  void registerShopProducts(Iterable<int?> ids) {
    for (final id in ids) {
      if (id != null) _shopProductIds.add(id);
    }
  }

  // ---------------------------------------------------------------------------
  // Carga única del carrito al entrar a la pantalla del proveedor.
  // ---------------------------------------------------------------------------
  Future<void> loadShopCart({bool notify = true}) async {
    final res = await cartServiceInterface.getCartList(couponCode: null);
    if (res.response != null && res.response!.statusCode == 200) {
      _byProductId.clear();
      for (var item in res.response!.data) {
        final cart = CartModel.fromJson(item);
        if (cart.productId != null && cart.id != null) {
          _byProductId[cart.productId!] = SurtidoCartLine(
            key: cart.id!,
            unitPrice: (cart.price ?? 0) - (cart.discount ?? 0),
            quantity: cart.quantity ?? 0,
          );
        }
      }
      _cartLoaded = true;
      if (notify) notifyListeners();
    }
  }

  /// Limpia el estado local al salir del proveedor (para no arrastrar el carrito
  /// ni los ids de una tienda a otra).
  void clearShopCart() {
    _byProductId.clear();
    _busyProductIds.clear();
    _shopProductIds.clear();
    _cartLoaded = false;
  }

  // ---------------------------------------------------------------------------
  // Steppers (TRABAJO A). Cantidad inicial = minimum_order_qty; el "-" en el
  // mínimo elimina; el "+" respeta current_stock.
  // ---------------------------------------------------------------------------
  Future<void> addProduct(BuildContext context, Product product) async {
    final int? pid = product.id;
    if (pid == null || isBusy(pid)) return;
    final int stock = product.currentStock ?? 0;
    if (stock <= 0) return; // sin existencias: el botón "Agregar" ya va deshabilitado
    final int min = product.minimumOrderQuantity ?? 1;
    final int initialQty = min > stock ? stock : min;

    _shopProductIds.add(pid);
    _busyProductIds.add(pid);
    // Optimista: la card cambia a stepper de inmediato (llave temporal -1).
    _byProductId[pid] = SurtidoCartLine(key: -1, unitPrice: _unitPriceOf(product), quantity: initialQty);
    notifyListeners();

    final ok = await _rawAdd(pid, initialQty);
    if (ok) {
      // Sync puntual SOLO de este producto (transición 0 -> n) para conocer la
      // llave real de la nueva línea. No recargamos todo el mapa para no pisar
      // un +/- en vuelo de otro producto durante el surtido rápido.
      await _syncLineFromServer(pid);
    } else {
      _byProductId.remove(pid);
    }
    _busyProductIds.remove(pid);
    notifyListeners();
  }

  /// Lee el carrito y actualiza SOLO la línea de [pid] (llave + cantidad reales),
  /// sin tocar el resto del mapa.
  Future<void> _syncLineFromServer(int pid) async {
    final res = await cartServiceInterface.getCartList(couponCode: null);
    if (res.response != null && res.response!.statusCode == 200) {
      for (var item in res.response!.data) {
        final cart = CartModel.fromJson(item);
        if (cart.productId == pid && cart.id != null) {
          final existing = _byProductId[pid];
          if (existing != null) {
            existing.key = cart.id!;
            existing.quantity = cart.quantity ?? existing.quantity;
          } else {
            _byProductId[pid] = SurtidoCartLine(
              key: cart.id!,
              unitPrice: (cart.price ?? 0) - (cart.discount ?? 0),
              quantity: cart.quantity ?? 0,
            );
          }
          break;
        }
      }
    }
  }

  Future<void> increment(BuildContext context, Product product) async {
    final int? pid = product.id;
    final line = pid == null ? null : _byProductId[pid];
    if (pid == null || line == null || isBusy(pid)) return;
    final int stock = product.currentStock ?? 0;
    if (line.quantity + 1 > stock) {
      showCustomSnackBarWidget(getTranslated('surtido_no_more_stock', context), Get.context!, snackBarType: SnackBarType.warning);
      return;
    }
    final int prev = line.quantity;
    _busyProductIds.add(pid);
    line.quantity = prev + 1;
    notifyListeners();

    final ok = await _rawUpdate(line.key, line.quantity);
    if (!ok) line.quantity = prev;
    _busyProductIds.remove(pid);
    notifyListeners();
  }

  Future<void> decrement(BuildContext context, Product product) async {
    final int? pid = product.id;
    final line = pid == null ? null : _byProductId[pid];
    if (pid == null || line == null || isBusy(pid)) return;
    final int min = product.minimumOrderQuantity ?? 1;
    if (line.quantity - 1 < min) {
      // Bajar del mínimo = quitar del carrito (nunca cae a mínimo-1).
      await removeProduct(context, pid);
      return;
    }
    final int prev = line.quantity;
    _busyProductIds.add(pid);
    line.quantity = prev - 1;
    notifyListeners();

    final ok = await _rawUpdate(line.key, line.quantity);
    if (!ok) line.quantity = prev;
    _busyProductIds.remove(pid);
    notifyListeners();
  }

  Future<void> removeProduct(BuildContext context, int pid) async {
    final line = _byProductId[pid];
    if (line == null || isBusy(pid)) return;
    _busyProductIds.add(pid);
    _byProductId.remove(pid);
    notifyListeners();

    final ok = await _rawDelete(line.key);
    if (!ok) _byProductId[pid] = line; // revert
    _busyProductIds.remove(pid);
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Repetir pedido (TRABAJO B). Secuencial (await encadenado, NUNCA ráfaga
  // paralela — rate limit del hosting), con progreso y reporte de faltantes.
  // ---------------------------------------------------------------------------
  bool _repeating = false;
  int _repeatDone = 0;
  int _repeatTotal = 0;
  bool get repeating => _repeating;
  int get repeatDone => _repeatDone;
  int get repeatTotal => _repeatTotal;

  Future<RepeatOrderResult> repeatOrder({required String orderId}) async {
    if (_repeating) return RepeatOrderResult(added: 0, missing: 0, total: 0);
    _repeating = true;
    _repeatDone = 0;
    _repeatTotal = 0;
    notifyListeners();

    // 1) Traer los items del pedido.
    final detailRes = await orderDetailsServiceInterface.getOrderDetails(orderId);
    final List<OrderDetailsModel> items = [];
    if (detailRes.response != null && detailRes.response!.statusCode == 200) {
      for (var o in detailRes.response!.data) {
        items.add(OrderDetailsModel.fromJson(o));
      }
    }

    // 2) Carrito actual (para decidir SUMA en productos ya presentes).
    await loadShopCart(notify: false);

    _repeatTotal = items.length;
    notifyListeners();

    int added = 0;
    int missing = 0;

    for (final it in items) {
      final int? pid = it.productId;
      final int qty = it.qty ?? 0;
      final Product? p = it.productDetails;

      final bool unavailable = p == null ||
          p.status != 1 ||
          (p.productType == 'physical' && (p.currentStock ?? 0) <= 0);
      final bool hasVariant = (it.variant != null && it.variant!.isNotEmpty) ||
          (p != null && _hasVariantDimensions(p));

      if (pid == null || qty <= 0 || unavailable || hasVariant) {
        // Omite y cuenta como faltante (no disponible o con variante no
        // reconstruible desde el pedido). Decisión documentada en el plan.
        missing++;
        _repeatDone++;
        notifyListeners();
        continue;
      }

      bool ok;
      final existing = _byProductId[pid];
      if (existing != null) {
        // Ya en carrito -> SUMA cantidades (garantizado del lado app).
        ok = await _rawUpdate(existing.key, existing.quantity + qty);
      } else {
        ok = await _rawAdd(pid, qty);
      }
      if (ok) {
        added++;
      } else {
        missing++;
      }
      _repeatDone++;
      notifyListeners();
    }

    _repeating = false;
    notifyListeners();

    // El reporte honesto + navegación al carrito los maneja el widget (para un
    // ciclo de vida limpio del diálogo de progreso).
    return RepeatOrderResult(added: added, missing: missing, total: _repeatTotal);
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------
  bool _hasVariantDimensions(Product p) =>
      (p.colors != null && p.colors!.isNotEmpty) ||
      (p.choiceOptions != null && p.choiceOptions!.isNotEmpty) ||
      (p.variation != null && p.variation!.isNotEmpty);

  double _unitPriceOf(Product product) {
    final double price = product.unitPrice ?? 0;
    final double discount = product.discount ?? 0;
    if (discount <= 0) return price;
    if (product.discountType == 'percent') return price - (price * discount / 100);
    return price - discount;
  }

  Future<bool> _rawAdd(int productId, int quantity) async {
    final res = await cartServiceInterface.addToCartListData(
      CartModelBody(productId: productId, quantity: quantity, variant: ''),
      <ChoiceOptions>[],
      <int>[],
      0,
      null,
      null,
    );
    return res.response != null && res.response!.statusCode == 200;
  }

  Future<bool> _rawUpdate(int key, int quantity) async {
    final res = await cartServiceInterface.updateQuantity(key, quantity);
    return res.response != null && res.response!.statusCode == 200;
  }

  Future<bool> _rawDelete(int key) async {
    final res = await cartServiceInterface.delete(key);
    return res.response != null && res.response!.statusCode == 200;
  }
}
