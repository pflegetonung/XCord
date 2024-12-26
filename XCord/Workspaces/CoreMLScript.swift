//
//  CoreMLScript.swift
//  XCord
//
//  Created by Phillip on 27.12.2024.
//  Copyright © 2024 Vincent Liu. All rights reserved.
//

import Foundation

func getCreateMLActivity() -> (state: String, details: String)? {
    let script = """
    tell application "Create ML"
        try
            if not (exists front document) then
                return "Idle;No project open"
            end if
            
            set docName to name of front document
            set docType to class of front document
            
            if docType is "MLModel" then
                return "Editing: " & docName & ";Working on ML Model"
            else if docType is "MLTraining" then
                return "Training Model: " & docName & ";Model Training in Progress"
            else
                return "Active;Working on " & docName
            end if
        on error
            return "Idle;No project open"
        end try
    end tell
    """

    let appleScript = NSAppleScript(source: script)
    var errorDict: NSDictionary?
    if let output = appleScript?.executeAndReturnError(&errorDict).stringValue {
        print("AppleScript Output: \(output)") // Логируем результат
        let components = output.split(separator: ";")
        if components.count == 2 {
            return (state: String(components[0]), details: String(components[1]))
        }
    } else if let error = errorDict {
        print("AppleScript Error: \(error)") // Логируем ошибки
    }
    return (state: "Idle", details: "No project open")
}
