//
//  Task+.swift
//
//
//  Created by Igor  on 18.07.24.
//

import Foundation

@available(iOS, introduced: 15.0)
@available(macOS, introduced: 12.0)
extension Task where Success == Never, Failure == Never {
    
    /// Suspends the current task for the given time interval.
    ///
    /// - Parameter duration: The time interval to sleep for.
    static func sleep(for duration: Double) async throws {
        if #available(iOS 16, macOS 13, *) {
            try await Task.sleep(for: .seconds(duration))
        } else {
            try await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
        }
    }
}
