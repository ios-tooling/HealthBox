//
//  HealthMetric.swift
//  HealthBox
//
//  Created by Ben Gottlieb on 1/16/24.
//

import Foundation
@preconcurrency import HealthKit

extension HKCategoryTypeIdentifier: Codable { }

public struct HealthMetric: Equatable, Sendable, Codable {
	enum CodingKeys: String, CodingKey { case type, category, units, cumulative }
	public let typeIdentifier: HKQuantityTypeIdentifier?
	public let categoryIdentifier: HKCategoryTypeIdentifier?
	
	public let units: HKUnit?
	public let cumulative: Bool
	
	public var id: String { typeIdentifier?.rawValue ?? categoryIdentifier?.rawValue ?? "" }
	
	public init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		if let type = try container.decodeIfPresent(String.self, forKey: .type) {
			typeIdentifier = HKQuantityTypeIdentifier(rawValue: type)
		} else {
			typeIdentifier = nil
		}
		categoryIdentifier = try container.decodeIfPresent(HKCategoryTypeIdentifier.self, forKey: .category)
		
		if let unitString = try container.decodeIfPresent(String.self, forKey: .units) {
			units = HKUnit(from: unitString)
		} else {
			units = nil
		}
		
		cumulative = try container.decode(Bool.self, forKey: .cumulative)
	}
	
	public func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		
		if let typeIdentifier { try container.encode(typeIdentifier.rawValue, forKey: .type) }
		if let categoryIdentifier { try container.encode(categoryIdentifier, forKey: .category) }
		
		if let units { try container.encode(units.unitString, forKey: .units) }
		try container.encodeIfPresent(cumulative, forKey: .cumulative)
	}
	
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
		return HealthMetric.all.value.first { $0.typeIdentifier == identifier }
	}
	
	public static func metric(with identifier: HKCategoryTypeIdentifier) -> HealthMetric? {
		let _ = HealthMetric.common
		return HealthMetric.all.value.first { $0.categoryIdentifier == identifier }
	}
	
	public static func metric(with name: String) -> HealthMetric? {
		let _ = HealthMetric.common
		return HealthMetric.all.value.first { $0.name == name }
	}
	
}

extension [HealthMetric] {
	var signature: String {
		map { $0.name }.sorted().joined(separator: ", ")
	}
}
