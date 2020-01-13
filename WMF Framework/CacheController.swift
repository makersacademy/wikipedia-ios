
import Foundation

public class CacheController {
    
    static let cacheURL: URL = {
        var url = FileManager.default.wmf_containerURL().appendingPathComponent("PersistentCache", isDirectory: true)
        
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        do {
            try url.setResourceValues(values)
        } catch {
            return url
        }
        
        return url
    }()
    
    static let backgroundCacheContext: NSManagedObjectContext? = {
        
        //create ManagedObjectModel based on Cache.momd
        guard let modelURL = Bundle.wmf.url(forResource: "PersistentCache", withExtension: "momd"),
            let model = NSManagedObjectModel(contentsOf: modelURL) else {
                assertionFailure("Failure to create managed object model")
                return nil
        }
                
        //create persistent store coordinator / persistent store
        let dbURL = cacheURL.deletingLastPathComponent().appendingPathComponent("PersistentCache.sqlite", isDirectory: false)
        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        
        let options = [
            NSMigratePersistentStoresAutomaticallyOption: NSNumber(booleanLiteral: true),
            NSInferMappingModelAutomaticallyOption: NSNumber(booleanLiteral: true)
        ]
        
        do {
            try persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: dbURL, options: options)
        } catch {
            do {
                try FileManager.default.removeItem(at: dbURL)
            } catch {
                assertionFailure("Failure to remove old db file")
                return nil
            }

            do {
                try persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: dbURL, options: options)
            } catch {
                assertionFailure("Failure to add persistent store to coordinator")
                return nil
            }
        }

        let cacheBackgroundContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        cacheBackgroundContext.persistentStoreCoordinator = persistentStoreCoordinator
                
        return cacheBackgroundContext
    }()
    
    let provider: CacheProviding
    let dbWriter: CacheDBWriting
    let fileWriter: CacheFileWriting
    let gatekeeper = CacheGatekeeper()
    
    
    
    init(fetcher: Fetcher, dbWriter: CacheDBWriting, fileWriter: CacheFileWriting, provider: CacheProviding) {
        self.provider = provider
        self.dbWriter = dbWriter
        self.fileWriter = fileWriter
    }
    
    func clearURLCache() { }//maybe settings hook? clear only url cache.
    func clearCoreDataCache() {}
    //todo: Settings hook, logout don't sync hook, etc.
    //clear out from core data, leave URL cache as-is.
    
    public func toggleCache(url: URL) {
        assertionFailure("Must subclass")
    }

    func add(url: URL, groupKey: String, itemKey: String) {
        
        dbWriter.add(url: url, groupKey: groupKey, itemKey: itemKey)
    }
    
    func remove(groupKey: String, itemKey: String) {
        
        gatekeeper.removeQueuedCompletionItems(with: groupKey)
        
        dbWriter.cancelTasks(for: groupKey)
        fileWriter.cancelTasks(for: groupKey)
        
        let itemKeysToRemove = dbWriter.itemKeysToRemove(for: groupKey)
        
        for itemKey in itemKeysToRemove {
            fileWriter.remove(groupKey: groupKey, itemKey: itemKey)
        }
    }
    
    public func isCached(url: URL) -> Bool {
        dbWriter.isCached(url: url)
    }
    
    public func recentCachedURLResponse(for url: URL) -> CachedURLResponse? {
        return provider.recentCachedURLResponse(for: url)
    }
    
    public func persistedCachedURLResponse(for url: URL) -> CachedURLResponse? {
        return provider.persistedCachedURLResponse(for: url)
    }
    
    private func finishAndRunQueue(groupKey: String, itemKey: String, result: CacheResult) {
        
        handleFinalResult(groupKey: groupKey, itemKey: itemKey, result: result)
        
        gatekeeper.runAndCleanOutQueuedCompletionItems(result: result, itemKey: itemKey)
    }
    
    private func handleFinalResult(groupKey: String, itemKey: String, result: CacheResult) {
        switch (result.status, result.type) {
        case (.succeed, .add):
            handleAddSuccess(groupKey: groupKey, itemKey: itemKey)
        case (.fail, .add):
            //tonitodo: notify user that file add failed
            break
        case (.fail, .remove):
            //tonitodo: notify user that file remove failed
            break
        case (.succeed, .remove):
            handleRemoveSuccess(groupKey: groupKey, itemKey: itemKey)
        }
    }
    
    private func handleRemoveSuccess(groupKey: String, itemKey: String) {
        
        if dbWriter.allDeleted(groupKey: groupKey) {
            //notify that group is fully deleted
        }
    }
    
    private func handleAddSuccess(groupKey: String, itemKey: String) {
        
        dbWriter.markDownloaded(itemKey: itemKey)
        
        if dbWriter.allDownloaded(groupKey: groupKey) {
            
            //notify that item is fully downloaded
        }
    }
}

extension CacheController: CacheDBWritingDelegate {

    func shouldQueue(groupKey: String, itemKey: String) -> Bool {
        
        return gatekeeper.shouldQueue(groupKey: groupKey, itemKey: itemKey)
    }
    
    func queue(groupKey: String, itemKey: String) {
        return gatekeeper.queue(groupKey: groupKey, itemKey: itemKey) { [weak self] (result) in
            
            guard let self = self else {
                return
            }
            
            self.handleFinalResult(groupKey: groupKey, itemKey: itemKey, result: result)
        }
    }
    
    func dbWriterDidAdd(groupKey: String, itemKey: String) {
        fileWriter.add(groupKey: groupKey, itemKey: itemKey)
    }
    
    func dbWriterDidRemove(groupKey: String, itemKey: String) {
        finishAndRunQueue(groupKey: groupKey, itemKey: itemKey, result: CacheResult(status: .succeed, type: .remove))
    }
    
    func dbWriterDidFailAdd(groupKey: String, itemKey: String) {
        finishAndRunQueue(groupKey: groupKey, itemKey: itemKey, result: CacheResult(status: .fail, type: .add))
    }
    
    func dbWriterDidFailRemove(groupKey: String, itemKey: String) {
        finishAndRunQueue(groupKey: groupKey, itemKey: itemKey, result: CacheResult(status: .fail, type: .remove))
    }
    
    func dbWriterDidOutrightFailAdd(groupKey: String) {
        
        let key = groupKey
        remove(groupKey: key, itemKey: key)
        
        //tonitodo: notify failure here
    }
}

extension CacheController: CacheFileWritingDelegate {
    func fileWriterDidAdd(groupKey: String, itemKey: String) {
         
        finishAndRunQueue(groupKey: groupKey, itemKey: itemKey, result: CacheResult(status: .succeed, type: .add))
    }
    
    func fileWriterDidRemove(groupKey: String, itemKey: String) {
        dbWriter.remove(groupKey: groupKey, itemKey: itemKey)
    }
    
    func fileWriterDidFailAdd(groupKey: String, itemKey: String) {
        finishAndRunQueue(groupKey: groupKey, itemKey: itemKey, result: CacheResult(status: .fail, type: .add))
    }
    
    func fileWriterDidFailRemove(groupKey: String, itemKey: String) {
        finishAndRunQueue(groupKey: groupKey, itemKey: itemKey, result: CacheResult(status: .fail, type: .remove))
    }
}

struct CacheResult {
    
    enum Status {
        case succeed
        case fail
    }

    enum ResultType {
        case add
        case remove
    }
    
    let status: Status
    let type: ResultType
}
