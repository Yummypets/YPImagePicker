//
//  YPLog.swift
//  YPImagePicker
//
//  Created by Nik Kov on 13.08.2021.
//

internal func ypLog(_ description: String,
           fileName: String = #file,
           lineNumber: Int = #line,
           functionName: String = #function) {
    guard YPConfig.isDebugLogsEnabled else {
        return
    }

    // swiftlint:disable:next line_length
    let traceString = "🖼 YPImagePicker. \(fileName.components(separatedBy: "/").last!) -> \(functionName) -> \(description) (line: \(lineNumber))"
    print(traceString)
}
