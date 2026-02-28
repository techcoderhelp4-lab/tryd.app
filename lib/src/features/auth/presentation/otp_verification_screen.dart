import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../widgets/gradient_button.dart';
import 'package:tryd/src/features/auth/data/auth_repository.dart';
import "../../home/presentation/home_screen.dart";
import '../../notifications/data/real_time_notification_service.dart';
import 'dart:async';
import '../../../../widgets/custom_arrow_icon.dart';
import 'package:tryd/src/features/auth/presentation/controllers/auth_controller.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String email;
  final bool isLogin;
  final Map<String, String>? registrationData;

  const OtpVerificationScreen({
    super.key,
    required this.email,
    this.isLogin = false,
    this.registrationData,
  });

  @override
  ConsumerState<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  static const Color _primaryTextColor = Color(0xFF000000);
  static const Color _labelColor = Color(0xFF8B88B5);
  static const Color _inputTextColor = Color(0xFF221F48);
  static const Color _linkColor = Color(0xFFF83A71);
  static const Color _inputBgColor = Color(0xFFFFFFFF);

  final List<TextEditingController> _otpControllers = List.generate(
    4,
    (index) => TextEditingController(),
  );

  final List<FocusNode> _otpFocusNodes = List.generate(
    4,
    (index) => FocusNode(),
  );

  bool _isVerifying = false;
  bool _isResending = false;

  static const int _timerDuration = 60;
  int _timerRemaining = _timerDuration;
  bool _canResend = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();

    // Auto-focus first OTP field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _otpFocusNodes[0].requestFocus();
    });
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
        // Focus first field
        _otpFocusNodes[0].requestFocus();
        ref.read(realTimeNotificationServiceProvider).showInAppBanner(
          'OTP Resent',
          'A new verification code has been sent to your email.',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to resend OTP', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _handleVerification() async {
    final otp = _getOtpCode();
    if (otp.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter complete OTP', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_isVerifying) return;
    setState(() => _isVerifying = true);

    try {
      final authController = ref.read(authControllerProvider.notifier);

      if (widget.isLogin) {
        await authController.verifyOtpLogin(widget.email, otp);
      } else if (widget.registrationData != null) {
        await authController.verifyOtp(widget.email, otp);
        await authController.register(
          name: widget.registrationData!['name'] ?? '',
          email: widget.registrationData!['email'] ?? widget.email,
          password: widget.registrationData!['password'] ?? 'TRYD@123',
          phoneNumber: widget.registrationData!['phoneNumber'] ?? '',
        );
      } else {
        await authController.verifyOtpLogin(widget.email, otp);
      }

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Verification error: $e');
      if (mounted) {
        String errorMessage = 'Verification failed. Check OTP.';
        if (e is DioException) {
          errorMessage = e.response?.data['message'] ?? e.message ?? 'Network error occurred';
        } else {
          errorMessage = e.toString();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage, style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
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

        if (_getOtpCode().length == 4) {
          _handleVerification();
        }
        return;
      } else {
        _otpControllers[index].text = digits[0];
        _otpControllers[index].selection = TextSelection.fromPosition(
          TextPosition(offset: 1),
        );
      }
    }

    if (value.isNotEmpty) {
      if (index < 3) {
        _otpFocusNodes[index + 1].requestFocus();
      } else {
        _otpFocusNodes[index].unfocus();
        _handleVerification();
      }
    } else if (value.isEmpty && index > 0) {
      // Backspace: move to previous field
      _otpFocusNodes[index - 1].requestFocus();
    }
  }

  String _getOtpCode() {
    return _otpControllers.map((controller) => controller.text).join();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;
    final isTablet = screenWidth > 600;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    const double smallScale = 0.80;
    const double mediumScale = 0.90;
    const double largeScale = 0.97;
    const double tabletScale = 1.20;

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
              filterQuality: FilterQuality.high,
              isAntiAlias: true,
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
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(height: 40.0 * scale),
                              _buildLogo(scale),
                              SizedBox(height: 40.0 * scale),
                              _buildTitle(scale),
                              SizedBox(height: 18.0 * scale),
                              _buildSubtitle(scale),
                              SizedBox(height: 20.0 * scale),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16.0 * scale),
                                child: _buildOtpField(scale),
                              ),
                              SizedBox(height: 24.0 * scale),
                              _buildVerifyButton(scale),
                              SizedBox(height: 24.0 * scale),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16.0 * scale),
                                child: _buildResendSection(scale),
                              ),
                              SizedBox(height: bottomInset > 0 ? bottomInset * 0.3 : 20.0 * scale),
                            ],
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
      widget.registrationData != null
          ? 'Verify your number to complete signup'
          : 'Enter verification code to login',
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.visible,
      softWrap: false,
      style: GoogleFonts.lexendDeca(
        fontSize: 18.0 * scale,
        fontWeight: FontWeight.w600,
        height: 1.25,
        color: _primaryTextColor,
      ),
    );
  }

  Widget _buildSubtitle(double scale) {
    return Text(
      'We have sent the OTP to ${widget.email}',
      textAlign: TextAlign.center,
      style: GoogleFonts.poppins(
        fontSize: 14.0 * scale,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: _labelColor,
      ),
    );
  }

  Widget _buildOtpField(double scale) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < 4; i++) ...[
          Expanded(child: _buildOtpDigitBox(i, scale)),
          if (i < 3) SizedBox(width: 10.0 * scale),
        ],
      ],
    );
  }

  Widget _buildOtpDigitBox(int index, double scale) {
    final hasValue = _otpControllers[index].text.isNotEmpty;
    return Container(
      height: 62.0 * scale,
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

  Widget _buildVerifyButton(double scale) {
    return GradientButton(
      text: _isVerifying ? 'Verifying...' : 'Verify OTP',
      height: 58.0 * scale,
      onPressed: _isVerifying ? () {} : _handleVerification,
    );
  }

  Widget _buildResendSection(double scale) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "If you didn't receive a code!  ",
              style: GoogleFonts.poppins(
                fontSize: 14.0 * scale,
                fontWeight: FontWeight.w500,
                color: _labelColor,
              ),
            ),
            if (_canResend)
              GestureDetector(
                onTap: _isResending ? null : _handleResend,
                child: Text(
                  _isResending ? 'Sending...' : 'Resend',
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
        SizedBox(height: 12.0 * scale),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20 * scale, vertical: 8 * scale),
            decoration: BoxDecoration(
              border: Border.all(color: _linkColor.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Change Email Address',
              style: GoogleFonts.poppins(
                fontSize: 14.0 * scale,
                fontWeight: FontWeight.w500,
                color: _linkColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
