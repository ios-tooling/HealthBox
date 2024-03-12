//
//  HealthHistoryImporter.swift
//  HealthBox
//
//  Created by Ben Gottlieb on 1/15/24.
//

import Foundation
import HealthKit
import Suite

public actor HealthHistoryImporter: ObservableObject {
	public static let instance = HealthHistoryImporter()
	
	public func resetProgress() {
		try? FileManager.default.removeItem(at: directory)
		try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
	}
	var historyFetchType = ImportProgress.RangeType.weeks(1)
	var noContentEndThresholdDuration = TimeInterval.day * 30 		// assume any gap longer than 30 days means there's no more data for this metric
	
	let directory: URL = {
		let url = URL.library(named: "imported_metrics")

		try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
		return url
	}()
	
	public func progress(for metric: HealthMetric) -> ImportProgress {
		let url = directory.appendingPathComponent(metric.id, conformingTo: .json)
		guard 
			let data = try? Data(contentsOf: url),
			let progress = try? JSONDecoder().decode(ImportProgress.self, from: data)
		else {
			return .init(metric: metric)
		}
		
		return progress
	}
	
	public func resetProgress(for metric: HealthMetric) {
		let url = directory.appendingPathComponent(metric.id, conformingTo: .json)
		try? FileManager.default.removeItem(at: url)
	}
	
	public func nextRange(for metric: HealthMetric) -> DateInterval? {
		progress(for: metric).nextRange(type: historyFetchType)
	}
	
	public func nextImport(for metric: HealthMetric) async throws -> ExportedHealthKitData? {
		var progress = progress(for: metric)
		guard let range = progress.nextRange(type: historyFetchType) else { return nil }
		
		let samples = try await HealthDataFetcher.instance.fetch(metric, start: range.start, end: range.end)
		
		progress.update(from: range)
		if samples.isEmpty {
			if let firstNoContentDate = progress.firstDateWithNoContent {
				progress.startReached = firstNoContentDate.timeIntervalSince(range.start) > noContentEndThresholdDuration
			} else {
				progress.firstDateWithNoContent = range.end
			}
		} else {
			progress.firstDateWithNoContent = nil
		}
		progress.save()
		return samples
	}
}
