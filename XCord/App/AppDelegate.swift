//
//  AppDelegate.swift
//  XCord
//
//  Created by Phillip on 26.12.2024.
//

import Foundation
import Cocoa
import SwordRPC
import ServiceManagement

class AppDelegate: NSObject, NSApplicationDelegate {
    var timer: Timer?
    var rpc: SwordRPC?
    var startDate: Date?
    var inactiveDate: Date?
    var lastWindow: String?
    var statusItem: NSStatusItem!
    let helperBundleId = "com.yourcompany.helper"
    let assetsMapping: [String: String] = [
        "Xcode": "swiftfile",
        "Simulator": "simulator",
        "Instruments": "instruments",
        "Accessibility Inspector": "accessibilityinspector",
        "FileMerge": "filemerge",
        "Create ML": "createml",
        "RealityComposer": "realitycomposer"
    ]
    
    fileprivate func generatePresenceInfo(an: String?, ws: String?, fn: String?) -> (String, String) {
        var details = "Taking a break... ☕️"
        var state = "No file open"
        
            // MARK: - XCode:
        if an == "Xcode" {
            if let ws = ws, ws != "Untitled" {
                details = "Working on \(withoutFileExt(ws)) 🛠️"
            } else {
                details = "Loading ⚡️"
            }
            // STATE
            if let fn = fn {
                if let fileExt = getFileExt(fn) {
                    state = "\(withoutFileExt(fn)).\(fileExt)"
                } else {
                    state = "\(fn) (no extension)"
                }
            }
            // MARK: - Simulator:
        } else if an == "Simulator" {
            if let ws = ws, ws != "Untitled" {
                details = "\(withoutFileExt(ws)) in Action 📱"
            } else {
                details = "Loading ⚡️"
            }
            if let fn = fn, let simulatorInfo = getActiveSimulator() {
                state = "\(simulatorInfo.osVersion), \(simulatorInfo.model)"
            } else {
                state = "Unknown Simulator"
            }
            // MARK: - Instruments:
        } else if an == "Instruments" {
            if let ws = ws, ws != "Untitled" {
                details = "Using Instruments 🔧"
            } else {
                details = "Loading ⚡️"
            }
            let activity = getInstrumentsActivity()
            if activity == "Unknown Activity" || activity.isEmpty {
                state = "Getting ready"
            } else {
                state = "Profiling: \(activity)"
            }
            // MARK: - FileMerge:
        } else if an == "FileMerge" {
            details = "Merging files ⚙️"
            state = "TODO: REDO"
            // MARK: - Accessibility Inspector:
        } else if an == "Accessibility Inspector" {
            if let ws = ws, ws != "Untitled" {
                details = "Inspecting 🔍"
            } else {
                details = "Loading ⚡️"
            }
            state = "TODO: REDO"
            // MARK: - Create ML
        } else if an == "Create ML" {
            if let ws = ws, ws != "Untitled" {
                details = "Training a ML Model 🦾"
            } else {
                details = "Loading ⚡️"
            }
        }
        
        return (details, state)
    }
    
    func updateStatus() {
        var rp = RichPresence()
        let an = getActiveWindow()
        let fn = getActiveFilename()
        let ws = getActiveWorkspace()
        
        // MARK: - Images
        if let an = an {
            if an == "Xcode" {
                if let fn = fn, let fileExt = getFileExt(fn) {
                    rp.assets.largeImage = discordRPImageKeys.contains(fileExt) ? fileExt : "default"
                } else {
                    rp.assets.largeImage = "xcode"
                }
                rp.assets.smallImage = "mini"
            } else if let largeImage = assetsMapping[an] {
                rp.assets.largeImage = largeImage
                rp.assets.smallImage = "mini"
            } else {
                rp.assets.largeImage = "default"
                rp.assets.smallImage = "mini"
            }
        } else {
            rp.assets.largeImage = "icon"
            rp.assets.smallImage = "mini"
        }
        
        let (finalDetails, finalState) = generatePresenceInfo(an: an, ws: ws, fn: fn)
        rp.details = finalDetails
        rp.state  = finalState
        
        // MARK: - Timer
        if startDate == nil {
            startDate = Date()
        }
        rp.timestamps.start = startDate
        rp.timestamps.end = nil
        
        rpc?.setPresence(rp)
    }
    
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
    
    // MARK: - RPC
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
        
        // MARK: - macOS menu
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
    
    func swordRPCDidReceiveError(_ rpc: SwordRPC, code: Int, message msg: String) { }
}
