//
//  DeviceIntegrity.swift
//  NoICE
//
//  Jailbreak detection: No-ICE refuses to run on a jailbroken iPhone or iPad.
//

import Foundation
import UIKit
import os

enum DeviceIntegrity {
    /// Evaluated once, on first access (at launch, on the main thread: canOpenURL needs it).
    static let isCompromised: Bool = evaluate()

    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "NoICE", category: "DeviceIntegrity")

    private static func evaluate() -> Bool {
        #if DEBUG
        // Headless check of the blocked screen: `-SimulateJailbreak YES`.
        if UserDefaults.standard.bool(forKey: "SimulateJailbreak") { return true }
        #endif

        #if targetEnvironment(simulator)
        return false
        #else
        // Only iPhone and iPad are checked. The iPad app on an Apple Silicon Mac (or on Vision Pro)
        // sees that platform's file system, where /bin/bash and friends are normal.
        let process = ProcessInfo.processInfo
        if process.isiOSAppOnMac || process.isMacCatalystApp { return false }
        let idiom = UIDevice.current.userInterfaceIdiom
        guard idiom == .phone || idiom == .pad else { return false }

        guard let finding = JailbreakChecks.firstFinding() else { return false }
        logger.error("Jailbreak detected: \(finding, privacy: .public)")
        return true
        #endif
    }
}
