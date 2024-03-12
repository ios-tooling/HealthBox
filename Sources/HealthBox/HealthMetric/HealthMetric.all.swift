//
//  HealthMetric.all.swift
//  HealthBox
//
//  Created by Ben Gottlieb on 1/17/24.
//

import Foundation
import HealthKit
import Combine

public extension HealthMetric {
	static let ofInterest: CurrentValueSubject<[HealthMetric], Never> = .init([])
	static let required: CurrentValueSubject<[HealthMetric], Never> = .init([])

	static let all: CurrentValueSubject<[HealthMetric], Never> = .init([])
	
	internal static func register(_ metric: HealthMetric) {
		if !all.value.contains(metric) { all.value.append(metric) }
	}
	
	static let heartRate = HealthMetric(identifier: .heartRate, units: .count().unitDivided(by: .second()), cumulative: false)
	static let activeEnergyBurned = HealthMetric(identifier: .activeEnergyBurned, units: .kilocalorie(), cumulative: true)
	static let stepCount = HealthMetric(identifier: .stepCount, units: .count(), cumulative: true)
	
	static let appleExerciseTime = HealthMetric(identifier: .appleExerciseTime, units: .minute(), cumulative: true)
	static let appleMoveTime = HealthMetric(identifier: .appleMoveTime, units: .minute(), cumulative: true)
	static let appleStandTime = HealthMetric(identifier: .appleStandTime, units: .minute(), cumulative: true)

	
	static let common: [HealthMetric] = [
		.activeEnergyBurned,
		.stepCount,
		.heartRate,
		
		.appleExerciseTime,
		.appleMoveTime,
		.appleStandTime,
		
		.init(identifier: .distanceWalkingRunning, units: .meter(), cumulative: true),
		.init(identifier: .distanceSwimming, units: .meter(), cumulative: true),
		.init(identifier: .distanceCycling, units: .meter(), cumulative: true),
		.init(identifier: .distanceWheelchair, units: .meter(), cumulative: true),
		.init(identifier: .restingHeartRate, units: .count().unitDivided(by: .second()), cumulative: false),
		.init(identifier: .walkingHeartRateAverage, units: .count().unitDivided(by: .second()), cumulative: false),

		.init(identifier: .sleepAnalysis),
	]

}
