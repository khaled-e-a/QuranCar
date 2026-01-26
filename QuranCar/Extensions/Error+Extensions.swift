//
//  Error+Extensions.swift
//  QuranCar
//
//  Created on 2026-01-25.
//

import Foundation

extension Error {
    /// Checks if this error is the socket idle warning that should be suppressed from users.
    /// This error occurs when URLSession attempts to set socket options that aren't available
    /// in certain environments (simulators, certain iOS versions).
    ///
    /// - Returns: `true` if this is a socket idle error that should be suppressed, `false` otherwise.
    func isSocketIdleError() -> Bool {
        let errorDescription = self.localizedDescription
        return errorDescription.contains("nw_socket_set_connection_idle") &&
               errorDescription.contains("SO_CONNECTION_IDLE")
    }
}
