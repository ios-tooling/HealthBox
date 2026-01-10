//
//  HealthDataFetcher.ExportedSample.swift
//  HealthBox
//
//  Created by Ben Gottlieb on 1/5/24.
//

import Foundation
import HealthKit
import Suite

extension HealthDataFetcher {
	public struct ExportedSample: Codable, Comparable, Sendable, Equatable, Hashable {
		public let value: Double
		public let start: Date
		public let end: Date?
		public let metadata: CodableJSONDictionary?
		public let device: DeviceInfo?
		public let source: SourceInfo?
		public let timeZone: String?
		
		init(value: Double, start: Date, end: Date?, metadata: [String: Any]?, device: HKDevice?, source: HKSourceRevision?, timeZone: String?) {
			self.value = value
			self.start = start
			self.end = end
			self.metadata = CodableJSONDictionary(metadata)
			self.device = .init(device)
			self.source = .init(source)
			self.timeZone = timeZone
		}
		
		public func hash(into hasher: inout Hasher) {
			hasher.combine(device)
			hasher.combine(start)
			hasher.combine(end)
			hasher.combine(value)
		}

		
		public struct SourceInfo: Codable, Equatable, Sendable, Hashable {
			public let name: String?
			public let identifier: String?
			public let version: String?
			public let productType: String?
			public let operatingSystemVersion: String?
			
			public static func ==(lhs: Self, rhs: Self) -> Bool { lhs.identifier == rhs.identifier }
			public func hash(into hasher: inout Hasher) {
				hasher.combine(identifier)
			}
			
			init?(_ revision: HKSourceRevision?) {
				guard let revision else { return nil }
				name = revision.source.name
				identifier = revision.source.bundleIdentifier
				version = revision.version
				productType = revision.productType
				operatingSystemVersion = "\(revision.operatingSystemVersion.majorVersion).\(revision.operatingSystemVersion.minorVersion).\(revision.operatingSystemVersion.patchVersion)"
			}
		}
		
		public struct DeviceInfo: Codable, Equatable, Sendable, Hashable {
			public let name: String?
			public let manufacturer: String?
			public let model: String?
			public let udiDeviceIdentifier: String?
			public let hardwareVersion: String?
			public let softwareVersion: String?
			public let firmwareVersion: String?
			
			init?(_ device: HKDevice?) {
				guard let device else { return nil }
				name = device.name
				manufacturer = device.manufacturer
				model = device.model
				udiDeviceIdentifier = device.udiDeviceIdentifier
				firmwareVersion = device.firmwareVersion
				softwareVersion = device.softwareVersion
				hardwareVersion = device.hardwareVersion
			}
		}
		
		public static func <(lhs: Self, rhs: Self) -> Bool {
			lhs.start < rhs.start
		}
	}
}
