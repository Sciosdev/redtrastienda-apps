import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';

/// Avatar de inicial: el directorio no expone foto (solo nombre/negocio/estado),
/// así que se pinta la primera letra del nombre sobre el color primario.
class AvatarInicialTiendaWidget extends StatelessWidget {
  final String? nombre;
  final double size;
  const AvatarInicialTiendaWidget({super.key, required this.nombre, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final String inicial = (nombre ?? '').trim().isNotEmpty ? (nombre ?? '').trim()[0].toUpperCase() : '?';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        inicial,
        style: textMedium.copyWith(
          color: Theme.of(context).primaryColor,
          fontSize: Dimensions.fontSizeLarge,
        ),
      ),
    );
  }
}
