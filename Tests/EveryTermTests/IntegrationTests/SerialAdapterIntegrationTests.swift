import Testing
import Foundation
import Darwin
@testable import EveryTerm

/// FIX-1 통합 테스트: PTY 쌍을 열어 SerialAdapter 가 read 루프를 통해
/// outputStream 으로 수신 데이터를 정확히 방출하는지 확인한다.
///
/// 환경 가드: SERIAL_INTEGRATION=1 일 때만 실행 (로컬/수동 검증용).
/// CI 의 기본 441개 테스트 수에는 포함되지 않도록 skip 처리한다.
@Suite("Serial Adapter Integration (PTY)")
struct SerialAdapterIntegrationTests {

    private static var isEnabled: Bool {
        ProcessInfo.processInfo.environment["SERIAL_INTEGRATION"] == "1"
    }

    @Test("PTY 슬레이브에 쓴 바이트가 SerialAdapter.outputStream 으로 수신된다")
    @MainActor func ptyLoopback_readsBackIntoOutputStream() async throws {
        guard Self.isEnabled else {
            // 환경 미설정 시 즉시 반환 (skip 효과).
            return
        }

        // 1) PTY 마스터 open + grant/unlock + slave 경로 획득
        let master = posix_openpt(O_RDWR | O_NOCTTY)
        #expect(master >= 0)
        guard master >= 0 else { return }
        defer { Darwin.close(master) }

        #expect(grantpt(master) == 0)
        #expect(unlockpt(master) == 0)

        guard let slaveCStr = ptsname(master) else {
            Issue.record("ptsname 실패")
            return
        }
        let slavePath = String(cString: slaveCStr)

        // 2) SerialAdapter 생성 및 연결. 화이트리스트에 실제 PTY 슬레이브 경로가
        //    포함되지 않을 수 있으므로 이 테스트는 SERIAL_INTEGRATION 설정 시
        //    slavePath 의 prefix 가 허용 리스트에 들어 있어야 한다.
        //    (자체 검증 실패 시 즉시 반환.)
        guard SerialAdapter.isValidDevicePath(slavePath) else {
            Issue.record("PTY slave path \(slavePath) 가 허용 prefix 에 없음. 환경별 SKIP.")
            return
        }

        let config = SerialSessionConfig(sessionId: UUID())
        config.devicePath = slavePath
        let adapter = SerialAdapter(config: config)

        do {
            try await adapter.connect()
        } catch {
            Issue.record("connect 실패: \(error)")
            return
        }

        // 3) 마스터 쪽으로 bytes 전송 → slave(adapter) 가 수신해야 함
        let payload: [UInt8] = [0x48, 0x65, 0x6C, 0x6C, 0x6F] // "Hello"
        payload.withUnsafeBytes { buf in
            _ = Darwin.write(master, buf.baseAddress, buf.count)
        }

        // 4) outputStream 에서 읽어서 비교
        let stream = await adapter.outputStream
        let receivedTask = Task { () -> Data in
            var collected = Data()
            for await chunk in stream {
                collected.append(chunk)
                if collected.count >= payload.count { break }
            }
            return collected
        }

        // 간단한 타임아웃
        let deadline = Date().addingTimeInterval(2.0)
        while !receivedTask.isCancelled && receivedTask.isCancelled == false && Date() < deadline {
            try? await Task.sleep(nanoseconds: 50_000_000)
            if receivedTask.isCancelled { break }
            // 값이 준비되었는지 확인하기 위한 race: 0.05s 마다 loop.
            // 값은 별도 task 에서 수집중이므로 여기서는 wait 만.
            break
        }

        // task 에서 값을 얻는다 (최대 2초까지 기다림).
        let received: Data
        do {
            received = try await withThrowingTaskGroup(of: Data.self) { group in
                group.addTask { await receivedTask.value }
                group.addTask {
                    try await Task.sleep(nanoseconds: 2_000_000_000)
                    throw CancellationError()
                }
                if let first = try await group.next() {
                    group.cancelAll()
                    return first
                }
                return Data()
            }
        } catch {
            receivedTask.cancel()
            await adapter.disconnect()
            Issue.record("outputStream 수신 타임아웃")
            return
        }

        #expect(received == Data(payload))

        await adapter.disconnect()
    }
}
