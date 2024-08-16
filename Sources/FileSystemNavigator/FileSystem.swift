import Foundation
import SwiftUI

@Observable
public final class FileSystem {
    public static let shared = FileSystem()
    
    private var rootItems: [FileItem] = []
    private var itemCache: [URL: FileItem] = [:]
    private var observer: FileSystemObserver?
    
    public var selection: Set<FileItem> = []
    public var editItem: FileItem?
    public var showingDeleteConfirmation = false
    
    private init() {
        startObserving()
    }

    public func item(for url: URL) -> FileItem {
        if let cachedItem = itemCache[url] {
            return cachedItem
        }
        let newItem = FileItem(url: url)
        itemCache[url] = newItem
        return newItem
    }
    
    public func loadChildrenIfNeeded(for item: FileItem) -> FileItem {
        guard item.isDirectory else { return item }
        if let cachedItem = itemCache[item.url], cachedItem.children != nil {
            return cachedItem
        }
        let fileManager = FileManager.default
        guard let contents = try? fileManager.contentsOfDirectory(
            at: item.url,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]) else {
            return item
        }
        let children = contents.map { self.item(for: $0) }
        let updatedItem = FileItem(url: item.url, children: children)
        itemCache[item.url] = updatedItem
        return updatedItem
    }
    
    
    private func startObserving() {
        guard observer == nil else { return }
        
        let configuration = FileSystemObserver.Configuration(
            url: FileManager.default.homeDirectoryForCurrentUser,
            filterType: .extensions(["*"]),
            includeSubdirectories: true
        )
        
        observer = FileSystemObserver(configuration: configuration) { [weak self] event in
            self?.handleFileSystemEvent(event)
        }
        
        observer?.startObserving()
    }
    
    private func handleFileSystemEvent(_ event: FileSystemObserver.Event) {
        DispatchQueue.main.async {
            switch event {
            case .created(let url), .modified(let url), .deleted(let url):
                self.updateItem(at: url)
            case .renamed(let oldURL, let newURL):
                self.updateItem(at: oldURL)
                self.updateItem(at: newURL)
            }
        }
    }
    

    private func updateItem(at url: URL) {
        let parentURL = url.deletingLastPathComponent().standardized
        if let parentItem = itemCache[parentURL] {
            let updatedParentItem = loadChildrenIfNeeded(for: parentItem)
            itemCache[parentURL] = updatedParentItem
        } else {
            updateParentChain(for: parentURL)
        }
    }
    
    private func updateParentChain(for url: URL) {
        var currentURL = url
        while !itemCache.keys.contains(currentURL) && currentURL.pathComponents.count > 1 {
            currentURL = currentURL.deletingLastPathComponent()
        }
        if let item = itemCache[currentURL] {
            let updatedItem = loadChildrenIfNeeded(for: item)
            itemCache[currentURL] = updatedItem
        }
    }
    
    public func editNameStart() {
        self.editItem = selection.first
    }
    
    public func editNameEnd() {
        self.editItem = nil
    }

    public func delete(items: Set<FileItem>) {
        let fileManager = FileManager.default
        for item in items {
            do {
                try fileManager.removeItem(at: item.url)
                itemCache.removeValue(forKey: item.url)
                updateItem(at: item.url.deletingLastPathComponent())
            } catch {
                print("Error deleting item: \(error)")
            }
        }
        selection.subtract(items)
    }
    
    public func copy(item: FileItem, to destinationURL: URL) {
        let fileManager = FileManager.default
        let newURL = destinationURL.appendingPathComponent(item.name)
        do {
            try fileManager.copyItem(at: item.url, to: newURL)
            updateItem(at: destinationURL)
        } catch {
            print("Error copying item: \(error)")
        }
    }
    
    public func move(item: FileItem, to destinationURL: URL) {
        let fileManager = FileManager.default
        let newURL = destinationURL.appendingPathComponent(item.name)
        do {
            try fileManager.moveItem(at: item.url, to: newURL)
            itemCache.removeValue(forKey: item.url)
            updateItem(at: item.url.deletingLastPathComponent())
            updateItem(at: destinationURL)
        } catch {
            print("Error moving item: \(error)")
        }
    }
    
    public func rename(item: FileItem, to newName: String) {
        let fileManager = FileManager.default
        let newURL = item.url.deletingLastPathComponent().appendingPathComponent(newName)
        do {
            try fileManager.moveItem(at: item.url, to: newURL)
            itemCache.removeValue(forKey: item.url)
            updateItem(at: item.url.deletingLastPathComponent())
        } catch {
            print("Error renaming item: \(error)")
        }
    }
    
    deinit {
        observer?.stopObserving()
    }
}

extension FileSystem {
    
    @ViewBuilder
    public func view<Content: View>(_ sections: [FileItemSection] = [], @ViewBuilder content: @escaping (Binding<FileItem>, Bool) -> Content) -> some View {
        FileSystemNavigator(sections: sections, content: content)
    }
}

