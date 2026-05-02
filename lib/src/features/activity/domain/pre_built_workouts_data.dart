import '../domain/workout.dart';

final preBuiltWorkouts = [
  const PreBuiltWorkout(
    id: 'hiit_express',
    title: 'HIIT Express',
    imageUrl: 'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?auto=format&fit=crop&w=400&q=80',
    workDuration: 15,
    restDuration: 15,
    totalExercises: 1,
    totalRounds: 3,
  ),
  const PreBuiltWorkout(
    id: 'full_body_blast',
    title: 'Full Body Blast',
    imageUrl: 'https://images.unsplash.com/photo-1517963879433-6ad2b056d712?auto=format&fit=crop&w=400&q=80',
    workDuration: 60,
    restDuration: 30,
    totalExercises: 5,
    totalRounds: 4,
  ),
  const PreBuiltWorkout(
    id: 'hyrox_prep',
    title: 'HYROX Prep',
    imageUrl: 'https://images.unsplash.com/photo-1599058917212-d750089bc07e?auto=format&fit=crop&w=400&q=80',
    workDuration: 40,
    restDuration: 20,
    totalExercises: 8,
    totalRounds: 3,
  ),
];

