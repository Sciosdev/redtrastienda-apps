import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_app_bar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_button_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_textfield_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/affiliate_profile/controllers/affiliate_profile_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/widgets/anp_number_field_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/profile/controllers/profile_contrroller.dart';
import 'package:flutter_sixvalley_ecommerce/helper/route_healper.dart';
import 'package:flutter_sixvalley_ecommerce/helper/velidate_check.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:provider/provider.dart';

/// R-Afiliación: wizard de activación de cuenta precargada.
/// Paso 1: número ANP (campo con prefijo fijo, reusado de r-anp-prefijo).
/// Paso 2: segundo dato de identidad según el factor (teléfono / nombre / correo).
/// Paso 3: correo real + contraseña → sesión iniciada + invitación a completar perfil.
class ActivateAccountScreen extends StatefulWidget {
  const ActivateAccountScreen({super.key});

  @override
  State<ActivateAccountScreen> createState() => _ActivateAccountScreenState();
}

class _ActivateAccountScreenState extends State<ActivateAccountScreen> {
  final TextEditingController _numeroAnpController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _correoContactoController = TextEditingController();
  final TextEditingController _correoRealController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final GlobalKey<FormState> _paso1Key = GlobalKey<FormState>();
  final GlobalKey<FormState> _paso2Key = GlobalKey<FormState>();
  final GlobalKey<FormState> _paso3Key = GlobalKey<FormState>();

  int _paso = 1;
  bool _solicitudManualEnviada = false;

  String get _numeroCompleto => AnpNumberFieldWidget.fullNumero(_numeroAnpController.text);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        Provider.of<AuthController>(context, listen: false).resetActivacion());
  }

  @override
  void dispose() {
    _numeroAnpController.dispose();
    _telefonoController.dispose();
    _nombreController.dispose();
    _correoContactoController.dispose();
    _correoRealController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _continuarPaso1(AuthController authProvider) async {
    if (!(_paso1Key.currentState?.validate() ?? false)) return;

    final bool activable = await authProvider.consultarNumeroParaActivacion(_numeroCompleto);
    if (!mounted) return;

    if (activable) {
      setState(() => _paso = 2);
      return;
    }
    if (authProvider.anpReclamada) {
      showCustomSnackBarWidget(getTranslated('cuenta_ya_activada_inicia_sesion', context), context, snackBarType: SnackBarType.success);
      Navigator.pop(context);
      return;
    }
    // No existe o no está precargado: el aviso de contacto ya está en pantalla.
    showCustomSnackBarWidget(
        authProvider.activacionMensaje ?? getTranslated('numero_anp_sin_cuenta_para_activar', context),
        context, snackBarType: SnackBarType.error);
  }

  Future<void> _continuarPaso2(AuthController authProvider) async {
    if (!(_paso2Key.currentState?.validate() ?? false)) return;

    final String? factor = authProvider.anpFactor;
    final bool ok = await authProvider.verificarIdentidadAnp(
      numeroAnp: _numeroCompleto,
      telefono: factor == 'telefono' ? _telefonoController.text : null,
      nombre: factor == 'nombre' ? _nombreController.text : null,
      correoContacto: factor == 'ninguno' ? _correoContactoController.text : null,
    );
    if (!mounted) return;

    if (!ok) {
      showCustomSnackBarWidget(
          authProvider.activacionMensaje ?? getTranslated('los_datos_no_coinciden', context),
          context, snackBarType: SnackBarType.error);
      return;
    }
    if (authProvider.activacionRequiereManual) {
      setState(() => _solicitudManualEnviada = true);
      return;
    }
    setState(() => _paso = 3);
  }

  Future<void> _continuarPaso3(AuthController authProvider) async {
    if (!(_paso3Key.currentState?.validate() ?? false)) return;

    final bool ok = await authProvider.activarCuentaAnp(
      correoReal: _correoRealController.text,
      password: _passwordController.text.trim(),
      confirmPassword: _confirmPasswordController.text.trim(),
    );
    if (!mounted) return;

    if (!ok) {
      showCustomSnackBarWidget(
          authProvider.activacionMensaje ?? getTranslated('no_se_pudo_activar_la_cuenta', context),
          context, snackBarType: SnackBarType.error);
      return;
    }

    // Sesión iniciada: cargar el perfil e invitar (sin bloquear) a completarlo.
    await Provider.of<ProfileController>(context, listen: false).getUserInfo(context);
    if (!mounted) return;
    final AffiliateProfileController affiliateController = Provider.of<AffiliateProfileController>(context, listen: false);
    await affiliateController.getAffiliateProfile();
    if (!mounted) return;

    final List<String> faltantes = affiliateController.profile?.camposFaltantes ?? [];
    if (faltantes.isNotEmpty) {
      await _mostrarInvitacionCompletarPerfil(faltantes);
      if (!mounted) return;
    }
    RouterHelper.getDashboardRoute(action: RouteAction.pushNamedAndRemoveUntil);
  }

  /// Invitación amigable (no es un error): la cuenta ya quedó activada, solo
  /// sugerimos completar los datos del negocio cuando el afiliado quiera.
  Future<void> _mostrarInvitacionCompletarPerfil(List<String> faltantes) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Dimensions.radiusLarge)),
      ),
      builder: (bottomSheetContext) => Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.check_circle, color: const Color(0xFF2E7D32), size: 28),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Expanded(child: Text(getTranslated('cuenta_activada_bienvenido', bottomSheetContext) ?? '',
                style: textBold.copyWith(fontSize: Dimensions.fontSizeLarge))),
          ]),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          Text(getTranslated('completa_tu_perfil_cuando_quieras', bottomSheetContext) ?? '',
              style: textRegular.copyWith(color: Theme.of(bottomSheetContext).hintColor)),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          ...faltantes.map((campo) => Padding(
                padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeExtraSmall),
                child: Row(children: [
                  Icon(Icons.radio_button_unchecked, size: 14, color: Theme.of(bottomSheetContext).hintColor),
                  const SizedBox(width: Dimensions.paddingSizeSmall),
                  Text(getTranslated(campo, bottomSheetContext) ?? campo),
                ]),
              )),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          CustomButton(
            buttonText: getTranslated('continuar', bottomSheetContext),
            onTap: () => Navigator.pop(bottomSheetContext),
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: getTranslated('activa_tu_cuenta', context)),
      body: Consumer<AuthController>(builder: (context, authProvider, _) {
        return ListView(padding: const EdgeInsets.all(Dimensions.paddingSizeDefault), children: [
          Center(child: Padding(padding: const EdgeInsets.all(30),
              child: Image.asset(Images.logoWithNameImage, height: 120, width: 120))),

          if (_solicitudManualEnviada)
            _buildSolicitudManualEnviada(context)
          else if (_paso == 1)
            _buildPaso1(context, authProvider)
          else if (_paso == 2)
            _buildPaso2(context, authProvider)
          else
            _buildPaso3(context, authProvider),
        ]);
      }),
    );
  }

  Widget _buildPaso1(BuildContext context, AuthController authProvider) {
    return Form(
      key: _paso1Key,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(getTranslated('ya_soy_afiliado_anpec', context) ?? '', textAlign: TextAlign.center,
            style: textBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
        Text(getTranslated('escribe_tu_numero_anp_para_activar', context) ?? '', textAlign: TextAlign.center,
            style: textRegular.copyWith(color: Theme.of(context).hintColor)),
        const SizedBox(height: Dimensions.marginSizeDefault),

        AnpNumberFieldWidget(
          controller: _numeroAnpController,
          inputAction: TextInputAction.done,
        ),
        const SizedBox(height: Dimensions.marginSizeDefault),

        Container(
          margin: const EdgeInsets.symmetric(horizontal: Dimensions.marginSizeDefault),
          child: CustomButton(
            isLoading: authProvider.activacionLoading,
            buttonText: getTranslated('continuar', context),
            onTap: () => _continuarPaso1(authProvider),
          ),
        ),
      ]),
    );
  }

  Widget _buildPaso2(BuildContext context, AuthController authProvider) {
    final String? factor = authProvider.anpFactor;
    return Form(
      key: _paso2Key,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(_numeroCompleto, textAlign: TextAlign.center,
            style: textBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).primaryColor)),
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
        Text(getTranslated('confirma_tu_identidad', context) ?? '', textAlign: TextAlign.center,
            style: textBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),

        if (factor == 'telefono') ...[
          Text(getTranslated('escribe_el_telefono_registrado_en_anpec', context) ?? '', textAlign: TextAlign.center,
              style: textRegular.copyWith(color: Theme.of(context).hintColor)),
          const SizedBox(height: Dimensions.marginSizeDefault),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: Dimensions.marginSizeDefault),
            child: CustomTextFieldWidget(
              hintText: getTranslated('telefono_10_digitos', context),
              labelText: getTranslated('telefono_10_digitos', context),
              labelTextStyle: textRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge!.color),
              controller: _telefonoController,
              required: true,
              inputType: TextInputType.phone,
              inputAction: TextInputAction.done,
              prefixIcon: Images.callIcon,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
              validator: (value) => (value == null || value.trim().length != 10)
                  ? (getTranslated('el_telefono_debe_tener_10_digitos', context) ?? '')
                  : null,
            ),
          ),
        ] else if (factor == 'nombre') ...[
          Text(getTranslated('escribe_tu_nombre_como_esta_registrado_en_anpec', context) ?? '', textAlign: TextAlign.center,
              style: textRegular.copyWith(color: Theme.of(context).hintColor)),
          const SizedBox(height: Dimensions.marginSizeDefault),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: Dimensions.marginSizeDefault),
            child: CustomTextFieldWidget(
              hintText: getTranslated('nombre_completo', context),
              labelText: getTranslated('nombre_completo', context),
              labelTextStyle: textRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge!.color),
              controller: _nombreController,
              required: true,
              inputType: TextInputType.name,
              inputAction: TextInputAction.done,
              capitalization: TextCapitalization.words,
              prefixIcon: Images.username,
              validator: (value) => (value == null || value.trim().split(RegExp(r'\s+')).length < 2)
                  ? (getTranslated('escribe_al_menos_nombre_y_apellido', context) ?? '')
                  : null,
            ),
          ),
        ] else ...[
          // Factor 'ninguno': la fila del Excel no trae teléfono ni nombre.
          Text(getTranslated('necesitamos_verificar_tu_identidad_manualmente', context) ?? '', textAlign: TextAlign.center,
              style: textRegular.copyWith(color: Theme.of(context).hintColor)),
          const SizedBox(height: Dimensions.marginSizeDefault),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: Dimensions.marginSizeDefault),
            child: CustomTextFieldWidget(
              hintText: getTranslated('enter_your_email', context),
              labelText: getTranslated('enter_your_email', context),
              labelTextStyle: textRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge!.color),
              controller: _correoContactoController,
              required: true,
              inputType: TextInputType.emailAddress,
              inputAction: TextInputAction.done,
              prefixIcon: Images.email,
              validator: (value) => ValidateCheck.validateEmail(value),
            ),
          ),
        ],

        const SizedBox(height: Dimensions.marginSizeDefault),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: Dimensions.marginSizeDefault),
          child: CustomButton(
            isLoading: authProvider.activacionLoading,
            buttonText: getTranslated(factor == 'ninguno' ? 'enviar_solicitud' : 'continuar', context),
            onTap: () => _continuarPaso2(authProvider),
          ),
        ),
      ]),
    );
  }

  Widget _buildPaso3(BuildContext context, AuthController authProvider) {
    return Form(
      key: _paso3Key,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(getTranslated('crea_tus_credenciales', context) ?? '', textAlign: TextAlign.center,
            style: textBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
        Text(getTranslated('con_este_correo_y_contrasena_entraras_a_la_app', context) ?? '', textAlign: TextAlign.center,
            style: textRegular.copyWith(color: Theme.of(context).hintColor)),
        const SizedBox(height: Dimensions.marginSizeDefault),

        Container(
          margin: const EdgeInsets.symmetric(horizontal: Dimensions.marginSizeDefault),
          child: CustomTextFieldWidget(
            hintText: getTranslated('enter_your_email', context),
            labelText: getTranslated('enter_your_email', context),
            labelTextStyle: textRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge!.color),
            controller: _correoRealController,
            required: true,
            inputType: TextInputType.emailAddress,
            inputAction: TextInputAction.next,
            prefixIcon: Images.email,
            validator: (value) => ValidateCheck.validateEmail(value),
          ),
        ),
        const SizedBox(height: Dimensions.marginSizeSmall),

        Container(
          margin: const EdgeInsets.symmetric(horizontal: Dimensions.marginSizeDefault),
          child: CustomTextFieldWidget(
            hintText: getTranslated('minimum_password_length', context),
            labelText: getTranslated('password', context),
            labelTextStyle: textRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge!.color),
            controller: _passwordController,
            isPassword: true,
            required: true,
            inputAction: TextInputAction.next,
            prefixIcon: Images.pass,
            validator: (value) => ValidateCheck.validatePassword(value, "password_must_be_required"),
          ),
        ),
        const SizedBox(height: Dimensions.marginSizeSmall),

        Container(
          margin: const EdgeInsets.symmetric(horizontal: Dimensions.marginSizeDefault),
          child: CustomTextFieldWidget(
            hintText: getTranslated('re_enter_password', context),
            labelText: getTranslated('re_enter_password', context),
            labelTextStyle: textRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge!.color),
            controller: _confirmPasswordController,
            isPassword: true,
            required: true,
            inputAction: TextInputAction.done,
            prefixIcon: Images.pass,
            validator: (value) => ValidateCheck.validateConfirmPassword(value, _passwordController.text.trim()),
          ),
        ),
        const SizedBox(height: Dimensions.marginSizeDefault),

        Container(
          margin: const EdgeInsets.symmetric(horizontal: Dimensions.marginSizeDefault),
          child: CustomButton(
            isLoading: authProvider.activacionLoading,
            buttonText: getTranslated('activar_mi_cuenta', context),
            onTap: () => _continuarPaso3(authProvider),
          ),
        ),
      ]),
    );
  }

  Widget _buildSolicitudManualEnviada(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Icon(Icons.mark_email_read_outlined, size: 60, color: Theme.of(context).primaryColor),
      const SizedBox(height: Dimensions.paddingSizeDefault),
      Text(getTranslated('solicitud_enviada', context) ?? '', textAlign: TextAlign.center,
          style: textBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
      const SizedBox(height: Dimensions.paddingSizeExtraSmall),
      Text(getTranslated('anpec_validara_tu_identidad_y_te_contactara', context) ?? '', textAlign: TextAlign.center,
          style: textRegular.copyWith(color: Theme.of(context).hintColor)),
      const SizedBox(height: Dimensions.marginSizeDefault),
      Container(
        margin: const EdgeInsets.symmetric(horizontal: Dimensions.marginSizeDefault),
        child: CustomButton(
          buttonText: getTranslated('entendido', context),
          onTap: () => Navigator.pop(context),
        ),
      ),
    ]);
  }
}
