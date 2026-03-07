import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import '../../../../widgets/custom_arrow_icon.dart';
import '../../../../widgets/custom_chevron_icon.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_constants.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/auth_screen.dart';
import '../../notifications/data/real_time_notification_service.dart';
import 'package:tryd/src/generated/l10n/app_localizations.dart';
import '../../../../main.dart' show localeProvider;

// ── Notification Preferences Provider ────────────────
final notificationPrefsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.read(apiClientProvider);
  final response = await dio.get(ApiConstants.notificationPreferences);
  return Map<String, dynamic>.from(response.data);
});

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // ── Colors ─────────────────────────────────────────
  static const _primaryColor = Color(0xFF900EBF);
  static const _accentColor = Color(0xFFF83A71);
  static const _textDark = Color(0xFF24252C);
  static const _textMuted = Color(0xFF8B88B5);
  static const _cardBorder = Color(0xFFF5F3F3);
  static const _dangerColor = Color(0xFFE53935);

  // ── Notification prefs state ───────────────────────
  Map<String, dynamic>? _prefs;
  bool _prefsLoading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.get(ApiConstants.notificationPreferences);
      if (mounted) {
        setState(() {
          _prefs = Map<String, dynamic>.from(response.data);
          _prefsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _prefsLoading = false);
    }
  }

  Future<void> _updatePref(String path, bool value) async {
    if (_saving) return;
    setState(() => _saving = true);

    // Optimistic update
    final keys = path.split('.');
    if (keys.length == 2 && _prefs != null) {
      final section = Map<String, dynamic>.from(_prefs![keys[0]] ?? {});
      section[keys[1]] = value;
      _prefs![keys[0]] = section;
    }
    setState(() {});

    try {
      final dio = ref.read(apiClientProvider);
      if (keys[0] == 'globalPreferences') {
        await dio.put(ApiConstants.notificationPreferencesGlobal, data: {keys[1]: value});
      } else {
        await dio.put(ApiConstants.notificationPreferences, data: {
          keys[0]: {keys[1]: value}
        });
      }
    } catch (e) {
      // Revert on failure
      if (keys.length == 2 && _prefs != null) {
        final section = Map<String, dynamic>.from(_prefs![keys[0]] ?? {});
        section[keys[1]] = !value;
        _prefs![keys[0]] = section;
      }
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.failedToUpdatePreference)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  bool _getPref(String path) {
    if (_prefs == null) return false;
    final keys = path.split('.');
    if (keys.length == 2) {
      final section = _prefs![keys[0]];
      if (section is Map) return section[keys[1]] == true;
    }
    return false;
  }

  Future<void> _handleChangePassword(double scale) async {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _ChangePasswordDialog(
        currentController: currentController,
        newController: newController,
        confirmController: confirmController,
        scale: scale,
      ),
    );

    if (result != true) return;

    try {
      final dio = ref.read(apiClientProvider);
      await dio.put(ApiConstants.changePassword, data: {
        'currentPassword': currentController.text,
        'newPassword': newController.text,
      });
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ref.read(realTimeNotificationServiceProvider).showInAppBanner(
          l10n.passwordChanged,
          l10n.passwordUpdatedSuccess,
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        String msg = l10n.somethingWentWrong;
        if (e is DioException) {
          msg = e.response?.data['message'] ?? msg;
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    }
  }

  Future<void> _handleDeleteAccount(double scale) async {
    final l10n = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final fontScale = isAr ? 1.15 : 1.0;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
            side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 32.0, left: 24.0, right: 24.0, bottom: 24.0),
                child: Column(
                  children: [
                    Text(
                      l10n.deleteAccountTitle,
                    style: GoogleFonts.lexend(
                      fontSize: 20.0 * fontScale,
                      fontWeight: FontWeight.w600,
                      color: _textDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12.0),
                  Text(
                    l10n.deleteAccountWarning,
                    style: GoogleFonts.lexend(
                      fontSize: 14.0 * fontScale,
                      color: _textDark.withValues(alpha: 0.8),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0xFFE5E7EB), height: 1, thickness: 1),
            InkWell(
              onTap: () => Navigator.pop(context, true),
              borderRadius: BorderRadius.zero,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                alignment: Alignment.center,
                child: Text(
                  l10n.deleteAccountButton,
                  style: GoogleFonts.lexend(
                    fontSize: 16.0 * fontScale,
                    color: _dangerColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const Divider(color: Color(0xFFE5E7EB), height: 1, thickness: 1),
            InkWell(
              onTap: () => Navigator.pop(context, false),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20.0),
                bottomRight: Radius.circular(20.0),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                alignment: Alignment.center,
                child: Text(
                  l10n.cancelButton,
                  style: GoogleFonts.lexend(
                    fontSize: 16.0 * fontScale,
                    color: _textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    try {
      final dio = ref.read(apiClientProvider);
      await dio.delete(ApiConstants.deleteAccount);
      await ref.read(authRepositoryProvider).logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        String msg = 'Failed to delete account';
        if (e is DioException) {
          msg = e.response?.data['message'] ?? msg;
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    }
  }

  Future<void> _handleLogout() async {
    await ref.read(authRepositoryProvider).logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;

    final double scale = isTablet
        ? 1.30
        : screenHeight < 680
            ? 0.85
            : screenHeight < 850
                ? 0.98
                : 1.05;

    final l10n = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final fontScale = isAr ? 1.15 : 1.0;

    final horizontalPadding = 18.0 * scale;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background
          Container(color: const Color(0xFFF7E6EB)),

          // Header background
          Positioned(
            top: 0, left: 0, right: 0,
            height: 120 * scale,
            child: Container(color: const Color(0xFFF7E6EB)),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 26.0 * scale, vertical: 16.0 * scale),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40.0 * scale,
                          height: 40.0 * scale,
                          alignment: Alignment.center,
                          child: Transform.scale(
                            scaleX: isAr ? 1.0 : -1.0,
                            child: CustomArrowIcon(
                              size: 28.0 * scale,
                              color: const Color(0xFF130F26),
                            ),
                          ),
                        ),
                      ),
                      Text(
                        l10n.settingsTitle,
                        style: GoogleFonts.lexendDeca(
                          fontSize: 19.0 * scale * fontScale,
                          fontWeight: FontWeight.w600,
                          color: _textDark,
                        ),
                      ),
                      SizedBox(width: 40.0 * scale),
                    ],
                  ),
                ),

                // Scrollable content
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                      child: ListView(
                        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 24 * scale),
                        children: [
                          // ── Notifications Section ──────
                          _buildSectionTitle(l10n.notificationsSection, scale, fontScale),
                          SizedBox(height: 10 * scale),
                          _buildToggleItem(
                            icon: Icons.notifications_active_outlined,
                            title: l10n.pushNotifications,
                            value: _getPref('globalPreferences.push'),
                            onChanged: (v) => _updatePref('globalPreferences.push', v),
                            scale: scale,
                            fontScale: fontScale,
                            loading: _prefsLoading,
                          ),
                          SizedBox(height: 8 * scale),
                          _buildToggleItem(
                            icon: Icons.chat_bubble_outline,
                            title: l10n.inAppNotifications,
                            value: _getPref('globalPreferences.inApp'),
                            onChanged: (v) => _updatePref('globalPreferences.inApp', v),
                            scale: scale,
                            fontScale: fontScale,
                            loading: _prefsLoading,
                          ),

                          SizedBox(height: 24 * scale),

                          // ── Language Section ───────────
                          _buildSectionTitle(isAr ? 'اللغة' : 'Language', scale, fontScale),
                          SizedBox(height: 10 * scale),
                          _buildLangItem(scale, fontScale, isAr),

                          SizedBox(height: 24 * scale),

                          // ── About Section ──────────────
                          _buildSectionTitle(l10n.aboutSection, scale, fontScale),
                          SizedBox(height: 10 * scale),
                          _buildMenuItem(
                            icon: Icons.info_outline,
                            title: l10n.appVersionLabel,
                            trailing: Text(
                              'v1.0.0',
                              style: GoogleFonts.poppins(fontSize: 14 * scale * fontScale, color: _textMuted),
                            ),
                            scale: scale,
                            fontScale: fontScale,
                            isAr: isAr,
                          ),

                          SizedBox(height: 32 * scale),

                          // ── Logout Button ──────────────
                          GestureDetector(
                            onTap: _handleLogout,
                            child: Container(
                              height: 56 * scale,
                              decoration: BoxDecoration(
                                border: Border.all(color: _dangerColor.withValues(alpha: 0.3)),
                                borderRadius: BorderRadius.circular(15 * scale),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                l10n.logoutButton,
                                style: GoogleFonts.poppins(
                                  fontSize: 16 * scale * fontScale,
                                  fontWeight: FontWeight.w600,
                                  color: _dangerColor,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: 40 * scale),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLangItem(double scale, double fontScale, bool isAr) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        ref.read(localeProvider.notifier).setLocale(Locale(value));
      },
      color: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      offset: Offset(0, 60 * scale),
      constraints: BoxConstraints(minWidth: 170 * scale),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'en',
          height: 44 * scale,
          padding: EdgeInsets.symmetric(horizontal: 18 * scale, vertical: 2 * scale),
          child: Row(children: [
            Text('English',
                style: GoogleFonts.lexendDeca(
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.w600,
                    color: !isAr ? const Color(0xFF900EBF) : const Color(0xFF24252C))),
            const Spacer(),
            if (!isAr) Icon(Icons.check_rounded, size: 18 * scale, color: const Color(0xFF900EBF)),
          ]),
        ),
        PopupMenuItem(
          value: 'ar',
          height: 44 * scale,
          padding: EdgeInsets.symmetric(horizontal: 18 * scale, vertical: 2 * scale),
          child: Row(children: [
            Text('العربية',
                style: GoogleFonts.cairo(
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.w600,
                    color: isAr ? const Color(0xFF900EBF) : const Color(0xFF24252C))),
            const Spacer(),
            if (isAr) Icon(Icons.check_rounded, size: 18 * scale, color: const Color(0xFF900EBF)),
          ]),
        ),
      ],
      child: Container(
        height: 60 * scale,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _cardBorder.withValues(alpha: 0.62)),
          borderRadius: BorderRadius.circular(15 * scale),
          boxShadow: [
            BoxShadow(offset: const Offset(0, 3), blurRadius: 20, color: Colors.black.withValues(alpha: 0.04)),
          ],
        ),
        padding: EdgeInsets.symmetric(horizontal: 20 * scale),
        child: Row(
          children: [
            Icon(Icons.language_rounded, size: 24 * scale, color: _accentColor),
            SizedBox(width: 12 * scale),
            Expanded(
              child: Text(
                isAr ? 'اللغة' : 'Language',
                style: GoogleFonts.poppins(
                  fontSize: 15 * scale * fontScale,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1B2D51),
                ),
              ),
            ),
            Text(
              isAr ? 'العربية' : 'English',
              style: GoogleFonts.poppins(
                fontSize: 14 * scale * fontScale,
                fontWeight: FontWeight.w500,
                color: _textMuted,
              ),
            ),
            SizedBox(width: 6 * scale),
            
          ],
        ),
      ),
    );
  }

  // ── Section Title ────────────────────────────────────
  Widget _buildSectionTitle(String title, double scale, double fontScale) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4 * scale),
      child: Text(
        title,
        style: GoogleFonts.lexendDeca(
          fontSize: 15 * scale * fontScale,
          fontWeight: FontWeight.w600,
          color: _textDark,
        ),
      ),
    );
  }

  // ── Menu Item (navigation style) ─────────────────────
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required double scale,
    required double fontScale,
    required bool isAr,
    VoidCallback? onTap,
    Widget? trailing,
    bool danger = false,
  }) {
    final color = danger ? _dangerColor : _accentColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60 * scale,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _cardBorder.withValues(alpha: 0.62)),
          borderRadius: BorderRadius.circular(15 * scale),
          boxShadow: [
            BoxShadow(offset: const Offset(0, 3), blurRadius: 20, color: Colors.black.withValues(alpha: 0.04)),
          ],
        ),
        padding: EdgeInsets.symmetric(horizontal: 20 * scale),
        child: Row(
          children: [
            Icon(icon, size: 24 * scale, color: color),
            SizedBox(width: 12 * scale),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 15 * scale * fontScale,
                  fontWeight: FontWeight.w500,
                  color: danger ? _dangerColor : const Color(0xFF1B2D51),
                ),
              ),
            ),
            trailing ?? Transform.scale(
              scaleX: isAr ? -1.0 : 1.0,
              child: CustomChevronIcon(size: 10 * scale, color: _textDark),
            ),
          ],
        ),
      ),
    );
  }

  // ── Toggle Item ──────────────────────────────────────
  Widget _buildToggleItem({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    required double scale,
    required double fontScale,
    bool loading = false,
  }) {
    return Container(
      height: 60 * scale,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _cardBorder.withValues(alpha: 0.62)),
        borderRadius: BorderRadius.circular(15 * scale),
        boxShadow: [
          BoxShadow(offset: const Offset(0, 3), blurRadius: 20, color: Colors.black.withValues(alpha: 0.04)),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: 20 * scale),
      child: Row(
        children: [
          Icon(icon, size: 24 * scale, color: _accentColor),
          SizedBox(width: 12 * scale),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 15 * scale * fontScale,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1B2D51),
              ),
            ),
          ),
          Opacity(
            opacity: loading ? 0.4 : 1.0,
            child: Switch.adaptive(
              value: value,
              activeTrackColor: _primaryColor,
              onChanged: loading ? null : onChanged,
            ),
          ),
        ],
      ),
    );
  }

  // ── Category Row (push + email toggles) ──────────────
  Widget _buildCategoryRow(String label, String key, double scale) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20 * scale, vertical: 14 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _cardBorder.withValues(alpha: 0.62)),
        borderRadius: BorderRadius.circular(15 * scale),
        boxShadow: [
          BoxShadow(offset: const Offset(0, 3), blurRadius: 20, color: Colors.black.withValues(alpha: 0.04)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 15 * scale,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1B2D51),
              ),
            ),
          ),
          // Push toggle
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.phone_android, size: 16 * scale, color: _textMuted),
              SizedBox(height: 2 * scale),
              Opacity(
                opacity: _prefsLoading ? 0.4 : 1.0,
                child: Switch.adaptive(
                  value: _getPref('$key.push'),
                  activeTrackColor: _primaryColor,
                  onChanged: _prefsLoading ? null : (v) => _updatePref('$key.push', v),
                ),
              ),
            ],
          ),
          SizedBox(width: 12 * scale),
          // Email toggle
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.email_outlined, size: 16 * scale, color: _textMuted),
              SizedBox(height: 2 * scale),
              Opacity(
                opacity: _prefsLoading ? 0.4 : 1.0,
                child: Switch.adaptive(
                  value: _getPref('$key.email'),
                  activeTrackColor: _primaryColor,
                  onChanged: _prefsLoading ? null : (v) => _updatePref('$key.email', v),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Change Password Dialog ─────────────────────────────
class _ChangePasswordDialog extends StatefulWidget {
  final TextEditingController currentController;
  final TextEditingController newController;
  final TextEditingController confirmController;
  final double scale;

  const _ChangePasswordDialog({
    required this.currentController,
    required this.newController,
    required this.confirmController,
    required this.scale,
  });

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    final localL10n = AppLocalizations.of(context)!;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: EdgeInsets.all(24 * s),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.changePasswordTitle,
              style: GoogleFonts.lexend(fontSize: 18 * s * (Localizations.localeOf(context).languageCode == 'ar' ? 1.15 : 1.0), fontWeight: FontWeight.w600, color: const Color(0xFF24252C)),
            ),
            SizedBox(height: 20 * s),
            _buildPasswordField(AppLocalizations.of(context)!.currentPasswordLabel, widget.currentController, _obscureCurrent, () {
              setState(() => _obscureCurrent = !_obscureCurrent);
            }, s),
            SizedBox(height: 12 * s),
            _buildPasswordField(AppLocalizations.of(context)!.newPasswordLabel, widget.newController, _obscureNew, () {
              setState(() => _obscureNew = !_obscureNew);
            }, s),
            SizedBox(height: 12 * s),
            _buildPasswordField(AppLocalizations.of(context)!.confirmPasswordLabel, widget.confirmController, _obscureConfirm, () {
              setState(() => _obscureConfirm = !_obscureConfirm);
            }, s),
            SizedBox(height: 24 * s),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(AppLocalizations.of(context)!.cancelButton, style: GoogleFonts.poppins(color: const Color(0xFF8B88B5))),
                ),
                SizedBox(width: 8 * s),
                TextButton(
                  onPressed: () {
                    if (widget.newController.text != widget.confirmController.text) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(localL10n.passwordsDoNotMatch)),
                      );
                      return;
                    }
                    if (widget.newController.text.length < 6) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(localL10n.passwordLengthError)),
                      );
                      return;
                    }
                    Navigator.pop(context, true);
                  },
                  child: Text(
                    localL10n.saveButton,
                    style: GoogleFonts.poppins(color: const Color(0xFF900EBF), fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller, bool obscure, VoidCallback toggleObscure, double s) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF5F3F3).withValues(alpha: 0.62)),
        boxShadow: [
          BoxShadow(offset: const Offset(0, 2), blurRadius: 8, color: Colors.black.withValues(alpha: 0.04)),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 12 * s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.lexendDeca(fontSize: 11 * s * (Localizations.localeOf(context).languageCode == 'ar' ? 1.15 : 1.0), fontWeight: FontWeight.w500, color: const Color(0xFF8B88B5)),
          ),
          SizedBox(height: 4 * s),
           TextField(
            controller: controller,
            obscureText: obscure,
            style: GoogleFonts.poppins(fontSize: 15 * s * (Localizations.localeOf(context).languageCode == 'ar' ? 1.15 : 1.0), fontWeight: FontWeight.w500, color: const Color(0xFF24252C)),
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
              suffixIcon: GestureDetector(
                onTap: toggleObscure,
                child: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20 * s, color: const Color(0xFF8B88B5)),
              ),
              suffixIconConstraints: BoxConstraints(maxHeight: 24 * s),
            ),
          ),
        ],
      ),
    );
  }
}
