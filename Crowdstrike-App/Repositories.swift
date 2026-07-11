import Foundation
import SwiftData

// MARK: - Endpoint Repository

/// Encapsulates all SwiftData operations for `HostEntity`, keeping the
/// view model focused on orchestration rather than persistence details.
@MainActor
struct EndpointRepository {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    /// Fetches all host entities from the store.
    func fetchAll() throws -> [HostEntity] {
        try modelContext.fetch(FetchDescriptor<HostEntity>())
    }
    
    /// Replaces all host entities in the store with the provided DTOs.
    /// Deletes existing entities, inserts new ones, and saves in a single
    /// batch to minimize `ModelContext.save()` calls.
    func replaceAll(with hosts: [Host]) throws {
        try modelContext.delete(model: HostEntity.self)
        for host in hosts {
            modelContext.insert(HostEntity(from: host))
        }
        try modelContext.save()
    }
    
    /// Deletes all host entities from the store.
    func deleteAll() throws {
        try modelContext.delete(model: HostEntity.self)
        try modelContext.save()
    }
}

// MARK: - Alert Repository

/// Encapsulates all SwiftData operations for `AlertEntity`, keeping the
/// view model focused on orchestration rather than persistence details.
@MainActor
struct AlertRepository {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    /// Fetches all alert entities from the store, sorted by created date
    /// descending (most recent first).
    func fetchAllSortedByCreatedDate() throws -> [AlertEntity] {
        let descriptor = FetchDescriptor<AlertEntity>(
            sortBy: [SortDescriptor(\.createdDate, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// Replaces all alert entities in the store with the provided DTOs.
    /// Deletes existing entities, inserts new ones, and saves in a single
    /// batch to minimize `ModelContext.save()` calls.
    func replaceAll(with alerts: [Alert]) throws {
        try modelContext.delete(model: AlertEntity.self)
        for alert in alerts {
            modelContext.insert(AlertEntity(from: alert))
        }
        try modelContext.save()
    }
    
    /// Deletes all alert entities from the store.
    func deleteAll() throws {
        try modelContext.delete(model: AlertEntity.self)
        try modelContext.save()
    }
}
