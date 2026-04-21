import Testing
import Foundation
@testable import EveryTerm

@Suite("AccessibilityLabelsCatalog Tests")
struct AccessibilityLabelsTests {

    // MARK: - [쉬움] 핵심 키 존재

    @Test("핵심 키 존재 — newSession / closeTab / connect / disconnect")
    func coreKeysExist() {
        #expect(AccessibilityLabels.newSession.isEmpty == false)
        #expect(AccessibilityLabels.closeTab.isEmpty == false)
        #expect(AccessibilityLabels.connect.isEmpty == false)
        #expect(AccessibilityLabels.disconnect.isEmpty == false)
    }

    @Test("각 라벨 문자열 공백이 아닌 길이 ≥ 2")
    func labelsMinLength() {
        let labels = [
            AccessibilityLabels.newSession,
            AccessibilityLabels.closeTab,
            AccessibilityLabels.connect,
            AccessibilityLabels.disconnect,
        ]
        for label in labels {
            let trimmed = label.trimmingCharacters(in: .whitespaces)
            #expect(trimmed.count >= 2)
        }
    }

    // MARK: - [보통] label + hint 쌍

    @Test("label/hint 쌍 등록 — newSessionLabel + newSessionHint 모두 존재")
    func labelHintPairsExist() {
        #expect(AccessibilityLabels.newSessionLabel.isEmpty == false)
        #expect(AccessibilityLabels.newSessionHint.isEmpty == false)
    }

}
