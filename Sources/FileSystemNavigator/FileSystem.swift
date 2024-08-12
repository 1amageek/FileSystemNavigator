import SwiftUI

@Observable
public final class FileSystem {
    
    public static let shared: FileSystem = FileSystem()
        
    public var selection: Set<FileItem> = []
    
    var editItem: FileItem?
    
    var showingDeleteConfirmation = false
    
    init() { }
    
    func editNameStart() {
        self.editItem = selection.first
        self.editItem?.isEditing = true
    }
    
    func editNameEnd() {
        self.editItem?.isEditing = false
        self.editItem = nil
    }
    
    func delete(item: FileItem) {
        deleteItems([item])
    }
    
    func deleteItems(_ items: Set<FileItem>) {
        let fileManager = FileManager.default
        for item in items {
            try? fileManager.removeItem(at: item.url)
        }
    }
    
    func copy(item: FileItem, to destinationURL: URL) {
        let fileManager = FileManager.default
        let destination = destinationURL.appendingPathComponent(item.name)
        try? fileManager.copyItem(at: item.url, to: destination)
    }
    
    func move(item: FileItem, to destinationURL: URL) {
        let fileManager = FileManager.default
        let destination = destinationURL.appendingPathComponent(item.name)
        if fileManager.fileExists(atPath: destination.path) {
            try? fileManager.removeItem(at: destination)
        }
        try? fileManager.moveItem(at: item.url, to: destination)
    }
    
    func rename(item: FileItem, newName: String) {
        let fileManager = FileManager.default
        let destination = item.url.deletingLastPathComponent().appendingPathComponent(newName)
        try? fileManager.moveItem(at: item.url, to: destination)
    }
}

extension FileSystem {
    
    @ViewBuilder
    public func view<Content: View>(_ sections: [FileItemSection] = [], @ViewBuilder content: @escaping (Binding<FileItem>, Bool) -> Content) -> some View {
        FileSystemNavigator(sections: sections, content: content)
    }
}

