import SwiftUI
import WidgetKit

@main
struct TrydWorkoutWidgetBundle: WidgetBundle {
    var body: some Widget {
        if #available(iOS 16.1, *) {
            TrydWorkoutLiveActivity()
        }
    }
}
