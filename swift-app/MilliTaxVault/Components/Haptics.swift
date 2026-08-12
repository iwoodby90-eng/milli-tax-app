import Foundation
#if canImport(UIKit)
import UIKit
#endif

enum Haptics {
    static func thunderStrike() {
        #if canImport(UIKit)
        let heavy = UIImpactFeedbackGenerator(style: .heavy)
        heavy.prepare()
        heavy.impactOccurred(intensity: 1.0)
        let rigid = UIImpactFeedbackGenerator(style: .rigid)
        rigid.prepare()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            rigid.impactOccurred(intensity: 1.0)
        }
        let notif = UINotificationFeedbackGenerator()
        notif.prepare()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            notif.notificationOccurred(.success)
        }
        #endif
    }

    static func softPulse() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        #endif
    }
}
