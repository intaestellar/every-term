import Testing
import Foundation
@testable import EveryTerm

@Suite("Telnet Protocol / Option Negotiator Tests")
struct TelnetOptionNegotiatorTests {

    // MARK: - [쉬움] 커맨드/옵션 rawValue

    @Test("TelnetCommand rawValue (IAC=255, WILL=251, WONT=252, DO=253, DONT=254)")
    func telnetCommandRawValues() {
        #expect(TelnetCommand.iac.rawValue == 255)
        #expect(TelnetCommand.will.rawValue == 251)
        #expect(TelnetCommand.wont.rawValue == 252)
        #expect(TelnetCommand.doCmd.rawValue == 253)
        #expect(TelnetCommand.dont.rawValue == 254)
    }

    @Test("TelnetOption rawValue (ECHO=1, SGA=3, TTYPE=24, NAWS=31)")
    func telnetOptionRawValues() {
        #expect(TelnetOption.echo.rawValue == 1)
        #expect(TelnetOption.sga.rawValue == 3)
        #expect(TelnetOption.ttype.rawValue == 24)
        #expect(TelnetOption.naws.rawValue == 31)
    }

    // MARK: - [쉬움] 순수 데이터 스트림

    @Test("순수 데이터(IAC 없음) → 그대로 사용자 데이터로 방출")
    func pureData_passthrough() {
        var parser = TelnetParser()
        let input = Data([0x48, 0x65, 0x6C, 0x6C, 0x6F]) // "Hello"
        let result = parser.feed(input)

        #expect(result.data == input)
        #expect(result.commands.isEmpty)
    }

    @Test("IAC IAC (0xFF 0xFF) 이스케이프 → 사용자 데이터 0xFF 한 바이트")
    func iacEscape_collapsesToSingleByte() {
        var parser = TelnetParser()
        let input = Data([0xFF, 0xFF])
        let result = parser.feed(input)

        #expect(result.data == Data([0xFF]))
        #expect(result.commands.isEmpty)
    }

    // MARK: - [보통] 명령 파싱

    @Test("IAC DO NAWS (0xFF 0xFD 0x1F) → .do(.naws)")
    func parseIacDoNaws() {
        var parser = TelnetParser()
        let input = Data([0xFF, 0xFD, 0x1F])
        let result = parser.feed(input)

        #expect(result.data.isEmpty)
        #expect(result.commands.count == 1)
        if let first = result.commands.first {
            #expect(first == .doOption(.naws))
        }
    }

    @Test("IAC WILL ECHO (0xFF 0xFB 0x01) → .will(.echo)")
    func parseIacWillEcho() {
        var parser = TelnetParser()
        let input = Data([0xFF, 0xFB, 0x01])
        let result = parser.feed(input)

        #expect(result.commands.count == 1)
        if let first = result.commands.first {
            #expect(first == .will(.echo))
        }
    }

    @Test("사용자 데이터 + 명령 혼합 → 데이터/명령 분리")
    func mixedDataAndCommand() {
        var parser = TelnetParser()
        // "A" + IAC DO NAWS + "B"
        let input = Data([0x41, 0xFF, 0xFD, 0x1F, 0x42])
        let result = parser.feed(input)

        #expect(result.data == Data([0x41, 0x42]))
        #expect(result.commands.count == 1)
    }

    @Test("청크 경계에서 명령이 쪼개져 도착해도 최종 파싱 성공 (streaming)")
    func streamingParse_acrossChunks() {
        var parser = TelnetParser()
        let r1 = parser.feed(Data([0xFF]))
        let r2 = parser.feed(Data([0xFD]))
        let r3 = parser.feed(Data([0x1F]))

        let totalCommands = r1.commands.count + r2.commands.count + r3.commands.count
        #expect(totalCommands == 1)
    }

    @Test("NAWS 서브네고시에이션 생성 바이트 (width=80, height=24)")
    func buildNAWSSubnegotiation() {
        let bytes = TelnetProtocol.buildNAWSSubnegotiation(width: 80, height: 24)
        // IAC SB NAWS 0 80 0 24 IAC SE
        let expected: [UInt8] = [0xFF, 0xFA, 0x1F, 0x00, 0x50, 0x00, 0x18, 0xFF, 0xF0]
        #expect(Array(bytes) == expected)
    }

    // MARK: - [어려움] 옵션 협상 상태 머신

    @Test("서버 DO NAWS → 클라이언트 WILL NAWS 자동 응답 생성")
    func negotiator_replyToDoNAWS() async {
        let negotiator = TelnetOptionNegotiator()
        let reply = await negotiator.respond(to: .doOption(.naws))
        #expect(reply == Data([0xFF, 0xFB, 0x1F])) // IAC WILL NAWS
    }

    @Test("이미 합의된 옵션 재요청 시 응답 없음 (Q Method loop 방지)")
    func negotiator_ignoreDuplicateAgreedOption() async {
        let negotiator = TelnetOptionNegotiator()
        _ = await negotiator.respond(to: .doOption(.naws))
        let secondReply = await negotiator.respond(to: .doOption(.naws))
        #expect(secondReply.isEmpty)
    }

    // MARK: - [어려움] FIX-4: Subnegotiation 버퍼 상한 (DoS 방어)

    @Test("IAC SE 없이 SB payload 가 상한을 초과해도 파서는 OOM 없이 복귀하며 이벤트를 발생시키지 않는다")
    func sbBuffer_exceedsCap_isDroppedAndStateRecovers() {
        var parser = TelnetParser()

        // IAC SB NAWS [ maxSize+1 바이트의 쓰레기 payload ] (SE 없음)
        var input = Data([0xFF, 0xFA, 0x1F])
        let oversized = TelnetParser.maxSubnegotiationSize + 1
        input.append(contentsOf: [UInt8](repeating: 0x41, count: oversized))

        let result1 = parser.feed(input)
        // SE 를 보내지 않았고 상한 초과 → subnegotiation 이벤트 없음, data 도 비어야 함
        #expect(result1.commands.isEmpty)
        #expect(result1.data.isEmpty)

        // 파서가 .data state 로 정상 복귀했는지: 순수 텍스트를 먹여보고 그대로 나오는지 확인
        let result2 = parser.feed(Data([0x48, 0x69])) // "Hi"
        #expect(result2.data == Data([0x48, 0x69]))
        #expect(result2.commands.isEmpty)
    }

    @Test("상한 이하의 SB payload 는 정상 수집되어 subnegotiation 이벤트로 노출된다")
    func sbBuffer_withinCap_emitsEvent() {
        var parser = TelnetParser()
        // NAWS: IAC SB NAWS 0 80 0 24 IAC SE → 정상 payload
        let input = Data([0xFF, 0xFA, 0x1F, 0x00, 0x50, 0x00, 0x18, 0xFF, 0xF0])
        let result = parser.feed(input)
        #expect(result.commands.count == 1)
        if case .subnegotiation(let opt, let payload) = result.commands.first {
            #expect(opt == .naws)
            #expect(payload == Data([0x00, 0x50, 0x00, 0x18]))
        } else {
            Issue.record("subnegotiation 이벤트가 있어야 한다")
        }
    }
}
