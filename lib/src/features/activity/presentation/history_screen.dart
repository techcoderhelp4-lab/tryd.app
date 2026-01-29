import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../widgets/custom_bottom_navigation.dart';
import '../../../../widgets/custom_arrow_icon.dart';
import '../../../../widgets/custom_calendar_icon.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../data/activity_repository.dart';
import '../domain/workout.dart';
import '../../home/presentation/home_screen.dart';
import 'running_screen.dart';
import '../../rewards/presentation/rewards_screen.dart';
import 'workout_screen.dart';
import '../../club/presentation/club_screen.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  int _selectedIndex = 3; // History/Workout tab

  @override
  Widget build(BuildContext context) {
    final workoutHistoryAsync = ref.watch(workoutHistoryProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.8,
              child: Image.asset(
                'assets/images/bg-gradient.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 28),
                _buildHeader(context),
                const SizedBox(height: 52),
                Expanded(
                  child: workoutHistoryAsync.when(
                    data: (history) => history.isEmpty 
                      ? Center(child: Text("No workouts yet", style: GoogleFonts.lexend(color: Colors.grey)))
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          itemCount: history.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 15),
                          itemBuilder: (context, index) {
                            return _buildHistoryCard(history[index]);
                          },
                        ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text("Error: $e")),
                  ),
                ),
                const SizedBox(height: 140),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CustomBottomNavigation(
              currentIndex: _selectedIndex,
              onTap: (index) {
                if (index == 3) {
                  Navigator.pop(context);
                  return;
                }
                
                Widget? page;
                switch (index) {
                  case 0: page = const HomeScreen(); break;
                  case 1: page = const RunningScreen(); break;
                  case 2: page = const RewardsScreen(); break;
                  case 4: page = const ClubScreen(); break;
                }
                
                if (page != null) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => page!),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 26),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              child: Transform.scale(
                scaleX: -1,
                child: const CustomArrowIcon(
                  size: 24,
                  color: Color(0xFF130F26),
                ),
              ),
            ),
          ),
          Text(
            'History',
            style: GoogleFonts.lexendDeca(
              fontSize: 19,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF24252C),
            ),
          ),
          const SizedBox(width: 40), // Spacer for alignment
        ],
      ),
    );
  }

  Widget _buildHistoryCard(Workout workout) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: const Color(0xFFE8ECF4).withOpacity(0.49),
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CustomCalendarIcon(
                  size: 24,
                  color: Color(0xFFF83A71),
                ),
                const SizedBox(width: 7),
                Text(
                  DateFormat('dd MMM yyyy').format(workout.date),
                  style: GoogleFonts.poppins(
                    fontSize: 19,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF221F48),
                    height: 22 / 19,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _buildStatsRow(workout),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(Workout workout) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildStatItem('Work', '${workout.workDuration ?? 0}s'),
        _buildStatItem('Rest', '${workout.restDuration ?? 0}s'),
        _buildStatItem('Ex', '${workout.exercises ?? 0}'),
        _buildStatItem('Rounds', '${workout.rounds ?? 0}'),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF221F48),
            height: 31 / 14,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.roboto(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF221F48),
            height: 31 / 24,
          ),
        ),
      ],
    );
  }
}
