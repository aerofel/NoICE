//
//  NoICEApp.swift
//  NoICE
//
//  Created by Philippe LE GALL on 16/01/2026.
//

import SwiftUI
import HOTKit

@main
struct NoICEApp: App {
    @StateObject private var configuration = DefaultHOTConfiguration()
    @StateObject private var hotState = HOTState()

    var body: some Scene {
        WindowGroup {
            ContentView(configuration: configuration, hotState: hotState)
        }
    }
}
