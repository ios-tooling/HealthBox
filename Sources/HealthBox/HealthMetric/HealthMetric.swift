//
//  HealthMetric.swift
//  HealthBox
//
//  Created by Ben Gottlieb on 1/16/24.
//

import Foundation
import HealthKit

public struct HealthMetric: Equatable {
	public let typeIdentifier: HKQuantityTypeIdentifier?
	public let categoryIdentifier: HKCategoryTypeIdentifier?
	
	public let units: HKUnit?
	public let cumulative: Bool
	
	public var id: String { typeIdentifier?.rawValue ?? categoryIdentifier?.rawValue ?? "" }
	
	public var name: String {
		if let typeIdentifier { return typeIdentifier.rawValue.replacingOccurrences(of: "HKQuantityTypeIdentifier", with: "") }
		if let categoryIdentifier { return categoryIdentifier.rawValue.replacingOccurrences(of: "HKCategoryTypeIdentifier", with: "") }
		return "Unknown Metric"
	}
	
	public init(identifier: HKQuantityTypeIdentifier, units: HKUnit, cumulative: Bool) {
		typeIdentifier = identifier
		categoryIdentifier = nil
		self.units = units
		self.cumulative = cumulative
		Self.register(self)
	}
	
	public init(identifier: HKCategoryTypeIdentifier) {
		categoryIdentifier = identifier
		typeIdentifier = nil
		self.units = nil
		self.cumulative = false
		Self.register(self)
	}
	
	public var sampleType: HKSampleType? {
		if let typeIdentifier { return HKQuantityType.quantityType(forIdentifier: typeIdentifier)! }
		if let categoryIdentifier { return HKQuantityType.categoryType(forIdentifier: categoryIdentifier)! }
		return nil
	}

	public static func metric(with identifier: HKQuantityTypeIdentifier) -> HealthMetric? {
		let _ = HealthMetric.common
		return HealthMetric.all.first { $0.typeIdentifier == identifier }
	}
	
	public static func metric(with identifier: HKCategoryTypeIdentifier) -> HealthMetric? {
		let _ = HealthMetric.common
		return HealthMetric.all.first { $0.categoryIdentifier == identifier }
	}
	
	public static func metric(with name: String) -> HealthMetric? {
		let _ = HealthMetric.common
		return HealthMetric.all.first { $0.name == name }
	}
	
}

extension [HealthMetric] {
	var signature: String {
		map { $0.name }.sorted().joined(separator: ", ")
	}
}
