import ActivityKit
import Foundation

struct WorkoutActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // ── Running fields ───────────────────────────────────────────────────
        var elapsedSeconds: Int
        var distanceKm: Double
        var pacePerKm: Double
        var calories: Double
        var steps: Int
        var isPaused: Bool

        // ── Gym fields ───────────────────────────────────────────────────────
        var phase: String          // "Work" | "Rest"
        var currentRound: Int
        var totalRounds: Int
        var currentExercise: Int
        var totalExercises: Int
        var remainingSeconds: Int

        init(
            elapsedSeconds: Int = 0,
            distanceKm: Double = 0,
            pacePerKm: Double = 0,
            calories: Double = 0,
            steps: Int = 0,
            isPaused: Bool = false,
            phase: String = "Work",
            currentRound: Int = 1,
            totalRounds: Int = 1,
            currentExercise: Int = 1,
            totalExercises: Int = 1,
            remainingSeconds: Int = 0
        ) {
            self.elapsedSeconds = elapsedSeconds
            self.distanceKm = distanceKm
            self.pacePerKm = pacePerKm
            self.calories = calories
            self.steps = steps
            self.isPaused = isPaused
            self.phase = phase
            self.currentRound = currentRound
            self.totalRounds = totalRounds
            self.currentExercise = currentExercise
            self.totalExercises = totalExercises
            self.remainingSeconds = remainingSeconds
        }

        // ── Running formatters ───────────────────────────────────────────────
        var formattedTime: String {
            let h = elapsedSeconds / 3600
            let m = (elapsedSeconds % 3600) / 60
            let s = elapsedSeconds % 60
            if h > 0 {
                return String(format: "%d:%02d:%02d", h, m, s)
            }
            return String(format: "%02d:%02d", m, s)
        }

        var formattedPace: String {
            guard pacePerKm > 0, pacePerKm < 60, !pacePerKm.isNaN, !pacePerKm.isInfinite else { return "--:--" }
            let m = Int(pacePerKm)
            let s = Int((pacePerKm - Double(m)) * 60)
            return String(format: "%d:%02d", m, s)
        }

        var formattedDistance: String {
            String(format: "%.2f", distanceKm)
        }

        // ── Gym formatters ───────────────────────────────────────────────────
        var formattedRemaining: String {
            let m = remainingSeconds / 60
            let s = remainingSeconds % 60
            return String(format: "%02d:%02d", m, s)
        }
    }

    var workoutType: String  // "running" | "walking" | "gym"
}
