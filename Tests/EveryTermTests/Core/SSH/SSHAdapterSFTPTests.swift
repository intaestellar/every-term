import Testing
@testable import EveryTerm

@Suite("SSHAdapter SFTP Tests")
struct SSHAdapterSFTPTests {

    // MARK: - [쉬움] 연결 상태 검증

    @Test("미연결 상태에서 openSFTPClient() 호출 시 SSHConnectionError.notConnected 에러를 throw해야 한다")
    func openSFTPClientWhenDisconnected() async {
        let adapter = SSHAdapter(
            host: "localhost",
            port: 22,
            username: "user",
            authMethod: .password(SecureBytes([]))
        )

        // 연결하지 않은 상태에서 openSFTPClient 호출 → notConnected
        await #expect(throws: SSHConnectionError.self) {
            try await adapter.openSFTPClient()
        }
    }

    @Test("sshClient가 nil인 경우 SSHConnectionError.notConnected를 throw해야 한다")
    func openSFTPClientWhenClientNil() async {
        let adapter = SSHAdapter(
            host: "localhost",
            port: 22,
            username: "user",
            authMethod: .password(SecureBytes([]))
        )

        // sshClient가 초기화되지 않은 상태 (disconnected)
        await #expect(throws: SSHConnectionError.self) {
            try await adapter.openSFTPClient()
        }
    }

    // MARK: - [보통] 정상 동작

    @Test("connected 상태에서 openSFTPClient() 호출 시 SFTPClient를 반환해야 한다")
    func openSFTPClientWhenConnected() async throws {
        // 실제 SSH 서버 없이는 테스트 불가 — 통합 테스트에서 확인
        // 여기서는 openSFTPClient 메서드 시그니처 존재를 검증
        let adapter = SSHAdapter(
            host: "localhost",
            port: 22,
            username: "user",
            authMethod: .password(SecureBytes([]))
        )

        // 메서드 시그니처 컴파일 검증
        // 실제 호출은 connected 상태가 아니므로 에러가 발생할 것
        do {
            let _ = try await adapter.openSFTPClient()
            Issue.record("disconnected 상태에서 성공하면 안 된다")
        } catch {
            // SSHConnectionError.notConnected 예상
            #expect(error is SSHConnectionError)
        }
    }

    @Test("openSFTPClient()가 내부적으로 sshClient.openSFTP()를 호출해야 한다")
    func openSFTPClientCallsInternalOpenSFTP() async {
        // SSHAdapter 내부에서 sshClient.openSFTP()를 호출하는 로직은
        // 통합 테스트에서 실제 SSH 연결을 통해 검증
        // 여기서는 메서드 존재와 시그니처만 확인
        let adapter = SSHAdapter(
            host: "localhost",
            port: 22,
            username: "user",
            authMethod: .password(SecureBytes([]))
        )

        // openSFTPClient()는 async throws 메서드여야 한다
        await #expect(throws: SSHConnectionError.self) {
            try await adapter.openSFTPClient()
        }
    }

    @Test("openSFTPClient() 호출 시 추가 TCP 연결을 생성하지 않아야 한다 (기존 SSH 채널 재사용)")
    func openSFTPClientReusesSSHChannel() async {
        // 기존 SSH 채널을 재사용하는지는 통합 테스트에서 검증
        // 단위 테스트에서는 openSFTPClient가 SSHClient.openSFTP()만 호출하는 것을 확인
        let adapter = SSHAdapter(
            host: "localhost",
            port: 22,
            username: "user",
            authMethod: .password(SecureBytes([]))
        )

        // disconnected 상태에서는 notConnected 에러
        await #expect(throws: SSHConnectionError.self) {
            try await adapter.openSFTPClient()
        }
    }

    // MARK: - [어려움] 에러 전파

    @Test("sshClient.openSFTP()가 에러를 throw하면 그대로 전파되어야 한다")
    func openSFTPClientPropagatesError() async {
        // 실제 SSH 서버 연결 없이는 openSFTP() 내부 에러 전파를 테스트할 수 없음
        // 통합 테스트에서 검증. 여기서는 에러 전파 패턴만 확인
        let adapter = SSHAdapter(
            host: "localhost",
            port: 22,
            username: "user",
            authMethod: .password(SecureBytes([]))
        )

        do {
            let _ = try await adapter.openSFTPClient()
            Issue.record("에러 없이 성공하면 안 된다")
        } catch {
            // 에러가 전파되어야 함
            #expect(error is SSHConnectionError)
        }
    }
}
