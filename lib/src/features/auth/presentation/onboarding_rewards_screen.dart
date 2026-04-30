import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../widgets/custom_bottom_navigation.dart';
import '../../../../widgets/gradient_button.dart';
import '../../../shell/main_shell.dart';

class OnboardingRewardsScreen extends StatefulWidget {
  final String userName;
  final int points;
  final int referralPoints;
  const OnboardingRewardsScreen({
    super.key,
    this.userName = '',
    this.points = 200,
    this.referralPoints = 0,
  });

  @override
  State<OnboardingRewardsScreen> createState() => _OnboardingRewardsScreenState();
}

class _OnboardingRewardsScreenState extends State<OnboardingRewardsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _cardScale;
  late Animation<double> _cardFade;
  late Animation<Offset> _cardSlide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
    _cardScale = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _cardFade  = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(const Duration(milliseconds: 180), () {
      if (mounted) _controller.forward();
    });
    _markSeen();
  }

  Future<void> _markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_rewards_seen', true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainShell()),
      (route) => false,
    );
  }

  String get _firstName {
    final name = widget.userName.trim();
    if (name.isEmpty) return '';
    return name.split(' ').first;
  }

  @override
  Widget build(BuildContext context) {
    final mq       = MediaQuery.of(context);
    final screenH  = mq.size.height;
    final screenW  = mq.size.width;
    final isTablet = screenW > 600;

    const double smallScale  = 0.65;
    const double mediumScale = 0.78;
    const double largeScale  = 0.88;
    const double tabletScale = 1.05;

    final double scale = isTablet
        ? tabletScale
        : screenH < 680
            ? smallScale
            : screenH < 850
                ? mediumScale
                : largeScale;

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: 2,
        onTap: (_) => _goHome(),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full bleed gradient — goes behind nav bar too
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFF83A71),
                  Color(0xFFBF1AB0),
                  Color(0xFFB040D8),
                ],
                stops: [0.0, 0.42, 1.0],
              ),
            ),
          ),

          // Content
          SafeArea(
            bottom: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: 12.0 * scale),

                        // Logo
                        Image.asset(
                          'assets/images/logo-full-white.png',
                          width: 190.0 * scale,
                          height: 76.0 * scale,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),

                        SizedBox(height: 48.0 * scale),

                        // Welcome text — single line, name trimmed to fit
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0 * scale),
                          child: RichText(
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            text: TextSpan(
                              style: GoogleFonts.lexend(
                                fontSize: 28.0 * scale,
                                fontWeight: FontWeight.w400,
                                color: Colors.white,
                                height: 1.2,
                              ),
                              children: [
                                const TextSpan(text: 'Welcome to '),
                                TextSpan(
                                  text: _firstName.isNotEmpty
                                      ? 'TRYD, $_firstName!'
                                      : 'TRYD!',
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: 10.0 * scale),

                        // Step Up — full width
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4.0 * scale),
                          child: FittedBox(
                            fit: BoxFit.fitWidth,
                            child: Text(
                              'Step Up Your Journey.',
                              style: GoogleFonts.lexend(
                                fontSize: 20.0 * scale,
                                fontWeight: FontWeight.w400,
                                color: Colors.white.withValues(alpha: 0.90),
                                letterSpacing: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),

                        SizedBox(height: 32.0 * scale),

                        // White card
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.0 * scale),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 450),
                            child: FadeTransition(
                              opacity: _cardFade,
                              child: SlideTransition(
                                position: _cardSlide,
                                child: ScaleTransition(
                                  scale: _cardScale,
                                  child: Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.fromLTRB(
                                      24.0 * scale,
                                      24.0 * scale,
                                      24.0 * scale,
                                      24.0 * scale,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(28.0 * scale),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.18),
                                          blurRadius: 30,
                                          spreadRadius: 2,
                                          offset: const Offset(0, 10),
                                        ),
                                        BoxShadow(
                                          color: const Color(0xFFF83A71).withValues(alpha: 0.10),
                                          blurRadius: 20,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Crown
                                        SvgPicture.asset(
                                          'assets/images/crown_icon.svg',
                                          width: 64.0 * scale,
                                          height: 64.0 * scale,
                                          colorFilter: const ColorFilter.mode(
                                            Color(0xFFFFB300),
                                            BlendMode.srcIn,
                                          ),
                                        ),

                                        SizedBox(height: 10.0 * scale),

                                        // Points display
                                        if (widget.referralPoints > 0) ...[
                                          // Two-column breakdown
                                          Padding(
                                            padding: EdgeInsets.symmetric(vertical: 8.0 * scale),
                                            child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              // Download
                                              Expanded(
                                                child: Column(
                                                  children: [
                                                    Text(
                                                      '+${widget.points - widget.referralPoints}',
                                                      style: GoogleFonts.lexend(
                                                        fontSize: 52.0 * scale,
                                                        fontWeight: FontWeight.w800,
                                                        color: const Color(0xFF1B2D51),
                                                        height: 1.0,
                                                      ),
                                                    ),
                                                    SizedBox(height: 4.0 * scale),
                                                    Text(
                                                      'DOWNLOAD',
                                                      style: GoogleFonts.lexend(
                                                        fontSize: 11.0 * scale,
                                                        fontWeight: FontWeight.w700,
                                                        color: const Color(0xFF8B88B5),
                                                        letterSpacing: 1.8,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              // Divider
                                              Container(
                                                width: 1.5,
                                                height: 54.0 * scale,
                                                color: const Color(0xFFE8E0F5),
                                              ),

                                              // Referral
                                              Expanded(
                                                child: Column(
                                                  children: [
                                                    Text(
                                                      '+${widget.referralPoints}',
                                                      style: GoogleFonts.lexend(
                                                        fontSize: 52.0 * scale,
                                                        fontWeight: FontWeight.w800,
                                                        color: const Color(0xFF8A0BBB),
                                                        height: 1.0,
                                                      ),
                                                    ),
                                                    SizedBox(height: 4.0 * scale),
                                                    Text(
                                                      'REFERRAL',
                                                      style: GoogleFonts.lexend(
                                                        fontSize: 11.0 * scale,
                                                        fontWeight: FontWeight.w700,
                                                        color: const Color(0xFF8B88B5),
                                                        letterSpacing: 1.8,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          ),
                                        ] else ...[
                                          // Original single number
                                          Text(
                                            '+${widget.points}',
                                            style: GoogleFonts.lexend(
                                              fontSize: 64.0 * scale,
                                              fontWeight: FontWeight.w800,
                                              color: const Color(0xFF1B2D51),
                                              height: 1.0,
                                            ),
                                          ),
                                          SizedBox(height: 4.0 * scale),
                                          Text(
                                            'POINTS',
                                            style: GoogleFonts.lexend(
                                              fontSize: 18.0 * scale,
                                              fontWeight: FontWeight.w800,
                                              color: const Color(0xFF8B88B5),
                                              letterSpacing: 2.5,
                                            ),
                                          ),
                                        ],

                                        SizedBox(height: 20.0 * scale),

                                        // Button
                                        GradientButton(
                                          text: 'Claim Your Welcome Reward!',
                                          onPressed: _goHome,
                                          width: double.infinity,
                                          height: 64.0 * scale,
                                          showIcon: false,
                                          textStyle: GoogleFonts.lexendDeca(
                                            fontSize: 20.0 * scale,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 80.0 * scale),
                      ],
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
}
