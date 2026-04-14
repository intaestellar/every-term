import Testing
import Foundation
@testable import EveryTerm

@Suite("JumpHostResolver Tests")
struct JumpHostResolverTests {

    // MARK: - [보통] 정상 체인

    @Test("Jump Host 없는 단일 세션: 직접 연결")
    @MainActor func directConnectionWithoutJumpHost() throws {
        let session = Session(
            name: "Direct",
            type: .ssh,
            host: "server.com",
            username: "user",
            authMethod: .password
        )

        let resolver = JumpHostResolver()
        let chain = try resolver.resolveChain(for: session, allSessions: [session])

        #expect(chain.count == 1)
        #expect(chain.first?.id == session.id)
    }

    @Test("1단계 Jump (A→B→Target): 체인 순서 올바름 확인")
    @MainActor func singleJumpChain() throws {
        let bastionId = UUID()
        let targetId = UUID()

        let bastion = Session(id: bastionId, name: "Bastion", type: .ssh, host: "bastion.com", username: "jump", authMethod: .key)
        let target = Session(id: targetId, name: "Target", type: .ssh, host: "10.0.0.5", username: "deploy", authMethod: .key, jumpHostId: bastionId)

        let resolver = JumpHostResolver()
        let chain = try resolver.resolveChain(for: target, allSessions: [bastion, target])

        #expect(chain.count == 2)
        #expect(chain[0].id == bastionId)
        #expect(chain[1].id == targetId)
    }

    @Test("2단계 Jump (A→B→C→Target): 체인 해석 올바름")
    @MainActor func twoJumpChain() throws {
        let idA = UUID()
        let idB = UUID()
        let idC = UUID()

        let sessionA = Session(id: idA, name: "A", type: .ssh, host: "a.com", username: "u", authMethod: .password)
        let sessionB = Session(id: idB, name: "B", type: .ssh, host: "b.com", username: "u", authMethod: .password, jumpHostId: idA)
        let sessionC = Session(id: idC, name: "C", type: .ssh, host: "c.com", username: "u", authMethod: .password, jumpHostId: idB)

        let resolver = JumpHostResolver()
        let chain = try resolver.resolveChain(for: sessionC, allSessions: [sessionA, sessionB, sessionC])

        #expect(chain.count == 3)
        #expect(chain[0].id == idA)
        #expect(chain[1].id == idB)
        #expect(chain[2].id == idC)
    }

    // MARK: - [보통] 순환 참조 감지

    @Test("자기 참조 순환 감지 → 에러 throw")
    @MainActor func selfReferenceCycleThrows() {
        let idA = UUID()
        let session = Session(id: idA, name: "A", type: .ssh, host: "a.com", username: "u", authMethod: .password, jumpHostId: idA)

        let resolver = JumpHostResolver()
        #expect(throws: JumpHostResolverError.self) {
            try resolver.resolveChain(for: session, allSessions: [session])
        }
    }

    @Test("간접 순환 감지 (A→B→C→A) → 에러 throw")
    @MainActor func indirectCycleThrows() {
        let idA = UUID()
        let idB = UUID()
        let idC = UUID()

        let sessionA = Session(id: idA, name: "A", type: .ssh, host: "a.com", username: "u", authMethod: .password, jumpHostId: idB)
        let sessionB = Session(id: idB, name: "B", type: .ssh, host: "b.com", username: "u", authMethod: .password, jumpHostId: idC)
        let sessionC = Session(id: idC, name: "C", type: .ssh, host: "c.com", username: "u", authMethod: .password, jumpHostId: idA)

        let resolver = JumpHostResolver()
        #expect(throws: JumpHostResolverError.self) {
            try resolver.resolveChain(for: sessionA, allSessions: [sessionA, sessionB, sessionC])
        }
    }

    @Test("삭제된 세션 참조 (nil jumpHost) → 에러 throw")
    @MainActor func missingJumpHostThrows() {
        let session = Session(
            name: "Orphan",
            type: .ssh,
            host: "a.com",
            username: "u",
            authMethod: .password,
            jumpHostId: UUID() // 존재하지 않는 세션
        )

        let resolver = JumpHostResolver()
        #expect(throws: JumpHostResolverError.self) {
            try resolver.resolveChain(for: session, allSessions: [session])
        }
    }
}
