//
//  Applescript.swift
//  XCord
//
//  Created by Phillip on 24.12.2024.
//

import Foundation
import Cocoa

enum APScripts: String {
    case windowNames = "return name of windows"
    case filePaths = "return file of documents"
    case documentNames = "return name of documents"
    case activeWorkspaceDocument = "return active workspace document"
}

func runAPScript(_ s: APScripts) -> [String]? {
    let scr = """
    tell application "Xcode"
        \(s.rawValue)
    end tell
    """
    
    let script = NSAppleScript.init(source: scr)
    let result = script?.executeAndReturnError(nil)

    if let desc = result {
        var arr: [String] = []
        if desc.numberOfItems == 0 {
            return arr
        }
        for i in 1...desc.numberOfItems {
            let strVal = desc.atIndex(i)!.stringValue
            if var uwStrVal = strVal {
                if uwStrVal.hasSuffix(" — Edited") {
                    uwStrVal.removeSubrange(uwStrVal.lastIndex(of: "—")!...)
                    uwStrVal.removeLast()
                }
                arr.append(uwStrVal)
            }
        }
        
        return arr
    }
    return nil
}

func getActiveFilename() -> String? {
    guard let fileNames = runAPScript(.documentNames),
          let windowNames = runAPScript(.windowNames) else {
        print("DEBUG: Can't get documentNames or windowNames")
        return nil
    }

    print("DEBUG: Files: \(fileNames)")
    print("DEBUG: Windows: \(windowNames)")

    for window in windowNames {
        let cleanWindowName = window.trimmingCharacters(in: .whitespacesAndNewlines)
        for file in fileNames {
            let cleanFileName = file.trimmingCharacters(in: .whitespacesAndNewlines)

            if cleanWindowName.contains(cleanFileName) {
                print("DEBUG: Active file: \(cleanFileName)")
                return cleanFileName
            }
        }
    }

    return nil
}

func getActiveWorkspace() -> String? {
    if let awd = runAPScript(.activeWorkspaceDocument), awd.count >= 2 {
        return awd[1]
    }
    return nil
}

func getActiveWindow() -> String? {
    let activeApplication = """
        tell application "System Events"
            get the name of every application process whose frontmost is true
        end tell
    """
    
    let script = NSAppleScript.init(source: activeApplication)
    let result = script?.executeAndReturnError(nil)

    if let desc = result {
        var arr: [String] = []
        for i in 1...desc.numberOfItems {
            guard let strVal = desc.atIndex(i)!.stringValue else { return "Xcode" }
            arr.append(strVal)
        }
        return arr[0]
    }
    return ""
}
