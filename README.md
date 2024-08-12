# FileSystemNavigator

FileSystemNavigator is a SwiftUI library that provides an easy-to-use and customizable file system navigation interface for macOS and iOS applications.

## Features

- Display file system hierarchy in a tree-like structure
- Customizable file/folder item views
- Real-time file system monitoring and updates
- Built-in support for common file operations (rename, delete, move)
- Keyboard shortcuts for improved navigation
- Context menu support for additional actions

## Requirements

- macOS 14.0+ or iOS 17.0+
- Swift 5.10+

## Installation

FileSystemNavigator can be installed using Swift Package Manager. Add the following dependency to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/1amageek/FileSystemNavigator.git", branch: "main")
]
```

## Usage

1. Import the FileSystemNavigator module in your SwiftUI view:

```swift
import SwiftUI
import FileSystemNavigator
```

2. Create a `FileSystem` instance and use it as an environment object:

```swift
@State private var fileSystem: FileSystem = FileSystem.shared
```

3. Use the `FileSystemNavigator` view to display your file hierarchy:

```swift
var body: some View {
    fileSystem.view([
        .init(name: "Project", item: .init(url: projectURL))
    ]) { item, isHovered in
        Text(item.wrappedValue.name)
    }
    .environment(fileSystem)
}
```

## Customization

You can customize the appearance of file/folder items by providing your own view builder:

```swift
fileSystem.view([
    .init(name: "Project", item: .init(url: projectURL))
]) { item, isHovered in
    HStack {
        Image(systemName: item.wrappedValue.isDirectory ? "folder" : "doc")
        Text(item.wrappedValue.name)
            .foregroundColor(isHovered ? .blue : .primary)
    }
}
```

## File Operations

FileSystemNavigator provides built-in support for common file operations:

- Rename: Press Return/Enter key on a selected item
- Delete: Press Delete key on a selected item or use the context menu
- Move: Use the `move(item:to:)` method on the `FileSystem` instance
- Copy: Use the `copy(item:to:)` method on the `FileSystem` instance

## Contributing

Contributions to FileSystemNavigator are welcome! Please feel free to submit a Pull Request.

## License

FileSystemNavigator is available under the MIT license. See the LICENSE file for more info.
