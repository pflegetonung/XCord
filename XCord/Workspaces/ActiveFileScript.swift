//
//  ActiveFileScript.swift
//  XCord
//
//  Created by Phillip on 26.12.2024.
//

import Foundation
import Cocoa

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
