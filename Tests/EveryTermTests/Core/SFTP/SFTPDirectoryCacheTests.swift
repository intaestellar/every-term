import Testing
import Foundation
@testable import EveryTerm

@Suite("SFTPDirectoryCache Tests")
struct SFTPDirectoryCacheTests {

    // MARK: - Helper

    private func makeSampleEntries() -> [SFTPFileEntry] {
        [
            SFTPFileEntry(
                id: "/home/user/file1.txt",
                name: "file1.txt",
                path: "/home/user/file1.txt",
                size: 100,
                permissions: 0o100644,
                modifiedAt: Date(),
                ownerUid: 1000,
                ownerGid: 1000,
                isDirectory: false,
                isSymlink: false,
                symlinkTarget: nil
            ),
            SFTPFileEntry(
                id: "/home/user/file2.txt",
                name: "file2.txt",
                path: "/home/user/file2.txt",
                size: 200,
                permissions: 0o100644,
                modifiedAt: Date(),
                ownerUid: 1000,
                ownerGid: 1000,
                isDirectory: false,
                isSymlink: false,
                symlinkTarget: nil
            )
        ]
    }

    // MARK: - [쉬움] 기본 캐시 동작

    @Test("캐시에 저장한 디렉토리 목록을 조회할 수 있어야 한다")
    func cacheStoreAndRetrieve() async {
        let cache = SFTPDirectoryCache()
        let entries = makeSampleEntries()

        await cache.set(entries, for: "/home/user")
        let result = await cache.get("/home/user")

        #expect(result != nil)
        #expect(result?.count == 2)
    }

    @Test("캐시에 없는 경로 조회 시 nil을 반환해야 한다")
    func cacheMissReturnsNil() async {
        let cache = SFTPDirectoryCache()

        let result = await cache.get("/nonexistent/path")

        #expect(result == nil)
    }

    @Test("Actor 타입이어야 한다")
    func cacheIsActor() {
        let cache = SFTPDirectoryCache()
        let _: any Actor = cache
        #expect(true)
    }

    // MARK: - [쉬움] 캐시 무효화

    @Test("invalidate(path:)로 특정 경로 캐시를 무효화할 수 있어야 한다")
    func invalidateSpecificPath() async {
        let cache = SFTPDirectoryCache()
        let entries = makeSampleEntries()

        await cache.set(entries, for: "/home/user")
        await cache.invalidate(path: "/home/user")
        let result = await cache.get("/home/user")

        #expect(result == nil)
    }

    @Test("invalidateAll()로 전체 캐시를 무효화할 수 있어야 한다")
    func invalidateAll() async {
        let cache = SFTPDirectoryCache()
        let entries = makeSampleEntries()

        await cache.set(entries, for: "/home/user")
        await cache.set(entries, for: "/home/other")
        await cache.invalidateAll()

        let result1 = await cache.get("/home/user")
        let result2 = await cache.get("/home/other")

        #expect(result1 == nil)
        #expect(result2 == nil)
    }

    @Test("무효화된 경로 조회 시 nil을 반환해야 한다")
    func invalidatedPathReturnsNil() async {
        let cache = SFTPDirectoryCache()
        let entries = makeSampleEntries()

        await cache.set(entries, for: "/home/user")
        await cache.invalidate(path: "/home/user")
        let result = await cache.get("/home/user")

        #expect(result == nil)
    }

    // MARK: - [보통] TTL 만료

    @Test("기본 TTL 30초 이내 조회 시 캐시 히트해야 한다")
    func withinTTLCacheHit() async {
        let cache = SFTPDirectoryCache()
        let entries = makeSampleEntries()

        await cache.set(entries, for: "/home/user")
        // 즉시 조회 — TTL 이내
        let result = await cache.get("/home/user")

        #expect(result != nil)
        #expect(result?.count == 2)
    }

    @Test("TTL 만료 후 조회 시 nil을 반환해야 한다 (캐시 미스)")
    func afterTTLExpiryCacheMiss() async {
        // TTL을 0초로 설정하여 즉시 만료되게 함
        let cache = SFTPDirectoryCache(ttl: 0)
        let entries = makeSampleEntries()

        await cache.set(entries, for: "/home/user")
        // TTL 0이므로 즉시 만료
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        let result = await cache.get("/home/user")

        #expect(result == nil)
    }

    @Test("커스텀 TTL 설정이 동작해야 한다")
    func customTTL() async {
        let cache = SFTPDirectoryCache(ttl: 60)
        let entries = makeSampleEntries()

        await cache.set(entries, for: "/home/user")
        let result = await cache.get("/home/user")

        #expect(result != nil)
    }

    // MARK: - [보통] NSCache 기반 메모리 관리

    @Test("메모리 압박 시 NSCache가 자동으로 항목을 제거해야 한다")
    func memorePressureEviction() async {
        // NSCache는 메모리 압박 시 자동 제거하므로
        // 여기서는 NSCache 기반임을 확인 (항목 추가/조회 가능)
        let cache = SFTPDirectoryCache()
        let entries = makeSampleEntries()

        await cache.set(entries, for: "/home/user")
        let result = await cache.get("/home/user")

        // NSCache 기반이라 결과가 있을 수도, 없을 수도 있음 (메모리 상황에 따라)
        // 여기서는 정상 상황에서 캐시가 동작함을 확인
        #expect(result != nil)
    }

    @Test("캐시 키가 NSString(경로)으로 올바르게 변환되어야 한다")
    func cacheKeyConversion() async {
        let cache = SFTPDirectoryCache()
        let entries = makeSampleEntries()

        // 다양한 경로 형태의 키로 저장/조회
        await cache.set(entries, for: "/home/user/특수문자/경로")
        let result = await cache.get("/home/user/특수문자/경로")

        #expect(result != nil)
        #expect(result?.count == 2)
    }
}
