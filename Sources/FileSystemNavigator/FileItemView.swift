import SwiftUI

struct FileItemView<Content: View>: View {
    
    @Environment(FileSystem.self) var fileSystem: FileSystem
    
    @State private var isHovered = false
    
    @State private var name: String
    
    @FocusState private var focus: Bool
        
    @Binding var item: FileItem
    
    var content: ((Binding<FileItem>, Bool) -> Content)
    
    init(item: Binding<FileItem>, @ViewBuilder content: @escaping (Binding<FileItem>, Bool) -> Content) {
        self._item = item
        self._name = State(initialValue: item.wrappedValue.name)
        self.content = content
    }
    
    var body: some View {
        HStack {
            Image(systemName: item.isDirectory ? "folder" : "doc")
                .foregroundColor(item.isDirectory ? .blue : .gray)
            if fileSystem.editItem?.url == item.url {
                TextField("", text: $name)
                    .focused($focus)
                    .onSubmit {
                        fileSystem.rename(item: item, to: name)
                        fileSystem.editNameEnd()
                    }
                    .onAppear {
                        focus = true
                    }
            } else {
                content($item, isHovered)
            }
        }
        .contentShape(Rectangle())
        .onHover { isHovered in
            self.isHovered = isHovered
        }     
    }
}
