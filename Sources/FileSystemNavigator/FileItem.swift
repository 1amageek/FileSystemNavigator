import Foundation

@Observable
public class FileItem: Identifiable {
    
    public var id: String { url.absoluteString }
    public var name: String { url.lastPathComponent }
    public var url: URL
    public var isDirectory: Bool
    public var isEditing: Bool
    public var children: [FileItem]?
    
    @ObservationIgnored
    private var source: DispatchSourceFileSystemObject?
    
    public init(url: URL) {
        self.url = url
        var isDirectory: ObjCBool = false
        FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
        self.isEditing = false
        self.isDirectory = isDirectory.boolValue
        if self.isDirectory {
            self.children = []
        } else {
            self.children = nil
        }
        loadFileItems()
    }
    
    public func loadFileItems() {
        if self.isDirectory {
            startMonitoring()
            let fileManager = FileManager.default
            guard let contents = try? fileManager.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]) else {
                return
            }
            self.children = contents.map { FileItem(url: $0) }
        } else {
            self.children = nil
        }
    }
    
    private func startMonitoring() {
        let fileDescriptor = open(url.path, O_EVTONLY)
        guard fileDescriptor != -1 else { return }
        source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fileDescriptor, eventMask: [.write, .rename, .delete], queue: DispatchQueue.global())
        source?.setEventHandler { [weak self] in
            DispatchQueue.main.async {
                    self?.loadFileItems()
            }
        }
        source?.setCancelHandler {
            close(fileDescriptor)
        }
        source?.resume()
    }
    
    func stopMonitoring() {
        source?.cancel()
        source = nil
    }
    
    deinit {
        stopMonitoring()
    }
}

extension FileItem: Hashable, Equatable {
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(children)
    }
    
    public static func == (lhs: FileItem, rhs: FileItem) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}

extension FileItem: CustomStringConvertible {
    
    public var description: String {
        return description(indentation: 0)
    }
    
    private func description(indentation: Int) -> String {
        let indent = String(repeating: "    ", count: indentation)
        var result = "\(indent)- \(name)"
        
        if let children = children, !children.isEmpty {
            result += ":\n"
            for child in children {
                result += child.description(indentation: indentation + 1) + "\n"
            }
        }
        
        return result
    }
}
