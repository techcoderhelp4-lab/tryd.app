import ActivityKit
import Flutter
import HealthKit
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    let controller = window?.rootViewController as! FlutterViewController

    // ── HealthKit observers ───────────────────────────────────────────────
    let healthChannel = FlutterMethodChannel(name: "tryd.app/health_ultra",
                                             binaryMessenger: controller.binaryMessenger)
    healthChannel.setMethodCallHandler { call, result in
      if call.method == "startHealthKitObservers" {
        HealthKitManager.shared.setupChannel(messenger: controller.binaryMessenger)
        HealthKitManager.shared.startObserverQueries()
        result(nil)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    // ── Live Activity controls ────────────────────────────────────────────
    let liveActivityChannel = FlutterMethodChannel(name: "tryd.app/live_activity",
                                                   binaryMessenger: controller.binaryMessenger)
    liveActivityChannel.setMethodCallHandler { call, result in
      if #available(iOS 16.2, *) {
        WorkoutLiveActivityManager.shared.handle(call: call, result: result)
      } else {
        result(nil)
      }
    }

    // Store the channel so URL-scheme callbacks can forward actions to Flutter.
    if #available(iOS 16.2, *) {
      WorkoutLiveActivityManager.shared.setChannel(liveActivityChannel)
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // ── Handle tryd://workout/<action> deep links from Live Activity buttons ──
  // iOS routes Live Activity Link taps back to the app via this method.
  // We parse the action segment and forward it to Flutter so the workout
  // controller can pause, resume, or finish the run without extra UI.
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    if url.scheme == "tryd", url.host == "workout" {
      let action = url.lastPathComponent // "pause" | "resume" | "finish"
      if #available(iOS 16.2, *) {
        WorkoutLiveActivityManager.shared.sendAction(action)
      }
      return true
    }
    return super.application(app, open: url, options: options)
  }
}

// MARK: – Live Activity Manager

@available(iOS 16.2, *)
class WorkoutLiveActivityManager {
  static let shared = WorkoutLiveActivityManager()
  private var currentActivity: Activity<WorkoutActivityAttributes>?
  private var flutterChannel: FlutterMethodChannel?

  func setChannel(_ channel: FlutterMethodChannel) {
    flutterChannel = channel
  }

  /// Forward a workout control action to the Flutter workout controller.
  /// Called both from URL-scheme taps (Live Activity buttons) and any future
  /// push-to-update paths.
  func sendAction(_ action: String) {
    DispatchQueue.main.async {
      self.flutterChannel?.invokeMethod("onAction", arguments: action)
    }
  }

  func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "startActivity":
      guard let args = call.arguments as? [String: Any] else { result(nil); return }
      startActivity(args: args)
      result(nil)
    case "updateActivity":
      guard let args = call.arguments as? [String: Any] else { result(nil); return }
      updateActivity(args: args)
      result(nil)
    case "stopActivity":
      stopActivity()
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func makeState(from args: [String: Any]) -> WorkoutActivityAttributes.ContentState {
    WorkoutActivityAttributes.ContentState(
      elapsedSeconds: args["elapsedSeconds"] as? Int ?? 0,
      distanceKm: args["distanceKm"] as? Double ?? 0,
      pacePerKm: args["pacePerKm"] as? Double ?? 0,
      calories: args["calories"] as? Double ?? 0,
      steps: args["steps"] as? Int ?? 0,
      isPaused: args["isPaused"] as? Bool ?? false,
      phase: args["phase"] as? String ?? "Work",
      currentRound: args["currentRound"] as? Int ?? 1,
      totalRounds: args["totalRounds"] as? Int ?? 1,
      currentExercise: args["currentExercise"] as? Int ?? 1,
      totalExercises: args["totalExercises"] as? Int ?? 1,
      remainingSeconds: args["remainingSeconds"] as? Int ?? 0
    )
  }

  private func startActivity(args: [String: Any]) {
    stopActivity()
    let attributes = WorkoutActivityAttributes(
      workoutType: args["workoutType"] as? String ?? "running"
    )
    let state = makeState(from: args)
    do {
      currentActivity = try Activity.request(
        attributes: attributes,
        content: .init(state: state, staleDate: nil),
        pushType: nil
      )
    } catch {
      print("LiveActivity start error: \(error)")
    }
  }

  private func updateActivity(args: [String: Any]) {
    guard let activity = currentActivity else { return }
    let state = makeState(from: args)
    Task {
      await activity.update(.init(state: state, staleDate: nil))
    }
  }

  private func stopActivity() {
    guard let activity = currentActivity else { return }
    Task {
      await activity.end(nil, dismissalPolicy: .immediate)
    }
    currentActivity = nil
  }
}

// MARK: – HealthKit Manager

class HealthKitManager: NSObject {
    static let shared = HealthKitManager()
    let healthStore = HKHealthStore()

    private var channel: FlutterMethodChannel?

    func setupChannel(messenger: FlutterBinaryMessenger) {
        channel = FlutterMethodChannel(name: "tryd.app/health_ultra",
                                       binaryMessenger: messenger)
    }

    private func sendUpdate(type: String, value: Double) {
        DispatchQueue.main.async {
            self.channel?.invokeMethod("onHealthDataUpdate",
                                       arguments: ["type": type, "value": value])
        }
    }

    func startObserverQueries() {
        let identifiers: [HKQuantityTypeIdentifier] = [
            .stepCount,
            .distanceWalkingRunning,
            .heartRate
        ]
        for identifier in identifiers {
            guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else { continue }
            healthStore.enableBackgroundDelivery(for: type, frequency: .immediate) { _, _ in }
        }

        guard let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        let stepsQuery = HKObserverQuery(sampleType: stepsType, predicate: nil) { _, completionHandler, _ in
            self.fetchLatestSteps()
            completionHandler()
        }
        healthStore.execute(stepsQuery)

        guard let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) else { return }
        let distanceQuery = HKObserverQuery(sampleType: distanceType, predicate: nil) { _, completionHandler, _ in
            self.fetchLatestDistance()
            completionHandler()
        }
        healthStore.execute(distanceQuery)

        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        let heartRateQuery = HKObserverQuery(sampleType: heartRateType, predicate: nil) { _, completionHandler, _ in
            self.fetchLatestHeartRate()
            completionHandler()
        }
        healthStore.execute(heartRateQuery)
    }

    func fetchLatestSteps() {
        guard let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        let now = Date()
        let start = now.addingTimeInterval(-30)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: now,
                                                     options: .strictStartDate)
        let query = HKStatisticsQuery(quantityType: stepsType,
                                      quantitySamplePredicate: predicate,
                                      options: .cumulativeSum) { _, result, _ in
            if let sum = result?.sumQuantity() {
                let steps = sum.doubleValue(for: HKUnit.count())
                self.sendUpdate(type: "steps", value: steps)
            }
        }
        healthStore.execute(query)
    }

    func fetchLatestDistance() {
        guard let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) else { return }
        let now = Date()
        let start = now.addingTimeInterval(-30)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: now,
                                                     options: .strictStartDate)
        let query = HKStatisticsQuery(quantityType: distanceType,
                                      quantitySamplePredicate: predicate,
                                      options: .cumulativeSum) { _, result, _ in
            if let sum = result?.sumQuantity() {
                let distance = sum.doubleValue(for: HKUnit.meter())
                self.sendUpdate(type: "distance", value: distance)
            }
        }
        healthStore.execute(query)
    }

    func fetchLatestHeartRate() {
        guard let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        let now = Date()
        let start = now.addingTimeInterval(-120)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: now,
                                                     options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: hrType,
                                   predicate: predicate,
                                   limit: 1,
                                   sortDescriptors: [sortDescriptor]) { _, results, _ in
            if let sample = results?.first as? HKQuantitySample {
                let hr = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                self.sendUpdate(type: "heartRate", value: hr)
            }
        }
        healthStore.execute(query)
    }
}
