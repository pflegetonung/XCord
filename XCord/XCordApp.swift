//
//  XCordApp.swift
//  XCord
//
//  Created by Phillip on 24.12.2024.
//

import Foundation
import SwiftUI
import Cocoa
import SwordRPC

@main
struct XCordApp {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var timer: Timer?
    var rpc: SwordRPC?
    var startDate: Date?
    var inactiveDate: Date?
    var lastWindow: String?

    func beginTimer() {
        timer = Timer(timeInterval: TimeInterval(refreshInterval), repeats: true, block: { _ in
            self.updateStatus()
        })
        RunLoop.main.add(timer!, forMode: .common)
        timer!.fire()
    }

    func clearTimer() {
        timer?.invalidate()
    }

    func updateStatus() {
        var p = RichPresence()

        let an = getActiveWindow()
        let fn = getActiveFilename()
        let ws = getActiveWorkspace()

        // Первая строка
        if let an = an, an == "Xcode" {
            // Xcode активно
            p.assets.largeImage = "xcode" // Large image: Xcode
            p.assets.smallImage = "mini" // Small image: Mini
        } else {
            // Xcode неактивно
            p.assets.largeImage = "icon" // Large image: Mini
            p.assets.smallImage = "mini"    // Small image: не используется
        }

        // Вторая строка
        if let ws = ws, an == "Xcode" {
            if ws != "Untitled" {
                p.state = "🔥 Working on \(withoutFileExt(ws))"
                lastWindow = ws
            } else {
                p.state = "🔍 Checking something else"
            }
        } else {
            p.state = "☕️ Taking a break..."
        }

        // Третья строка
        if let fn = fn {
            if let fileExt = getFileExt(fn) {
                p.details = "Editing \(withoutFileExt(fn)).\(fileExt)"
            } else {
                p.details = "\(fn) (no extension)"
            }
        } else {
            p.details = "No file open"
        }

        // Добавляем больше строк через timestamps
        p.timestamps.start = startDate
        p.timestamps.end = startDate?.addingTimeInterval(15 * 60) // Добавим таймер на 15 минут

        // Отправка обновленного RichPresence
        rpc?.setPresence(p)
    }

    func initRPC() {
        rpc = SwordRPC(appId: discordClientId)
        rpc?.delegate = self
        rpc?.connect()
    }

    func deinitRPC() {
        rpc?.setPresence(RichPresence())
        rpc?.disconnect()
        rpc = nil
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        for app in NSWorkspace.shared.runningApplications where app.bundleIdentifier == xcodeBundleId {
            initRPC()
        }

        let notifCenter = NSWorkspace.shared.notificationCenter
        notifCenter.addObserver(forName: NSWorkspace.didLaunchApplicationNotification, object: nil, queue: nil) { notif in
            if let app = notif.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
               app.bundleIdentifier == xcodeBundleId {
                self.initRPC()
            }
        }

        notifCenter.addObserver(forName: NSWorkspace.didTerminateApplicationNotification, object: nil, queue: nil) { notif in
            if let app = notif.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
               app.bundleIdentifier == xcodeBundleId {
                self.deinitRPC()
            }
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        deinitRPC()
        clearTimer()
    }
}

extension AppDelegate: SwordRPCDelegate {
    func swordRPCDidConnect(_ rpc: SwordRPC) {
        startDate = Date()
        beginTimer()
    }

    func swordRPCDidDisconnect(_ rpc: SwordRPC, code: Int?, message msg: String?) {
        clearTimer()
    }

    func swordRPCDidReceiveError(_ rpc: SwordRPC, code: Int, message msg: String) {}
}
