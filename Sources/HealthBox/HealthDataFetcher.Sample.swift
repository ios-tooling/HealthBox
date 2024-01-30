//
//  HealthDataFetcher.Sample.swift
//  HealthBox
//
//  Created by Ben Gottlieb on 1/5/24.
//

import Foundation
import HealthKit

extension HealthDataFetcher {
	public struct Sample: Codable, Comparable {
		let value: Double
		let start: Date
		let end: Date?
		
		public static func <(lhs: Self, rhs: Self) -> Bool {
			lhs.start < rhs.start
		}
	}
}
