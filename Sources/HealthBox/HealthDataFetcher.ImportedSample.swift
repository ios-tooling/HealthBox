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
	public struct ImportedSample: Codable, Comparable {
		public let value: Double
		public let start: Date
		public let end: Date?
		public let metadata: CodableJSONDictionary?
		public let device: DeviceInfo?
		
		init(value: Double, start: Date, end: Date?, metadata: [String: Any]?, device: HKDevice?) {
			self.value = value
			self.start = start
			self.end = end
			self.metadata = CodableJSONDictionary(metadata)
			self.device = DeviceInfo(device)
		}
		
		public struct DeviceInfo: Codable, Equatable {
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
