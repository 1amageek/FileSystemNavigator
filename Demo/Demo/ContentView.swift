//
//  ContentView.swift
//  Demo
//
//  Created by Norikazu Muramoto on 2024/08/12.
//

import SwiftUI
import FileSystemNavigator

struct ContentView: View {
    
    @Environment(FileSystem.self) var fileSystem: FileSystem
    
    @State private var url: URL?

    var body: some View {
        NavigationSplitView {
            if let url {
                fileSystem.view([
                    .init(name: "Project", item: .init(url: url))
                ]) { item, isHovered in
                    Text(item.wrappedValue.name)
                }
            } else {
                VStack {
                    Text("No directory loaded")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    
                    Button {
                        selectDirectory()
                    } label: {
                        Text("Select Directory")
                    }
                }
            }
        } detail: {
            Text("Select an item")
        }
    }
    
    func selectDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Select a directory to save improved code files"
        panel.prompt = "Select"
        
        if panel.runModal() == .OK, let url = panel.url {
            self.url = url
        }
    }
}

#Preview {
    ContentView()
}
