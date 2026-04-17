import SwiftUI

// MARK: - Reduce-motion-aware animation helper

extension View {
    /// Apply an animation that respects the user's "Reduce Motion" preference.
    /// When reduce motion is enabled, changes happen instantly (nil animation).
    ///
    /// Usage: `myView.reduceMotionAnimation(.easeInOut(duration: 0.2))`
    public func reduceMotionAnimation(
        _ animation: Animation? = .easeInOut(duration: 0.2)
    ) -> some View {
        modifier(ReduceMotionModifier(animation: animation))
    }
}

private struct ReduceMotionModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    let animation: Animation?

    func body(content: Content) -> some View {
        content.animation(reduceMotion ? nil : animation, value: 0)
    }
}
