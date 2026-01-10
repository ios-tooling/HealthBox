//
//  HealthDataFetcher.ExportedSample.swift
//  HealthBox
//
//  Created by Ben Gottlieb on 1/5/24.
//

import Foundation
import HealthKit
import Suite

public extension [HealthDataFetcher.ExportedSample] {
	var isSingleDay: Bool {
		let dates = map(\.start)
		
		guard let min = dates.min(), let max = dates.max() else { return false }
		let delta = abs(min.timeIntervalSince(max))
		
		return delta < .day * 11 / 10
	}
	
	var filteredForLargestSource: [Element] {
		guard let mostCommonSource else { return self }
		return self.filter { $0.source == mostCommonSource }
	}
	
	var mostCommonSource: HealthDataFetcher.ExportedSample.SourceInfo? {
		let sources = sources
		if sources.count <= 1 { return sources.first }
		
		var largest = 0
		var largestSource = sources.first
		
		for source in sources {
			let count = filter { $0.source == source }.count
			if count > largest {
				largest = count
				largestSource = source
			}
		}
		
		return largestSource
	}

	var sources: Set<HealthDataFetcher.ExportedSample.SourceInfo> {
		Set(self.compactMap { $0.source })
	}
}
