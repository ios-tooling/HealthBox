//
//  ExportedHealthKitData.swift
//  HealthBox
//
//  Created by Ben Gottlieb on 1/12/24.
//

import Foundation
import Suite

public struct ExportedHealthKitData: Codable, CustomStringConvertible, Sendable {
	public let dataType: String
	public let startDate: Date
	public let endDate: Date
	public let data: [HealthDataFetcher.ExportedSample]
	
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
