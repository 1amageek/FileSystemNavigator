import Foundation
import UniformTypeIdentifiers

public class FileSystemObserver {
    public enum FilterType {
        case utTypes([UTType])
        case extensions([String])
    }
    
    public struct Configuration {
        let url: URL
        let filterType: FilterType
        let includeSubdirectories: Bool
        let latency: CFTimeInterval
        let queue: DispatchQueue
        
        public init(url: URL, filterType: FilterType, includeSubdirectories: Bool = true, latency: CFTimeInterval = 0.3, queue: DispatchQueue = .main) {
            self.url = url
            self.filterType = filterType
            self.includeSubdirectories = includeSubdirectories
            self.latency = latency
            self.queue = queue
        }
    }
    
    public enum Event {
        case created(URL)
        case modified(URL)
        case deleted(URL)
        case renamed(oldURL: URL, newURL: URL)
    }
    
    private var eventStream: FSEventStreamRef?
    private let configuration: Configuration
    private var callback: (Event) -> Void
    private var lastEventId: FSEventStreamEventId = FSEventStreamEventId(kFSEventStreamEventIdSinceNow)
    
    public init(configuration: Configuration, callback: @escaping (Event) -> Void) {
        self.configuration = configuration
        self.callback = callback
    }
    
    public func startObserving() {
        var context = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )
        
        var flags: FSEventStreamCreateFlags = UInt32(kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagNoDefer)
        if !configuration.includeSubdirectories {
            flags |= UInt32(kFSEventStreamCreateFlagWatchRoot)
        }
        
        eventStream = FSEventStreamCreate(
            kCFAllocatorDefault,
            fileSystemEventsCallback,
            &context,
            [configuration.url.path] as CFArray,
            lastEventId,
            configuration.latency,
            flags
        )
        
        guard let eventStream = eventStream else {
            print("Failed to create FSEventStream")
            return
        }
        
        FSEventStreamSetDispatchQueue(eventStream, configuration.queue)
        FSEventStreamStart(eventStream)
    }
    
    public func stopObserving() {
        guard let eventStream = eventStream else { return }
        FSEventStreamStop(eventStream)
        FSEventStreamInvalidate(eventStream)
        FSEventStreamRelease(eventStream)
        self.eventStream = nil
    }
    
    private let fileSystemEventsCallback: FSEventStreamCallback = { (streamRef, clientCallBackInfo, numEvents, eventPaths, eventFlags, eventIds) in
        guard let clientCallBackInfo = clientCallBackInfo else { return }
        let observer = Unmanaged<FileSystemObserver>.fromOpaque(clientCallBackInfo).takeUnretainedValue()
        let paths = UnsafeBufferPointer(start: eventPaths.assumingMemoryBound(to: UnsafePointer<CChar>.self), count: numEvents)
        let flags = UnsafeBufferPointer(start: eventFlags, count: numEvents)
        let ids = UnsafeBufferPointer(start: eventIds, count: numEvents)
        observer.processEvents(paths: paths, flags: flags, ids: ids)
    }
    
    private func processEvents(paths: UnsafeBufferPointer<UnsafePointer<CChar>>, flags: UnsafeBufferPointer<FSEventStreamEventFlags>, ids: UnsafeBufferPointer<FSEventStreamEventId>) {
        for i in 0..<paths.count {
            guard let path = String(cString: paths[i], encoding: .utf8) else { continue }
            let url = URL(fileURLWithPath: path)
            let flag = flags[i]
            
            if !matchesFilter(url) { continue }
            
            if flag & UInt32(kFSEventStreamEventFlagItemCreated) != 0 {
                configuration.queue.async { self.callback(.created(url)) }
            } else if flag & UInt32(kFSEventStreamEventFlagItemModified) != 0 {
                configuration.queue.async { self.callback(.modified(url)) }
            } else if flag & UInt32(kFSEventStreamEventFlagItemRemoved) != 0 {
                configuration.queue.async { self.callback(.deleted(url)) }
            } else if flag & UInt32(kFSEventStreamEventFlagItemRenamed) != 0 {
                // Handling rename events requires keeping track of the previous event
                // This is a simplified version; a more robust implementation would pair old and new names
                configuration.queue.async { self.callback(.renamed(oldURL: url, newURL: url)) }
            }
            
            lastEventId = ids[i]
        }
    }
    
    private func matchesFilter(_ url: URL) -> Bool {
        switch configuration.filterType {
        case .utTypes(let types):
            guard let type = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType else {
                return false
            }
            return types.contains { type.conforms(to: $0) }
        case .extensions(let extensions):
            return extensions.contains(url.pathExtension.lowercased())
        }
    }
    
    deinit {
        stopObserving()
    }
}
