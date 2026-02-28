import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import '../../../../widgets/gradient_button.dart';
import '../data/auth_repository.dart';
import 'otp_verification_screen.dart';
import 'signup_details_screen.dart';
import '../../../../core/utils/snackbar_utils.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  static const Color _primaryTextColor = Color(0xFF000000);
  static const Color _labelColor = Color(0xFF8B88B5);
  static const Color _inputTextColor = Color(0xFF221F48);
  static const Color _inputBgColor = Color(0xFFFFFFFF);

  bool _isLoading = false;
  String _loadingText = '';

  final TextEditingController _emailController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_isLoading) return;

    final email = _emailController.text.trim();
    final emailRegex = RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");

    if (email.isEmpty || !emailRegex.hasMatch(email)) {
      CustomSnackBar.show(context, message: 'Please enter a valid email address');
      return;
    }

    // Dismiss keyboard before API call
    _emailFocusNode.unfocus();

    setState(() {
      _isLoading = true;
      _loadingText = 'Checking...';
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);

      final userExists = await authRepo.checkUserExists(email: email);

      if (!mounted) return;

      if (userExists) {
        setState(() => _loadingText = 'Sending OTP...');
        await authRepo.sendOtp(email);

        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => OtpVerificationScreen(
                email: email,
                isLogin: true,
              ),
            ),
          );
        }
      } else {
        setState(() => _loadingText = 'Sending OTP...');
        await authRepo.sendOtp(email);

        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => SignupDetailsScreen(
                email: email,
              ),
            ),
          );
        }
      }
    } on DioException catch (e) {
      if (mounted) {
        final msg = e.response?.data['message'] ?? 'Network error. Check your connection.';
        CustomSnackBar.show(context, message: msg);
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(context, message: 'Something went wrong. Try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingText = '';
        });
      }
    }
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
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
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
                          constraints: BoxConstraints(maxWidth: isTablet ? 480 : 340),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: (isTablet ? 32.0 : 24.0) * scale),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(height: 40.0 * scale),
                                _buildLogo(scale),
                                SizedBox(height: 40.0 * scale),
                                _buildTitle(scale),
                                SizedBox(height: 18.0 * scale),
                                _buildSubtitle(scale),
                                SizedBox(height: 30.0 * scale),
                                _buildInputFields(scale),
                                SizedBox(height: 18.0 * scale),
                                _buildSubmitButton(scale),
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
          ],
        ),
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
      'Enter your email address\nto get started.',
      textAlign: TextAlign.center,
      style: GoogleFonts.lexendDeca(
        fontSize: 20.0 * scale,
        fontWeight: FontWeight.w600,
        height: 1.25,
        color: _primaryTextColor,
      ),
    );
  }

  Widget _buildSubtitle(double scale) {
    return Text(
      'Sign in or join to reach your\npeak performance today',
      textAlign: TextAlign.center,
      style: GoogleFonts.poppins(
        fontSize: 14.0 * scale,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: _labelColor,
      ),
    );
  }

  Widget _buildInputFields(double scale) {
    return AutofillGroup(
      child: Container(
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
          padding: EdgeInsets.symmetric(horizontal: 16.0 * scale, vertical: 16.0 * scale),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Email Address',
                style: GoogleFonts.lexendDeca(
                  fontSize: 12.0 * scale,
                  fontWeight: FontWeight.w500,
                  height: 1.25,
                  color: _labelColor,
                  letterSpacing: 0.2,
                ),
              ),
              SizedBox(height: 8.0 * scale),
              TextField(
                controller: _emailController,
                focusNode: _emailFocusNode,
                autofocus: true,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.email],
                onSubmitted: (_) => _handleSubmit(),
                style: GoogleFonts.poppins(
                  fontSize: 16.0 * scale,
                  fontWeight: FontWeight.w500,
                  color: _inputTextColor,
                  height: 1.4,
                ),
                decoration: InputDecoration(
                  hintText: 'example@mail.com',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 16.0 * scale,
                    fontWeight: FontWeight.w400,
                    color: _labelColor.withValues(alpha: 0.5),
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(double scale) {
    return GradientButton(
      text: _isLoading ? _loadingText : 'Continue',
      height: 58.0 * scale,
      onPressed: _isLoading ? () {} : _handleSubmit,
    );
  }
}
