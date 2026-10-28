import Foundation
import XCTest

@testable import DiagnosticsKit

/// 可再生缓存的取路径入口。
///
/// 钉住的核心行为：**图片字节这类可再生数据必须落在 `Caches` 下**，而不是
/// `Application Support`。放错一边不是风格问题 —— iOS 上 `Caches` 会被系统在存储
/// 吃紧时回收、且不进 iCloud 备份，`Application Support` 两条都不成立，于是几百 MB
/// 重下即可获得的海报字节进了用户的备份（实测本机曾达 370 MB，而两套上限相加 768 MB）。
final class PlayXStorageTests: XCTestCase {

    // MARK: - 缓存根

    /// 非隔离运行：缓存根就是 `Caches/OcPlayer`，与数据根**不是**同一个地方。
    func testCachesRootSitsUnderSystemCaches() throws {
        try XCTSkipIf(PlayXStorage.isIsolated, "隔离运行下缓存根落在隔离根，本用例不适用")

        let root = PlayXStorage.cachesRoot.standardizedFileURL
        XCTAssertEqual(root.lastPathComponent, PlayXStorage.directoryName)
        XCTAssertEqual(root.deletingLastPathComponent().path,
                       PlayXStorage.caches.standardizedFileURL.path)
        // 反证：绝不能落在 Application Support 下（那正是本修复要摆脱的位置）
        XCTAssertFalse(
            root.path.hasPrefix(PlayXStorage.applicationSupport.standardizedFileURL.path),
            "缓存根不该在 Application Support 下：\(root.path)")
    }

    /// 隔离运行：缓存根落到隔离根下，否则跑一次测试就会写开发机真实的 `~/Library/Caches`。
    func testCachesRootFollowsIsolation() {
        guard PlayXStorage.isIsolated else { return }
        XCTAssertEqual(
            PlayXStorage.cachesRoot.standardizedFileURL.deletingLastPathComponent().path,
            PlayXStorage.isolationRoot.standardizedFileURL.path)
    }

    /// 两条入口永远不重合 —— 重合就意味着「用户数据」与「可清缓存」混在一个目录里。
    func testCacheRootNeverEqualsDataRoot() {
        XCTAssertNotEqual(
            PlayXStorage.cachesRoot.standardizedFileURL.path,
            PlayXStorage.defaultRoot.standardizedFileURL.path)
    }

    // MARK: - 子目录

    func testCacheDirectoryLivesUnderCachesRoot() {
        let url = PlayXStorage.cacheDirectory("ImageCache")
        XCTAssertEqual(url.lastPathComponent, "ImageCache")
        XCTAssertEqual(url.deletingLastPathComponent().path,
                       PlayXStorage.cachesRoot.standardizedFileURL.path)
    }

    /// 同一名字，缓存入口与数据入口必须给出**不同**路径（搬家的全部意义）。
    func testCacheDirectoryDiffersFromDataDirectory() {
        XCTAssertNotEqual(
            PlayXStorage.cacheDirectory("ImageCache").standardizedFileURL.path,
            PlayXStorage.directory("ImageCache").standardizedFileURL.path)
    }

    /// `base` 是测试注入口，必须原样生效。
    func testCacheDirectoryHonoursInjectedBase() {
        let base = FileManager.default.temporaryDirectory
            .appendingPathComponent("cache-base-\(UUID().uuidString)", isDirectory: true)
        XCTAssertEqual(
            PlayXStorage.cacheDirectory("ImageCache", in: base).standardizedFileURL.path,
            base.appendingPathComponent("ImageCache", isDirectory: true).standardizedFileURL.path)
    }
}
