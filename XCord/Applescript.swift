//
//  Applescript.swift
//  DiscordX
//
//  Created by Asad Azam on 28/9/20.
//  Copyright © 2021 Asad Azam. All rights reserved.
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
    
    // execute the script
    let script = NSAppleScript.init(source: scr)
    let result = script?.executeAndReturnError(nil)

    // format the result as a Swift array
    if let desc = result {
        var arr: [String] = []
        if desc.numberOfItems == 0 {
            return arr
        }
        for i in 1...desc.numberOfItems {
            let strVal = desc.atIndex(i)!.stringValue
            if var uwStrVal = strVal {
                // remove " — Edited" suffix if it exists
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
    // Запускаем AppleScript для получения названий документов и окон
    guard let fileNames = runAPScript(.documentNames),
          let windowNames = runAPScript(.windowNames) else {
        print("Ошибка: Не удалось получить названия файлов или окон")
        return nil
    }

    print("Найденные файлы: \(fileNames)")
    print("Найденные окна: \(windowNames)")

    // Попробуем найти совпадение между окнами и файлами
    for window in windowNames {
        let cleanWindowName = window.trimmingCharacters(in: .whitespacesAndNewlines)
        for file in fileNames {
            let cleanFileName = file.trimmingCharacters(in: .whitespacesAndNewlines)

            // Сравниваем окно с файлом
            if cleanWindowName.contains(cleanFileName) {
                print("Активный файл найден: \(cleanFileName)")
                return cleanFileName
            }
        }
    }

    print("Не удалось сопоставить файл и окно")
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
    
//    get the name of every process whose visible is true
    
    let script = NSAppleScript.init(source: activeApplication)
    let result = script?.executeAndReturnError(nil)

    if let desc = result {
        var arr: [String] = []
        for i in 1...desc.numberOfItems {
            guard let strVal = desc.atIndex(i)!.stringValue else { return "Xcode" }
            arr.append(strVal)
        }
//        print(arr[0])
        return arr[0]
    }
    return ""
}
