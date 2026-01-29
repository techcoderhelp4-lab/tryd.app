import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/country_picker_dialog.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../widgets/gradient_button.dart';
import '../data/auth_repository.dart';
import "../../auth/presentation/signup_screen.dart";
import "../../home/presentation/home_screen.dart";

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  static const Color _primaryTextColor = Color(0xFF000000);
  static const Color _labelColor = Color(0xFF8B88B5);
  static const Color _inputTextColor = Color(0xFF221F48);
  static const Color _linkColor = Color(0xFFF83A71);
  static const Color _inputBgColor = Color(0xFFFFFFFF);
  static const int _otpTimerDuration = 60;
  static const int _maxResendAttempts = 3;

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  bool _isOtpSent = false;
  Timer? _otpTimer;
  int _otpTimeRemaining = _otpTimerDuration;
  bool _canResendOtp = false;
  int _resendAttempts = 0;
  int _dynamicMaxLength = 12;

  String _completePhoneNumber = '';
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _otpTimer?.cancel();
    super.dispose();
  }

  void _startOtpTimer() {
    _otpTimer?.cancel();
    setState(() {
      _otpTimeRemaining = _otpTimerDuration;
      _canResendOtp = false;
    });

    _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_otpTimeRemaining > 0) {
        setState(() {
          _otpTimeRemaining--;
        });
      } else {
        timer.cancel();
        setState(() {
          _canResendOtp = true;
        });
      }
    });
  }

  Future<void> _sendOtp() async {
    if (_phoneController.text.isNotEmpty && _completePhoneNumber.length >= 8) {
      if (_resendAttempts >= _maxResendAttempts) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Maximum resend attempts reached. Please try again later.',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final authRepo = ref.read(authRepositoryProvider);
        
        // 1. Check if user exists (Reverse of signup logic)
        final userExists = await authRepo.checkUserExists(_completePhoneNumber);

        if (!userExists) {
            if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(
                 content: Text(
                   'User not found with this number. Please Sign Up first.', 
                   style: GoogleFonts.poppins()
                 ), 
                 backgroundColor: Colors.red
               ),
             );
            }
             setState(() {
              _isLoading = false;
            });
            return;
        }

        // 2. User exists, Send OTP
        await authRepo.sendOtp(_completePhoneNumber);

        setState(() {
          _isOtpSent = true;
          _resendAttempts++;
        });
        _startOtpTimer();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'OTP sent successfully',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: const Color(0xFF900EBF),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to send OTP. Please try again.', style: GoogleFonts.poppins()), 
              backgroundColor: Colors.red
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid mobile number', style: GoogleFonts.poppins()), 
          backgroundColor: Colors.red
        ),
      );
    }
  }

  void _resendOtp() {
    if (_canResendOtp && _resendAttempts < _maxResendAttempts) {
      _sendOtp();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

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
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.084),
                child: Column(
                  children: [
                    const SizedBox(height: 136),
                    _buildLogo(),
                    const SizedBox(height: 52),
                    _buildTitle(),
                    const SizedBox(height: 48),
                    _buildInputFields(),
                    const SizedBox(height: 18),
                    _buildSignInButton(),
                    const SizedBox(height: 48),
                    _buildSignUpSection(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Image.asset(
      'assets/images/logo-full.png',
      width: 201,
      height: 80,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      isAntiAlias: true,
    );
  }

  Widget _buildTitle() {
    return Text(
      'Enter your mobile number\nto login account.',
      textAlign: TextAlign.center,
      style: GoogleFonts.lexendDeca(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.25,
        color: _primaryTextColor,
      ),
    );
  }

  Widget _buildInputFields() {
    return Column(
      children: [
        Container(
          height: 72,
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 27, vertical: 8), 
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Mobile No',
                  style: GoogleFonts.lexendDeca(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    height: 1.25,
                    color: _labelColor,
                  ),
                ),
                Expanded(
                  child: IntlPhoneField(
                    controller: _phoneController,
                    enabled: !_isOtpSent,
                    disableLengthCheck: true,
                    validator: (phone) => null,
                    decoration: InputDecoration(
                      hintText: '12456 65324',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: _labelColor,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      counterText: '',
                      errorStyle: const TextStyle(height: 0),
                    ),
                    initialCountryCode: 'KW', 
                    showDropdownIcon: true,
                    dropdownIconPosition: IconPosition.trailing,
                    flagsButtonPadding: const EdgeInsets.only(right: 8),
                    pickerDialogStyle: PickerDialogStyle(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.all(20),
                      countryCodeStyle: GoogleFonts.poppins(
                        fontSize: 16, 
                        fontWeight: FontWeight.w400,
                        color: _inputTextColor,
                      ),
                      countryNameStyle: GoogleFonts.poppins(
                        fontSize: 16, 
                        fontWeight: FontWeight.w400,
                        color: _inputTextColor,
                      ),
                      searchFieldInputDecoration: InputDecoration(
                        hintText: 'Search Country',
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: _labelColor,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        prefixIcon: const Icon(Icons.search, color: _labelColor),
                      ),
                    ),
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: _inputTextColor,
                      height: 1.5,
                    ),
                    dropdownTextStyle: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: _inputTextColor,
                    ),
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(_dynamicMaxLength),
                    ],
                    onCountryChanged: (country) {
                      setState(() {
                        _dynamicMaxLength = country.maxLength + 1;
                      });
                    },
                    onChanged: (phone) {
                      _completePhoneNumber = phone.completeNumber;
                      // print(phone.completeNumber);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: _isOtpSent
              ? Column(
                  children: [
                    const SizedBox(height: 18),
                    _buildInputField(
                      label: 'Enter OTP',
                      placeholder: '• • • • •',
                      controller: _otpController,
                      obscureText: true,
                      isOTP: true,
                    ),
                    const SizedBox(height: 12),
                    _buildTimerAndResend(),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  void _changeNumber() {
    setState(() {
      _isOtpSent = false;
      _otpController.clear();
      _otpTimer?.cancel();
      _otpTimeRemaining = _otpTimerDuration;
      _canResendOtp = false;
      _resendAttempts = 0;
    });
  }

  Widget _buildTimerAndResend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: _changeNumber,
          child: Text(
            'Change Number',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _labelColor,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        if (!_canResendOtp)
          Text(
            'Resend OTP in 0:${_otpTimeRemaining.toString().padLeft(2, '0')}',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: _labelColor,
            ),
          )
        else
          GestureDetector(
            onTap: _resendOtp,
            child: Text(
              'Resend OTP',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _linkColor,
                decoration: TextDecoration.underline,
                decorationColor: _linkColor,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required String placeholder,
    required TextEditingController controller,
    required bool obscureText,
    bool isOTP = false,
  }) {
    return Container(
      height: 72,
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 27, vertical: 13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.lexendDeca(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                height: 1.25,
                color: _labelColor,
              ),
            ),
            TextField(
              controller: controller,
              obscureText: obscureText,
              obscuringCharacter: '•',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.5,
                color: _inputTextColor,
              ),
              decoration: InputDecoration(
                hintText: placeholder,
                hintStyle: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                  color: _labelColor,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              keyboardType: isOTP ? TextInputType.number : TextInputType.phone,
              maxLength: null,
              buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignInButton() {
    return GradientButton(
      text: _isOtpSent ? (_isLoading ? 'Signing In...' : 'Sign in') : (_isLoading ? 'Sending...' : 'Send OTP'),
      onPressed: _isLoading ? () {} : () async {
        if (_isOtpSent) {
          if (_otpController.text.isNotEmpty) {
            
            setState(() {
              _isLoading = true;
            });

            try {
              final authRepo = ref.read(authRepositoryProvider);
              await authRepo.verifyOtpLogin(_completePhoneNumber, _otpController.text);

                if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => const HomeScreen(),
                  ),
                  (route) => false,
                );
              }
            } catch (e) {
               if (mounted) {
                 String errorMessage = 'Verification failed. Invalid OTP.';
                 if (e is DioException) {
                   errorMessage = e.response?.data['message'] ?? 'Connection error';
                 }
                 
                 ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(errorMessage, style: GoogleFonts.poppins()),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            } finally {
               if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
            }
          } else {
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
          }
        } else {
          _sendOtp();
        }
      },
    );
  }

  Widget _buildSignUpSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account?  ",
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.14,
            color: _labelColor,
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const SignupScreen(),
              ),
            );
          },
          child: Text(
            'Sign up',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.14,
              color: _linkColor,
            ),
          ),
        ),
      ],
    );
  }

}
