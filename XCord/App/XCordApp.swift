//
//  XCordApp.swift
//  XCord
//
//  Created by Phillip on 24.12.2024.
//

import Foundation
import Cocoa

@main
struct XCordApp {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}
