import SwiftUI

// MARK: - Reduce-motion-aware animation helper

extension View {
    /// Apply an animation that respects the user's "Reduce Motion" preference.
    /// When reduce motion is enabled, changes happen instantly (nil animation).
    ///
    /// Usage: `myView.reduceMotionAnimation(.easeInOut(duration: 0.2))`
    @ViewBuilder
    public func reduceMotionAnimation(
        _ animation: Animation? = .easeInOut(duration: 0.2)
    ) -> some View {
        self.animation(animation, value: 0)
    }
}
