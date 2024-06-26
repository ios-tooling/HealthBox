//
//  HealthHistoryImporter+ImportProgress.swift
//  HealthBox
//
//  Created by Ben Gottlieb on 1/17/24.
//

import Foundation

extension HealthHistoryImporter {
	public struct ImportProgress: Codable, CustomStringConvertible, CustomDebugStringConvertible {
		public enum RangeType { case month, weeks(Int) }
		
		public var metricID: String
		public var latestData: Date
		public var earliestData: Date
		public var startReached = false
		public var firstDateWithNoContent: Date?
		
		public var description: String {
			"\(metricID): \(earliestData.formatted()) - \(latestData.formatted())"
		}
		
		public var debugDescription: String { description }
		
		init(metric: HealthMetric, date: Date = .now) {
			metricID = metric.id
			latestData = date.midnight
			earliestData = date.midnight
		}
		
		func nextRange(type: RangeType, latestWindowDate: Date = .now) -> DateInterval? {
			let ageFromWindow = latestWindowDate.timeIntervalSince(latestData)
			
			if ageFromWindow > .hour {		// grab the latest data
				return .init(start: min(latestWindowDate, latestData), end: latestWindowDate)
			}
			
			if startReached { return nil }
			let newEarliest = earliestData.addingTimeInterval(-1)
			
			switch type {
			case .month:
				if newEarliest.isSameMonth(as: latestWindowDate) {						// grab the earlier part of this month
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
		
		public func save() {
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
