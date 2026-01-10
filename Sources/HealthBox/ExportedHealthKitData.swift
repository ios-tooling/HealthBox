//
//  ExportedHealthKitData.swift
//  HealthBox
//
//  Created by Ben Gottlieb on 1/12/24.
//

import Foundation
import Suite

public struct ExportedHealthKitData: Codable, CustomStringConvertible, Sendable, Identifiable {
	public var dataType: String
	public var startDate: Date
	public var endDate: Date
	public var data: [HealthDataFetcher.ExportedSample]
	public var metric: HealthMetric? { HealthMetric.metric(with: dataType) }

	public var id: String { dataType + startDate.description }

	public var description: String {
		"\(dataType): \(data.count) samples, " + startDate.formatted() + " - " + endDate.formatted()
	}
	
	public var isEmpty: Bool { data.isEmpty }
	public var range: DateInterval {
		.init(start: startDate, end: endDate)
	}
	
	public init(dataType: String, startDate: Date, endDate: Date, data: [HealthDataFetcher.ExportedSample]) {
		self.dataType = dataType
		self.startDate = startDate
		self.endDate = endDate
		self.data = data
	}
}

extension ExportedHealthKitData {
	public func inRange(_ range: DateInterval) -> Self {
		let newData = data.filter { sample in range.contains(sample.start) }
		
		return ExportedHealthKitData(dataType: dataType, startDate: startDate, endDate: endDate, data: newData)
	}
}
