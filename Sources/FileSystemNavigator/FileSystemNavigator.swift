import SwiftUI

public struct FileSystemNavigator<RowItem: View>: View {
    
    @Environment(FileSystem.self) var fileSystem: FileSystem
    
    @State var sections: [FileItemSection]
    
    var content: (Binding<FileItem>) -> RowItem
    
    public init(sections: [FileItemSection], @ViewBuilder content: @escaping (Binding<FileItem>) -> RowItem = { _ in EmptyView() }) {
        self._sections = State(initialValue: sections)
        self.content = content
    }
    
    public var body: some View {
        @Bindable var system = fileSystem
        
        List(selection: $system.selection) {
            ForEach($sections) { section in
                Section {
                    OutlineGroup(section.item, children: \.children) { item in
                        FileItemView(item: item, content: content)
                            .tag(item.wrappedValue)
                            .contextMenu {
                                let item = item.wrappedValue
#if os(macOS)
                                Button {
                                    NSWorkspace.shared.activateFileViewerSelecting([item.url])
                                } label: {
                                    Text("Show in Finder")
                                    Image(systemName: "finder")
                                }
                                
                                Divider()
#endif
                                
                                Button {
                                    fileSystem.delete(item: item)
                                } label: {
                                    Text("Delete")
                                    Image(systemName: "trash")
                                }
                                Button {
                                    fileSystem.copy(item: item, to: item.url)
                                } label: {
                                    Text("Copy")
                                    Image(systemName: "doc.on.doc")
                                }
                                Button {
                                    fileSystem.move(item: item, to: item.url)
                                } label: {
                                    Text("Move")
                                    Image(systemName: "arrow.right")
                                }
                                Button {
                                    fileSystem.rename(item: item, newName: "NewName")
                                } label: {
                                    Text("Rename")
                                    Image(systemName: "pencil")
                                }
                            }
                    }
                } header: {
                    Text(section.wrappedValue.name)
                }
                .onAppear { section.wrappedValue.item.loadFileItems() }
            }
        }
        .focusable()
        .focusEffectDisabled()
        .onKeyPress(.init(Character(UnicodeScalar(127)))) {
            fileSystem.showingDeleteConfirmation.toggle()
            return .handled
        }
        .onKeyPress(.return) {
            fileSystem.editNameStart()
            return .handled
        }
        .onChange(of: fileSystem.selection) { _, newValue in
            fileSystem.editNameEnd()
        }
        .frame(minWidth: 220)
        .alert("Move to Trash", isPresented: $system.showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Move to Trash", role: .destructive) {
                fileSystem.deleteItems(fileSystem.selection)
            }
        } message: {
            let selectedFiles = fileSystem.selection.filter { !$0.isDirectory }
            if selectedFiles.count == 1 {
                Text("Do you want to move '\(selectedFiles.first!.name)' to the Trash?")
            } else {
                Text("Do you want to move \(selectedFiles.count) items to the Trash?")
            }
        }
    }
}

#Preview {
    @State var fileSystem = FileSystem.shared
    
    return fileSystem.view { _ in 
        Text("Content")
    }
}
