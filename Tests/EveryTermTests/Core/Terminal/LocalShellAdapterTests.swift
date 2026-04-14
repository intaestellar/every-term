import Testing
import Foundation
@testable import EveryTerm

@Suite("LocalShellAdapter Tests")
struct LocalShellAdapterTests {

    // MARK: - [어려움] 기본 동작

    @Test("셸 프로세스 시작 후 상태 .connected 전이")
    func connectTransition() async throws {
        let adapter = LocalShellAdapter()
        try await adapter.connect()

        let state = await adapter.state
        if case .connected = state {
            #expect(true)
        } else {
            #expect(Bool(false), "connect 후 connected 상태여야 한다")
        }

        await adapter.disconnect()
    }

    @Test("echo 명령 전송 후 outputStream에서 결과 수신")
    func echoCommandOutput() async throws {
        let adapter = LocalShellAdapter()
        try await adapter.connect()

        let stream = await adapter.outputStream
        try await adapter.send(Data("echo hello_test\n".utf8))

        var received = Data()
        for await chunk in stream {
            received.append(chunk)
            if String(data: received, encoding: .utf8)?.contains("hello_test") == true {
                break
            }
        }

        let output = String(data: received, encoding: .utf8) ?? ""
        #expect(output.contains("hello_test"))

        await adapter.disconnect()
    }

    @Test("disconnect() 호출 후 프로세스 종료 및 .disconnected 상태")
    func disconnectTerminatesProcess() async throws {
        let adapter = LocalShellAdapter()
        try await adapter.connect()
        await adapter.disconnect()

        let state = await adapter.state
        if case .disconnected = state {
            #expect(true)
        } else {
            #expect(Bool(false), "disconnect 후 disconnected 상태여야 한다")
        }
    }

    @Test("프로세스 자체 종료 시 .disconnected 상태 전이")
    func processExitTriggersDisconnected() async throws {
        let adapter = LocalShellAdapter()
        try await adapter.connect()

        // exit 명령으로 프로세스 자체 종료
        try await adapter.send(Data("exit\n".utf8))

        // 상태 변경 대기
        let stream = await adapter.stateStream
        for await state in stream {
            if case .disconnected = state {
                #expect(true)
                return
            }
        }
    }

    @Test("RemoteConnection 프로토콜 준수 확인")
    func conformsToRemoteConnection() async {
        let adapter = LocalShellAdapter()
        // 컴파일 타임 확인: RemoteConnection 프로토콜로 사용 가능
        let connection: any RemoteConnection = adapter
        let _ = await connection.id
    }

    // MARK: - [어려움] PTY 크기 조정

    @Test("PTY 크기 변경 확인")
    func resizePTY() async throws {
        let adapter = LocalShellAdapter()
        try await adapter.connect()

        // 크기 변경이 크래시 없이 동작해야 함
        await adapter.resize(columns: 120, rows: 40)

        await adapter.disconnect()
    }

    @Test("여러 번 크기 변경 후 최종 크기 올바름 확인")
    func multipleResizes() async throws {
        let adapter = LocalShellAdapter()
        try await adapter.connect()

        await adapter.resize(columns: 80, rows: 24)
        await adapter.resize(columns: 120, rows: 40)
        await adapter.resize(columns: 200, rows: 50)

        let size = await adapter.currentSize
        #expect(size.columns == 200)
        #expect(size.rows == 50)

        await adapter.disconnect()
    }
}
