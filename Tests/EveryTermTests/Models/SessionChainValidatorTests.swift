import Testing
import Foundation
@testable import EveryTerm

@Suite("SessionChainValidator Tests")
struct SessionChainValidatorTests {

    @Test("Jump Host 체인 없는 단일 세션: 유효")
    @MainActor func singleSessionWithoutJumpHost() throws {
        let session = Session(
            name: "Direct",
            type: .ssh,
            host: "server.com",
            username: "user",
            authMethod: .password
        )

        let validator = SessionChainValidator()
        #expect(throws: Never.self) {
            try validator.validate(session: session, allSessions: [session])
        }
    }

    @Test("선형 체인 (A→B→C): 유효")
    @MainActor func linearChainIsValid() throws {
        let idA = UUID()
        let idB = UUID()
        let idC = UUID()

        let sessionC = Session(id: idC, name: "C", type: .ssh, host: "c.com", username: "u", authMethod: .password)
        let sessionB = Session(id: idB, name: "B", type: .ssh, host: "b.com", username: "u", authMethod: .password, jumpHostId: idC)
        let sessionA = Session(id: idA, name: "A", type: .ssh, host: "a.com", username: "u", authMethod: .password, jumpHostId: idB)

        let validator = SessionChainValidator()
        let allSessions = [sessionA, sessionB, sessionC]
        #expect(throws: Never.self) {
            try validator.validate(session: sessionA, allSessions: allSessions)
        }
    }

    @Test("자기 자신 참조 (A→A): 순환 감지 에러")
    @MainActor func selfReferenceDetected() {
        let idA = UUID()
        let session = Session(id: idA, name: "A", type: .ssh, host: "a.com", username: "u", authMethod: .password, jumpHostId: idA)

        let validator = SessionChainValidator()
        #expect(throws: SessionChainError.self) {
            try validator.validate(session: session, allSessions: [session])
        }
    }

    @Test("2-노드 순환 (A→B→A): 순환 감지 에러")
    @MainActor func twoNodeCycleDetected() {
        let idA = UUID()
        let idB = UUID()

        let sessionA = Session(id: idA, name: "A", type: .ssh, host: "a.com", username: "u", authMethod: .password, jumpHostId: idB)
        let sessionB = Session(id: idB, name: "B", type: .ssh, host: "b.com", username: "u", authMethod: .password, jumpHostId: idA)

        let validator = SessionChainValidator()
        #expect(throws: SessionChainError.self) {
            try validator.validate(session: sessionA, allSessions: [sessionA, sessionB])
        }
    }

    @Test("3-노드 순환 (A→B→C→A): 순환 감지 에러")
    @MainActor func threeNodeCycleDetected() {
        let idA = UUID()
        let idB = UUID()
        let idC = UUID()

        let sessionA = Session(id: idA, name: "A", type: .ssh, host: "a.com", username: "u", authMethod: .password, jumpHostId: idB)
        let sessionB = Session(id: idB, name: "B", type: .ssh, host: "b.com", username: "u", authMethod: .password, jumpHostId: idC)
        let sessionC = Session(id: idC, name: "C", type: .ssh, host: "c.com", username: "u", authMethod: .password, jumpHostId: idA)

        let validator = SessionChainValidator()
        #expect(throws: SessionChainError.self) {
            try validator.validate(session: sessionA, allSessions: [sessionA, sessionB, sessionC])
        }
    }

    @Test("존재하지 않는 jumpHostId 참조: 에러 처리")
    @MainActor func missingJumpHostReference() {
        let session = Session(
            name: "Orphan",
            type: .ssh,
            host: "a.com",
            username: "u",
            authMethod: .password,
            jumpHostId: UUID() // 존재하지 않는 ID
        )

        let validator = SessionChainValidator()
        #expect(throws: SessionChainError.self) {
            try validator.validate(session: session, allSessions: [session])
        }
    }

    @Test("빈 세션 목록에서 검증: 에러")
    @MainActor func emptySessionList() {
        let session = Session(
            name: "Alone",
            type: .ssh,
            host: "a.com",
            username: "u",
            authMethod: .password,
            jumpHostId: UUID()
        )

        let validator = SessionChainValidator()
        #expect(throws: SessionChainError.self) {
            try validator.validate(session: session, allSessions: [])
        }
    }
}
