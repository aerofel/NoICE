//
//  DeviceIntegrity.swift
//  NoICE
//
//  Jailbreak detection: No-ICE refuses to run on a jailbroken iPhone or iPad.
//

import Foundation
import IOSSecuritySuite
import os

enum DeviceIntegrity {
    /// Evaluated once, on first access (at launch, on the main thread: canOpenURL needs it).
    static let isCompromised: Bool = evaluate()

    private static let logger = Logger(subsystem: "org.looping.NoICE", category: "DeviceIntegrity")

    private static func evaluate() -> Bool {
        #if DEBUG
        // Headless check of the blocked screen: `-SimulateJailbreak YES`.
        if UserDefaults.standard.bool(forKey: "SimulateJailbreak") { return true }
        #endif

        #if targetEnvironment(simulator)
        return false
        #else
        // The iPad app on an Apple Silicon Mac sees macOS paths (/bin/bash, /usr/sbin/sshd, ...)
        // that read as a jailbreak; IOSSecuritySuite is meant for iOS/iPadOS only.
        if ProcessInfo.processInfo.isiOSAppOnMac { return false }

        let status = IOSSecuritySuite.amIJailbrokenWithFailMessage()
        if status.jailbroken {
            logger.error("Jailbreak detected: \(status.failMessage, privacy: .public)")
        }
        return status.jailbroken
        #endif
    }
}
