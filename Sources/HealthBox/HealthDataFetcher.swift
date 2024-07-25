//
//  HealthDataFetcher.swift
//  HealthBox
//
//  Created by Ben Gottlieb on 1/5/24.
//

import Foundation
import HealthKit

public actor HealthDataFetcher {
    public static let instance = HealthDataFetcher()
    var useStatisticsQuery = false
    enum HealthDataFetcherError: Error, LocalizedError {
        case failedToBuildAPredicate, noResultsReturned, unhandledIdentifier
        
        public var errorDescription: String? {
            switch self {
            case .failedToBuildAPredicate: "Failed to build a predicate"
            case .noResultsReturned: "No results returned"
            case .unhandledIdentifier: "Unhandled identifier"
            }
        }
    }
    
    public func setUseStatisticsQuery(_ use: Bool) { useStatisticsQuery = use }
    public func hasData(for metrics: [HealthMetric] = HealthMetric.common) async -> Bool {
        for metric in metrics {
            if let identifier = metric.typeIdentifier, await hasData(for: identifier) {
                return true
            }
        }
        return false
    }
    
    public func hasData(for identifier: HKQuantityTypeIdentifier) async -> Bool {
        do {
            return try await !fetch(identifier, start: .earliestHealthKitDate, end: .now, limit: 1).isEmpty
        } catch {
            return false
        }
    }
    
    public func hasData(for identifier: HKCategoryTypeIdentifier) async -> Bool {
        do {
            return try await !fetch(identifier, start: .earliestHealthKitDate, end: .now, limit: 1).isEmpty
        } catch {
            return false
        }
    }
    
    public func fetch(_ identifier: HKQuantityTypeIdentifier, start: Date = .earliestHealthKitDate, end: Date = .now, limit: Int = 1000000) async throws -> ExportedHealthKitData {
        guard let metric = HealthMetric.metric(with: identifier) else { throw HealthDataFetcherError.unhandledIdentifier }
        
        return try await fetch(metric, start: start, end: end, limit: limit)
    }
    
    public func fetch(_ identifier: HKCategoryTypeIdentifier, start: Date = .earliestHealthKitDate, end: Date = .now, limit: Int = 1000000) async throws -> ExportedHealthKitData {
        guard let metric = HealthMetric.metric(with: identifier) else { throw HealthDataFetcherError.unhandledIdentifier }
        
        return try await fetch(metric, start: start, end: end, limit: limit)
    }
    
    public func fetch(_ metric: HealthMetric, start: Date = .earliestHealthKitDate, end: Date = .now, limit: Int = 1000000) async throws -> ExportedHealthKitData {
        let store = HealthBox.instance.healthStore
        let pred = HKQuery.predicateForSamples(withStart: start, end: end, options: [])
        
        guard let sampleType = metric.sampleType else { return ExportedHealthKitData(dataType: metric.name, startDate: start, endDate: end, data: []) }
        
        let results: [ExportedSample] = try await withCheckedThrowingContinuation { continuation in
            if useStatisticsQuery, let quantityType = sampleType as? HKQuantityType {
                let query = HKStatisticsCollectionQuery(quantityType: quantityType, quantitySamplePredicate: nil, anchorDate: start, intervalComponents: DateComponents(day: 7))
                
                query.initialResultsHandler = { query, collection, error in
                    self.handleStatistics(continuation, metric: metric, query, collection?.statistics(), error)
                }
                store.execute(query)
            } else {
                let query = HKSampleQuery(sampleType: sampleType, predicate: pred, limit: limit, sortDescriptors: nil, resultsHandler: { query, samples, error in
                    self.handleResults(continuation, metric: metric, query, samples, error)
                })
                
                store.execute(query)
            }
        }
        
        return ExportedHealthKitData(dataType: metric.name, startDate: start, endDate: end, data: results)
    }
    
    func handleResults(_ continuation: CheckedContinuation<[ExportedSample], Error>, metric: HealthMetric, _ query: HKQuery, _ samples: [HKSample]?, _ error: Error?) {
        if let error {
            continuation.resume(throwing: error)
        } else if let results = samples as? [HKQuantitySample] {
            let mapped = results.compactMap { sample in
                if let units = metric.units {
                    return ExportedSample(value: sample.quantity.doubleValue(for: units), start: sample.startDate, end: sample.endDate, metadata: sample.metadata, device: sample.device)
                }
                return nil
            }
            continuation.resume(returning: mapped)
        } else if let results = samples as? [HKCategorySample] {
            let mapped = results.compactMap { sample in
                ExportedSample(value: Double(sample.value), start: sample.startDate, end: sample.endDate, metadata: sample.metadata, device: sample.device)
            }
            continuation.resume(returning: mapped)
        } else {
            continuation.resume(throwing: HealthDataFetcherError.noResultsReturned)
        }
    }
    
    func handleStatistics(_ continuation: CheckedContinuation<[ExportedSample], Error>, metric: HealthMetric, _ query: HKQuery, _ samples: [HKStatistics]?, _ error: Error?) {
        if let error {
            continuation.resume(throwing: error)
        } else if let results = samples {
            let mapped = results.compactMap { sample in
                if let units = metric.units, let quantity = sample.averageQuantity() {
                    return ExportedSample(value: quantity.doubleValue(for: units), start: sample.startDate, end: sample.endDate, metadata: nil, device: nil)
                }
                return nil
            }
            continuation.resume(returning: mapped)
        } else if let results = samples as? [HKCategorySample] {
            let mapped = results.compactMap { sample in
                ExportedSample(value: Double(sample.value), start: sample.startDate, end: sample.endDate, metadata: sample.metadata, device: sample.device)
            }
            continuation.resume(returning: mapped)
        } else {
            continuation.resume(throwing: HealthDataFetcherError.noResultsReturned)
        }
    }
}

extension Date {
	public static var earliestHealthKitDate: Date {
		let components = DateComponents(year: 2015, month: 4, day: 24, hour: 0, minute: 0)
		return Calendar.current.date(from: components) ?? .distantPast
	}
}
