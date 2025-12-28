//
//  HKObject.swift
//  HealthBox
//
//  Created by Ben Gottlieb on 12/24/25.
//

import Foundation
import HealthKit

public extension HKObject {
	var timeZone: TimeZone? {
		metadata?[HKMetadataKeyTimeZone] as? TimeZone
	}
}
