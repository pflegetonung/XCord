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
import ServiceManagement

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
    var statusItem: NSStatusItem!
    let helperBundleId = "com.yourcompany.helper"

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
        var rp = RichPresence()
        let an = getActiveWindow()
        let fn = getActiveFilename()
        let ws = getActiveWorkspace()
        
        if let an = an, an == "Xcode" {
            rp.assets.largeImage = "xcode"
            rp.assets.smallImage = "mini"
        } else {
            rp.assets.largeImage = "icon"
            rp.assets.smallImage = "mini"
        }
        
        if let ws = ws, an == "Xcode" {
            if ws != "Untitled" {
                rp.details = "Working on \(withoutFileExt(ws)) 🔥"
                lastWindow = ws
            } else {
                rp.details = "Checking something else 🔍"
            }
        } else {
            rp.details = "Taking a break... ☕️"
        }
        
        if let fn = fn {
            if let fileExt = getFileExt(fn) {
                rp.state = "\(withoutFileExt(fn)).\(fileExt)"
            } else {
                rp.state = "\(fn) (no extension)"
            }
        } else {
            rp.state = "No file open"
        }
        
        if startDate == nil {
            startDate = Date()
        }
        rp.timestamps.start = startDate
        rp.timestamps.end = nil
        
        rpc?.setPresence(rp)
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
        NSApp.setActivationPolicy(.accessory)
        
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
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "fleuron", accessibilityDescription: "App Icon")
            button.image?.isTemplate = true
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))

        statusItem.menu = menu
    }
    
    @objc func toggleLaunchAtLogin() {
        let isEnabled = isLaunchAtLoginEnabled()
        SMLoginItemSetEnabled(helperBundleId as CFString, !isEnabled)

        if !isEnabled {
            print("Launch at login enabled")
        } else {
            print("Launch at login disabled")
        }
    }

    func isLaunchAtLoginEnabled() -> Bool {
        let jobs = SMJobCopyDictionary(kSMDomainUserLaunchd, helperBundleId as CFString)?.takeRetainedValue()
        return jobs != nil
    }

    @objc func quitApp() {
        NSApplication.shared.terminate(self)
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
