//
//  HealthHistoryImporter+ImportProgress.swift
//  HealthBox
//
//  Created by Ben Gottlieb on 1/17/24.
//

import Foundation

extension HealthHistoryImporter {
	struct ImportProgress: Codable, CustomStringConvertible, CustomDebugStringConvertible {
		enum RangeType { case month, weeks(Int) }
		
		var metricID: String
		var latestData: Date
		var earliestData: Date
		var startReached = false
		var firstDateWithNoContent: Date?
		
		var description: String {
			"\(metricID): \(earliestData.formatted()) - \(latestData.formatted())"
		}
		
		var debugDescription: String { description }
		
		init(metric: HealthMetric) {
			metricID = metric.id
			latestData = .now.midnight
			earliestData = .now.midnight
		}
		
		func nextRange(type: RangeType) -> DateInterval? {
			if abs(latestData.timeIntervalSinceNow) > .hour {		// grab the latest data
				return .init(start: latestData, end: .now)
			}
			
			if startReached { return nil }
			let newEarliest = earliestData.addingTimeInterval(-1)
			
			switch type {
			case .month:
				if newEarliest.isSameMonth(as: .now) {						// grab the earlier part of this month
					return .init(start: newEarliest.firstDayInMonth.midnight, end: newEarliest)
				}
				
				let start = newEarliest.previousDay.firstDayInMonth.midnight
				let end = start.lastDayInMonth.lastSecond
				
				return .init(start: start, end: end)
				
			case .weeks(let count):
				var start = newEarliest.previousDay
				for _ in 0..<count {
					start = start.previous(.sunday)
				}
				let end = newEarliest
				
				return .init(start: start, end: end)
			}
			
		}
		
		mutating func update(from interval: DateInterval) {
			if interval.start < earliestData {
				earliestData = interval.start
			} 
			
			if interval.end > latestData {
				latestData = interval.end
			}
		}
		
		func save() {
			do {
				let url = HealthHistoryImporter.instance.directory.appendingPathComponent(metricID, conformingTo: .json)
				let data = try? JSONEncoder().encode(self)
				try data?.write(to: url)
			} catch {
				print("Failed to save history: \(error)")
			}
		}
	}
}
