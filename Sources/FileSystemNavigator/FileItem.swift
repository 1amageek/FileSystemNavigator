import Foundation
import SwiftUI

public struct FileItem: Identifiable {
    
    public var id: String
    public var name: String
    public var url: URL
    public var isDirectory: Bool
    public var children: [FileItem]?
    
    public init(url: URL, children: [FileItem]? = nil) {
        self.url = url
        self.id = url.absoluteString
        self.name = url.lastPathComponent
        var isDirectory: ObjCBool = false
        FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
        self.isDirectory = isDirectory.boolValue
        self.children = children
    }
}

extension FileItem {
    
    @discardableResult
    public mutating func loadChildren() -> [FileItem]? {
        self.children = getChildren()
        return self.children
    }
    
    public func getChildren() -> [FileItem]? {
        guard self.isDirectory else { return nil }
        let fileManager = FileManager.default
        guard let contents = try? fileManager.contentsOfDirectory(
            at: self.url,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]) else {
            return nil
        }
        return contents.map { FileItem(url: $0) }
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
