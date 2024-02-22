//
//  HealthDataFetcher.Sample.swift
//  HealthBox
//
//  Created by Ben Gottlieb on 1/5/24.
//

import Foundation
import HealthKit
import Suite

extension HealthDataFetcher {
	public struct Sample: Codable, Comparable {
		let value: Double
		let start: Date
		let end: Date?
		let metadata: CodableJSONDictionary?
		
		init(value: Double, start: Date, end: Date?, metadata: [String: Any]?) {
			self.value = value
			self.start = start
			self.end = end
			self.metadata = CodableJSONDictionary(metadata)
		}
		
		public static func <(lhs: Self, rhs: Self) -> Bool {
			lhs.start < rhs.start
		}
	}
}
