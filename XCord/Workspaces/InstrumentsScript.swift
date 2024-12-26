//
//  InstrumentsScript.swift
//  XCord
//
//  Created by Phillip on 26.12.2024.
//

import Foundation
import Cocoa

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
