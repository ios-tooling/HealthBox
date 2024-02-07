//
//  HealthMetric.all.swift
//  HealthBox
//
//  Created by Ben Gottlieb on 1/17/24.
//

import Foundation
import HealthKit

public extension HealthMetric {
	static var ofInterest: [HealthMetric] = []
	static var required: [HealthMetric] = []

	static var all: [HealthMetric] = []
	
	internal static func register(_ metric: HealthMetric) {
		if !all.contains(metric) { all.append(metric) }
	}
	
	static let common: [HealthMetric] = [
		.init(identifier: .activeEnergyBurned, units: .kilocalorie(), cumulative: true),
		.init(identifier: .stepCount, units: .count(), cumulative: true),
		.init(identifier: .heartRate, units: .count().unitDivided(by: .second()), cumulative: false),

		.init(identifier: .appleExerciseTime, units: .minute(), cumulative: true),
		.init(identifier: .appleMoveTime, units: .minute(), cumulative: true),
		.init(identifier: .appleStandTime, units: .minute(), cumulative: true),
		
		.init(identifier: .distanceWalkingRunning, units: .meter(), cumulative: true),
		.init(identifier: .distanceSwimming, units: .meter(), cumulative: true),
		.init(identifier: .distanceCycling, units: .meter(), cumulative: true),
		.init(identifier: .distanceWheelchair, units: .meter(), cumulative: true),
		.init(identifier: .restingHeartRate, units: .count().unitDivided(by: .second()), cumulative: false),
		.init(identifier: .walkingHeartRateAverage, units: .count().unitDivided(by: .second()), cumulative: false),

		.init(identifier: .sleepAnalysis),
	]

}
