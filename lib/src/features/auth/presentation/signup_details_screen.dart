import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import '../../../../widgets/gradient_button.dart';
import '../data/auth_repository.dart';
import '../../../../widgets/custom_arrow_icon.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import '../../home/presentation/home_screen.dart';
import '../../../../core/utils/snackbar_utils.dart';
import 'package:tryd/src/features/auth/presentation/controllers/auth_controller.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/country_picker_dialog.dart';

class SignupDetailsScreen extends ConsumerStatefulWidget {
  final String email;

  const SignupDetailsScreen({
    super.key,
    required this.email,
  });

  @override
  ConsumerState<SignupDetailsScreen> createState() => _SignupDetailsScreenState();
}

class _SignupDetailsScreenState extends ConsumerState<SignupDetailsScreen> {
  static const Color _primaryTextColor = Color(0xFF000000);
  static const Color _labelColor = Color(0xFF8B88B5);
  static const Color _inputTextColor = Color(0xFF221F48);
  static const Color _inputBgColor = Color(0xFFFFFFFF);
  static const Color _linkColor = Color(0xFFF83A71);

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isSigningUp = false;
  bool _isResending = false;
  String _completePhoneNumber = '';

  final List<TextEditingController> _otpControllers = List.generate(
    4,
    (index) => TextEditingController(),
  );

  final List<FocusNode> _otpFocusNodes = List.generate(
    4,
    (index) => FocusNode(),
  );

  static const int _timerDuration = 60;
  int _timerRemaining = _timerDuration;
  bool _canResend = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();

    // Handle backspace on empty fields (onChanged doesn't fire for empty fields)
    for (int i = 1; i < 4; i++) {
      final index = i;
      _otpFocusNodes[index].onKeyEvent = (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.backspace &&
            _otpControllers[index].text.isEmpty) {
          _otpControllers[index - 1].clear();
          _otpFocusNodes[index - 1].requestFocus();
          if (mounted) setState(() {});
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      };
    }
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _timerRemaining = _timerDuration;
      _canResend = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerRemaining > 0) {
        if (mounted) setState(() => _timerRemaining--);
      } else {
        if (mounted) setState(() => _canResend = true);
        timer.cancel();
      }
    });
  }

  Future<void> _handleResend() async {
    if (!_canResend || _isResending) return;

    setState(() => _isResending = true);
    try {
      await ref.read(authRepositoryProvider).sendOtp(widget.email);
      if (mounted) {
        // Clear OTP fields first
        for (var controller in _otpControllers) {
          controller.clear();
        }
        // Restart timer
        _startTimer();
        // Focus first OTP field
        _otpFocusNodes[0].requestFocus();
        CustomSnackBar.show(context, message: 'OTP resent successfully', isError: false);
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(context, message: 'Failed to resend OTP');
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  String _getOtpCode() {
    return _otpControllers.map((controller) => controller.text).join();
  }

  void _onOtpDigitChanged(String value, int index) {
    if (value.length > 1) {
      String digits = value.replaceAll(RegExp(r'\D'), '');
      if (digits.isEmpty) {
        _otpControllers[index].clear();
        return;
      }

      if (digits.length > 1) {
        // Paste handling
        for (int i = 0; i < digits.length && (index + i) < 4; i++) {
          _otpControllers[index + i].text = digits[i];
        }
        int nextFocus = (index + digits.length).clamp(0, 3);
        _otpFocusNodes[nextFocus].requestFocus();
        setState(() {});
        return;
      } else {
        _otpControllers[index].text = digits[0];
        _otpControllers[index].selection = TextSelection.fromPosition(
          TextPosition(offset: 1),
        );
      }
    }

    if (mounted) setState(() {});

    if (value.isNotEmpty) {
      if (index < 3) {
        _otpFocusNodes[index + 1].requestFocus();
      }
    } else if (value.isEmpty && index > 0) {
      _otpFocusNodes[index - 1].requestFocus();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _timer?.cancel();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _handleSignup() async {
    final otp = _getOtpCode();
    if (otp.length < 4) {
      CustomSnackBar.show(context, message: 'Please enter complete OTP');
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final phoneNumber = _phoneController.text.trim();
    final digitsOnly = phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length < 8) {
      CustomSnackBar.show(context, message: 'Please enter a valid phone number');
      return;
    }

    if (_isSigningUp) return;
    setState(() => _isSigningUp = true);

    try {
      final authController = ref.read(authControllerProvider.notifier);

      await authController.verifyOtp(widget.email, otp);

      await authController.register(
        name: _nameController.text,
        email: widget.email,
        password: 'TRYD@123',
        phoneNumber: _completePhoneNumber,
      );

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Signup error: $e');
      if (mounted) {
        String errorMessage = 'Verification or Signup failed. Try again.';
        if (e is DioException) {
          errorMessage = e.response?.data['message'] ?? e.message ?? 'Network error occurred';
        } else {
          errorMessage = e.toString();
        }
        CustomSnackBar.show(context, message: errorMessage);
      }
    } finally {
      if (mounted) setState(() => _isSigningUp = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;
    final isTablet = screenWidth > 600;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    const double smallScale = 0.70;
    const double mediumScale = 0.78;
    const double largeScale = 0.84;
    const double tabletScale = 1.10;

    final double scale = isTablet
        ? tabletScale
        : screenHeight < 680
            ? smallScale
            : screenHeight < 850
                ? mediumScale
                : largeScale;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg-gradient.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 450),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24.0 * scale),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(height: 24.0 * scale),
                                _buildLogo(scale),
                                SizedBox(height: 16.0 * scale),
                                _buildTitle(scale),
                                SizedBox(height: 32.0 * scale),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 14.0 * scale),
                                  child: _buildInputField(
                                    label: 'Full Name',
                                    placeholder: 'Enter full name',
                                    controller: _nameController,
                                    scale: scale,
                                  ),
                                ),
                                SizedBox(height: 18.0 * scale),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 14.0 * scale),
                                  child: _buildPhoneField(scale),
                                ),
                                SizedBox(height: 38.0 * scale),
                                _buildOtpField(scale),
                                SizedBox(height: 16.0 * scale),
                                _buildResendSection(scale),
                                SizedBox(height: 44.0 * scale),
                                GradientButton(
                                  text: _isSigningUp ? 'Signing up...' : 'Complete Signup',
                                  onPressed: _isSigningUp ? () {} : _handleSignup,
                                  height: 66.0 * scale,
                                  textStyle: GoogleFonts.lexendDeca(
                                    fontSize: 21.0 * scale,
                                    fontWeight: FontWeight.w600,
                                    height: 1.26,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: bottomInset > 0 ? bottomInset * 0.3 : 40.0 * scale),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: 20,
            left: 20,
            child: SafeArea(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 56.0 * scale,
                  height: 56.0 * scale,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Transform.scale(
                    scaleX: -1,
                    child: CustomArrowIcon(
                      size: 32.0 * scale,
                      color: const Color(0xFF130F26),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (defaultTargetPlatform == TargetPlatform.iOS && bottomInset > 0)
            Positioned(
              bottom: bottomInset,
              left: 0,
              right: 0,
              child: Container(
                color: const Color(0xFFD2D5DB),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () => FocusScope.of(context).unfocus(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          'Done',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF007AFF),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLogo(double scale) {
    return Image.asset(
      'assets/images/logo-full.png',
      width: 201.0 * scale,
      height: 80.0 * scale,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      isAntiAlias: true,
    );
  }

  Widget _buildTitle(double scale) {
    return Text(
      'Complete your profile',
      textAlign: TextAlign.center,
      style: GoogleFonts.lexendDeca(
        fontSize: 20.0 * scale,
        fontWeight: FontWeight.w600,
        height: 1.25,
        color: _primaryTextColor,
      ),
    );
  }

  Widget _buildOtpField(double scale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Verification Code',
          style: GoogleFonts.lexendDeca(
            fontSize: 16.0 * scale,
            fontWeight: FontWeight.w600,
            color: _primaryTextColor,
          ),
        ),
        SizedBox(height: 6.0 * scale),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Code sent to ',
                style: GoogleFonts.poppins(
                  fontSize: 13.0 * scale,
                  color: _labelColor,
                  fontWeight: FontWeight.w400,
                ),
              ),
              TextSpan(
                text: widget.email,
                style: GoogleFonts.poppins(
                  fontSize: 13.0 * scale,
                  color: const Color(0xFF900EBF),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 20.0 * scale),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0 * scale),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 0; i < 4; i++) ...[
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: _buildOtpDigitBox(i, scale),
                  ),
                ),
                if (i < 3) SizedBox(width: 10.0 * scale),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOtpDigitBox(int index, double scale) {
    final hasValue = _otpControllers[index].text.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        color: _inputBgColor,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: hasValue ? const Color(0xFF900EBF).withValues(alpha: 0.3) : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 0),
            blurRadius: 5.8,
            spreadRadius: 0,
            color: const Color(0xFFAFA9A9).withValues(alpha: 0.12),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _otpFocusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        textInputAction: index == 3 ? TextInputAction.done : TextInputAction.next,
        style: GoogleFonts.poppins(
          fontSize: 22.0 * scale,
          fontWeight: FontWeight.w600,
          height: 1.5,
          color: _inputTextColor,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          counterText: '',
          contentPadding: EdgeInsets.zero,
        ),
        inputFormatters: [
          LengthLimitingTextInputFormatter(4),
          FilteringTextInputFormatter.digitsOnly,
        ],
        onChanged: (value) => _onOtpDigitChanged(value, index),
        onTap: () {
          _otpControllers[index].selection = TextSelection(
            baseOffset: 0,
            extentOffset: _otpControllers[index].text.length,
          );
        },
      ),
    );
  }

  Widget _buildResendSection(double scale) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 6.0 * scale),
      child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  "Didn't receive code? ",
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 14.0 * scale,
                    fontWeight: FontWeight.w400,
                    color: _labelColor,
                  ),
                ),
              ),
              if (_canResend)
                GestureDetector(
                  onTap: _isResending ? null : _handleResend,
                  child: Text(
                    _isResending ? 'Sending...' : 'Resend code',
                    style: GoogleFonts.poppins(
                      fontSize: 14.0 * scale,
                      fontWeight: FontWeight.w600,
                      color: _isResending ? _labelColor : _linkColor,
                    ),
                  ),
                )
              else
                Text(
                  '0:${_timerRemaining.toString().padLeft(2, '0')}',
                  style: GoogleFonts.poppins(
                    fontSize: 14.0 * scale,
                    fontWeight: FontWeight.w500,
                    color: _labelColor,
                  ),
                ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Text(
            'Change Email',
            style: GoogleFonts.poppins(
              fontSize: 12.0 * scale,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF900EBF),
            ),
          ),
        ),
      ],
      ),
    );
  }

  Widget _buildPhoneField(double scale) {
    return Container(
      decoration: BoxDecoration(
        color: _inputBgColor,
        borderRadius: BorderRadius.circular(17),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 0,
            color: const Color(0xFF000000).withValues(alpha: 0.04),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 0, vertical: 12.0 * scale),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0 * scale),
              child: Text(
                'Phone Number',
                style: GoogleFonts.lexendDeca(
                  fontSize: 12.0 * scale,
                  fontWeight: FontWeight.w500,
                  height: 1.25,
                  color: _labelColor,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            SizedBox(height: 4.0 * scale),
            IntlPhoneField(
              controller: _phoneController,
              decoration: InputDecoration(
                hintText: '1234 5678',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 22.0 * scale,
                  fontWeight: FontWeight.w400,
                  color: _labelColor.withValues(alpha: 0.5),
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 24.0 * scale, vertical: 6.0 * scale),
                counterText: '',
                errorStyle: const TextStyle(fontSize: 0, height: 0),
              ),
              style: GoogleFonts.poppins(
                fontSize: 20.0 * scale,
                fontWeight: FontWeight.w500,
                color: _inputTextColor,
              ),
              initialCountryCode: 'KW',
              disableLengthCheck: true,
              autovalidateMode: AutovalidateMode.disabled,
              onChanged: (phone) {
                _completePhoneNumber = phone.completeNumber;
              },
              pickerDialogStyle: PickerDialogStyle(
                backgroundColor: Colors.white,
                countryCodeStyle: GoogleFonts.poppins(fontSize: 14 * scale),
                countryNameStyle: GoogleFonts.poppins(fontSize: 14 * scale),
                searchFieldPadding: EdgeInsets.all(16 * scale),
              ),
              dropdownTextStyle: GoogleFonts.poppins(
                fontSize: 20.0 * scale,
                fontWeight: FontWeight.w500,
                color: _inputTextColor,
              ),
              showCountryFlag: true,
              dropdownIconPosition: IconPosition.trailing,
              dropdownIcon: Icon(Icons.arrow_drop_down, color: _labelColor, size: 20 * scale),
              flagsButtonPadding: EdgeInsets.only(left: 24.0 * scale),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String placeholder,
    required TextEditingController controller,
    required double scale,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _inputBgColor,
        borderRadius: BorderRadius.circular(17),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 0,
            color: const Color(0xFF000000).withValues(alpha: 0.04),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.0 * scale, vertical: 16.0 * scale),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.lexendDeca(
                fontSize: 12.0 * scale,
                fontWeight: FontWeight.w500,
                height: 1.25,
                color: _labelColor,
                letterSpacing: 0.2,
              ),
            ),
            SizedBox(height: 8.0 * scale),
            TextFormField(
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType,
              style: GoogleFonts.poppins(
                fontSize: 18.0 * scale,
                fontWeight: FontWeight.w500,
                color: _inputTextColor,
                height: 1.4,
              ),
              decoration: InputDecoration(
                hintText: placeholder,
                hintStyle: GoogleFonts.poppins(
                  fontSize: 16.0 * scale,
                  fontWeight: FontWeight.w400,
                  color: _labelColor.withValues(alpha: 0.5),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
          ],
        ),
      ),
    );
  }
}
