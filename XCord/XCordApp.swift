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
    let assetsMapping: [String: String] = [
        "Xcode": "xcode",
        "Simulator": "simulator",
        "Instruments": "instruments",
        "Accessibility Inspector": "accessibilityinspector",
        "FileMerge": "filemerge",
        "Create ML": "createml",
        "RealityComposer": "realitycomposer"
    ]

    func updateStatus() {
        var rp = RichPresence()
        let an = getActiveWindow()
        let fn = getActiveFilename()
        let ws = getActiveWorkspace()
        
        if !isProjectOpen() {
            rpc?.setPresence(RichPresence())
            return
        }
        
        // MARK: - Images
        if let an = an, let largeImage = assetsMapping[an] {
            rp.assets.largeImage = largeImage
            rp.assets.smallImage = "mini"
        } else {
            rp.assets.largeImage = "icon"
            rp.assets.smallImage = "mini"
        }
        
        // MARK: - Details (1st row)
        if let ws = ws, an == "Xcode" {
            if ws != "Untitled" {
                rp.details = "Working on \(withoutFileExt(ws)) 🔥"
                lastWindow = ws
            } else {
                rp.details = "Loading ⚡️"
            }
        } else if let ws = ws, an == "Simulator" {
            if ws != "Untitled" {
                rp.details = "\(withoutFileExt(ws)) in Action 📱"
                lastWindow = ws
            } else {
                rp.details = "Loading ⚡️"
            }
        } else if let ws = ws, an == "Instruments" {
            if ws != "Untitled" {
                rp.details = "Using Instruments 🔧"
                lastWindow = ws
            } else {
                rp.details = "Loading ⚡️"
            }
        } else if let ws = ws, an == "Accessibility Inspector" {
            if ws != "Untitled" {
                rp.details = "Inspecting 🔍"
                lastWindow = ws
            } else {
                rp.details = "Loading ⚡️"
            }
        } else {
            rp.details = "Taking a break... ☕️"
        }
        
        // MARK: - State (2nd row)
        if let fn = fn, an == "Xcode" {
            if let fileExt = getFileExt(fn) {
                rp.state = "\(withoutFileExt(fn)).\(fileExt)"
            } else {
                rp.state = "\(fn) (no extension)"
            }
        } else if let fn = fn, an == "Simulator" {
            if let simulatorInfo = getActiveSimulator() {
                rp.state = "\(simulatorInfo.osVersion), \(simulatorInfo.model)"
            } else {
                rp.state = "Unknown Simulator"
            }
        } else if let fn = fn, an == "Instruments" {
            let activity = getInstrumentsActivity()
            if activity == "Unknown Activity" || activity.isEmpty {
                rp.state = "Getting ready"
            } else {
                rp.state = "Profiling: \(activity)"
            }
        } else if let fn = fn, an == "Accessibility Inspector" {
            if let elementInfo = getAccessibilityElement() {
                rp.state = "Traits: \(elementInfo.traits)"
            } else {
                rp.state = "No element selected"
            }
        } else {
            rp.state = "No file open"
        }
        
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
    
    func getActiveSimulator() -> (model: String, osVersion: String)? {
        let process = Process()
        let pipe = Pipe()

        // Указываем путь к simctl
        process.executableURL = URL(fileURLWithPath: "/Applications/Xcode.app/Contents/Developer/usr/bin/simctl")
        process.arguments = ["list", "devices"]
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            print("Failed to run simctl: \(error)")
            return nil
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else {
            print("No output from simctl")
            return nil
        }

        let lines = output.split(separator: "\n")

        var currentOS: String = ""
        for line in lines {
            if line.hasPrefix("-- iOS") {
                currentOS = line.replacingOccurrences(of: "--", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                print("Detected iOS version: \(currentOS)")
            } else if line.contains("(Booted)") {
                print("Booted device line: \(line)")
                let components = line.split(separator: "(")
                if components.count > 0 {
                    let model = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
                    return (model: model, osVersion: currentOS)
                }
            }
        }

        print("No booted device found.")
        return nil
    }
    
    func isProjectOpen() -> Bool {
        let script = """
        tell application "Xcode"
            try
                if (count of workspace documents) > 0 then
                    return true
                else
                    return false
                end if
            on error
                return false
            end try
        end tell
        """

        let appleScript = NSAppleScript(source: script)
        var errorDict: NSDictionary?
        if let result = appleScript?.executeAndReturnError(&errorDict).booleanValue {
            return result
        }
        return false
    }
    
    func getInstrumentsActivity() -> String {
        let script = """
        tell application "Instruments"
            try
                set activeDocument to name of front document
                return activeDocument
            on error
                return "Unknown Activity"
            end try
        end tell
        """

        let appleScript = NSAppleScript(source: script)
        var errorDict: NSDictionary?
        if let output = appleScript?.executeAndReturnError(&errorDict).stringValue {
            return output
        }
        return "Unknown Activity"
    }

    struct AccessibilityElement {
        let name: String
        let type: String
        let traits: String
    }

    func getAccessibilityElement() -> AccessibilityElement? {
        let script = """
        tell application "Accessibility Inspector"
            try
                set selectedElement to selected UI element
                if selectedElement is not missing value then
                    set elementLabel to value of attribute "AXLabel" of selectedElement
                    set elementTitle to value of attribute "AXTitle" of selectedElement
                    set elementType to value of attribute "AXRole" of selectedElement

                    if elementLabel is missing value then
                        set elementLabel to "None"
                    end if
                    if elementTitle is missing value then
                        set elementTitle to "None"
                    end if
                    if elementType is missing value then
                        set elementType to "Unknown Type"
                    end if

                    return elementTitle & ";" & elementLabel & ";" & elementType
                else
                    return "No element selected"
                end if
            on error
                return "No element selected"
            end try
        end tell
        """

        let appleScript = NSAppleScript(source: script)
        var errorDict: NSDictionary?
        if let output = appleScript?.executeAndReturnError(&errorDict).stringValue {
            print("AppleScript Output: \(output)") // Логируем результат
            if output == "No element selected" {
                return nil
            }

            let components = output.split(separator: ";")
            if components.count == 3 {
                print("Parsed Components: \(components)") // Логируем разобранные данные
                return AccessibilityElement(
                    name: String(components[1]), // Label, если нет Title
                    type: String(components[2]), // Type
                    traits: String(components[0]) // Title
                )
            } else {
                print("Unexpected AppleScript Output: \(output)") // Отладка
            }
        } else if let error = errorDict {
            print("AppleScript Error: \(error)") // Логируем ошибки
        }
        return nil
    }
    
    struct FileMergeActivity {
        let state: String
        let details: String
    }

    func getFileMergeActivity() -> FileMergeActivity? {
        let script = """
        tell application "FileMerge"
            try
                if not (exists front document) then return "idle"
                set docName to name of front document
                set leftFile to name of left file of front document
                set rightFile to name of right file of front document
                if (exists leftFile) and (exists rightFile) then
                    return leftFile & " ↔ " & rightFile
                else
                    return "Merging"
                end if
            on error
                return "idle"
            end try
        end tell
        """

        let appleScript = NSAppleScript(source: script)
        var errorDict: NSDictionary?
        if let output = appleScript?.executeAndReturnError(&errorDict).stringValue {
            if output.contains("↔") {
                return FileMergeActivity(
                    state: "Comparing: \(output)",
                    details: "FileMerge: Highlighting differences"
                )
            } else if output == "Merging" {
                return FileMergeActivity(
                    state: "Merging changes",
                    details: "Resolving conflicts"
                )
            }
        }
        return nil
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
