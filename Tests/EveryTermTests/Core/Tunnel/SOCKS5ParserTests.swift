import Testing
import Foundation
@testable import EveryTerm

@Suite("SOCKS5 Parser Tests")
struct SOCKS5ParserTests {

    // MARK: - [쉬움] 핸드셰이크

    @Test("인증 없음 핸드셰이크 요청 바이트 파싱 (0x05, 0x01, 0x00)")
    func parseNoAuthHandshakeRequest() throws {
        let requestBytes: [UInt8] = [0x05, 0x01, 0x00]
        let data = Data(requestBytes)
        let result = try SOCKS5Parser.parseHandshake(data)

        #expect(result.version == 5)
        #expect(result.methods.contains(0x00)) // NO AUTHENTICATION
    }

    @Test("인증 없음 핸드셰이크 응답 바이트 생성 (0x05, 0x00)")
    func buildNoAuthHandshakeResponse() {
        let response = SOCKS5Parser.buildHandshakeResponse(method: 0x00)

        #expect(response.count == 2)
        #expect(response[0] == 0x05)
        #expect(response[1] == 0x00)
    }

    // MARK: - [보통] CONNECT 요청 파싱

    @Test("CONNECT 요청 파싱 - IPv4 대상 주소 추출")
    func parseConnectRequestIPv4() throws {
        // VER=5, CMD=CONNECT(1), RSV=0, ATYP=IPv4(1), IP=192.168.1.1, PORT=80
        var data = Data([0x05, 0x01, 0x00, 0x01])
        data.append(contentsOf: [192, 168, 1, 1])  // IPv4
        data.append(contentsOf: [0x00, 0x50])       // Port 80

        let request = try SOCKS5Parser.parseConnectRequest(data)

        #expect(request.host == "192.168.1.1")
        #expect(request.port == 80)
    }

    @Test("CONNECT 요청 파싱 - 도메인명 대상 주소 추출")
    func parseConnectRequestDomain() throws {
        // VER=5, CMD=CONNECT(1), RSV=0, ATYP=DOMAIN(3)
        var data = Data([0x05, 0x01, 0x00, 0x03])
        let domain = "example.com"
        data.append(UInt8(domain.count))
        data.append(contentsOf: domain.utf8)
        data.append(contentsOf: [0x00, 0x50]) // Port 80

        let request = try SOCKS5Parser.parseConnectRequest(data)

        #expect(request.host == "example.com")
        #expect(request.port == 80)
    }

    @Test("CONNECT 성공 응답 바이트 생성")
    func buildConnectSuccessResponse() {
        let response = SOCKS5Parser.buildConnectResponse(success: true)

        #expect(response.count >= 10)
        #expect(response[0] == 0x05) // VER
        #expect(response[1] == 0x00) // REP=succeeded
    }

    // MARK: - [어려움] 인증 / 에러

    @Test("사용자명+비밀번호 인증 서브네고시에이션 파싱 (RFC 1929)")
    func parseUsernamePasswordAuth() throws {
        // VER=0x01, ULEN=4, UNAME="user", PLEN=4, PASSWD="pass"
        var data = Data([0x01, 0x04])
        data.append(contentsOf: "user".utf8)
        data.append(0x04)
        data.append(contentsOf: "pass".utf8)

        let auth = try SOCKS5Parser.parseUsernamePassword(data)

        #expect(auth.username == "user")
        #expect(auth.password == "pass")
    }

    @Test("불완전한 패킷 수신 시 에러 처리")
    func incompletePacketThrows() {
        let incompleteData = Data([0x05]) // 핸드셰이크인데 메서드 정보 없음

        #expect(throws: SOCKS5ParseError.self) {
            try SOCKS5Parser.parseHandshake(incompleteData)
        }
    }
}
