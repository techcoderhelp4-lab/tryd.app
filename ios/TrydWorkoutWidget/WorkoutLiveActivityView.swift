import ActivityKit
import SwiftUI
import WidgetKit

// MARK: – Shared colours
private let trydPurple = Color(red: 0.565, green: 0.055, blue: 0.745)
private let cardBg     = Color(red: 0.12, green: 0.12, blue: 0.16)

// MARK: – Lock-screen / StandBy router

struct WorkoutLockScreenView: View {
    let context: ActivityViewContext<WorkoutActivityAttributes>
    var body: some View {
        if context.attributes.workoutType == "gym" {
            GymLockScreenView(context: context)
        } else {
            RunningLockScreenView(context: context)
        }
    }
}

// MARK: – Running lock-screen

struct RunningLockScreenView: View {
    let context: ActivityViewContext<WorkoutActivityAttributes>
    var state: WorkoutActivityAttributes.ContentState { context.state }

    var body: some View {
        VStack(spacing: 0) {

            // ── Top row: icon · timer pill · logo ────────────────────────────
            HStack(alignment: .center) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 36, height: 36)
                    Image(systemName: context.attributes.workoutType == "running"
                          ? "shoe.fill" : "figure.walk")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                }

                Spacer()

                HStack(spacing: 4) {
                    Circle()
                        .fill(state.isPaused ? Color.orange.opacity(0.7) : Color.orange)
                        .frame(width: 6, height: 6)
                    Text(state.formattedTime)
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.orange.opacity(0.25))
                .clipShape(Capsule())

                Spacer()

                Image(systemName: "chevron.up.2")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(trydPurple)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 12)

            // ── Stats: Distance + Pace ────────────────────────────────────────
            HStack(alignment: .bottom, spacing: 0) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(state.formattedDistance + " km")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                    Text("Distance")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.55))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 1, height: 44)
                    .padding(.horizontal, 12)

                VStack(alignment: .leading, spacing: 2) {
                    Text(state.formattedPace + "/km")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                    Text("Pace")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.55))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

// MARK: – Gym lock-screen

struct GymLockScreenView: View {
    let context: ActivityViewContext<WorkoutActivityAttributes>
    var state: WorkoutActivityAttributes.ContentState { context.state }

    private var phaseColor: Color {
        state.phase == "Work" ? trydPurple : Color.orange
    }
    private var phaseIcon: String {
        state.phase == "Work" ? "flame.fill" : "pause.circle.fill"
    }

    var body: some View {
        VStack(spacing: 0) {

            // ── Top row: phase pill · round · dumbbell ───────────────────────
            HStack(alignment: .center) {
                HStack(spacing: 5) {
                    Image(systemName: phaseIcon)
                        .font(.system(size: 11, weight: .bold))
                    Text(state.phase.uppercased())
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(phaseColor.opacity(0.85))
                .clipShape(Capsule())

                Spacer()

                Text("Round \(state.currentRound) / \(state.totalRounds)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.75))

                Spacer()

                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(trydPurple)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 12)

            // ── Stats: Remaining · Exercise ──────────────────────────────────
            HStack(alignment: .bottom, spacing: 0) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(state.isPaused ? Color.orange.opacity(0.7) : Color.orange)
                            .frame(width: 6, height: 6)
                        Text(state.formattedRemaining)
                            .font(.system(size: 34, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white)
                            .minimumScaleFactor(0.7)
                            .lineLimit(1)
                    }
                    Text(state.isPaused ? "Paused" : "Remaining")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.55))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 1, height: 44)
                    .padding(.horizontal, 12)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(state.currentExercise) / \(state.totalExercises)")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                    Text("Exercise")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.55))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)

            // ── Pause / Resume button ────────────────────────────────────────
            let pauseAction = state.isPaused ? "resume" : "pause"
            let pauseIcon   = state.isPaused ? "play.fill"  : "pause.fill"
            let pauseLabel  = state.isPaused ? "Resume"     : "Pause"

            Link(destination: URL(string: "tryd://workout/\(pauseAction)")!) {
                HStack(spacing: 6) {
                    Image(systemName: pauseIcon)
                        .font(.system(size: 13, weight: .bold))
                    Text(pauseLabel)
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(trydPurple)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 14)
        }
        .background(cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

// MARK: – Dynamic Island compact (router)

struct WorkoutDynamicIslandCompact: View {
    let context: ActivityViewContext<WorkoutActivityAttributes>
    var isGym: Bool { context.attributes.workoutType == "gym" }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: isGym ? "dumbbell.fill" :
                  (context.attributes.workoutType == "running" ? "shoe.fill" : "figure.walk"))
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(trydPurple)
            Text(isGym ? context.state.formattedRemaining : context.state.formattedTime)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
        }
    }
}

// MARK: – Dynamic Island expanded (router)

struct WorkoutDynamicIslandExpanded: View {
    let context: ActivityViewContext<WorkoutActivityAttributes>
    var body: some View {
        if context.attributes.workoutType == "gym" {
            GymDynamicIslandExpanded(state: context.state)
        } else {
            RunningDynamicIslandExpanded(context: context)
        }
    }
}

// MARK: – Running Dynamic Island expanded

struct RunningDynamicIslandExpanded: View {
    let context: ActivityViewContext<WorkoutActivityAttributes>
    var state: WorkoutActivityAttributes.ContentState { context.state }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Label(
                    state.isPaused ? "Paused" : (context.attributes.workoutType == "running" ? "Running" : "Walking"),
                    systemImage: context.attributes.workoutType == "running" ? "shoe.fill" : "figure.walk"
                )
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(trydPurple)

                Spacer()

                Text(state.formattedTime)
                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.25))
                    .clipShape(Capsule())
            }

            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(state.formattedDistance + " km")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Distance")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(state.formattedPace + "/km")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Pace")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                Spacer()

                let action = state.isPaused ? "resume" : "pause"
                let icon   = state.isPaused ? "play.fill" : "pause.fill"
                Link(destination: URL(string: "tryd://workout/\(action)")!) {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(trydPurple)
                        .clipShape(Circle())
                }
            }
        }
        .padding(.horizontal, 4)
    }
}

// MARK: – Gym Dynamic Island expanded

struct GymDynamicIslandExpanded: View {
    let state: WorkoutActivityAttributes.ContentState

    private var phaseColor: Color {
        state.phase == "Work" ? trydPurple : Color.orange
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Label(
                    state.isPaused ? "Paused" : state.phase,
                    systemImage: state.phase == "Work" ? "flame.fill" : "pause.circle.fill"
                )
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(phaseColor)

                Spacer()

                Text("Round \(state.currentRound)/\(state.totalRounds)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.75))
            }

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(state.formattedRemaining)
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                    Text("Remaining")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text("\(state.currentExercise)/\(state.totalExercises)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Exercise")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                Spacer()

                let pauseAction = state.isPaused ? "resume" : "pause"
                let pauseIcon   = state.isPaused ? "play.fill" : "pause.fill"
                Link(destination: URL(string: "tryd://workout/\(pauseAction)")!) {
                    Image(systemName: pauseIcon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(trydPurple)
                        .clipShape(Circle())
                }
            }
        }
        .padding(.horizontal, 4)
    }
}

// MARK: – Widget configuration

@available(iOS 16.1, *)
struct TrydWorkoutLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
            WorkoutLockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    WorkoutDynamicIslandExpanded(context: context)
                }
            } compactLeading: {
                WorkoutDynamicIslandCompact(context: context)
            } compactTrailing: {
                let isGym = context.attributes.workoutType == "gym"
                if isGym {
                    Text(context.state.phase.prefix(1))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(context.state.phase == "Work" ? trydPurple : Color.orange)
                } else {
                    Text(context.state.formattedDistance + " km")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
            } minimal: {
                let isGym = context.attributes.workoutType == "gym"
                Image(systemName: isGym ? "dumbbell.fill" :
                      (context.attributes.workoutType == "running" ? "shoe.fill" : "figure.walk"))
                    .foregroundStyle(trydPurple)
            }
        }
    }
}
