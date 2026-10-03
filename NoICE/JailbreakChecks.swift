//
//  JailbreakChecks.swift
//  NoICE
//
//  Offline jailbreak indicators for iOS and iPadOS. Covers the same families of checks as
//  IOSSecuritySuite (files, symlinks, sandbox integrity, fork, injected libraries, bypass tweaks,
//  URL schemes), written independently. Matching is exact (no loose substrings) because a
//  positive result blocks the app.
//

import Foundation
import MachO
import ObjectiveC
import UIKit

enum JailbreakChecks {
    /// The first indicator found, or nil on a stock device. Call on the main thread (canOpenURL).
    static func firstFinding() -> String? {
        let checks: [() -> String?] = [
            suspiciousFiles,
            rootHideDirectory,
            symbolicLinks,
            writableSystem,
            sandboxAllowsFork,
            injectedLibraries,
            bypassTweakClasses,
            jailbreakURLSchemes,
        ]
        for check in checks {
            if let finding = check() { return finding }
        }
        return nil
    }

    // MARK: - Files

    /// Paths that don't exist on a stock device. Sandboxed apps can still stat most of them.
    private static let suspiciousPaths = [
        // Rootless jailbreaks (Dopamine, palera1n, RootHide) and their loaders
        "/var/jb",
        "/var/binpack",
        "/Applications/Dopamine.app",
        "/Applications/palera1nLoader.app",
        "/usr/bin/palera1n-helper",
        "/var/mobile/Library/Preferences/com.opa334.Dopamine.plist",
        "/var/mobile/Library/Preferences/com.roothide.pref.plist",
        // Rootful bootstraps (unc0ver, Electra, checkra1n, Procursus)
        "/.installed_unc0ver",
        "/.bootstrapped_electra",
        "/.procursus_strapped",
        "/.cydia_no_stash",
        "/jb",
        "/usr/lib/libjailbreak.dylib",
        // Package managers
        "/Applications/Cydia.app",
        "/Applications/Sileo.app",
        "/Applications/Zebra.app",
        "/etc/apt",
        "/private/var/lib/apt",
        "/private/var/lib/cydia",
        "/private/var/stash",
        // Tweak injection
        "/Library/MobileSubstrate/MobileSubstrate.dylib",
        "/Library/MobileSubstrate/DynamicLibraries",
        "/usr/lib/libsubstitute.dylib",
        "/usr/lib/libhooker.dylib",
        "/usr/lib/libellekit.dylib",
        "/usr/lib/TweakInject",
        // Detection-bypass tweaks
        "/var/mobile/Library/Preferences/me.jjolano.shadow.plist",
        "/Library/PreferenceBundles/ShadowPreferences.bundle",
        "/Library/PreferenceBundles/LibertyPref.bundle",
        "/Library/PreferenceBundles/ABypassPrefs.bundle",
        "/Library/PreferenceBundles/FlyJBPrefs.bundle",
        "/Applications/FlyJB.app",
        // Remote shell and instrumentation
        "/bin/bash",
        "/usr/sbin/sshd",
        "/usr/bin/ssh",
        "/usr/libexec/sftp-server",
        "/usr/sbin/frida-server",
    ]

    private static func suspiciousFiles() -> String? {
        suspiciousPaths.first(where: exists).map { "File present: \($0)" }
    }

    /// Three independent ways to see a path, so hooking one API isn't enough to hide it.
    /// `lstat` also sees a symlink whose target is hidden.
    private static func exists(_ path: String) -> Bool {
        var info = stat()
        if lstat(path, &info) == 0 { return true }
        if access(path, F_OK) == 0 { return true }
        return FileManager.default.fileExists(atPath: path)
    }

    /// RootHide hides /var/jb behind a randomised `/var/.jbroot-<hex>` directory.
    private static func rootHideDirectory() -> String? {
        guard let items = try? FileManager.default.contentsOfDirectory(atPath: "/var") else { return nil }
        return items.first { $0.hasPrefix(".jbroot-") }.map { "RootHide directory: /var/\($0)" }
    }

    /// Older jailbreaks move system folders to the data partition and leave symlinks behind.
    private static func symbolicLinks() -> String? {
        let paths = [
            "/Applications",
            "/Library/Ringtones",
            "/Library/Wallpaper",
            "/usr/arm-apple-darwin9",
            "/usr/include",
            "/usr/libexec",
            "/usr/share",
        ]
        for path in paths {
            if let target = try? FileManager.default.destinationOfSymbolicLink(atPath: path), !target.isEmpty {
                return "Symlinked system path: \(path) -> \(target)"
            }
        }
        return nil
    }

    // MARK: - Sandbox integrity

    /// The system volume is sealed read-only and the sandbox forbids writing outside the container.
    private static func writableSystem() -> String? {
        var volume = statvfs()
        if statvfs("/", &volume) == 0, volume.f_flag & UInt(ST_RDONLY) == 0 {
            return "System volume mounted read-write"
        }
        for directory in ["/private/", "/private/var/mobile/", "/"] {
            let path = directory + "noice-integrity-" + UUID().uuidString
            if FileManager.default.createFile(atPath: path, contents: Data()) {
                try? FileManager.default.removeItem(atPath: path)
                return "Wrote outside the sandbox: \(directory)"
            }
        }
        return nil
    }

    /// The sandbox denies fork(). It isn't callable from Swift, so it is looked up at run time.
    private static func sandboxAllowsFork() -> String? {
        guard let symbol = dlsym(UnsafeMutableRawPointer(bitPattern: -2), "fork") else { return nil } // RTLD_DEFAULT
        typealias Fork = @convention(c) () -> pid_t
        let pid = unsafeBitCast(symbol, to: Fork.self)()
        if pid == 0 { _exit(0) } // child: leave at once, never run app code
        guard pid > 0 else { return nil }
        kill(pid, SIGKILL)
        var status: Int32 = 0
        waitpid(pid, &status, 0)
        return "fork() allowed by the sandbox"
    }

    // MARK: - Runtime

    /// Tweak frameworks and instrumentation, by exact file name.
    private static let injectedLibraryNames: Set<String> = [
        "mobilesubstrate.dylib", "substrateloader.dylib", "substrateinserter.dylib",
        "substratebootstrap.dylib", "libsubstrate.dylib", "cydiasubstrate",
        "tweakinject.dylib", "libsubstitute.dylib", "substitute-inserter.dylib",
        "libhooker.dylib", "libellekit.dylib", "systemhook.dylib", "roothideinit.dylib",
        "libblackjack.dylib", "sslkillswitch.dylib", "sslkillswitch2.dylib",
        "fridagadget.dylib", "frida-agent.dylib", "libcycript.dylib",
        "shadow.dylib", "zzzzzliberty.dylib", "flyjb.dylib", "abypass.dylib",
        "preferenceloader.dylib", "rocketbootstrap.dylib",
    ]

    /// Folders tweaks are loaded from.
    private static let injectedLibraryFolders = [
        "/library/mobilesubstrate/",
        "/usr/lib/tweakinject/",
        "/var/jb/",
        "/.jbroot-",
    ]

    private static func injectedLibraries() -> String? {
        for index in 0..<_dyld_image_count() {
            guard let cName = _dyld_get_image_name(index) else { continue }
            let path = String(cString: cName)
            let lower = path.lowercased()
            let name = (lower as NSString).lastPathComponent
            if injectedLibraryNames.contains(name) || injectedLibraryFolders.contains(where: { lower.contains($0) }) {
                return "Injected library: \(path)"
            }
        }
        return nil
    }

    /// Classes registered by tweaks that hide a jailbreak from apps.
    private static func bypassTweakClasses() -> String? {
        let classes = ["ShadowRuleset", "UnSub", "Choicy", "Liberty", "FlyJB", "ABypass", "VnodeBypass", "HideJB"]
        return classes.first { objc_getClass($0) != nil }.map { "Bypass tweak loaded: \($0)" }
    }

    /// Needs the schemes in LSApplicationQueriesSchemes (NoICE/Info.plist). cydia:// is left out:
    /// an App Store app registers it too.
    private static func jailbreakURLSchemes() -> String? {
        let schemes = ["undecimus", "sileo", "zbra", "filza", "dopamine", "palera1n"]
        return schemes.first { scheme in
            guard let url = URL(string: "\(scheme)://") else { return false }
            return UIApplication.shared.canOpenURL(url)
        }.map { "Jailbreak app installed: \($0)://" }
    }
}
