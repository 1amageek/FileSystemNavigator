import Foundation

public struct FileItemSection: Identifiable {
    
    public var id: String { item.id }
    
    public var name: String
    
    public var item: FileItem
    
    public init(name: String, item: FileItem) {
        self.name = name
        self.item = item
    }
}
