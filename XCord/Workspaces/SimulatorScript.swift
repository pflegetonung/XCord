//
//  SimulatorScript.swift
//  XCord
//
//  Created by Phillip on 26.12.2024.
//  Copyright © 2024 Vincent Liu. All rights reserved.
//

import Foundation

func getActiveSimulator() -> (model: String, osVersion: String)? {
    let process = Process()
    let pipe = Pipe()
    
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
