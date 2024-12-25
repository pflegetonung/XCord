//
//  HelperFunctions.swift
//  XCord
//
//  Created by Phillip on 24.12.2024.
//

import Foundation

func getFileExt(_ file: String) -> String? {
    if let ext = file.split(separator: ".").last {
        return String(ext)
    }
    return nil
}

func withoutFileExt(_ file: String) -> String {
    if !file.contains(".") || file.last == "." {
        return file
    }

    var ret = file
    while (ret.popLast() != ".") {}
    return ret
}
