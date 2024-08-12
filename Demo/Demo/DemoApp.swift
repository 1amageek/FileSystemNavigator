//
//  DemoApp.swift
//  Demo
//
//  Created by Norikazu Muramoto on 2024/08/12.
//

import SwiftUI
import FileSystemNavigator

@main
struct DemoApp: App {
    
    @State private var fileSystem: FileSystem = FileSystem.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(fileSystem)
        }
    }
}
