import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../widgets/gradient_button.dart';
import 'package:tryd/src/features/auth/data/auth_repository.dart';
import "../../home/presentation/home_screen.dart";

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String phoneNumber;

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
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
  static const Color _dividerColor = Color(0x1A000000); // 10% opacity

  final List<TextEditingController> _otpControllers = List.generate(
    4,
    (index) => TextEditingController(),
  );

  final List<FocusNode> _otpFocusNodes = List.generate(
    4,
    (index) => FocusNode(),
  );

  bool _isLoading = false;

  @override
  void dispose() {
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
    if (otp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter OTP',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      
      // Call real verification API
      // Since our verification API returns a token, the repository handles saving it.
      await authRepo.verifyOtp(widget.phoneNumber, otp);

      if (mounted) {
        // Show success message
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verified successfully!', style: GoogleFonts.poppins()),
            backgroundColor: const Color(0xFF22D198),
          ),
        );

        // Navigate to Home
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      print('OTP Verification Error: $e');
      if (mounted) {
        String errorMessage = 'Verification failed';
        // You might want to parse 'e' to see if it's a DioException and show specific message (e.g. Invalid OTP)
        
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage, style: GoogleFonts.poppins()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onOtpDigitChanged(String value, int index) {
    if (value.isNotEmpty && index < 3) {
      _otpFocusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _otpFocusNodes[index - 1].requestFocus();
    }
  }

  String _getOtpCode() {
    return _otpControllers.map((controller) => controller.text).join();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 450),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24.w),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(height: 40.h),
                              _buildLogo(),
                              SizedBox(height: 40.h),
                              _buildTitle(),
                              SizedBox(height: 18.h),
                              _buildSubtitle(),
                              SizedBox(height: 44.h),
                              _buildOtpField(),
                              SizedBox(height: 18.h),
                              _buildVerifyButton(),
                              SizedBox(height: 48.h),
                              _buildResendSection(),
                              SizedBox(height: 20.h),
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
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Image.asset(
      'assets/images/logo-full.png',
      width: 201.w,
      height: 80.h,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      isAntiAlias: true,
    );
  }

  Widget _buildTitle() {
    return Text(
      'Mobile verification has\nsuccessfully done',
      textAlign: TextAlign.center,
      style: GoogleFonts.lexendDeca(
        fontSize: 20.sp,
        fontWeight: FontWeight.w600,
        height: 1.25,
        color: _primaryTextColor,
      ),
    );
  }

  Widget _buildSubtitle() {
    return Text(
      'We have send the OTP on ${widget.phoneNumber}\nwill apply auto to the fields',
      textAlign: TextAlign.center,
      style: GoogleFonts.poppins(
        fontSize: 14.sp,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: _labelColor,
      ),
    );
  }

  Widget _buildOtpField() {
    return Container(
      height: 72.h,
      decoration: BoxDecoration(
        color: _inputBgColor,
        borderRadius: BorderRadius.circular(17),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 0),
            blurRadius: 5.8,
            spreadRadius: 0,
            color: const Color(0xFFAFA9A9).withValues(alpha: 0.12),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int i = 0; i < 4; i++) ...[
            if (i > 0) _buildDivider(),
            _buildOtpDigitBox(i),
          ],
        ],
      ),
    );
  }

  Widget _buildOtpDigitBox(int index) {
    return SizedBox(
      width: 50.w,
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _otpFocusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: GoogleFonts.poppins(
          fontSize: 20.sp,
          fontWeight: FontWeight.w400,
          height: 1.5,
          color: _inputTextColor,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          counterText: '',
          contentPadding: EdgeInsets.zero,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        onChanged: (value) => _onOtpDigitChanged(value, index),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1.w,
      height: 32.h,
      color: _dividerColor,
      margin: EdgeInsets.symmetric(horizontal: 10.w),
    );
  }

  Widget _buildVerifyButton() {
    return GradientButton(
      text: _isLoading ? 'Verifying...' : 'Verify OTP',
      onPressed: _isLoading ? () {} : _handleVerification,
    );
  }

  Widget _buildResendSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "If you didn't receive a code!  ",
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                height: 1.14,
                color: _labelColor,
              ),
            ),
            GestureDetector(
              onTap: () {
                // Handle resend OTP
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'OTP resent successfully',
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: const Color(0xFF900EBF),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Text(
                'Resend',
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  height: 1.14,
                  color: _linkColor,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 24.h),
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Text(
            'Change Number',
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: _labelColor,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}
