import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../widgets/custom_bottom_navigation.dart';
import '../../../../widgets/gradient_button.dart';
import 'package:tryd/src/generated/l10n/app_localizations.dart';
import '../../../../widgets/swipe_to_pop_wrapper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shell/main_shell.dart' show mainNavTapProvider;

// Large multiplier for infinite-loop illusion
const int _kLoopMultiplier = 500;

class AddTimeScreen extends ConsumerStatefulWidget {
  final String title;
  final int initialSeconds;

  const AddTimeScreen({
    super.key,
    required this.title,
    required this.initialSeconds,
  });

  @override
  ConsumerState<AddTimeScreen> createState() => _AddTimeScreenState();
}

class _AddTimeScreenState extends ConsumerState<AddTimeScreen> {
  static const _accent   = Color(0xFF900EBF);
  static const _primary  = Color(0xFF24252C);

  final int _tabIndex = 3;

  late FixedExtentScrollController _mCtrl;
  late FixedExtentScrollController _sCtrl;

  static const int _mCount = 61; // 0–60 minutes
  static const int _sStep  = 5;
  static const int _sCount = 12; // 0,5,10,...,55

  int _minutes = 0;
  int _seconds = 0;

  bool get _secsDisabled => _minutes == 60;
  int get _sIndex => _seconds ~/ _sStep;
  int get _totalSeconds => _minutes * 60 + (_secsDisabled ? 0 : _seconds);

  @override
  void initState() {
    super.initState();
    int init = widget.initialSeconds;
    if (init <= 0) init = 45;
    init = init.clamp(5, 3600);

    _minutes = (init ~/ 60).clamp(0, 60);
    _seconds = _minutes == 60 ? 0 : ((init % 60) ~/ _sStep * _sStep).clamp(0, 55);

    _mCtrl = FixedExtentScrollController(initialItem: (_kLoopMultiplier ~/ 2) * _mCount + _minutes);
    _sCtrl = FixedExtentScrollController(initialItem: (_kLoopMultiplier ~/ 2) * _sCount + _sIndex);
  }

  @override
  void dispose() {
    _mCtrl.dispose();
    _sCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size        = MediaQuery.of(context).size;
    final isTablet    = size.width > 600;
    final h           = size.height;
    final scale       = isTablet ? 1.3 : h < 680 ? 0.85 : h < 850 ? 0.98 : 0.95;
    final l10n        = AppLocalizations.of(context)!;
    final isRTL       = Localizations.localeOf(context).languageCode == 'ar';
    final fontScale   = isRTL ? 1.2 : 1.0;

    return SwipeToPopWrapper(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.8,
                child: Image.asset('assets/images/bg-gradient.png', fit: BoxFit.cover),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  SizedBox(height: 10.0 * scale),
                  _header(context, isTablet, scale, isRTL, fontScale),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 120.0 * scale),
                        child: Column(
                          children: [
                            SizedBox(height: 28.0 * scale),
                            _clockBadge(scale),
                            SizedBox(height: 32.0 * scale),
                            _picker(scale, fontScale, l10n),
                            SizedBox(height: 40.0 * scale),
                            _continueBtn(scale, l10n, isRTL, fontScale),
                            SizedBox(height: 20.0 * scale),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: CustomBottomNavigation(
                currentIndex: _tabIndex,
                onTap: (i) {
                  if (i == 3) { Navigator.of(context).pop(); return; }
                  Navigator.of(context).popUntil((r) => r.isFirst);
                  ref.read(mainNavTapProvider)?.call(i);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────
  Widget _header(BuildContext ctx, bool isTablet, double scale, bool isRTL, double fontScale) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: (isTablet ? 20.0 : 26.0) * scale),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(ctx),
            child: SizedBox(
              width: 40.0 * scale, height: 40.0 * scale,
              child: Center(
                child: SvgPicture.asset(
                  'assets/images/back_arrow_icon.svg',
                  width: 24.0 * scale, height: 24.0 * scale,
                  matchTextDirection: true,
                ),
              ),
            ),
          ),
          Text(
            widget.title,
            style: isRTL
                ? GoogleFonts.cairo(fontSize: 19.0 * scale * fontScale, fontWeight: FontWeight.w700, color: _primary)
                : GoogleFonts.lexendDeca(fontSize: 19.0 * scale, fontWeight: FontWeight.w600, color: _primary),
          ),
          SizedBox(width: 40.0 * scale),
        ],
      ),
    );
  }

  // ── Clock badge ───────────────────────────────────────────
  Widget _clockBadge(double scale) {
    return Container(
      width: 110.0 * scale, height: 110.0 * scale,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFFFD66B), width: 2.0 * scale),
      ),
      child: Container(
        margin: EdgeInsets.all(9.0 * scale),
        decoration: const BoxDecoration(shape: BoxShape.circle, color: _accent),
        child: Center(
          child: Icon(Icons.access_time_rounded, size: 44.0 * scale, color: Colors.white),
        ),
      ),
    );
  }

  // ── Picker ────────────────────────────────────────────────
  Widget _picker(double scale, double fontScale, AppLocalizations l10n) {
    const itemH = 58.0;
    final itemHeight = itemH * scale;
    final pickerH    = itemHeight * 5;

    final labelStyle = GoogleFonts.lexend(
      fontSize: 11.0 * scale,
      fontWeight: FontWeight.w700,
      color: _accent,
      letterSpacing: 1.2,
    );

    final sepStyle = GoogleFonts.lexend(
      fontSize: 30.0 * scale,
      fontWeight: FontWeight.w200,
      color: _primary.withValues(alpha: 0.25),
      height: 1.0,
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.0 * scale),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(24.0 * scale),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24.0 * scale),
          child: Column(
            children: [
              SizedBox(
                height: pickerH,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Selection lines
                    Positioned(
                      top: (pickerH - itemHeight) / 2,
                      left: 12.0 * scale, right: 12.0 * scale,
                      child: Container(height: 1.5, color: _accent.withValues(alpha: 0.35)),
                    ),
                    Positioned(
                      top: (pickerH + itemHeight) / 2 - 1.5,
                      left: 12.0 * scale, right: 12.0 * scale,
                      child: Container(height: 1.5, color: _accent.withValues(alpha: 0.35)),
                    ),

                    // Columns + separator — always LTR so MIN stays left, SEC stays right
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Minutes
                        Expanded(
                          child: _InfinitePickerColumn(
                            controller: _mCtrl,
                            itemHeight: itemHeight,
                            itemCount: _mCount,
                            loopMultiplier: _kLoopMultiplier,
                            selectedValue: _minutes,
                            valueAt: (i) => i.toString().padLeft(2, '0'),
                            onChanged: (i) {
                              HapticFeedback.selectionClick();
                              final mins = i % _mCount;
                              setState(() {
                                _minutes = mins;
                                // snap seconds to 0 when 60 min selected
                                if (_secsDisabled) _seconds = 0;
                              });
                            },
                            scale: scale,
                            fontScale: fontScale,
                          ),
                        ),
                        Text(':', style: sepStyle),
                        // Seconds — disabled at 60 min
                        Expanded(
                          child: AnimatedOpacity(
                            opacity: _secsDisabled ? 0.25 : 1.0,
                            duration: const Duration(milliseconds: 200),
                            child: IgnorePointer(
                              ignoring: _secsDisabled,
                              child: _InfinitePickerColumn(
                                controller: _sCtrl,
                                itemHeight: itemHeight,
                                itemCount: _sCount,
                                loopMultiplier: _kLoopMultiplier,
                                selectedValue: _secsDisabled ? 0 : _sIndex,
                                valueAt: (i) => (i * _sStep).toString().padLeft(2, '0'),
                                onChanged: (i) {
                                  HapticFeedback.selectionClick();
                                  setState(() => _seconds = (i % _sCount) * _sStep);
                                },
                                scale: scale,
                                fontScale: fontScale,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    ),
                  ],
                ),
              ),

              // Labels bar
              Directionality(
                textDirection: TextDirection.ltr,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 10.0 * scale),
                  child: Row(
                    children: [
                      Expanded(child: Center(child: Text(l10n.minutesShort, style: labelStyle))),
                      SizedBox(width: 16.0 * scale),
                      Expanded(
                        child: Center(
                          child: Text(
                            l10n.secondsShort,
                            style: labelStyle.copyWith(
                              color: _secsDisabled ? _accent.withValues(alpha: 0.25) : _accent,
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
        ),
      ),
    );
  }

  // ── Continue button ───────────────────────────────────────
  Widget _continueBtn(double scale, AppLocalizations l10n, bool isRTL, double fontScale) {
    final total = _totalSeconds.clamp(5, 3600);
    final isValid = _totalSeconds > 0;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 36.0 * scale),
      child: GradientButton(
        text: l10n.continueButton,
        onPressed: () => Navigator.pop(context, total),
        height: 58.0 * scale,
        enabled: isValid,
        textStyle: isRTL
            ? GoogleFonts.cairo(fontSize: 19.0 * fontScale, fontWeight: FontWeight.w600, color: Colors.white)
            : null,
      ),
    );
  }
}

// ── Infinite looping picker column ────────────────────────────
class _InfinitePickerColumn extends StatelessWidget {
  static const _primary = Color(0xFF24252C);

  final FixedExtentScrollController controller;
  final double itemHeight;
  final int itemCount;
  final int loopMultiplier;
  final int selectedValue; // actual 0..itemCount-1 index
  final String Function(int) valueAt;
  final ValueChanged<int> onChanged;
  final double scale;
  final double fontScale;

  const _InfinitePickerColumn({
    required this.controller,
    required this.itemHeight,
    required this.itemCount,
    required this.loopMultiplier,
    required this.selectedValue,
    required this.valueAt,
    required this.onChanged,
    required this.scale,
    required this.fontScale,
  });

  @override
  Widget build(BuildContext context) {
    final totalItems = itemCount * loopMultiplier;

    return CupertinoPicker.builder(
      scrollController: controller,
      itemExtent: itemHeight,
      selectionOverlay: const SizedBox.shrink(),
      backgroundColor: Colors.transparent,
      diameterRatio: 1.6,
      squeeze: 1.0,
      magnification: 1.08,
      useMagnifier: true,
      onSelectedItemChanged: onChanged,
      childCount: totalItems,
      itemBuilder: (context, globalIndex) {
        final i          = globalIndex % itemCount;
        final isSelected = i == selectedValue;
        final distance   = (i - selectedValue).abs();
        final distWrap   = distance > itemCount / 2 ? itemCount - distance : distance;
        final opacity    = isSelected ? 1.0 : distWrap == 1 ? 0.5 : 0.22;

        return Center(
          child: Text(
            valueAt(i),
            style: GoogleFonts.lexend(
              fontSize: (isSelected ? 28.0 : 23.0) * scale * fontScale,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
              color: _primary.withValues(alpha: opacity),
              height: 1.0,
            ),
          ),
        );
      },
    );
  }
}
