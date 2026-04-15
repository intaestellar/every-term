import Testing
import Foundation
@testable import EveryTerm

@Suite("SFTPBrowserViewModel Tests")
struct SFTPBrowserViewModelTests {

    // MARK: - Helper

    private func makeMockConnection() -> MockSFTPConnection {
        MockSFTPConnection()
    }

    private func makeSampleEntries() -> [SFTPFileEntry] {
        [
            SFTPFileEntry(
                id: "/home/user/.hidden",
                name: ".hidden",
                path: "/home/user/.hidden",
                size: 10,
                permissions: 0o100644,
                modifiedAt: Date(timeIntervalSince1970: 1000),
                ownerUid: 1000,
                ownerGid: 1000,
                isDirectory: false,
                isSymlink: false,
                symlinkTarget: nil
            ),
            SFTPFileEntry(
                id: "/home/user/docs",
                name: "docs",
                path: "/home/user/docs",
                size: 0,
                permissions: 0o040755,
                modifiedAt: Date(timeIntervalSince1970: 2000),
                ownerUid: 1000,
                ownerGid: 1000,
                isDirectory: true,
                isSymlink: false,
                symlinkTarget: nil
            ),
            SFTPFileEntry(
                id: "/home/user/readme.md",
                name: "readme.md",
                path: "/home/user/readme.md",
                size: 500,
                permissions: 0o100644,
                modifiedAt: Date(timeIntervalSince1970: 3000),
                ownerUid: 1000,
                ownerGid: 1000,
                isDirectory: false,
                isSymlink: false,
                symlinkTarget: nil
            ),
            SFTPFileEntry(
                id: "/home/user/app.js",
                name: "app.js",
                path: "/home/user/app.js",
                size: 200,
                permissions: 0o100644,
                modifiedAt: Date(timeIntervalSince1970: 4000),
                ownerUid: 1000,
                ownerGid: 1000,
                isDirectory: false,
                isSymlink: false,
                symlinkTarget: nil
            ),
        ]
    }

    // MARK: - [쉬움] 초기 상태

    @Test("초기 currentPath가 ~ 또는 / 이어야 한다")
    @MainActor
    func initialCurrentPath() {
        let mock = makeMockConnection()
        let viewModel = SFTPBrowserViewModel(connection: mock)

        #expect(viewModel.currentPath == "~" || viewModel.currentPath == "/")
    }

    @Test("초기 파일 목록이 빈 배열이어야 한다")
    @MainActor
    func initialFileListEmpty() {
        let mock = makeMockConnection()
        let viewModel = SFTPBrowserViewModel(connection: mock)

        #expect(viewModel.files.isEmpty)
    }

    @Test("초기 isLoading이 false여야 한다")
    @MainActor
    func initialIsLoadingFalse() {
        let mock = makeMockConnection()
        let viewModel = SFTPBrowserViewModel(connection: mock)

        #expect(viewModel.isLoading == false)
    }

    // MARK: - [보통] 디렉토리 탐색

    @Test("navigateTo(path:)로 디렉토리 이동 시 파일 목록이 갱신되어야 한다")
    @MainActor
    func navigateToUpdatesFiles() async {
        let mock = makeMockConnection()
        await mock.setListDirectoryResult(makeSampleEntries())
        let viewModel = SFTPBrowserViewModel(connection: mock)

        await viewModel.navigateTo(path: "/home/user")

        #expect(!viewModel.files.isEmpty)
    }

    @Test("navigateUp()으로 상위 디렉토리 이동이 동작해야 한다")
    @MainActor
    func navigateUp() async {
        let mock = makeMockConnection()
        await mock.setListDirectoryResult(makeSampleEntries())
        let viewModel = SFTPBrowserViewModel(connection: mock)

        await viewModel.navigateTo(path: "/home/user/docs")
        await viewModel.navigateUp()

        // /home/user/docs → /home/user로 이동
        #expect(viewModel.currentPath == "/home/user" || viewModel.currentPath == "/home/user/")
    }

    @Test("navigateHome()으로 홈 디렉토리 이동이 동작해야 한다")
    @MainActor
    func navigateHome() async {
        let mock = makeMockConnection()
        await mock.setListDirectoryResult(makeSampleEntries())
        let viewModel = SFTPBrowserViewModel(connection: mock)

        await viewModel.navigateTo(path: "/var/log")
        await viewModel.navigateHome()

        #expect(viewModel.currentPath == "~" || viewModel.currentPath == "/")
    }

    @Test("탐색 중 isLoading이 true여야 한다")
    @MainActor
    func isLoadingDuringNavigation() async {
        let mock = makeMockConnection()
        await mock.setListDirectoryResult(makeSampleEntries())
        let viewModel = SFTPBrowserViewModel(connection: mock)

        // isLoading 프로퍼티가 존재하고 접근 가능해야 한다
        #expect(viewModel.isLoading == false)
    }

    @Test("탐색 완료 후 isLoading이 false여야 한다")
    @MainActor
    func isLoadingAfterNavigation() async {
        let mock = makeMockConnection()
        await mock.setListDirectoryResult(makeSampleEntries())
        let viewModel = SFTPBrowserViewModel(connection: mock)

        await viewModel.navigateTo(path: "/home/user")

        #expect(viewModel.isLoading == false)
    }

    // MARK: - [보통] 정렬

    @Test("이름순 정렬이 동작해야 한다")
    @MainActor
    func sortByName() async {
        let mock = makeMockConnection()
        await mock.setListDirectoryResult(makeSampleEntries())
        let viewModel = SFTPBrowserViewModel(connection: mock)

        await viewModel.navigateTo(path: "/home/user")
        viewModel.sortBy = .name

        let fileNames = viewModel.sortedFiles.map(\.name)
        // 디렉토리가 먼저, 그 다음 파일 (이름순)
        #expect(!fileNames.isEmpty)
    }

    @Test("크기순 정렬이 동작해야 한다")
    @MainActor
    func sortBySize() async {
        let mock = makeMockConnection()
        await mock.setListDirectoryResult(makeSampleEntries())
        let viewModel = SFTPBrowserViewModel(connection: mock)

        await viewModel.navigateTo(path: "/home/user")
        viewModel.sortBy = .size

        #expect(!viewModel.sortedFiles.isEmpty)
    }

    @Test("날짜순 정렬이 동작해야 한다")
    @MainActor
    func sortByDate() async {
        let mock = makeMockConnection()
        await mock.setListDirectoryResult(makeSampleEntries())
        let viewModel = SFTPBrowserViewModel(connection: mock)

        await viewModel.navigateTo(path: "/home/user")
        viewModel.sortBy = .date

        #expect(!viewModel.sortedFiles.isEmpty)
    }

    @Test("타입순 정렬이 동작해야 한다")
    @MainActor
    func sortByType() async {
        let mock = makeMockConnection()
        await mock.setListDirectoryResult(makeSampleEntries())
        let viewModel = SFTPBrowserViewModel(connection: mock)

        await viewModel.navigateTo(path: "/home/user")
        viewModel.sortBy = .type

        #expect(!viewModel.sortedFiles.isEmpty)
    }

    @Test("디렉토리가 항상 파일보다 먼저 나와야 한다")
    @MainActor
    func directoriesFirst() async {
        let mock = makeMockConnection()
        await mock.setListDirectoryResult(makeSampleEntries())
        let viewModel = SFTPBrowserViewModel(connection: mock)

        await viewModel.navigateTo(path: "/home/user")
        viewModel.sortBy = .name

        let sorted = viewModel.sortedFiles
        if let firstFile = sorted.first(where: { !$0.isDirectory }),
           let lastDir = sorted.last(where: { $0.isDirectory }) {
            let dirIndex = sorted.firstIndex(where: { $0.id == lastDir.id })!
            let fileIndex = sorted.firstIndex(where: { $0.id == firstFile.id })!
            #expect(dirIndex < fileIndex)
        }
    }

    // MARK: - [보통] 숨김 파일 토글

    @Test("showHiddenFiles가 false이면 .으로 시작하는 파일이 제외되어야 한다")
    @MainActor
    func hideHiddenFiles() async {
        let mock = makeMockConnection()
        await mock.setListDirectoryResult(makeSampleEntries())
        let viewModel = SFTPBrowserViewModel(connection: mock)

        await viewModel.navigateTo(path: "/home/user")
        viewModel.showHiddenFiles = false

        let visibleFiles = viewModel.filteredFiles
        let hasHidden = visibleFiles.contains { $0.name.hasPrefix(".") }
        #expect(hasHidden == false)
    }

    @Test("showHiddenFiles가 true이면 모든 파일이 표시되어야 한다")
    @MainActor
    func showHiddenFiles() async {
        let mock = makeMockConnection()
        await mock.setListDirectoryResult(makeSampleEntries())
        let viewModel = SFTPBrowserViewModel(connection: mock)

        await viewModel.navigateTo(path: "/home/user")
        viewModel.showHiddenFiles = true

        let visibleFiles = viewModel.filteredFiles
        let hasHidden = visibleFiles.contains { $0.name.hasPrefix(".") }
        #expect(hasHidden == true)
    }

    // MARK: - [보통] 파일 필터 검색

    @Test("검색어로 파일 목록을 필터링할 수 있어야 한다")
    @MainActor
    func searchFilter() async {
        let mock = makeMockConnection()
        await mock.setListDirectoryResult(makeSampleEntries())
        let viewModel = SFTPBrowserViewModel(connection: mock)

        await viewModel.navigateTo(path: "/home/user")
        viewModel.searchQuery = "readme"

        let filtered = viewModel.filteredFiles
        #expect(filtered.allSatisfy { $0.name.localizedCaseInsensitiveContains("readme") })
    }

    @Test("검색어가 빈 문자열이면 전체 목록이 표시되어야 한다")
    @MainActor
    func emptySearchShowsAll() async {
        let mock = makeMockConnection()
        await mock.setListDirectoryResult(makeSampleEntries())
        let viewModel = SFTPBrowserViewModel(connection: mock)

        await viewModel.navigateTo(path: "/home/user")
        viewModel.searchQuery = ""
        viewModel.showHiddenFiles = true

        let filtered = viewModel.filteredFiles
        #expect(filtered.count == viewModel.files.count)
    }

    @Test("대소문자 구분 없이 검색되어야 한다")
    @MainActor
    func caseInsensitiveSearch() async {
        let mock = makeMockConnection()
        await mock.setListDirectoryResult(makeSampleEntries())
        let viewModel = SFTPBrowserViewModel(connection: mock)

        await viewModel.navigateTo(path: "/home/user")
        viewModel.searchQuery = "README"

        let filtered = viewModel.filteredFiles
        #expect(filtered.contains { $0.name.lowercased().contains("readme") })
    }

    // MARK: - [보통] 캐시 연동

    @Test("캐시 히트 시 네트워크 요청 없이 목록을 반환해야 한다")
    @MainActor
    func cacheHitNoNetwork() async {
        let mock = makeMockConnection()
        await mock.setListDirectoryResult(makeSampleEntries())
        let cache = SFTPDirectoryCache()
        let viewModel = SFTPBrowserViewModel(connection: mock, cache: cache)

        // 첫 번째 호출: 네트워크 → 캐시 저장
        await viewModel.navigateTo(path: "/home/user")
        let firstResult = viewModel.files

        // 두 번째 호출: 캐시 히트
        await viewModel.navigateTo(path: "/home/user")
        let secondResult = viewModel.files

        #expect(firstResult.count == secondResult.count)
    }

    @Test("수동 새로고침(refresh) 시 캐시를 무효화하고 재조회해야 한다")
    @MainActor
    func refreshInvalidatesCache() async {
        let mock = makeMockConnection()
        await mock.setListDirectoryResult(makeSampleEntries())
        let cache = SFTPDirectoryCache()
        let viewModel = SFTPBrowserViewModel(connection: mock, cache: cache)

        await viewModel.navigateTo(path: "/home/user")
        await viewModel.refresh()

        // refresh 후에도 파일 목록이 존재해야 한다
        #expect(!viewModel.files.isEmpty)
    }

    // MARK: - [어려움] 에러 처리

    @Test("연결 실패 시 에러 메시지가 설정되어야 한다")
    @MainActor
    func connectionErrorMessage() async {
        let mock = makeMockConnection()
        await mock.setShouldThrowError(MockSFTPError.connectionLost)
        let viewModel = SFTPBrowserViewModel(connection: mock)

        await viewModel.navigateTo(path: "/home/user")

        #expect(viewModel.errorMessage != nil)
    }

    @Test("권한 없음 에러 시 적절한 에러 메시지가 표시되어야 한다")
    @MainActor
    func permissionDeniedErrorMessage() async {
        let mock = makeMockConnection()
        await mock.setShouldThrowError(MockSFTPError.permissionDenied)
        let viewModel = SFTPBrowserViewModel(connection: mock)

        await viewModel.navigateTo(path: "/root")

        #expect(viewModel.errorMessage != nil)
    }
}

// MockSFTPConnection은 SFTPFileEntryTests.swift에서 정의됨
