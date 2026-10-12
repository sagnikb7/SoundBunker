import CoreData

/// Versioned local index. Media stays in its original folder; only record payloads live here.
@MainActor
final class LibraryDatabase {
    let container: NSPersistentContainer
    init(inMemory: Bool = false, storeURL: URL? = nil) throws {
        let model = NSManagedObjectModel()
        let entity = NSEntityDescription()
        entity.name = "LibraryRecord"
        entity.managedObjectClassName = "NSManagedObject"
        let definitions: [(String, NSAttributeType)] = [("key", .stringAttributeType), ("kind", .stringAttributeType), ("payload", .binaryDataAttributeType)]
        entity.properties = definitions.map { name, type in
            let attribute = NSAttributeDescription()
            attribute.name = name; attribute.attributeType = type; attribute.isOptional = false
            return attribute
        }
        entity.uniquenessConstraints = [["key"]]
        model.entities = [entity]
        model.versionIdentifiers = ["PocketMusicIndex1"]
        container = NSPersistentContainer(name: "PocketMusic", managedObjectModel: model)
        let description = NSPersistentStoreDescription()
        if inMemory { description.type = NSInMemoryStoreType }
        else {
            let base = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            description.url = storeURL ?? base.appendingPathComponent("PocketMusic.sqlite")
        }
        description.shouldAddStoreAsynchronously = false
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        container.persistentStoreDescriptions = [description]
        var failure: Error?
        container.loadPersistentStores { _, error in failure = error }
        if let failure = failure { throw failure }
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    func all<T: Decodable>(_ kind: String, as type: T.Type) throws -> [T] {
        let fetch = NSFetchRequest<NSManagedObject>(entityName: "LibraryRecord")
        fetch.predicate = NSPredicate(format: "kind == %@", kind)
        return try container.viewContext.fetch(fetch).map {
            try JSONDecoder().decode(T.self, from: $0.value(forKey: "payload") as! Data)
        }
    }
    func save<T: Encodable>(_ value: T, key: String, kind: String) throws {
        let context = container.viewContext
        let fetch = NSFetchRequest<NSManagedObject>(entityName: "LibraryRecord")
        fetch.predicate = NSPredicate(format: "key == %@", key); fetch.fetchLimit = 1
        let record = try context.fetch(fetch).first ?? NSEntityDescription.insertNewObject(forEntityName: "LibraryRecord", into: context)
        record.setValue(key, forKey: "key"); record.setValue(kind, forKey: "kind")
        record.setValue(try JSONEncoder().encode(value), forKey: "payload")
    }
    func remove(key: String) throws {
        let fetch = NSFetchRequest<NSManagedObject>(entityName: "LibraryRecord")
        fetch.predicate = NSPredicate(format: "key == %@", key)
        try container.viewContext.fetch(fetch).forEach(container.viewContext.delete)
    }
    func commit() throws { if container.viewContext.hasChanges { try container.viewContext.save() } }
}
