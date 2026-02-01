import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/country_picker_dialog.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../widgets/gradient_button.dart';
import '../data/auth_repository.dart';
import 'otp_verification_screen.dart';
import 'login_screen.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  static const Color _primaryTextColor = Color(0xFF000000);
  static const Color _labelColor = Color(0xFF8B88B5);
  static const Color _inputTextColor = Color(0xFF221F48);
  static const Color _linkColor = Color(0xFFF83A71);
  static const Color _inputBgColor = Color(0xFFFFFFFF);

  int _dynamicMaxLength = 12;
  String _completePhoneNumber = '';
  bool _isLoading = false;
  final TextEditingController _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (_phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('Please enter your mobile number', style: GoogleFonts.poppins()), backgroundColor: Colors.red),
      );
      return;
    }
    
    // Basic validation
    if (_completePhoneNumber.length < 8) {
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('Please enter a valid mobile number', style: GoogleFonts.poppins()), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // ---------------------------------------------------------
      // STEP 1: Check if phone number already exists 
      // ---------------------------------------------------------
      final authRepo = ref.read(authRepositoryProvider);
      final userAlreadyExists = await authRepo.checkUserExists(_completePhoneNumber);

      if (userAlreadyExists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'This mobile number is already registered.',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Login',
                textColor: Colors.white,
                onPressed: () {
                  Navigator.of(context).pop(); // Go back to login screen
                },
              ),
            ),
          );
        }
        return; // Stop execution here
      }

      // ---------------------------------------------------------
      // STEP 2: Send OTP if user does NOT exist
      // ---------------------------------------------------------
      await authRepo.sendOtp(_completePhoneNumber);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OTP sent successfully', style: GoogleFonts.poppins()),
            backgroundColor: const Color(0xFF900EBF),
          ),
        );
        
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => OtpVerificationScreen(
              phoneNumber: _completePhoneNumber,
            ),
          ),
        );
      }
    } catch (e) {
      print('Signup Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Something went wrong. Please try again.', style: GoogleFonts.poppins()), backgroundColor: Colors.red),
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
                              SizedBox(height: 18.h),
                              _buildInputFields(),
                              SizedBox(height: 18.h),
                              _buildSignUpButton(),
                              SizedBox(height: 48.h),
                              _buildSignInSection(),
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
      'Enter your mobile number\nto create account.',
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
      'We will send you one time\npassword (OTP)',
      textAlign: TextAlign.center,
      style: GoogleFonts.poppins(
        fontSize: 14.sp,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: _labelColor,
      ),
    );
  }

  Widget _buildInputFields() {
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
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 27.w, vertical: 8.h), 
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Mobile Number',
              style: GoogleFonts.lexendDeca(
                fontSize: 12.sp,
                fontWeight: FontWeight.w400,
                height: 1.25,
                color: _labelColor,
              ),
            ),
            SizedBox(height: 2.h),
            Expanded(
              child: IntlPhoneField(
                controller: _phoneController,
                disableLengthCheck: true,
                validator: (phone) => null,
                decoration: InputDecoration(
                  hintText: '12456 65324',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w400,
                    color: _labelColor,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.only(top: 4.h),
                  counterText: '',
                  errorStyle: const TextStyle(height: 0),
                ),
                initialCountryCode: 'KW', 
                showDropdownIcon: true,
                dropdownIconPosition: IconPosition.trailing,
                flagsButtonPadding: EdgeInsets.only(right: 8.w),
                pickerDialogStyle: PickerDialogStyle(
                  backgroundColor: Colors.white,
                  padding: EdgeInsets.all(20.w),
                  countryCodeStyle: GoogleFonts.poppins(
                    fontSize: 16.sp, 
                    fontWeight: FontWeight.w400,
                    color: _inputTextColor,
                  ),
                  countryNameStyle: GoogleFonts.poppins(
                    fontSize: 16.sp, 
                    fontWeight: FontWeight.w400,
                    color: _inputTextColor,
                  ),
                  searchFieldInputDecoration: InputDecoration(
                    hintText: 'Search Country',
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                      color: _labelColor,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                    prefixIcon: const Icon(Icons.search, color: _labelColor),
                  ),
                ),
                style: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w400,
                  color: _inputTextColor,
                  height: 1.25,
                ),
                dropdownTextStyle: GoogleFonts.poppins(
                  fontSize: 16.sp,
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
                },
              ),
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
    required bool obscureText,
  }) {
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
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 27.w, vertical: 13.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.lexendDeca(
                fontSize: 12.sp,
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
                fontSize: 14.sp,
                fontWeight: FontWeight.w400,
                height: 1.5,
                color: _inputTextColor,
              ),
              decoration: InputDecoration(
                hintText: placeholder,
                hintStyle: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                  color: _labelColor,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignUpButton() {
    return GradientButton(
      text: _isLoading ? 'Please wait...' : 'Sign up',
      onPressed: _isLoading ? () {} : _handleSignup,
    );
  }

  Widget _buildSignInSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'If you have an account?  ',
          style: GoogleFonts.poppins(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            height: 1.14,
            color: _labelColor,
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          },
          child: Text(
            'Sign In',
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
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
