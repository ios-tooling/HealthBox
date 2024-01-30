//
//  HealthDataFetcher.swift
//  HealthBox
//
//  Created by Ben Gottlieb on 1/5/24.
//

import Foundation
import HealthKit

public class HealthDataFetcher {
	public static let instance = HealthDataFetcher()
	
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
		
		let results: [Sample] = try await withCheckedThrowingContinuation { continuation in
			let query = HKSampleQuery(sampleType: sampleType, predicate: pred, limit: limit, sortDescriptors: nil, resultsHandler: { query, samples, error in
				if let error {
					continuation.resume(throwing: error)
				} else if let results = samples as? [HKQuantitySample] {
					let mapped = results.compactMap { sample in
						if let units = metric.units {
							return Sample(value: sample.quantity.doubleValue(for: units), start: sample.startDate, end: sample.endDate)
						}
						return nil
					}
					continuation.resume(returning: mapped)
				} else if let results = samples as? [HKCategorySample] {
					let mapped = results.compactMap { sample in
						Sample(value: Double(sample.value), start: sample.startDate, end: sample.endDate)
					}
					continuation.resume(returning: mapped)
				} else {
					continuation.resume(throwing: HealthDataFetcherError.noResultsReturned)
				}
			})
		
			store.execute(query)
		}
		
		return ExportedHealthKitData(dataType: metric.name, startDate: start, endDate: end, data: results)
	}
	
}

extension Date {
	public static var earliestHealthKitDate: Date {
		let components = DateComponents(year: 2015, month: 4, day: 24, hour: 0, minute: 0)
		return Calendar.current.date(from: components) ?? .distantPast
	}
}
