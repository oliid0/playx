import SwiftUI
import Foundation

@main
struct PlayerXApp: App {
    var body: some Scene {
        #if os(macOS)
        WindowGroup {
            RootView()
                .frame(minWidth: 980, minHeight: 640)
        }
        .defaultSize(width: 1_180, height: 760)
        .windowToolbarStyle(.unified)
        .commands {
            SidebarCommands()
            CommandGroup(after: .newItem) {
                Button("搜索…") {
                    NotificationCenter.default.post(name: .playerXOpenSearch, object: nil)
                }
                .keyboardShortcut("f", modifiers: .command)
            }
            CommandMenu("播放") {
                Button("播放 / 暂停") {
                    NotificationCenter.default.post(name: .playerXTogglePlayback, object: nil)
                }
                .keyboardShortcut(.space, modifiers: [])

                Button("后退") {
                    NotificationCenter.default.post(name: .playerXSkipBackward, object: nil)
                }
                .keyboardShortcut(.leftArrow, modifiers: [])

                Button("前进") {
                    NotificationCenter.default.post(name: .playerXSkipForward, object: nil)
                }
                .keyboardShortcut(.rightArrow, modifiers: [])

                Divider()

                Button("下一集") {
                    NotificationCenter.default.post(name: .playerXPlayNext, object: nil)
                }
                .keyboardShortcut(.rightArrow, modifiers: .command)

                Button("关闭播放器") {
                    NotificationCenter.default.post(name: .playerXClosePlayer, object: nil)
                }
                .keyboardShortcut(.escape, modifiers: [])
            }
        }
        #else
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
        }
        #endif
    }
}

extension Notification.Name {
    /// macOS 菜单「搜索…」的通知。RootView 监听后打开全局搜索。
    static let playerXOpenSearch = Notification.Name("playerx.openSearch")

    // macOS 播放菜单 → PlayerView。通知只在播放器打开时生效，其余时候是空操作。
    static let playerXTogglePlayback = Notification.Name("playerx.player.toggle")
    static let playerXSkipBackward = Notification.Name("playerx.player.backward")
    static let playerXSkipForward = Notification.Name("playerx.player.forward")
    static let playerXPlayNext = Notification.Name("playerx.player.next")
    static let playerXClosePlayer = Notification.Name("playerx.player.close")
}
