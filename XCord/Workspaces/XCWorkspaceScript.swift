//
//  XCWorkspaceScript.swift
//  XCord
//
//  Created by Phillip on 26.12.2024.
//

import Foundation
import Cocoa

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
