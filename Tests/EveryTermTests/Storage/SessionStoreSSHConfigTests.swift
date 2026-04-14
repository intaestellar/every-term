import Testing
import Foundation
@testable import EveryTerm

@Suite("SessionStore SSH Config Parsing Tests")
struct SessionStoreSSHConfigTests {

    @Test("기본 Host 블록 파싱: HostName, User, Port, IdentityFile 추출")
    @MainActor func parseBasicHostBlock() throws {
        let config = """
        Host myserver
            HostName 192.168.1.100
            User admin
            Port 2222
            IdentityFile ~/.ssh/id_rsa
        """

        let store = SessionStore.forTesting()
        let sessions = try store.parseSSHConfig(config)

        #expect(sessions.count == 1)
        let session = try #require(sessions.first)
        #expect(session.host == "192.168.1.100")
        #expect(session.username == "admin")
        #expect(session.port == 2222)
        #expect(session.keyPath == "~/.ssh/id_rsa")
    }

    @Test("ProxyJump 지시어 파싱 → jumpHostId 매핑")
    @MainActor func parseProxyJump() throws {
        let config = """
        Host bastion
            HostName bastion.example.com
            User jump

        Host target
            HostName 10.0.0.5
            User deploy
            ProxyJump bastion
        """

        let store = SessionStore.forTesting()
        let sessions = try store.parseSSHConfig(config)

        #expect(sessions.count == 2)
        let target = sessions.first(where: { $0.name == "target" })
        #expect(target?.jumpHostId != nil)
    }

    @Test("여러 Host 블록 동시 파싱")
    @MainActor func parseMultipleHosts() throws {
        let config = """
        Host server1
            HostName 10.0.0.1
            User admin

        Host server2
            HostName 10.0.0.2
            User root
            Port 22

        Host server3
            HostName 10.0.0.3
            User deploy
        """

        let store = SessionStore.forTesting()
        let sessions = try store.parseSSHConfig(config)

        #expect(sessions.count == 3)
    }

    @Test("와일드카드 Host(Host *) 처리 — 무시")
    @MainActor func wildcardHostIgnored() throws {
        let config = """
        Host *
            ServerAliveInterval 60

        Host myserver
            HostName server.com
            User user
        """

        let store = SessionStore.forTesting()
        let sessions = try store.parseSSHConfig(config)

        #expect(sessions.count == 1)
        #expect(sessions.first?.name == "myserver")
    }

    @Test("빈 파일 처리")
    @MainActor func emptyConfig() throws {
        let store = SessionStore.forTesting()
        let sessions = try store.parseSSHConfig("")

        #expect(sessions.isEmpty)
    }

    @Test("주석 줄(#) 무시")
    @MainActor func commentsIgnored() throws {
        let config = """
        # This is a comment
        Host myserver
            # Another comment
            HostName server.com
            User user
        """

        let store = SessionStore.forTesting()
        let sessions = try store.parseSSHConfig(config)

        #expect(sessions.count == 1)
    }
}
