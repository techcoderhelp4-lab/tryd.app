import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../data/referral_repository.dart';

class ShareEarnCard extends ConsumerWidget {
  final double scale;
  final double horizontalPadding;

  const ShareEarnCard({
    super.key,
    required this.scale,
    required this.horizontalPadding,
  });

  void _share(String code, int points) {
    Share.share(
      'Join me on Tryd and earn $points bonus points! '
      'Use my referral code: $code when you sign up. '
      'Download the app and start your fitness journey today! 💪',
      subject: 'Join Tryd & Earn $points Points!',
    );
  }

  void _copyCode(BuildContext context, String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Code copied!',
          style: GoogleFonts.poppins(fontSize: 13.0, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF8A0BBB),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Card always shows — home screen is only reachable when authenticated.
    // Use referral info for code + points; fall back gracefully while loading.
    final referralAsync = ref.watch(myReferralInfoProvider);
    final code = referralAsync.whenOrNull(data: (i) => i.referralCode);
    final pts = referralAsync.whenOrNull(data: (i) => i.pointsPerReferral) ?? 20;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF8A0BBB), Color(0xFFF52E6B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20 * scale),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF900EBF).withValues(alpha: 0.30),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20 * scale),
          child: Stack(
            children: [
              // Decorative circles removed

            // Content
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 14 * scale,
                vertical: 11 * scale,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.card_giftcard_rounded,
                    color: Colors.white,
                    size: 34 * scale,
                  ),

                  SizedBox(width: 14 * scale),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Invite & Earn $pts Points',
                          style: GoogleFonts.lexendDeca(
                            fontSize: 16 * scale,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.2,
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(height: 4 * scale),
                        Text(
                          'You each earn $pts pts when a friend joins',
                          style: GoogleFonts.poppins(
                            fontSize: 12 * scale,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.88),
                            height: 1.4,
                          ),
                        ),
                        if (code != null) ...[
                          SizedBox(height: 10 * scale),
                          GestureDetector(
                            onTap: () => _copyCode(context, code),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12 * scale,
                                vertical: 6 * scale,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                    BorderRadius.circular(10 * scale),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    code,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13 * scale,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF8A0BBB),
                                      letterSpacing: 3,
                                    ),
                                  ),
                                  SizedBox(width: 7 * scale),
                                  Icon(
                                    Icons.copy_all_rounded,
                                    size: 14 * scale,
                                    color: const Color(0xFF8A0BBB)
                                        .withValues(alpha: 0.6),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  SizedBox(width: 10 * scale),

                  // Invite / share button
                  Padding(
                    padding: EdgeInsets.only(right: 4 * scale),
                    child: GestureDetector(
                    onTap: () => _share(code ?? '', pts),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person_add_rounded,
                          color: Colors.white,
                          size: 32 * scale,
                        ),
                        SizedBox(height: 5 * scale),
                        Text(
                          'Invite',
                          style: GoogleFonts.poppins(
                            fontSize: 13 * scale,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.9),
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
  }
}
