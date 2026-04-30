import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../widgets/custom_bottom_navigation.dart';
import '../../../../widgets/custom_arrow_icon.dart';
import '../../../../widgets/custom_chevron_icon.dart';
import '../../activity/presentation/activity_screen.dart';
import '../../rewards/presentation/rewards_screen.dart';
import '../../activity/presentation/workout_screen.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/auth_screen.dart';
import '../../onboarding/presentation/start_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import 'package:image_picker/image_picker.dart';
import '../data/user_repository.dart';
import '../../notifications/data/real_time_notification_service.dart';
import 'dart:io';
import 'dart:math' as math;
import '../../auth/presentation/controllers/auth_controller.dart';
import 'package:tryd/src/generated/l10n/app_localizations.dart';
import '../../../../main.dart' show localeProvider;
import '../../../../widgets/swipe_to_pop_wrapper.dart';
import '../../../shell/main_shell.dart';

// Responsive helper extension to cap values for larger screens
extension ResponsiveDouble on num {
  /// Responsive font size - scales with screen but caps at max
  double get rsp => math.min(sp, toDouble() * 1.2);
  
  /// Responsive width - scales but caps at 1.5x base value
  double get rw => math.min(w, toDouble() * 1.3);
  
  /// Responsive height - scales but caps at 1.3x base value
  double get rh => math.min(h, toDouble() * 1.2);
  
  /// Responsive radius - scales but caps
  double get rr => math.min(r, toDouble() * 1.2);
}

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  int _selectedIndex = 4; // Profile is at index 4
  bool _showAvatar = true;
  double _dragProgress = 0.0;
  bool _isUploading = false;
  File? _optimisticImage;
  bool _isRemoving = false;

  void _onSheetDrag(double extent) {
    // extent ranges from minChildSize (0.72) to maxChildSize (0.87 in this case)
    const minSize = 0.72;
    const maxSize = 0.87;
    const threshold = 0.80; 

    // Calculate progress (0.0 to 1.0)
    final progress = ((extent - minSize) / (maxSize - minSize)).clamp(0.0, 1.0);

    if (_dragProgress != progress || (_showAvatar != (extent < threshold))) {
      setState(() {
        _showAvatar = extent < threshold;
        _dragProgress = progress;
      });
    }
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      imageQuality: 70,
    );

    if (image == null) return;
    
    final imageFile = File(image.path);

    if (mounted) {
      setState(() {
        _isUploading = true;
        _optimisticImage = imageFile;
      });
    }
    try {
      await ref.read(userRepositoryProvider).uploadProfilePicture(File(image.path));
      
      // Invalidate and immediately refresh the provider
      ref.invalidate(userProfileProvider);
      await ref.read(userProfileProvider.future);
      
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ref.read(realTimeNotificationServiceProvider).showInAppBanner(
          l10n.profileUpdated,
          l10n.profilePicChanged,
        );
      }
      
      // Clear optimistic preview after a short delay to allow provider to settle
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) setState(() => _optimisticImage = null);
      });
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.failedToUploadImage(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _removeProfilePicture() async {
    if (mounted) {
      setState(() {
        _isUploading = true;
        _isRemoving = true;
        _optimisticImage = null; // Forces fallback to asset
      });
    }
    
    try {
      await ref.read(userRepositoryProvider).removeProfilePicture();
      
      // Invalidate and refresh
      ref.invalidate(userProfileProvider);
      await ref.read(userProfileProvider.future);
      
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ref.read(realTimeNotificationServiceProvider).showInAppBanner(
          l10n.profileUpdated,
          "Profile picture removed successfully",
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to remove photo: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _isRemoving = false;
        });
      }
    }
  }

  void _showPhotoOptions(bool hasPhoto) {
    final l10n = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final fontScale = isAr ? 1.1 : 1.0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                l10n.changePicture,
                style: GoogleFonts.lexend(
                  fontSize: 18 * fontScale,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF24252C),
                ),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: Color(0xFF900EBF)),
              title: Text(l10n.takeAPhoto, style: GoogleFonts.lexend(fontSize: 16 * fontScale)),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: Color(0xFF900EBF)),
              title: Text(l10n.chooseFromGallery, style: GoogleFonts.lexend(fontSize: 16 * fontScale)),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage(ImageSource.gallery);
              },
            ),
            if (hasPhoto)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: Text(
                  // Look for localized string or fallback
                  (l10n as dynamic).removePhotoLabel ?? "Remove Photo", 
                  style: GoogleFonts.lexend(fontSize: 16 * fontScale, color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _removeProfilePicture();
                },
              ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> _editName(String currentName) async {
    final l10n = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final fontScale = isAr ? 1.15 : 1.0;
    
    final controller = TextEditingController(text: currentName);
    final newName = await showDialog<String>(
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.editNameTitle,
                    style: GoogleFonts.lexend(
                      fontSize: 20.0 * fontScale,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF24252C),
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(
                        color: const Color(0xFFF5F3F3).withOpacity(0.62),
                      ),
                      boxShadow: [
                        BoxShadow(
                          offset: const Offset(0, 2),
                          blurRadius: 8,
                          spreadRadius: 0,
                          color: const Color(0xFF000000).withOpacity(0.04),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.fullNameLabel,
                            style: GoogleFonts.lexendDeca(
                              fontSize: 12.0 * fontScale,
                              fontWeight: FontWeight.w500,
                              height: 1.25,
                              color: const Color(0xFF8B88B5),
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          TextField(
                            controller: controller,
                            autofocus: true,
                            style: GoogleFonts.poppins(
                              fontSize: 16.0,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF24252C),
                              height: 1.4,
                            ),
                            decoration: InputDecoration(
                              hintText: l10n.fullNamePlaceholder,
                              hintStyle: GoogleFonts.poppins(
                                fontSize: 16.0 * fontScale,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF8B88B5).withOpacity(0.5),
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
                ],
              ),
            ),
            const Divider(color: Color(0xFFE5E7EB), height: 1, thickness: 1),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20.0),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18.0),
                      alignment: Alignment.center,
                      child: Text(
                        l10n.cancelButton,
                        style: GoogleFonts.lexend(
                          fontSize: 16.0 * fontScale,
                          color: const Color(0xFF8B88B5),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 56,
                  color: const Color(0xFFE5E7EB),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => Navigator.pop(context, controller.text),
                    borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(20.0),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18.0),
                      alignment: Alignment.center,
                      child: Text(
                        l10n.saveButton,
                        style: GoogleFonts.lexend(
                          fontSize: 16.0 * fontScale,
                          color: const Color(0xFF900EBF),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != currentName) {
      try {
        await ref.read(userRepositoryProvider).updateProfile({'name': newName});
        
        // Invalidate and immediately refresh the provider
        ref.invalidate(userProfileProvider);
        await ref.read(userProfileProvider.future);
        
        if (mounted) {
          final l10n_inner = AppLocalizations.of(context)!;
          ref.read(realTimeNotificationServiceProvider).showInAppBanner(
            l10n_inner.nameUpdated,
            l10n_inner.nameChangedSuccess(newName),
          );
        }
      } catch (e) {
        if (mounted) {
          final l10n_inner = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n_inner.failedToUpdateName(e.toString()))),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProfileProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // ── Responsive Scale ──────────────────────────────────
    final isTablet = screenWidth > 600;

    const double smallScale  = 0.85;
    const double mediumScale = 0.98;
    const double largeScale  = 1.05;
    const double tabletScale = 1.30;

    final double scale = isTablet
        ? tabletScale
        : screenHeight < 680
            ? smallScale
            : screenHeight < 850
                ? mediumScale
                : largeScale;

    final l10n = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final fontScale = isAr ? 1.15 : 1.0;

    // Clamped horizontal padding
    final horizontalPadding = 18.0 * scale;
    
    // Responsive avatar size - proportional for all devices
    final avatarSize = 170.0 * scale;

    // Responsive header height
    final headerHeight = 240.0 * scale;

    // Base top padding for content
    final baseTopPadding = 90.0 * scale;

    return SwipeToPopWrapper(child: Scaffold(
      backgroundColor: Colors.white,
      body: userAsync.when(
        data: (user) => Stack(
          children: [
            // Background color
            Container(color: const Color(0xFFF7E6EB)),

            // Pink header background
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: headerHeight,
              child: Container(
                color: const Color(0xFFF7E6EB),
              ),
            ),

            // Navigation buttons in the header
            SafeArea(
              child: Padding(
                padding: EdgeInsets.only(top: isTablet ? 8.0 * scale : 16.0 * scale),
                child: _buildHeader(context, isTablet, scale, l10n, fontScale, isAr),
              ),
            ),

            // Fixed Bottom Sheet (No Dragging)
            DraggableScrollableSheet(
              initialChildSize: 0.72,
              minChildSize: 0.72,
              maxChildSize: 0.72,
              builder: (BuildContext context, ScrollController scrollController) {
                final avatarOffset = -(avatarSize / 2);
                final sheetRadius = 33.0 * scale;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // White Sheet Container
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(sheetRadius),
                          topRight: Radius.circular(sheetRadius),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            offset: const Offset(0, -3),
                            blurRadius: 15,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(sheetRadius),
                          topRight: Radius.circular(sheetRadius),
                        ),
                        child: ListView(
                          controller: scrollController,
                          padding: EdgeInsets.only(top: baseTopPadding),
                          children: [
                            // User Name
                            Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(
                                    child: Text(
                                      user.name,
                                      style: GoogleFonts.lexendDeca(
                                        fontSize: 18.0 * scale * fontScale,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF24252C),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.edit, size: 16.0 * scale, color: const Color(0xFFF83A71)),
                                    onPressed: () => _editName(user.name),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 20.0 * scale),
                            
                            // Menu items
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                              child: Column(
                                children: [
                                  _buildMenuItem(
                                    icon: Icons.emoji_events,
                                    title: l10n.myRewards,
                                    iconColor: const Color(0xFFF83A71),
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const RewardsScreen(showSwipeBack: true)),
                                    ),
                                    scale: scale,
                                    fontScale: fontScale,
                                    isAr: isAr,
                                  ),
                                  SizedBox(height: 8.0 * scale),
                                  _buildMenuItem(
                                    icon: Icons.history,
                                    title: l10n.activityLabel,
                                    iconColor: const Color(0xFFF83A71),
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const ActivityScreen()),
                                    ),
                                    scale: scale,
                                    fontScale: fontScale,
                                    isAr: isAr,
                                  ),
                                  SizedBox(height: 8.0 * scale),
                                  _buildMenuItem(
                                    icon: Icons.fitness_center,
                                    title: l10n.myWorkouts,
                                    iconColor: const Color(0xFFF83A71),
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const WorkoutScreen(showSwipeBack: true)),
                                    ),
                                    scale: scale,
                                    fontScale: fontScale,
                                    isAr: isAr,
                                  ),
                                  SizedBox(height: 8.0 * scale),
                                  _buildMenuItem(
                                    icon: Icons.settings,
                                    title: l10n.settingsLabel,
                                    iconColor: const Color(0xFFF83A71),
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const SettingsScreen()),
                                    ),
                                    scale: scale,
                                    fontScale: fontScale,
                                    isAr: isAr,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 120.0 * scale),
                          ],
                        ),
                      ),
                    ),
                    
                    // Avatar positioned at the top edge of the sheet
                    Positioned(
                      top: avatarOffset,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Stack(
                          children: [
                            _buildAvatar(avatarSize, user.profilePicture),
                            if (_isUploading)
                              Positioned.fill(
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.black26,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(color: Colors.white),
                                  ),
                                ),
                              ),
                            Positioned(
                              right: 12.0 * scale,
                              bottom: 12.0 * scale,
                              child: GestureDetector(
                                onTap: () => _showPhotoOptions(user.profilePicture != null && user.profilePicture!.isNotEmpty),
                                child: Container(
                                  padding: EdgeInsets.all(8.0 * scale),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF900EBF),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 8,
                                        offset: Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 18.0 * scale,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  );
                },
              ),

            // Bottom Navigation
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: CustomBottomNavigation(
                currentIndex: _selectedIndex,
                onTap: (index) {
                  if (index == _selectedIndex) return;
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  ref.read(mainNavTapProvider)?.call(index);
                },
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF900EBF))),
        error: (err, stack) => _buildErrorView(err.toString(), scale, l10n, fontScale),
      ),
    ));
  }

  Widget _buildErrorView(String message, double scale, AppLocalizations l10n, double fontScale) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.0 * scale),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, color: const Color(0xFFFD3C6F), size: 64.0 * scale),
          SizedBox(height: 16.0 * scale),
          Text(
            l10n.loadProfileError,
            style: GoogleFonts.lexendDeca(
              fontSize: 20.0 * scale * fontScale,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF24252C),
            ),
          ),
          SizedBox(height: 8.0 * scale),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14.0 * scale * fontScale,
              color: const Color(0xFF8B88B5),
            ),
          ),
          SizedBox(height: 24.0 * scale),
          ElevatedButton(
            onPressed: () => ref.invalidate(userProfileProvider),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF900EBF),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 32.0 * scale, vertical: 12.0 * scale),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0 * scale)),
            ),
            child: Text(l10n.retryButton),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isTablet, double scale, AppLocalizations l10n, double fontScale, bool isAr) {
    // Responsive sizes for consistency
    final padding = 26.0 * scale;
    final titleSize = 19.0 * scale * fontScale;
    final logoutSize = 26.0 * scale;
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              ref.read(mainTabProvider.notifier).state = 0;
              Navigator.of(context).pop();
            },
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 42.0 * scale,
              height: 42.0 * scale,
              child: Transform.scale(
                scaleX: Directionality.of(context) == TextDirection.rtl ? 1 : -1,
                child: CustomArrowIcon(
                  size: 42.0 * scale,
                  color: const Color(0xFF130F26),
                ),
              ),
            ),
          ),
          Text(
            l10n.profileTitle,
            style: GoogleFonts.lexendDeca(
              fontSize: titleSize,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF24252C),
            ),
          ),
          GestureDetector(
            onTap: () async {
              await ref.read(authControllerProvider.notifier).logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const AuthScreen()),
                  (route) => false,
                );
              }
            },
            child: Icon(
              Icons.logout,
              size: logoutSize,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(double size, String? imageUrl) {
    final innerSize = size * 0.85;
    final borderWidth = size * 0.08;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: borderWidth,
        ),
      ),
      child: ClipOval(
        child: Container(
          width: innerSize,
          height: innerSize,
          color: const Color(0xFFF3F4F6),
          child: _isRemoving 
              ? _buildDefaultAvatar(innerSize)
              : (_optimisticImage != null)
                  ? Image.file(
                      _optimisticImage!,
                      fit: BoxFit.cover,
                    )
                  : (imageUrl != null && imageUrl.isNotEmpty)
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildDefaultAvatar(innerSize),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                    : null,
                                strokeWidth: 2,
                                color: const Color(0xFF900EBF),
                              ),
                            );
                          },
                        )
                      : _buildDefaultAvatar(innerSize),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar(double size) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFFE5E7EB),
        image: DecorationImage(
          image: AssetImage('assets/images/profile.png'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required Color iconColor,
    required double scale,
    required double fontScale,
    required bool isAr,
    VoidCallback? onTap,
  }) {
    // Responsive values for consistency
    final height = 65.0 * scale;
    final iconSize = 26.0 * scale;
    final fontSize = 16.0 * scale * fontScale;
    final padding = 20.0 * scale;
    final chevronSize = 10.0 * scale;
    final radius = 15.0 * scale;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: const Color(0xFFF5F3F3).withOpacity(0.62),
          ),
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              offset: const Offset(0, 3),
              blurRadius: 20,
              color: Colors.black.withOpacity(0.04),
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(horizontal: padding),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                  Icon(
                  icon,
                  size: iconSize,
                  color: iconColor,
                ),
                SizedBox(width: 10.0 * scale),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1B2D51),
                  ),
                ),
              ],
            ),
            CustomChevronIcon(
              size: chevronSize,
              color: const Color(0xFF24252C),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFreePlanCard(double scale, AppLocalizations l10n, double fontScale) {
    // Responsive values for consistency
    final minHeight = 90.0 * scale;
    final titleSize = 18.0 * scale * fontScale;
    final subtitleSize = 12.0 * scale * fontScale;
    final badgeFontSize = 12.0 * scale * fontScale;
    final padding = 14.0 * scale;
    final radius = 15.0 * scale;
    
    return Container(
      constraints: BoxConstraints(minHeight: minHeight),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: const Color(0xFFF5F3F3).withOpacity(0.62),
        ),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 3),
            blurRadius: 20,
            color: Colors.black.withOpacity(0.04),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l10n.freePlan,
                  style: GoogleFonts.poppins(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                    color: const Color(0xFF1B2D51),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.freePlanSubtitle,
                  style: GoogleFonts.poppins(
                    fontSize: subtitleSize,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                    color: const Color(0xFF96AAD2),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.0 * scale, vertical: 6.0 * scale),
            decoration: BoxDecoration(
              color: const Color(0xFF22D198),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              'Current',
              style: GoogleFonts.poppins(
                fontSize: badgeFontSize,
                fontWeight: FontWeight.w400,
                height: 1.25,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumPlanCard(double scale) {
    // Responsive values for consistency
    final titleSize = 18.0 * scale;
    final subtitleSize = 13.0 * scale;
    final buttonFontSize = 14.0 * scale;
    final padding = 20.0 * scale;
    final radius = 22.0 * scale;
    final buttonWidth = 140.0 * scale;
    final buttonHeight = 40.0 * scale;
    final iconSize = 60.0 * scale;
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(-1.0, 0.07),
          end: Alignment(1.0, -0.07),
          colors: [Color(0xFF910EBF), Color(0xFFFD3C6F)],
        ),
        borderRadius: BorderRadius.circular(radius),
      ),
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Premium Plan',
                style: GoogleFonts.poppins(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 3),
              SizedBox(
                width: 200, // Fixed max width for description
                child: Text(
                  'Advanced features & exclusive rewards',
                  style: GoogleFonts.poppins(
                    fontSize: subtitleSize,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(height: 16.0 * scale),
              Container(
                width: buttonWidth,
                height: buttonHeight,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.46),
                  borderRadius: BorderRadius.circular(15.0 * scale),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Upgrade Now',
                  style: GoogleFonts.poppins(
                    fontSize: buttonFontSize,
                    fontWeight: FontWeight.w500,
                    height: 1.43,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            right: -8,
            bottom: -8,
            child: SvgPicture.asset(
              'assets/images/cup.svg',
              width: iconSize,
              height: iconSize,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(Icons.emoji_events, color: Colors.white, size: math.min(40.sp, 45.0)),
            ),
          ),
        ],
      ),
    );
  }
}
